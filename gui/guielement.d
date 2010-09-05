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
        GUIElement Parent = null;
        GUIElement[] Children;

        //Color of the element's border.
        Color BorderColor = Color(255, 255, 255, 96);
        //Bounds of this element in screen space.
        Rectanglei Bounds;

        //Is this element visible?
        bool Visible = true;
        //Draw border of this element?
        bool DrawBorder = true;

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
            assert(Parent is null && Children is null,
                   "GUIElement must be cleared before it is destroyed");
        }
        
        //This is probably not even needed, as the GC shoudln't need everything
        //to be disconnected.
        ///Destroy this element.
        void die()
        {
            foreach(ref child; Children)
            {
                child.die();
                child = null;
            }
            Children = null;
            Parent = null;
        }                 

        ///Get position in screen space.
        final Vector2i position_global(){return Bounds.min;}

        ///Set position in screen space.
        final void position_global(Vector2i position)
        out
        {
            assert(Bounds.min == position, 
                   "Global position of a GUI element was not set correctly");
        }
        body
        {
            Vector2i offset = position - Bounds.min;
            Bounds += offset;
            //move the children with parent
            foreach(ref child; Children)
            {
                child.position_global = child.position_global + offset;
            }
        }

        ///Get position relative to parent element.
        final Vector2i position_local(){return Bounds.min - Parent.Bounds.min;}

        ///Set position relative to parent element.
        final void position_local(Vector2i position)
        {
            Vector2i offset = Parent is null ? Vector2i(0,0) : Parent.Bounds.min;
            position_global(position + offset);
        }
        
        ///Return size of this element in screen space.
        final Vector2u size(){return Vector2u(Bounds.size.x, Bounds.size.y);}

        ///Set size of this element in screen space.
        void size(Vector2u size)
        {
            Bounds.max = Bounds.min + Vector2i(size.x, size.y);
        }

        ///Add a child element.
        final void add_child(GUIElement child)
        {
            Children ~= child;
            child.Parent = this;
        }

        ///Remove a child element.
        final void remove_child(GUIElement child)
        in
        {
            assert(Children.contains(child, true) && child.Parent is this,
                   "Trying to remove a child that is not a child of this GUI "
                   "element.");
        }
        body
        {
            Children.remove(child, true);
            child.Parent = null;
        }

        ///Return true if this element is visible, false if hidden.
        final bool visible(){return Visible;}

        ///Set this element to visible or hidden.
        final void visible(bool visible){Visible = visible;}

        ///Return parent of this element.
        final GUIElement parent(){return Parent;}

        ///Determine if an element is a child of this element.
        final bool is_child(GUIElement element){return Parent is element;}



    package:
        final void draw_children()
        {
            foreach(ref child; Children){child.draw();}
        }

    protected:
        void draw()
        {
            if(!Visible){return;}

            if(DrawBorder)
            {
                Vector2f min = Vector2f(Bounds.min.x, Bounds.min.y);
                Vector2f max = Vector2f(Bounds.max.x, Bounds.max.y);
                VideoDriver.get.draw_rectangle(min, max, BorderColor);
            }

            draw_children();
        }

        //Process keyboard input.
        void key(KeyState state, Key key, dchar unicode)
        {
            //ignore for hidden elements
            if(!Visible){return;}

            //pass input to the children
            foreach_reverse(ref child; Children){child.key(state, key, unicode);}
        }

        //Process mouse key presses. 
        void mouse_key(KeyState state, MouseKey key, Vector2u position)
        {
            //ignore hidden elements
            if(!Visible){return;}

            //pass input to the children
            foreach_reverse(ref child; Children)
            {
                child.mouse_key(state, key, position);
            }
        }

        //Process mouse movement.
        void mouse_move(Vector2u position, Vector2i relative)
        {
            //ignore hidden elements
            if(!Visible){return;}

            //pass input to the children
            foreach_reverse(ref child; Children)
            {
                child.mouse_move(position, relative);
            }
        }
}
