
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module gui.guielement;


import std.string;
import std.stdio;

import video.videodriver;
import math.vector2;
import math.rectangle;
import platform.platform;
import formats.mathparser;
import monitor.monitor;
import color;
import containers.array;
import util.factory;
import util.weaksingleton;


//In future, this should be rewritten to support background and border(?) textures,
//and should be serializable. Border might be a separate class/struct that 
//would not be mandatory (e.g. RA2 style GUI needs no borders)
///Base class for all GUI elements. Can be used directly to draw empty elements.
class GUIElement
{
    protected:
        alias std.string.toString to_string;

        ///Parent element of this element.
        GUIElement parent_ = null;
        ///Children elements of this element.
        GUIElement[] children_;

        ///Color of the element's border.
        Color border_color_ = Color(255, 255, 255, 96);
        ///Bounds of this element in screen space.
        Rectanglei bounds_;

        ///Is this element visible?
        bool visible_ = true;
        ///Draw border of this element?
        bool draw_border_;
        ///Are the contents of this element aligned based on its current properties?
        bool aligned_ = false;

        ///Math expression used to calculate X position of the element.
        string x_string_;
        ///Math expression used to calculate Y position of the element.
        string y_string_;
        ///Math expression used to calculate width of the element.
        string width_string_;
        ///Math expression used to calculate height of the element.
        string height_string_;

    public:
        ///Destroy this element and all its children.
        void die()
        {
            foreach(ref child; children_)
            {
                child.die();
                child = null;
            }
            children_ = null;
            parent_ = null;
        }                 

        ///Get position in screen space.
        final Vector2i position_global(){return bounds_.min;}

        ///Get position relative to parent element.
        final Vector2i position_local(){return bounds_.min - parent_.bounds_.min;}
        
        ///Get size of this element in screen space.
        final Vector2u size(){return to!(uint)(bounds_.size);}

        ///Get bounding rectangle of this GUI element in screen space.
        final Rectanglei bounds_global(){return bounds_;}

        /**
         * Add a child element. 
         *
         * A single child can't be added twice to the same element or to
         * two different GUI elements at the same time.
         *
         * Params:  child = Child to add.
         */
        final void add_child(GUIElement child)
        in
        {
            assert(!children_.contains(child, true), 
                   "Trying to add a child that is already a child of this GUI element.");
            assert(child.parent_ is null, "Trying to add a child that already has a parent");
        }
        body
        {
            children_ ~= child;
            child.parent_ = this;
        }

        ///Remove a child element. The specified element must be a child of this element.
        final void remove_child(GUIElement child)
        in
        {
            assert(children_.contains(child, true) && child.parent_ is this,
                   "Trying to remove a child that is not a child of this GUI element.");
        }
        body
        {
            alias containers.array.remove remove;
            children_.remove(child, true);
            child.parent_ = null;
        }

        ///Is this element visible?
        final bool visible(){return visible_;}

        ///Hide this element and its children.
        final void hide(){visible_ = false;}

        ///Make this element and its children visible.
        final void show(){visible_ = true;}

    protected:
        /**
         * Draw children of this element.
         *
         * Params:  driver = VideoDriver to draw with.
         */
        final void draw_children(VideoDriver driver)
        {
            foreach(ref child; children_)
            {
                //children can be null if we've just destroyed this element.
                if(child is null){continue;}
                child.draw(driver);
            }
        }

        ///Update children of this element.
        final void update_children()
        {
            foreach(ref child; children_)
            {
                //children can be null if we've just destroyed this element.
                if(child is null){continue;}
                child.update();
            }
        }

        /**
         * Construct a GUIElement with specified parameters.
         *
         * Params:  params = Parameters for construction of the GUIElement.
         */
        this(GUIElementParams params)
        {
            with(params)
            {
                x_string_ = x;
                y_string_ = y;
                width_string_ = width;
                height_string_ = height;
                draw_border_ = draw_border;
            }
            aligned_ = false;
        }

        ///Destructor. Used to assert that the element was correctly destroyed using die().
        ~this()
        {
            assert(parent_ is null && children_ is null,
                   "GUIElement must be cleared before it is destroyed");
        }
        
        /**
         * Draw this GUIElement and its children, if visible.
         *
         * Params:  driver = Driver to draw with.
         */
        void draw(VideoDriver driver)
        {
            if(!visible_){return;}

            if(!aligned_){realign(driver);}

            if(draw_border_)
            {
                driver.draw_rectangle(to!(float)(bounds_.min), to!(float)(bounds_.max), 
                                      border_color_);
            }

            draw_children(driver);
        }

        ///Update this GUIElement and its children.
        void update(){update_children();}

        /**
         * Process keyboard input.
         *
         * Params:  state   = State of the key.
         *          key     = Keyboard key.
         *          unicode = Unicode value of the key.
         */
        void key(KeyState state, Key key, dchar unicode)
        {
            //ignore for hidden elements
            if(!visible_){return;}

            //pass input to the children
            foreach_reverse(ref child; children_)
            {
                //children can be null if we've just destroyed this element.
                if(child is null){continue;}
                child.key(state, key, unicode);
            }
        }

        /**
         * Process mouse key input.
         *
         * Params:  state    = State of the key.
         *          key      = Mouse key.
         *          position = Position of the mouse.
         */
        void mouse_key(KeyState state, MouseKey key, Vector2u position)
        {
            //ignore hidden elements
            if(!visible_){return;}

            //pass input to the children
            foreach_reverse(ref child; children_)
            {
                //children can be null if we've just destroyed this element.
                if(child is null){continue;}
                child.mouse_key(state, key, position);
            }
        }

        /**
         * Process mouse movement.
         *
         * Params:  position = Position of the mouse in screen coordinates.
         *          relative = Relative movement of the mouse.
         */
        void mouse_move(Vector2u position, Vector2i relative)
        {
            //ignore hidden elements
            if(!visible_){return;}

            //pass input to the children
            foreach_reverse(ref child; children_)
            {
                //children can be null if we've just destroyed this element.
                if(child is null){continue;}
                child.mouse_move(position, relative);
            }
        }

        ///Realign contents of this element according to its dimensions.
        void realign(VideoDriver driver)
        {
            //process expressions for bounds coordinates.
            int[string] substitutions;

            //substitutions for window and parents' coordinates.
            substitutions["w_right"] = driver.screen_width;
            substitutions["w_bottom"] = driver.screen_height;
            substitutions["p_left"] = parent_ is null ? 0 : parent_.bounds_.min.x;
            substitutions["p_right"] = parent_ is null ? 0 : parent_.bounds_.max.x;
            substitutions["p_top"] = parent_ is null ? 0 : parent_.bounds_.min.y;
            substitutions["p_bottom"] = parent_ is null ? 0 : parent_.bounds_.max.y;
            substitutions["p_width"] = parent_ is null ? 0 : parent_.bounds_.width;
            substitutions["p_height"] = parent_ is null ? 0 : parent_.bounds_.height;

            int width, height;

            //fallback to fixed dimensions to avoid complicated exception resolving.
            void fallback()
            {
                width = height = 64;
                writefln("Falling back to fixed dimensions: 64x64");
            }

            scope(failure){writefln("GUI dimension expression parsing failed: width: " 
                                    ~ width_string_ ~ ", height: " ~ height_string_);}

            try
            {
                bounds_.min = Vector2i(parse_math(x_string_, substitutions), 
                                       parse_math(y_string_, substitutions));

                width = parse_math(width_string_, substitutions);
                height = parse_math(height_string_, substitutions);

                if(height < 0 || width < 0)
                {
                    writefln("Negative width and/or height of a GUI element! "   
                             "Probably caused by incorrect GUI math expressions.");
                    fallback();
                }
            }
            catch(MathParserException e)
            {
                writefln("Invalid GUI math expression.");
                writefln(e.msg);
                fallback();
            }

            bounds_.max = bounds_.min + Vector2i(width, height);

            //realign children
            foreach(ref child; children_){child.realign(driver);}

            aligned_ = true;
        }
}

///GUI root container. Contains drawing and input handling methods.
final class GUIRoot
{
    mixin WeakSingleton;
    private:
        ///The actual GUI root element.
        GUIElement root_;

    public:
        /**
         * Construct the GUI root.
         *
         * Size of the root GUI element will be identical to window size.
         *
         * Params:  platform = Platform to use for input.
         */
        this(Platform platform)
        {
            singleton_ctor();

            //construct the root element.
            with(new GUIElementFactory)
            {
                x = "0";
                y = "0";
                width = "w_right";
                height = "w_bottom";
                root_ = produce();
            }
            root_.draw_border_ = false;

            platform.key.connect(&root_.key);
            platform.mouse_motion.connect(&root_.mouse_move);
            platform.mouse_key.connect(&root_.mouse_key);
        }

        /**
         * Draw the GUI.
         *
         * Params:  driver = VideoDriver to draw with.
         */
        void draw(VideoDriver driver)
        {
            //save view zoom and offset
            real zoom = driver.zoom;
            auto offset = driver.view_offset; 

            //set 1:1 zoom and zero offset for GUI drawing
            driver.zoom = 1.0;
            driver.view_offset = Vector2d(0.0, 0.0);

            //draw the elements
            root_.draw(driver);

            //restore zoom and offset
            driver.zoom = zoom;
            driver.view_offset = offset;
        }

        ///Get the root element of the GUI.
        GUIElement root(){return root_;}

        ///Update the GUI.
        void update(){root_.update_children();}

        ///Add a child element.
        void add_child(GUIElement child){root_.add_child(child);}

        ///Remove a child element.
        void remove_child(GUIElement child){root_.remove_child(child);}

        ///Destroy the GUIRoot.
        void die()
        {
            root_.die();
            singleton_dtor();
        }

        ///Realign the GUI.
        void realign(VideoDriver driver){root_.realign(driver);}
}

/**
 * Factory used for GUI element construction.
 *
 * See_Also: GUIElementFactoryBase
 */
final class GUIElementFactory : GUIElementFactoryBase!(GUIElement)
{
    public GUIElement produce(){return new GUIElement(gui_element_params);}
}

/**
 * Template base class for all GUI element factories, template type T
 * specifies type of GUI element constructed by the factory.
 *
 * Position and size of GUI elements are specified with
 * strings containing simple math expressions which
 * are evaluated to determine the actual coordinates.
 *
 * Supported operators are +,-,*,/ as well as parentheses.
 *
 * Furthermore, there are builtin macros representing window and parent
 * coordinates. These are:
 *
 * w_right  : Window right end (left end is always 0, so this is window width)$(BR)
 * w_bottom : Window bottom end (top end is always 0, so this is window height)$(BR)
 * p_left   : Parent left end$(BR)
 * p_right  : Parent right end$(BR)
 * p_top    : Parent top end$(BR)
 * p_bottom : Parent bottom end$(BR)
 *
 * Params:  x           = X position math expression.
 *                        Default; "p_left"
 *          y           = Y position math expression. 
 *                        Default; "p_top"
 *          width       = Width math expression. 
 *                        Default; "64"
 *          height      = Height math expression. 
 *                        Default; "64"
 *          draw_border = Draw border of the element?
 *                        Default; true
 * Examples:
 * Example of usage of GUIElementFactory, which is used
 * to construct instances of GUIElement, but the principle is
 * the same for every GUI element class factory.
 *
 * --------------------
 * //Assuming other is some GUI element we already have or root GUI element
 *
 * //construction of a GUI element:
 *
 * GUIElement element;
 *
 * with(new GUIElementFactory)
 * {
 *     x = "p_left + 96";
 *     y = "p_top + 16";
 *     width = "p_right - 192";
 *     height = "p_bottom - 32";
 *     element = produce();
 *     other.add_child(element);
 * }
 *
 *
 * //destruction:
 * other.remove_child(element);
 * element.die();
 * //(alternatively, we could just destroy other, which would also destroy element)
 * --------------------
 */
abstract class GUIElementFactoryBase(T)
{
    mixin(generate_factory("string $ x $ \"p_left\"", 
                           "string $ y $ \"p_top\"", 
                           "string $ width $ \"64\"", 
                           "string $ height $ \"64\"",
                           "bool $ draw_border $ true"));

    ///Return a struct containing factory parameters packaged for GUIElement ctor.
    protected final GUIElementParams gui_element_params()
    {
        return GUIElementParams(x_, y_, width_, height_, draw_border_);
    }

    ///Return a new instance of the class produced by the factory with parameters of the factory.
    public T produce();
}

///GUI element constructor parameters
align(1) struct GUIElementParams
{
    private:
        ///Coordinates' math expressions.
        string x, y, width, height;
        ///Draw border of the GUI element?
        bool draw_border;
}
