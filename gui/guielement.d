module gui.guielement;


import std.string;

import video.videodriver;
import math.vector2;
import math.rectangle;
import platform.platform;
import formats.mathparser;
import color;
import arrayutil;


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

        string x_string_ = "w_right / 2";
        string y_string_ = "w_bottom / 2";

        string width_string_ = "64";
        string height_string_ = "64";

    public:
        this(){}

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

        final void position_x(string pos){x_string_ = pos; aligned_ = false;}

        final void position_y(string pos){y_string_ = pos; aligned_ = false;}

        final void width(string width){width_string_ = width; aligned_ = false;}

        final void height(string height){height_string_ = height; aligned_ = false;}

        ///Get position in screen space.
        final Vector2i position_global(){return bounds_.min;}

        ///Get position relative to parent element.
        final Vector2i position_local(){return bounds_.min - parent_.bounds_.min;}
        
        ///Return size of this element in screen space.
        final Vector2u size(){return Vector2u(bounds_.size.x, bounds_.size.y);}

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

        ///Set this element to visible or hidden.
        final void visible(bool visible){visible_ = visible;}

        ///Return parent of this element.
        final GUIElement parent(){return parent_;}

        ///Determine if an element is a child of this element.
        final bool is_child(GUIElement element){return parent_ is element;}

    package:
        final void draw_children()
        {
            foreach(ref child; children_){child.draw();}
        }

        final void update_children()
        {
            foreach(ref child; children_){child.update();}
        }

    protected:
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
            foreach_reverse(ref child; children_){child.key(state, key, unicode);}
        }

        //Process mouse key presses. 
        void mouse_key(KeyState state, MouseKey key, Vector2u position)
        {
            //ignore hidden elements
            if(!visible_){return;}

            //pass input to the children
            foreach_reverse(ref child; children_)
            {
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
