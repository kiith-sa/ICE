
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
    ///         width    = Window width.
    ///         height   = Window height.
    this(Platform platform, uint width, uint height)
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
        auto layoutSource    = loadYAML("{x: 0, y: 0, w: " ~ to!string(width) ~ 
                                        ",h: " ~ to!string(height) ~ "}"); 
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

    /// Load a widget tree connectable to a SlotWidget from YAML.
    RootWidget loadWidgetTree(YAMLNode source)
    {
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

    /// Render the GUI.
    void render(VideoDriver video)
    {
        static RenderEvent renderEvent;
        if(null is renderEvent){renderEvent = new RenderEvent();}

        // Save view zoom and offset.
        const zoom   = video.zoom;
        const offset = video.viewOffset; 

        // Set no zoom and zero offset for GUI drawing.
        video.zoom       = 1.0;
        video.viewOffset = Vector2d(0.0, 0.0);

        renderEvent.videoDriver = video;
        rootSlot_.handleEvent(renderEvent);

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

    /// Set the currently focused widget. Can be called by Widget only.
    @property void focusedWidget(Widget rhs)
    {
        if(focusedWidget_ !is null)
        {
            focusedWidget_.lostFocusPackage();
        }
        focusedWidget_ = rhs;
        if(focusedWidget_ !is null)
        {
            focusedWidget_.gotFocusPackage();
        }
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
    }

    /// Process mouse key input.
    /// 
    /// Params:  state    = State of the key.
    ///          key      = Mouse key.
    ///          position = Position of the mouse.
    void inputMouseKey(KeyState state, MouseKey key, Vector2u position)
    {
        static MouseKeyEvent keyEvent;
        if(null is keyEvent){keyEvent = new MouseKeyEvent();}

        keyEvent.state    = state;
        keyEvent.key      = key;
        keyEvent.position = position;

        rootSlot_.handleEvent(keyEvent);
    }

    /// Process mouse movement.
    /// 
    /// Params:  position = Position of the mouse in screen coordinates.
    ///          relative = Relative movement of the mouse.
    void inputMouseMove(Vector2u position, Vector2i relative)
    {
        static MouseMoveEvent moveEvent;
        if(null is moveEvent){moveEvent = new MouseMoveEvent();}

        moveEvent.relative = relative;
        moveEvent.position = position;
        mousePosition_     = position;

        rootSlot_.handleEvent(moveEvent);
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
        // Parse layout, style manager types.
        bool popStyle  = false;
        bool popLayout = false;
        scope(exit)
        {
            if(popStyle) {styleManagerStack_.popBack();}
            if(popLayout){layoutManagerStack_.popBack();}
        }
        if(source.contains("styleManager"))
        {
            styleManagerStack_ ~= source["styleManager"].as!string;
            popStyle = true;
        }
        if(source.contains("layoutManager"))
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
