module gui.guielement;


import video.videodriver;
import math.vector2;
import math.rectangle;
import platform.platform;
import color;
import arrayutil;


//In future, this should be rewritten to support background and border(?) textures,
//and should be serializable. Border might be a separate class/struct that 
//would not be mandatory (e.g. RA2 style GUI needs no borders)
///Base class for all GUI elements. Can be used directly to draw empty elements.
class GUIElement
{
    protected:
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
        bool aligned_;

    public:
        ///Construct a new element with specified parameters.
        this(GUIElement parent, Vector2i position, Vector2u size)
        {
            if(parent !is null){parent.add_child(this);}
            this.size(size);
            position_local(position);
        }

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

        ///Set position in screen space.
        final void position_global(Vector2i position)
        out
        {
            assert(bounds_.min == position, 
                   "Global position of a GUI element was not set correctly");
        }
        body
        {
            Vector2i offset = position - bounds_.min;
            bounds_ += offset;
            //move the children with parent
            foreach(ref child; children_)
            {
                child.position_global = child.position_global + offset;
            }
        }

        ///Get position relative to parent element.
        final Vector2i position_local(){return bounds_.min - parent_.bounds_.min;}

        ///Set position relative to parent element.
        final void position_local(Vector2i position)
        {
            Vector2i offset = parent_ is null ? Vector2i(0,0) : parent_.bounds_.min;
            position_global(position + offset);
        }
        
        ///Return size of this element in screen space.
        final Vector2u size(){return Vector2u(bounds_.size.x, bounds_.size.y);}

        ///Set size of this element in screen space.
        final void size(Vector2u size)
        {
            bounds_.max = bounds_.min + Vector2i(size.x, size.y);
            aligned_ = false;
        }

        ///Add a child element.
        final void add_child(GUIElement child)
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
        void realign(){aligned_ = true;}
}
