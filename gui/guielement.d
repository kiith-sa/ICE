module gui.guielement;


import std.string;

import video.videodriver;
import math.vector2;
import math.rectangle;
import platform.platform;
import formats.mathparser;
import monitor.monitor;
import color;
import arrayutil;
import factory;
import singleton;


//In future, this should be rewritten to support background and border(?) textures,
//and should be serializable. Border might be a separate class/struct that 
//would not be mandatory (e.g. RA2 style GUI needs no borders)
///Base class for all GUI elements. Can be used directly to draw empty elements.
class GUIElement
{
    protected:
        alias std.string.toString to_string;

        GUIElement parent_ = null;
        GUIElement[] children_;

        //Color of the element's border.
        Color border_color_ = Color(255, 255, 255, 96);
        //Bounds of this element in screen space.
        Rectanglei bounds_;

        //Is this element visible?
        bool visible_ = true;
        //Draw border of this element?
        bool draw_border_ = true;
        //Are the contents of this element aligned based on its current dimensions?
        bool aligned_ = false;

        //Math expression used to calculate X position of the element.
        string x_string_;
        //Math expression used to calculate Y position of the element.
        string y_string_;
        //Math expression used to calculate width of the element.
        string width_string_;
        //Math expression used to calculate height of the element.
        string height_string_;

    public:
        ~this()
        {
            assert(parent_ is null && children_ is null,
                   "GUIElement must be cleared before it is destroyed");
        }
        
        //This is probably not even needed, as the GC shoudln't need everything
        //to be disconnected.
        ///Destroy this element.
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
        
        ///Return size of this element in screen space.
        final Vector2u size(){return Vector2u(bounds_.size.x, bounds_.size.y);}

        ///Return bounding rectangle of this GUI element in screen space.
        final Rectanglei bounds_global(){return bounds_;}

        ///Add a child element.
        final void add_child(GUIElement child)
        in
        {
            assert(!children_.contains(child, true), 
                   "Trying to add a child that is already a child of this GUI element.");
        }
        body
        {
            children_ ~= child;
            child.parent_ = this;
        }

        ///Remove a child element.
        final void remove_child(GUIElement child)
        in
        {
            assert(children_.contains(child, true) && child.parent_ is this,
                   "Trying to remove a child that is not a child of this GUI element.");
        }
        body
        {
            children_.remove(child, true);
            child.parent_ = null;
        }

        ///Return true if this element is visible, false if hidden.
        final bool visible(){return visible_;}

        ///Hide this element and its children.
        final void hide(){visible_ = false;}

        ///Make this element and its children visible;
        final void show(){visible_ = true;}

        ///Return parent of this element.
        final GUIElement parent(){return parent_;}

        ///Determine if an element is a child of this element.
        final bool is_child(GUIElement element){return parent_ is element;}

    package:
        final void draw_children()
        {
            foreach(ref child; children_)
            {
                if(child is null){continue;}
                child.draw();
            }
        }

        final void update_children()
        {
            foreach(ref child; children_)
            {
                if(child is null){continue;}
                child.update();
            }
        }

    protected:
        /*
         * Construct a GUI element with specified parameters.
         *
         * Position and size of GUI elements are specified with
         * strings containing simple math expressions which
         * are evaluated to determine the actual coordinates.
         *
         * Supported operators are + +,-,*,/ as well as parentheses.
         *
         * Furthermore, there are builtin macros representing window and parent
         * coordinates. These are:
         *
         * w_right  : Window right end (left end is always 0, so this is window width)
         * w_bottom : Window bottom end (top end is always 0, so this is window height)
         * p_left   : Parent left end
         * p_right  : Parent right end
         * p_top    : Parent top end
         * p_bottom : Parent bottom end
         *
         * Params:  x      = X position math expression.
         *          y      = Y position math expression. 
         *          width  = Width math expression. 
         *          height = Height math expression. 
         */
        this(string x, string y, string width, string height)
        {
            x_string_ = x;
            y_string_ = y;
            width_string_ = width;
            height_string_ = height;
            aligned_ = false;
        }

        void draw()
        {
            if(!visible_){return;}

            if(!aligned_){realign();}

            if(draw_border_)
            {
                Vector2f min = Vector2f(bounds_.min.x, bounds_.min.y);
                Vector2f max = Vector2f(bounds_.max.x, bounds_.max.y);
                VideoDriver.get.draw_rectangle(min, max, border_color_);
            }

            draw_children();
        }

        void update(){update_children();}

        //Process keyboard input.
        void key(KeyState state, Key key, dchar unicode)
        {
            //ignore for hidden elements
            if(!visible_){return;}

            //pass input to the children
            foreach_reverse(ref child; children_)
            {
                if(child is null){continue;}
                child.key(state, key, unicode);
            }
        }

        //Process mouse key presses. 
        void mouse_key(KeyState state, MouseKey key, Vector2u position)
        {
            //ignore hidden elements
            if(!visible_){return;}

            //pass input to the children
            foreach_reverse(ref child; children_)
            {
                if(child is null){continue;}
                child.mouse_key(state, key, position);
            }
        }

        //Process mouse movement.
        void mouse_move(Vector2u position, Vector2i relative)
        {
            //ignore hidden elements
            if(!visible_){return;}

            //pass input to the children
            foreach_reverse(ref child; children_)
            {
                if(child is null){continue;}
                child.mouse_move(position, relative);
            }
        }

        //Realign contents of this element according to its dimensions.
        void realign()
        {
            int[string] substitutions;
            auto driver = VideoDriver.get;

            substitutions["w_right"] = driver.screen_width;
            substitutions["w_bottom"] = driver.screen_height;
            substitutions["p_left"] = parent_ is null ? 0 : parent_.bounds_.min.x;
            substitutions["p_right"] = parent_ is null ? 0 : parent_.bounds_.max.x;
            substitutions["p_top"] = parent_ is null ? 0 : parent_.bounds_.min.y;
            substitutions["p_bottom"] = parent_ is null ? 0 : parent_.bounds_.max.y;

            bounds_.min = Vector2i(parse_math(x_string_, substitutions), 
                                   parse_math(y_string_, substitutions));

            int width = parse_math(width_string_, substitutions);
            int height = parse_math(height_string_, substitutions);

            if(height < 0 || width < 0)
            {
                throw new Exception("Negative width and/or height of a GUI element!");
            }

            bounds_.max = bounds_.min + Vector2i(width, height);

            foreach(ref child; children_)
            {
                child.realign();
            }

            aligned_ = true;
        }
}

///GUI root singleton. Contains drawing and input handling methods.
final class GUIRoot
{
    mixin Singleton;
    private:
        //The actual GUI root element.
        GUIElement root_;

    public:
        ///Construct the GUI root with size equal to screen size.
        this()
        {
            singleton_ctor();

            with(new GUIElementFactory)
            {
                x = "0";
                y = "0";
                width = "w_right";
                height = "w_bottom";
                root_ = produce();
            }
            root_.realign();

            Platform.get.key.connect(&root_.key);
            Platform.get.mouse_motion.connect(&root_.mouse_move);
            Platform.get.mouse_key.connect(&root_.mouse_key);
        }

        ///Draw the GUI.
        void draw()
        {
            auto driver = VideoDriver.get;

            //save view zoom and offset
            real zoom = driver.zoom;
            auto offset = driver.view_offset; 

            //set 1:1 zoom and zero offset for GUI drawing
            driver.zoom = 1.0;
            driver.view_offset = Vector2d(0.0, 0.0);

            //draw the elements
            root_.draw_children();

            //restore zoom and offset
            driver.zoom = zoom;
            driver.view_offset = offset;
        }

        ///Update the GUI.
        void update(){root_.update_children();}

        ///Add a child element.
        void add_child(GUIElement child){root_.add_child(child);}

        ///Remove a child element.
        void remove_child(GUIElement child){root_.remove_child(child);}

        ///Destroy this GUIRoot.
        void die(){root_.die();}
}

/**
 * Factory used for GUI element construction.
 *
 * See_Also: GUIElementFactoryBase
 */
final class GUIElementFactory : GUIElementFactoryBase!(GUIElement)
{
    public GUIElement produce(){return new GUIElement(x_, y_, width_, height_);}
}

/**
 * Template base class for all GUI element factories, template input
 * specifies type of GUI element constructed by the factory.
 *
 * Position and size of GUI elements are specified with
 * strings containing simple math expressions which
 * are evaluated to determine the actual coordinates.
 *
 * Supported operators are + +,-,*,/ as well as parentheses.
 *
 * Furthermore, there are builtin macros representing window and parent
 * coordinates. These are:
 *
 * w_right  : Window right end (left end is always 0, so this is window width)
 * w_bottom : Window bottom end (top end is always 0, so this is window height)
 * p_left   : Parent left end
 * p_right  : Parent right end
 * p_top    : Parent top end
 * p_bottom : Parent bottom end
 *
 * Params:  x      = X position math expression.
 *          y      = Y position math expression. 
 *          width  = Width math expression. 
 *          height = Height math expression. 
 */
abstract class GUIElementFactoryBase(T)
{
    mixin(generate_factory("string $ x $ \"p_left\"", 
                           "string $ y $ \"p_top\"", 
                           "string $ width $ \"64\"", 
                           "string $ height $ \"64\""));
    ///Return a new instance of the class produced by the factory with parameters of the factory.
    public T produce();
}
