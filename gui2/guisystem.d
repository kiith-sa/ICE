
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

import dgamevfs._;

import containers.vector;
import formats.image;
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
import gui2.progressbarwidget;
import gui2.stylemanager;
import gui2.widget;
import image;
import math.rect;
import math.vector2;
import platform.key;
import platform.platform;
import util.resourcemanager;
import util.yaml;
import video.texture;
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

    // Resource manager that manages loading of textures used by the GUI.
    //
    // Textures might be unloaded if the video driver is replaced,
    // so they should always be accessed through this manager.
    ResourceManager!Texture textureManager_;

    // Video driver used for the last render() call.
    //
    // A reference is kept here for textureManager_. If
    // the video driver changes, all textures are unloaded.
    VideoDriver video_;

    // Game data directory (used to load style sheets referenced by GUI sources).
    VFSDir gameDir_;

public:
    /// Construct the GUISystem.
    ///
    /// Params: platform = Platform to use for user input.
    ///         gameDir  = Game data directory.
    this(Platform platform, VFSDir gameDir)
    {
        platform_ = platform;
        gameDir_  = gameDir;
        platform.key.connect(&inputKey);
        platform.mouseMotion.connect(&inputMouseMove);
        platform.mouseKey.connect(&inputMouseKey);

        // Builtin widget constructors.
        addWidgetConstructor("root",        (ref YAMLNode yaml) => new RootWidget(yaml));
        addWidgetConstructor("slot",        (ref YAMLNode yaml) => new SlotWidget(yaml));
        addWidgetConstructor("container",   (ref YAMLNode yaml) => new ContainerWidget(yaml));
        addWidgetConstructor("button",      (ref YAMLNode yaml) => new ButtonWidget(yaml));
        addWidgetConstructor("label",       (ref YAMLNode yaml) => new LabelWidget(yaml));
        addWidgetConstructor("lineEdit",    (ref YAMLNode yaml) => new LineEditWidget(yaml));
        addWidgetConstructor("progressBar", (ref YAMLNode yaml) => new ProgressBarWidget(yaml));

        // Builtin layout constructors.
        Layout boxManualCtor(YAMLNode* yaml)
        {
            static msg = "Missing layout parameters; boxManual layout manager "
                         "requires layout parameters to be specified for every widget";
            enforce(yaml !is null, new LayoutInitException(msg));
            return new BoxManualLayout(*yaml);
        }
        Layout fixedCtor(YAMLNode* yaml)
        {
            static msg = "Missing layout parameters; fixed layout manager "
                         "requires layout parameters to be specified for every widget";
            enforce(yaml !is null, new LayoutInitException(msg));
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
                foundDefault = foundDefault || named[0] == "default";
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
        auto slotDummyStyles = [LineStyleManager.Style(styleSource, "default")];
        auto layoutSource    = loadYAML("{x: 0, y: 0, w: 640, h: 480}"); 
        rootSlot_.init("", this, cast(Widget[])[], new FixedLayout(layoutSource),
                       new LineStyleManager(slotDummyStyles));

        // Initialize the texture resource manager.
        bool textureLoader(VFSFile file, out Texture result)
        {
            assert(video_ !is null,
                   "GUI loading a texture before the first render()"
                   " call sets the video driver.");

            Image textureImage;
            if(file is null)
            {
                // Placeholder texture
                textureImage = Image(64, 64);
                textureImage.generateStripes(4);
            }
            // Load the texture.
            else try
            {
                scope(failure)
                {
                    // Placeholder texture
                    textureImage = Image(64, 64);
                    textureImage.generateStripes(2);
                }
                readImage(textureImage, file);
            }
            catch(VFSException e)
            {
                writeln("Failed to load a texture: " ~ e.msg);
            } 
            catch(ImageFileException e)
            {
                writeln("Failed to load a texture: " ~ e.msg);
            }
            result = video_.createTexture(textureImage, false);
            return true;
        }

        textureManager_ = new ResourceManager!Texture(gameDir, &textureLoader, "*.png");
    }

    /// Destroy the GUISystem.
    ~this()
    {
        clear(textureManager_);
        platform_.key.disconnect(&inputKey);
        platform_.mouseMotion.disconnect(&inputMouseMove);
        platform_.mouseKey.disconnect(&inputMouseKey);
    }

    /// Set area taken up by the root widget.
    ///
    /// Params: area = Area used by the root widget.
    void setGUIArea(ref const Recti area)
    {
        auto rootLayout = cast(FixedLayout)rootSlot_.layout;
        assert(rootLayout !is null, "Root widget layout must be a FixedLayout");
        rootLayout.setBounds(area);
        updateLayout();
    }

    /// Load a widget tree connectible to a SlotWidget from YAML.
    ///
    /// Throws:  GUIInitException on failure.
    RootWidget loadWidgetTree(YAMLNode source)
    {
        scope(failure)
        {
            writeln("GUISystem.loadWidgetTree() or a callee failed");
        }
        try
        {
            auto loader = WidgetLoader(this, gameDir_);
            return loader.parseRootWidget(source);
        }
        catch(YAMLException e)
        {
            throw new GUIInitException("Could not load a widget tree: " ~ to!string(e));
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
        if(video !is video_ && video_ !is null)
        {
            // Textures have been invalidated by the video driver change.
            textureManager_.clear();
        }
        video_ = video;
        static RenderEvent event;
        if(null is event){event = new RenderEvent();}

        // Save view zoom and offset.
        const zoom   = video.zoom;
        const offset = video.viewOffset; 

        // Set no zoom and zero offset for GUI drawing.
        video.zoom       = 1.0;
        video.viewOffset = Vector2d(0.0, 0.0);
        video_.scissor(rootSlot_.layout.bounds);

        scope(exit)
        {
            // Restore zoom and offset.
            video.zoom       = zoom;
            video.viewOffset = offset;
            video.disableScissor();
        }

        event.videoDriver = video;
        rootSlot_.handleEvent(event);
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
    /// It must _not_ modify the array.
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

    // Pointer to the stylesheet used to style the generated widgets.
    Stylesheet* styleSheet_;

    // Metadata of all parents of the widget constructed by this builder, and of this widget.
    Vector!WidgetMeta widgetMetaStack_;

public:
    /// Construct a WidgetBuilder.
    ///
    /// Params:  guiSystem  = GUISystem to manage built widgets.
    ///          stylesheet = Stylesheet to style the widgets. Must not be null.
    ///                       May be safely destroyed after the widgets are built.
    this(GUISystem guiSystem, Stylesheet* stylesheet)
    {
        widgetMetaStack_ ~= WidgetMeta.init;
        styleSheet_ = stylesheet;
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
            widgetMetaStack_.back.type = widgetTypeName;

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
            auto yamlStylesParameters = styleSheet_.getStyleParameters(widgetMetaStack_[]);
            auto styleManagerName = styleSheet_.styleManagerName;
            auto styleCtor = styleManagerName in guiSystem_.styleCtors_;
            enforce(styleCtor !is null,
                    new GUIInitException("Unknown style manager: " ~ styleManagerName));
            auto styleManager = (*styleCtor)(yamlStylesParameters);
            styleManager.textureManager = guiSystem_.textureManager_;

            // Construct the widget.
            auto widgetCtor = widgetTypeName in guiSystem_.widgetCtors_;
            enforce(widgetCtor !is null,
                    new GUIInitException("Unknown widget type: " ~ widgetTypeName));
            auto widgetYAML = loadYAML(widgetParams_);
            auto result = (*widgetCtor)(widgetYAML);
            result.init(widgetMetaStack_.back.name, guiSystem_, subBuilder.builtWidgets,
                        layout, styleManager);
            widgetMetaStack_.back = WidgetMeta.init;

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
    ///
    /// Must be called before building any subwidgets.
    @property void name(const string name)
    {
        assert(parent_ !is null, "Trying to set widget name when not building a widget");
        parent_.widgetMetaStack_.back.name = name;
        widgetMetaStack_[widgetMetaStack_.length - 2].name = name;
    }

    /// Set widget style class, if any.
    ///
    /// Can only be called by build delegates passed to buildWidget().
    ///
    /// Must be called before building any subwidgets.
    @property void styleClass(const string styleClass)
    {
        assert(parent_ !is null, "Trying to set widget style class when not building a widget");
        parent_.widgetMetaStack_.back.styleClass = styleClass;
        widgetMetaStack_[widgetMetaStack_.length - 2].styleClass = styleClass;
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

    /// Get all widgets built by this WidgetBuilder so far.
    @property Widget[] builtWidgets() pure nothrow
    {
        return builtWidgets_;
    }

private:
    /// Construct a nested WidgetBuilder building subwidgets of the widget
    /// being built by parent WidgetBuilder.
    ///
    /// Params:  guiSystem  = GUISystem to manage built widgets.
    ///          parent     = WidgetBuilder building the parent widget.
    this(GUISystem guiSystem, WidgetBuilder* parent)
    {
        widgetMetaStack_ = parent.widgetMetaStack_;
        widgetMetaStack_ ~= WidgetMeta.init;
        guiSystem_       = guiSystem;
        parent_          = parent;
        styleSheet_      = parent.styleSheet_;
    }
}

/// A stylesheet similar in concept to CSS, but without the "cascading" part.
///
/// There are style classes similar to the ones used with CSS, and widget names 
/// are used as CSS IDs. A style declaration (style section) in a style sheet
/// can, like in CSS, nest widget type, style class and name specifiers to 
/// flexibly define which widgets should a style be applied to. E.g; a
/// style section can specify that it only applies to labels in a widget with 
/// name "sidebar" : ";sidebar label". The semicolon specifies the start of an
/// ID. A dot specifies the start of a class. Widget specifiers are separated 
/// by spaces, and each may contain a widget type, name and style class.
/// Each specifier matches a nesting level in widget hierarchy, but a widget 
/// will match the style section even if it has more nesting levels between the 
/// specifiers.
///
/// Each style section defines one or more styles of the widget. For example,
/// buttons can use an "active" and "focused" style. The default style, 
/// "default", must always be specified.
///
/// Unlike CSS, we support multiple ways of styling widgets; multiple style 
/// managers. Each stylesheet must have a meta section specifying which 
/// style manager is used (Currently, the only supported value is "line" for
/// LineStyleManager).
///
/// Also unlike CSS, there is no "cascading". Only one style section can match
/// a widget (if more than one match, the most specififc is used, and if there 
/// is more than one that's the most used, last one of those is used). This 
/// also means the section must specify all style attributes (that shouldn't use 
/// defaults of their style manager). This is not as much of a problem as it is
/// in CSS as we have far less style attributes.
/// 
///
/// Example:
/// --------------------
/// meta:
///   styleManager: line
/// styles:
///   !!pairs
///   - root:
///       default:
///         backgroundColor: rgb000000
///   - ;sidebar button:
///       default:
///         borderColor: rgbaC0C0FF60
///         fontColor:   rgbaA0A0FFC0
///       focused:
///         borderColor: rgbaC0C0FFA0
///         fontColor:   rgbaC0C0FFC0
///       active:
///         borderColor: rgbaC0C0FFFF
///         fontColor:   rgbaE0E0FFFF
///   - label:
///       default:
///         fontColor:   rgbaFFFFFF80
///         drawBorder:  false
///         fontSize:    12
///         font:        orbitron-medium.ttf
///         textAlignX:  left
///   - label.header:
///       default:
///         fontColor:  rgbaFFFFFF80
///         drawBorder: false
///         fontSize:   14
///         font:       orbitron-bold.ttf
///   - label.sectionHeader:
///       default:
///         fontColor:   rgbaEFEFFFCF
///         drawBorder:  false
///         fontSize:    12
///         font:        orbitron-medium.ttf
///         textAlignX:  left
/// --------------------
struct Stylesheet
{
private:
    // Name of the stylesheet used for debugging.
    string name_;

    // Name of the style manager (e.g. line for LineStyleManager) to use with
    // this stylesheet.
    string styleManagerName_;

    // Represents a style section in the stylesheet.
    //
    // Describing which widgets the section applies to and styles those widgets
    // should use.
    struct StyleSection
    {
        /// Specifiers describing widgets this style section should apply to.
        Vector!WidgetMeta widgetSpecifiers;
        /// Styles declared in the section, with their names.
        ///
        /// As of DMD 2.060, this can't be a Vector because of a compiler error.
        Tuple!(string, YAMLNode)[] styles;
    }

    // All style sections declared in the stylesheet file.
    Vector!StyleSection styleSections_;

public:
    /// Construct a Stylesheet.
    ///
    /// Params:  yaml = YAML source of the stylesheet.
    ///          name = Name of the stylesheet used for debugging.
    ///
    /// Throws:  YAMLException if the YAML source is in unexpected format.
    ///          GUIInitException on failure (e.g. malformed widget specifier).
    this(ref YAMLNode yaml, string name)
    {
        name_ = name;
        loadMeta(yaml["meta"]);
        loadStyles(yaml["styles"]);
    }

    /// Construct and return a default style sheet, used if no style sheet is specified.
    static Stylesheet defaultStylesheet()
    {
        // We don't really set anything here, just use the style manager's defaults.
        string styleString = 
            "meta:\n"                ~
            "  styleManager: line\n" ~
            "styles: !!pairs []\n";
        auto styleYAML = loadYAML(styleString);
        try
        {
            return Stylesheet(styleYAML, "_default_stylesheet_");
        }
        catch(YAMLException e)
        {
            assert(false, "Error in default style sheet: " ~ e.msg);
        }
    }

package:
    /// Get style parameters for a widget.
    ///
    /// Params:  widgetMetaStack = Metadata describing the full stack of parents
    ///                            above the widget. The last element describes
    ///                            the widget itself.
    ///
    /// Returns: Styles for the widget to use (null if none).
    ///          The returned array must not be modified.
    Tuple!(string, YAMLNode)[] getStyleParameters(const(WidgetMeta[]) widgetMetaStack)
    {
        Tuple!(string, YAMLNode)[] outStyles = null;
        ulong maxScore = 0;
        foreach(ref section; styleSections_)
        {
            ulong score = 0;
            // Part of widgetSpecifiers we did not yet match.
            const(WidgetMeta)[] widgetSpecifiersLeft = section.widgetSpecifiers[];
            enum metaCount = 3;
            foreach_reverse(index, ref meta; widgetMetaStack)
            {
                // Needs to be updated if metaCount changes.
                enforce(index <= 31, new GUIInitException("Widget nesting too deep; " ~ 
                                                          "only 31 levels are supported"));
                // section's widgetSpecifiers are "crawling" up
                // from the widget along the tree 
                // (of which we only have the stack above the widget).
                //
                // So we search up the stack for the next widget specifier. 
                // If we don't find all specifiers in order, we don't match.
                // Otherwise, the "score" of the match depends on how specific
                // the specifiers are, and matches deeper in the tree override 
                // those above them. We do this by calculating score in base N+1,
                // where N is the "most specific match". The matchScore variable 
                // takes track of how specific a match is.
                //
                // If more than one style sections have the best score,
                // we simply use the last one (unlike CSS, which would merge them)
                const spec = widgetSpecifiersLeft.back;
                ulong matchScore = 0;
                bool match(string delegate(ref const WidgetMeta) prop)
                {
                    if(prop(spec) is null){return true;}
                    if(prop(spec) == prop(meta)){++ matchScore; return true;}
                    return false;
                }
                if(!match((ref const WidgetMeta a) => a.type) || 
                   !match((ref const WidgetMeta a) => a.name) ||
                   !match((ref const WidgetMeta a) => a.styleClass))
                {
                    continue;
                }

                score += matchScore * (metaCount + 1) ^^ index;
                widgetSpecifiersLeft.popBack;
                if(widgetSpecifiersLeft.empty)
                {
                    break;
                }
            }

            // If we've not matched all widgetSpecifiers.
            if(!widgetSpecifiersLeft.empty)
            {
                continue;
            }

            // If multiple style sections have the best score, we use the last one.
            if(score >= maxScore)
            {
                maxScore = score;
                outStyles = section.styles[];
            }
        }
        return outStyles;
    }

    /// Get the name of the style manager used by this stylesheet.
    @property string styleManagerName() const pure nothrow {return styleManagerName_;}

private:
    // Load stylesheet metadata (the "meta" section).
    void loadMeta(ref YAMLNode meta)
    {
        styleManagerName_ = meta["styleManager"].as!string;
    }

    // Load style sections (the "style" section).
    //
    // Throws:  GUIInitException on failure.
    void loadStyles(ref YAMLNode styles)
    {
        // Process each style section in the stylesheet, with header describing
        // widgets to apply the styling to.
        foreach(string header, ref YAMLNode styleData; styles)
        {
            StyleSection section;
            parseHeader(header, section);

            // Load styles from the section.
            foreach(string styleName, ref YAMLNode style; styleData)
            {
                section.styles ~= tuple(styleName, style);
            }

            styleSections_ ~= section;
        }
    }

    // Parse style section header to get widget specifiers.
    //
    // Params:  header  = Style section header.
    //          section = StyleSection we're loading.
    void parseHeader(string header, ref StyleSection section)
    {
        // Specifiers are separated by space.
        // Each specifier can contain widget type, name and style class.
        auto headerParts = header.split(" ");
        section.widgetSpecifiers.reserve(headerParts.length);
        foreach(part; headerParts)
        {
            WidgetMeta meta;
            // Adds the current character to whichever string we're reading into.
            auto state_ = (dchar c) => meta.type ~= c;
            uint colonCount = 0;
            uint semicolonCount = 0;
            // This is very GC-inefficient. But it might not matter as
            // this only runs when a GUI is being loaded.
            foreach(dchar c; part)
            {
                // Style class, if any, starts with a semicolon.
                if(c == '.')
                {
                    ++colonCount;
                    state_ = (dchar c) => meta.styleClass ~= c;
                }
                // Widget name, if any, starts with a semicolon.
                else if(c == ';')
                {
                    ++semicolonCount;
                    state_ = (dchar c) => meta.name ~= c;
                }
                else
                {
                    // Process the character.
                    state_(c);
                }
            }
            enforce(colonCount <= 1 && semicolonCount <= 1,
                    new GUIInitException("More than 1 colon or semicolon in style "
                                         "section \"" ~ part ~ "\" in style \"" ~ name_ ~ "\""));
            section.widgetSpecifiers ~= meta;
        }
    }
}

/// Metadata describing a widget.
struct WidgetMeta
{
    /// Data type of the widget ('root' for RootWidget, 'label' for LabelWidget and so on.).
    string type;
    /// Name of the widget, if any.
    string name;
    /// Style class (like CSS class) of the widget, if any.
    string styleClass;
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

    /// Game data directory.
    VFSDir gameDir_;

    /// Stack keeping track of the layout type used in the current widget.
    ///
    /// Layout types specified in parent widgets are recursively used 
    /// in their children. 
    Vector!string layoutManagerStack_;

    /// Stack keeping track of the stylesheet used by the current widget.
    ///
    /// Stylesheets specified in parent widgets are recursively used in their children.
    Vector!Stylesheet styleSheetStack_;

    /// Stack storing the metadata of the current widget and all its parents.
    ///
    /// Used in styling.
    Vector!WidgetMeta widgetMetaStack_;

    @disable this();
    @disable this(this);

package:
    /// Construct a WidgetLoader.
    ///
    /// Params:  guiSystem = GUI system that will manage the widgets.
    ///          gameDir   = Game data directory to load any style sheets from.
    this(GUISystem guiSystem, VFSDir gameDir)
    {
        layoutManagerStack_ ~= "boxManual";
        widgetMetaStack_    ~= WidgetMeta("root", null, null);
        widgetMetaStack_.reserve(8);
        styleSheetStack_ = [Stylesheet.defaultStylesheet()];
        guiSystem_       = guiSystem;
        gameDir_         = gameDir;
    }

    /// Parse a root widget, and recursively, its widget tree.
    ///
    /// Params: source = Root node of the YAML tree to parse.
    ///
    /// Throws: GUIInitException on failure.
    RootWidget parseRootWidget(ref YAMLNode source)
    {
        return cast(RootWidget)parseWidget(source, guiSystem_.widgetCtors_["root"]);
    }

private:
    // Parse a widget (and recursively, its subwidgets) from YAML.
    //
    // Params: source     = Root node of the YAML tree to parse.
    //         widgetCtor = Function that construct the widget of correct type
    //                      (determined by the caller).
    //
    // Throws: GUIInitException on failure.
    Widget parseWidget(ref YAMLNode source, Widget delegate(ref YAMLNode) widgetCtor)
    {
        scope(failure)
        {
            writeln("WidgetLoader.parseWidget() or a callee failed");
        }
        // Parse layout type, stylesheet.
        bool popStyleSheet = false;
        bool popLayout     = false;
        scope(exit)
        {
            if(popStyleSheet) {styleSheetStack_.popBack();}
            if(popLayout)     {layoutManagerStack_.popBack();}
        }

        // We only throw GUIInitException here so make it shorter.
        alias GUIInitException E;

        bool layoutParametersSpecified = false;
        YAMLNode layoutParameters;
        Widget[] children;

        try
        {
            if(source.containsKey("stylesheet"))
            {
                loadStyleSheet(source["stylesheet"].as!string);
                popStyleSheet = true;
            }
            if(source.containsKey("layoutManager"))
            {
                layoutManagerStack_ ~= source["layoutManager"].as!string;
                popLayout = true;
            }

            /// Parse the widget's attributes and subwidgets.
            foreach(string key, ref YAMLNode value; source)
            {
                // A subwidget.
                if(key.startsWith("widget"))
                {
                    auto parts = key.split(" ");
                    enforce(parts.length >= 2,
                            new E("Can't parse a widget without type"));
                    // Metadata of the subwidget.
                    WidgetMeta subMeta = parseWidgetMeta(parts[1 .. $]);

                    auto ctor = subMeta.type in guiSystem_.widgetCtors_;
                    enforce(ctor !is null,
                            new E("Unknown widget type in YAML: " ~ subMeta.type));
                    widgetMetaStack_ ~= subMeta;
                    scope(exit){widgetMetaStack_.popBack();}
                    children ~= parseWidget(value, *ctor);
                }
                // Layout parameters.
                else if(key == "layout")
                {
                    layoutParameters = value;
                    layoutParametersSpecified = true;
                }
            }
        }
        catch(YAMLException e)
        {
            throw new E("Error while loading a " ~ widgetMetaStack_.back.type ~
                        " widget: " ~ e.msg);
        }

        auto layout = constructLayout(layoutParametersSpecified ? &layoutParameters : null);
        auto styleManager = constructStyleManager();

        // Construct the widget and return it.
        Widget result = widgetCtor(source);
        result.init(widgetMetaStack_.back.name, guiSystem_, children, layout, styleManager);
        return result;
    }


    // parseWidget utility functions //


    // Parse widget metadata from a widget declaration.
    //
    // Params:  parts = Parts of the widget declaration (separated by spaces)
    //                  except for the "widget" word at start.
    WidgetMeta parseWidgetMeta(string[] parts)
    {
        WidgetMeta meta;
        meta.type = parts[0];
        // Parse extra info in the widget declaration, like widget name, style class.
        foreach(part; parts[1 .. $])
        {
            // e.g. button class=someStyleClass
            if(part.canFind("=") && part.startsWith("class"))
            {
                meta.styleClass = part.split("=")[1];
            }
            // e.g. button widgetName
            else if(meta.name is null)
            {
                meta.name = part;
            }
        }
        return meta;
    }

    // Load a stylesheet from a file with specified name and push it to styleSheetStack_.
    void loadStyleSheet(const string styleSheetName)
    {
        try
        {
            auto styleFile = gameDir_.file(styleSheetName);
            auto styleYAML = loadYAML(styleFile);
            styleSheetStack_ ~= Stylesheet(styleYAML, styleSheetName);
        }
        catch(VFSException e)
        {
            throw new GUIInitException
                ("Failed to load GUI: stylesheet " ~ styleSheetName ~
                 " could not be read: " ~ e.msg);
        }
        catch(YAMLException e)
        {
            throw new GUIInitException
                ("Failed to load GUI: YAML error in stylesheet " ~
                 styleSheetName ~ " : " ~ e.msg);
        }
    }

    // Construct a layout with specified parameters (if any).
    //
    // Layout type is determined by the layout manager stack.
    //
    // Throws:  GUIInitException on failure.
    Layout constructLayout(YAMLNode* layoutParameters)
    {
        auto layoutType = layoutManagerStack_.back;
        auto layoutCtor = layoutType in guiSystem_.layoutCtors_;
        enforce(layoutCtor !is null,
                new GUIInitException("Unknown layout manager in YAML: " ~ layoutType));
        return (*layoutCtor)(layoutParameters);
    }

    // Construct a style manager with specified parameters.
    //
    // Style manager type is determined by the style sheet stack.
    //
    // Throws:  GUIInitException on failure.
    StyleManager constructStyleManager()
    {
        auto stylesParameters =
            styleSheetStack_.back.getStyleParameters(widgetMetaStack_[]);
        auto styleType = styleSheetStack_.back.styleManagerName;
        auto styleCtor = styleType in guiSystem_.styleCtors_;
        enforce(styleCtor !is null,
                new GUIInitException("Unknown style manager in YAML: " ~ styleType));
        auto styleManager = (*styleCtor)(stylesParameters);
        styleManager.textureManager = guiSystem_.textureManager_;
        return styleManager;
    }
}
