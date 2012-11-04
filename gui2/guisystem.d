
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// The main GUI class.
module gui2.guisystem;

import std.algorithm;
import std.array;
import std.conv;
import std.exception;
import std.stdio;
import std.typecons;

import gui2.boxmanuallayout;
import gui2.buttonwidget;
import gui2.containerwidget;
import gui2.event;
import gui2.exceptions;
import gui2.fixedlayout;
import gui2.layout;
import gui2.rootwidget;
import gui2.slotwidget;
import gui2.labelwidget;
import gui2.lineeditwidget;
import gui2.linestylemanager;
import gui2.stylemanager;
import gui2.widget;
import math.vector2;
import platform.key;
import platform.platform;
import util.yaml;
import video.videodriver;


/// The main GUI class. Manages widgets, emits events, etc.
class GUISystem
{
private:
    // Platform to use for user input.
    Platform platform_;

    // The root of the widget tree.
    SlotWidget rootSlot_;

    // Widget currently focused for mouse/keyboard input (if any).
    Widget focusedWidget_;

    // Current mouse position.
    Vector2u mousePosition_;

    // Widget construction functions indexed by widget type name in YAML.
    //
    // A widget constructor might throw a WidgetInitException on failure.
    Widget delegate(ref YAMLNode)[string] widgetCtors_;

    // Layout construction functions indexed by layout type name in YAML.
    //
    // A layout constructor might throw a LayoutInitException on failure.
    Layout delegate(YAMLNode*)[string] layoutCtors_;

    // StyleManager construction functions indexed by style manager type name in YAML.
    //
    // A style manager constructor might throw a StyleInitException on failure.
    StyleManager delegate(ref Tuple!(string, YAMLNode)[])[string] styleCtors_;

public:
    /// Construct the GUISystem.
    ///
    /// Params: platform = Platform to use for user input.
    this(Platform platform)
    {
        platform_ = platform;
        platform.key.connect(&inputKey);
        platform.mouseMotion.connect(&inputMouseMove);
        platform.mouseKey.connect(&inputMouseKey);

        // Builtin widget constructors.
        addWidgetConstructor("root",      (ref YAMLNode yaml) => new RootWidget(yaml));
        addWidgetConstructor("slot",      (ref YAMLNode yaml) => new SlotWidget(yaml));
        addWidgetConstructor("container", (ref YAMLNode yaml) => new ContainerWidget(yaml));
        addWidgetConstructor("button",    (ref YAMLNode yaml) => new ButtonWidget(yaml));
        addWidgetConstructor("label",     (ref YAMLNode yaml) => new LabelWidget(yaml));
        addWidgetConstructor("lineEdit",  (ref YAMLNode yaml) => new LineEditWidget(yaml));

        // Builtin layout constructors.
        Layout boxManualCtor(YAMLNode* yaml)
        {
            static msg = "Missing layout parameters; boxManual layout manager "
                         "requires layout parameters to be specified for every widget";
            enforce(yaml !is null, new LayoutInitException (msg));
            return new BoxManualLayout(*yaml);
        }
        Layout fixedCtor(YAMLNode* yaml)
        {
            static msg = "Missing layout parameters; fixed layout manager "
                         "requires layout parameters to be specified for every widget";
            enforce(yaml !is null, new LayoutInitException (msg));
            return new FixedLayout(*yaml);
        }
        addLayoutConstructor("boxManual", &boxManualCtor);
        addLayoutConstructor("fixed", &fixedCtor);

        // Builtin style manager constructors.
        StyleManager lineStyleManagerCtor(ref Tuple!(string, YAMLNode)[] namedStyles)
        {
            bool foundDefault = false;
            LineStyleManager.Style[] styles;
            foreach(ref named; namedStyles)
            {
                foundDefault = foundDefault || named[0] == "";
                styles ~= LineStyleManager.Style(named[1], named[0]);
            }
            if(!foundDefault)
            {
                styles ~= LineStyleManager.Style.init;
            }

            return new LineStyleManager(styles);
        }

        addStyleConstructor("line", &lineStyleManagerCtor);
        auto dummyMapping    = loadYAML("{}");
        rootSlot_            = new SlotWidget(dummyMapping);
        auto styleSource     = loadYAML("{drawBorder: false}");
        auto slotDummyStyles = [LineStyleManager.Style(styleSource, "")];
        auto layoutSource    = loadYAML("{x: 0, y: 0, w: 640, h: 480}"); 
        rootSlot_.init("", this, cast(Widget[])[], new FixedLayout(layoutSource),
                       new LineStyleManager(slotDummyStyles));
    }

    /// Destroy the GUISystem.
    ~this()
    {
        platform_.key.disconnect(&inputKey);
        platform_.mouseMotion.disconnect(&inputMouseMove);
        platform_.mouseKey.disconnect(&inputMouseKey);
    }

    /// Set size of the root widget.
    ///
    /// Params: width  = Window width.
    ///         height = Window height.
    void setGUISize(const uint width, const uint height)
    {
        auto rootLayout = cast(FixedLayout)rootSlot_.layout;
        assert(rootLayout !is null, "Root widget layout must be a FixedLayout");
        rootLayout.setSize(width, height);
        updateLayout();
    }

    /// Load a widget tree connectable to a SlotWidget from YAML.
    RootWidget loadWidgetTree(YAMLNode source)
    {
        scope(failure)
        {
            writeln("GUISystem.loadWidgetTree() or a callee failed");
        }
        try
        {
            auto loader = WidgetLoader(this);
            return loader.parseRootWidget(source);
        }
        catch(YAMLException e)
        {
            throw new GUIInitException("Could not load a widget tree: " ~ e.msg);
        }
    }

    /// Get the root SlotWidget.
    @property SlotWidget rootSlot()
    {
        return rootSlot_;
    }

    /// Get the currently focused widget, if any.
    @property Widget focusedWidget() pure nothrow 
    {
        return focusedWidget_;
    }

    /// Set the currently focused widget.
    @property void focusedWidget(Widget rhs)
    {
        /// If we're setting focus for already focused widget, don't make
        /// it lose/regain focus
        bool noChange = rhs is focusedWidget_;
        if(!noChange && focusedWidget_ !is null)
        {
            focusedWidget_.lostFocusPackage();
        }
        focusedWidget_ = rhs;
        if(!noChange && focusedWidget_ !is null)
        {
            focusedWidget_.gotFocusPackage();
        }
    }

    /// Render the GUI.
    void render(VideoDriver video)
    {
        static RenderEvent event;
        if(null is event){event = new RenderEvent();}

        // Save view zoom and offset.
        const zoom   = video.zoom;
        const offset = video.viewOffset; 

        // Set no zoom and zero offset for GUI drawing.
        video.zoom       = 1.0;
        video.viewOffset = Vector2d(0.0, 0.0);

        event.videoDriver = video;
        rootSlot_.handleEvent(event);

        // Restore zoom and offset.
        video.zoom       = zoom;
        video.viewOffset = offset;
    }

    /// Add a widget constructor function.
    ///
    /// This can be used to add support for new widget types. The constructor function
    /// will usually just call the constructor of the widget.
    ///
    /// This can be only called once per widget type name - this means that
    /// constructor functions for builtin widgets (e.g. "button") can't be 
    /// replaced.
    ///
    /// Params: widgetYAMLName = YAML widgets with this widget type name will
    ///                          be constructed with given constructor function.
    ///         widgetCtor     = Constructs a widget of from a YAML node.
    ///                          It can throw a WidgetInitException.
    void addWidgetConstructor(string widgetYAMLName, 
                              Widget delegate(ref YAMLNode) widgetCtor)
    {
        assert((widgetYAMLName in widgetCtors_) is null,
               "There already is a widget constructor for widget name " ~ widgetYAMLName);
        widgetCtors_[widgetYAMLName] = widgetCtor;
    }

    /// Add a layout constructor function.
    ///
    /// This can be used to add support for new layout types. The constructor function
    /// will usually just call the constructor of the layout.
    ///
    /// This can be only called once per layout type name - this means that
    /// constructor functions for builtin layouts (e.g. "boxManual") can't be 
    /// replaced.
    ///
    /// A widget might not specify layout parameters; in that case, the YAML node 
    /// pointer passed to layoutCtor is null. The function might then e.g. 
    /// default-construct the layout.
    ///
    /// Params: layoutYAMLName = YAML layout managers with this "layoutManager"
    ///                          name will be constructed with given constructor function.
    ///         layoutCtor     = Constructs a layout of from a YAML node.
    ///                          It can throw a LauoutInitException.
    void addLayoutConstructor(string layoutYAMLName, 
                              Layout delegate(YAMLNode*) layoutCtor)
    {
        assert((layoutYAMLName in layoutCtors_) is null,
               "There already is a layout constructor for layout name " ~ layoutYAMLName);
        layoutCtors_[layoutYAMLName] = layoutCtor;
    }

    /// Add a style manager constructor function.
    ///
    /// This can be used to add support for new style manager types. 
    /// The constructor function will usually just call the constructor 
    /// of the style manager.
    ///
    /// This can be only called once per style manager type name - this means that
    /// constructor functions for builtin style managers (e.g. "line") can't be 
    /// replaced.
    ///
    /// The style manager constructor is passed an array of named YAML nodes,
    /// each of which represents a style. If there is no default style 
    /// (unnamed, just "style"), it must be added in the constructor function.
    /// 
    /// Params: styleYAMLName = YAML style managers with this "styleManager"
    ///                         name will be constructed with given constructor function.
    ///         styleCtor     = Constructs a style manager of from an array of 
    ///                         name-YAMLNode pairs.
    ///                         It can throw a StyleInitException.
    void addStyleConstructor(string styleYAMLName, 
                             StyleManager delegate(ref Tuple!(string, YAMLNode)[]) styleCtor)
    {
        assert((styleYAMLName in styleCtors_) is null,
               "There already is a style manager constructor for style manager name "
               ~ styleYAMLName);
        styleCtors_[styleYAMLName] = styleCtor;
    }

package:
    /// Update layout of all widgets (e.g. after a new RootWidget is connected).
    void updateLayout()
    {
        // Reusing the same instances every time to avoid unnecessary allocation.
        static MinimizeEvent minimizeEvent;
        static ExpandEvent expandEvent;
        if(null is minimizeEvent){minimizeEvent = new MinimizeEvent();}
        if(null is expandEvent)  {expandEvent   = new ExpandEvent();}
        rootSlot_.handleEvent(minimizeEvent);
        rootSlot_.handleEvent(expandEvent);
    }

    /// Get current mouse position.
    @property Vector2u mousePosition() const pure nothrow
    {
        return mousePosition_;
    }

private:
    /// Process keyboard input.
    /// 
    /// Params:  state   = State of the key.
    ///          key     = Keyboard key.
    ///          unicode = Unicode value of the key.
    void inputKey(KeyState state, Key key, dchar unicode)
    {
        static KeyboardEvent event;
        if(null is event){event = new KeyboardEvent();}

        event.state   = state;
        event.key     = key;
        event.unicode = unicode;

        rootSlot_.handleEvent(event);
    }

    /// Process mouse key input.
    /// 
    /// Params:  state    = State of the key.
    ///          key      = Mouse key.
    ///          position = Position of the mouse.
    void inputMouseKey(KeyState state, MouseKey key, Vector2u position)
    {
        static MouseKeyEvent event;
        if(null is event){event = new MouseKeyEvent();}

        event.state    = state;
        event.key      = key;
        event.position = position;

        rootSlot_.handleEvent(event);
    }

    /// Process mouse movement.
    /// 
    /// Params:  position = Position of the mouse in screen coordinates.
    ///          relative = Relative movement of the mouse.
    void inputMouseMove(Vector2u position, Vector2i relative)
    {
        static MouseMoveEvent event;
        if(null is event){event = new MouseMoveEvent();}

        event.relative = relative;
        event.position = position;
        mousePosition_ = position;

        rootSlot_.handleEvent(event);
    }
}

/// Builds widgets dynamically.
struct WidgetBuilder
{
private:
    // Reference to the GUI system (widget/layout/style constructors).
    GUISystem guiSystem_;
    // Parent widget builder (when building nested widgets).
    WidgetBuilder* parent_;
    // Widgets built so far by calls to buildWidget().
    //
    // When building nested widget, these are the children of the widget 
    // built by the parent WidgetBuilder.
    Widget[] builtWidgets_;

    // The following data members are parameters of the widget currently being built.

    // Widget type specific parameters, if any (i.e. not common ones like style, etc.).
    string widgetParams_;
    // Name of the layout type for the widget to use.
    string layoutType_;
    // Layout parameters, if any.
    string layoutParams_;

    // Name of the style manager type for the widget to use.
    string styleManager_;
    // An array of name-parameters tuples of the widget's styles.
    Tuple!(string, string)[] stylesParameters_;
    // Name of the widget, if any.
    string name_;

public:
    /// Construct a WidgetBuilder building widgets with/for specified GUISystem.
    this(GUISystem guiSystem)
    {
        guiSystem_ = guiSystem;
        parent_    = null;
    }

    /// Build a widget.
    ///
    /// The widget is built by the passed delegate that recursively builds
    /// subwidgets.
    /// The topmost widget should always be a RootWidget ("root"), to 
    /// get a result that can be connected to other widget (through a SlotWidget).
    ///
    /// Params: widgetTypeName = Name of the widget type (the same as used in YAML).
    ///         buildDg        = Builds the widget by specifying parameters 
    ///                          like layout and style to the passed WidgetBuilder 
    ///                          and even building subWidgets through buildWidget 
    ///                          calls.
    ///
    /// Throws: GUIInitException on failure.
    void buildWidget(string widgetTypeName)
                    (void delegate(ref WidgetBuilder b) buildDg)
    {
        try
        {
            // Default widget parameters.
            widgetParams_     = "{}";
            layoutType_       = "boxManual";
            layoutParams_     = null;
            styleManager_     = "line";
            name_             = null;
            stylesParameters_ = [];

            // Builder for any nested widget.
            auto subBuilder = WidgetBuilder(guiSystem_, &this);
            // Call the build delegate, setting widget parameters and building subwidgets.
            buildDg(subBuilder);

            // Construct widget layout.
            auto layoutCtor = layoutType_ in guiSystem_.layoutCtors_;
            enforce(layoutCtor !is null,
                    new GUIInitException("Unknown layout manager: " ~ layoutType_));
            YAMLNode layoutYAML;
            if(layoutParams_ !is null){layoutYAML = loadYAML(layoutParams_);}
            auto layout = (*layoutCtor)(layoutParams_ is null ? null : &layoutYAML);

            // Construct the style manager of the widget.
            Tuple!(string, YAMLNode)[] yamlStylesParameters;
            foreach(namedStyle; stylesParameters_)
            {
                yamlStylesParameters ~= tuple(namedStyle[0], loadYAML(namedStyle[1]));
            }
            auto styleCtor = styleManager_ in guiSystem_.styleCtors_;
            enforce(styleCtor !is null,
                    new GUIInitException("Unknown style manager: " ~ styleManager_));
            auto styleManager = (*styleCtor)(yamlStylesParameters);

            // Construct the widget.
            auto widgetCtor = widgetTypeName in guiSystem_.widgetCtors_;
            enforce(widgetCtor !is null,
                    new GUIInitException("Unknown widget type: " ~ widgetTypeName));
            auto widgetYAML = loadYAML(widgetParams_);
            auto result = (*widgetCtor)(widgetYAML);
            result.init(name_, guiSystem_, subBuilder.builtWidgets,
                        layout, styleManager);

            builtWidgets_ ~= result;
        }
        catch(YAMLException e)
        {
            throw new WidgetInitException(
                "Could not build a widget (" ~ widgetTypeName ~ ") due to a "
                "YAML error: " ~ e.msg);
        }
    }

    /// Set widget type specific parameters, if any (i.e. not common ones like style, etc.).
    ///
    /// Can only be called by build delegates passed to buildWidget().
    @property void widgetParams(const string params) pure nothrow
    {
        assert(parent_ !is null, "Trying to set widget parameters when not building a widget");
        parent_.widgetParams_ = params;
    }

    /// Set widget name, if any.
    ///
    /// Can only be called by build delegates passed to buildWidget().
    @property void name(const string name) pure nothrow
    {
        assert(parent_ !is null, "Trying to set widget name when not building a widget");
        parent_.name_ = name;
    }

    /// Set layout type.
    ///
    /// Can only be called by build delegates passed to buildWidget().
    @property void layoutManager(const string manager) pure nothrow
    {
        assert(parent_ !is null, "Trying to set layout manager when not building a widget");
        parent_.layoutType_ = manager;
    }

    /// Set layout parameters.
    ///
    /// Can only be called by build delegates passed to buildWidget().
    @property void layout(const string layoutParams) pure nothrow
    {
        assert(parent_ !is null, "Trying to set layout parameters when not building a widget");
        parent_.layoutParams_ = layoutParams;
    }

    /// Set style manager type.
    ///
    /// Can only be called by build delegates passed to buildWidget().
    @property void styleManager(const string styleManager) pure nothrow
    {
        assert(parent_ !is null, "Trying to set style manager when not building a widget");
        parent_.styleManager_ = styleManager;
    }

    /// Set parameters of style with specified name.
    ///
    /// Can only be called by build delegates passed to buildWidget().
    void style(string name, string styleParams) pure nothrow
    {
        assert(parent_ !is null, "Trying to set a style when not building a widget");
        parent_.stylesParameters_ ~= tuple(name, styleParams);
    }

    /// Get all widgets built by this WidgetBuilder so far.
    @property Widget[] builtWidgets() pure nothrow
    {
        return builtWidgets_;
    }

private:
    /// Construct a nested WidgetBuilder building subwidgets of the widget
    /// currently being built by parent WidgetBuilder.
    this(GUISystem guiSystem, WidgetBuilder* parent)
    {
        guiSystem_ = guiSystem;
        parent_    = parent;
    }
}


private:

/// Encapsulates widget loading code.
///
/// This struct is only used by the GUISystem to load a widget tree.
struct WidgetLoader
{
private:
    /// GUI system that constructed this WidgetLoader.
    GUISystem guiSystem_;

    //TODO once tested, use vectors

    /// Stack keeping track of the style manager used in the current widget.
    ///
    /// Layout managers specified in parent widgets are recursively used 
    /// in their children. 
    string[] styleManagerStack_  = ["line"];
    /// Stack keeping track of the layout type used in the current widget.
    ///
    /// Layout types specified in parent widgets are recursively used 
    /// in their children. 
    string[] layoutManagerStack_ = ["boxManual"];

    @disable this();
    @disable this(this);
package:
    /// Construct a WidgetLoader loading widgets for specified GUI system.
    this(GUISystem guiSystem)
    {
        guiSystem_ = guiSystem;
    }

    /// Parse a root widget, and recursively, its widget tree.
    ///
    /// Params: source = Root node of the YAML tree to parse.
    ///
    /// Throws: GUIInitException on failure.
    RootWidget parseRootWidget(ref YAMLNode source)
    {
        return cast(RootWidget)parseWidget(source, guiSystem_.widgetCtors_["root"], null);
    }

private:
    /// Parse a widget (and recursively, its subwidgets) from YAML.
    ///
    /// Params: source     = Root node of the YAML tree to parse.
    ///         widgetCtor = Function that construct the widget of correct type
    ///                      (determined by the caller).
    ///         name       = Name of the widget. null if no name.
    ///
    /// Throws: GUIInitException on failure.
    Widget parseWidget(ref YAMLNode source, 
                       Widget delegate(ref YAMLNode) widgetCtor,
                       string name)
    {
        scope(failure)
        {
            writeln("WidgetLoader.parseWidget() or a callee failed");
        }
        // Parse layout, style manager types.
        bool popStyle  = false;
        bool popLayout = false;
        scope(exit)
        {
            if(popStyle) {styleManagerStack_.popBack();}
            if(popLayout){layoutManagerStack_.popBack();}
        }
        if(source.containsKey("styleManager"))
        {
            styleManagerStack_ ~= source["styleManager"].as!string;
            popStyle = true;
        }
        if(source.containsKey("layoutManager"))
        {
            layoutManagerStack_ ~= source["layoutManager"].as!string;
            popLayout = true;
        }

        Widget[] children;
        Tuple!(string, YAMLNode)[] stylesParameters;
        bool layoutParametersSpecified = false;
        YAMLNode layoutParameters;

        /// Parse the widget's attributes and subwidgets.
        foreach(string key, ref YAMLNode value; source)
        {
            // A subwidget.
            if(key.startsWith("widget"))
            {
                auto parts = key.split(" ");
                enforce(parts.length >= 2,
                        new GUIInitException("Can't parse a widget without widget type"));
                string type = parts[1];
                string subWidgetName = parts.length == 2 ? null : parts[2];

                auto ctor = type in guiSystem_.widgetCtors_;
                enforce(ctor !is null,
                        new GUIInitException("Unknown widget type in YAML: " ~ type));
                children ~= parseWidget(value, *ctor, subWidgetName);
            }
            // Parameters of a style ("style" is default style, "style xxx" is style xxx)..
            // Need to not try to read "styleManager"
            else if(key == "style" || key.startsWith("style "))
            {
                auto parts = key.split(" ");
                stylesParameters ~= tuple(parts.length >= 2 ? parts[1] : "",
                                          value);
            }
            // Layout parameters.
            else if(key == "layout")
            {
                layoutParameters = value;
                layoutParametersSpecified = true;
            }
        }

        // Construct the layout.
        auto layoutType = layoutManagerStack_.back;
        auto layoutCtor = layoutType in guiSystem_.layoutCtors_;
        enforce(layoutCtor !is null,
                new GUIInitException("Unknown layout manager in YAML: " ~ layoutType));
        auto layout = (*layoutCtor)(layoutParametersSpecified ? &layoutParameters : null);

        // Construct the style manager.
        auto styleType = styleManagerStack_.back;
        auto styleCtor = styleType in guiSystem_.styleCtors_;
        enforce(styleCtor !is null,
                new GUIInitException("Unknown style manager in YAML: " ~ styleType));
        auto styleManager = (*styleCtor)(stylesParameters);

        // Construct the widget and return it.
        Widget result = widgetCtor(source);
        result.init(name, guiSystem_, children, layout, styleManager);
        return result;
    }
}
