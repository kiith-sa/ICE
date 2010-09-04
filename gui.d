module gui;


import std.string;

import videodriver;
import videodriverutil;
import color;
import vector2;
import rectangle;
import platform;
import util;
import singleton;
import signal;
import math;

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
            if(parent !is null)
            {
                parent.add_child(this);
            }
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

    protected:
        void draw()
        {
            if(!Visible){return;}

            if(DrawBorder)
            {
                Vector2f min = Vector2f(Bounds.min.x, Bounds.min.y);
                Vector2f max = Vector2f(Bounds.max.x, Bounds.max.y);
                draw_rectangle(min, max, BorderColor);
            }

            foreach(ref child; Children){child.draw();}
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

///GUI root element singleton. Contains drawing and input handling methods.
final class GUIRoot : GUIElement, Singleton
{
    invariant
    {
        assert(Parent is null, "GUI root element must not have a parent");
    }

    mixin SingletonMixin;
    public:
        ///Draw the GUI.
        override void draw()
        {
            if(!Visible){return;}

            auto driver = VideoDriver.get;

            //save view zoom and offset
            real zoom = driver.zoom;
            auto offset = driver.view_offset; 

            //set 1:1 zoom and zero offset for GUI drawing
            driver.zoom = 1.0;
            driver.view_offset = Vector2d(0.0, 0.0);

            //draw the elements
            foreach(ref child; Children){child.draw();}

            //restore zoom and offset
            driver.zoom = zoom;
            driver.view_offset = offset;
        }

        ///Pass keyboard input to the GUI.
        void key_handler(KeyState state, Key key, dchar unicode)
        {
            foreach_reverse(ref child; Children){child.key(state, key, unicode);}
        }

        ///Pass mouse key press input to the GUI.
        void mouse_key_handler(KeyState state, MouseKey key, 
                                     Vector2u position)
        {
            foreach_reverse(ref child; Children)
            {
                child.mouse_key(state, key, position);
            }
        }

        ///Pass mouse move input to the GUI.
        void mouse_move_handler(Vector2u position, Vector2i relative)
        {
            foreach_reverse(ref child; Children){child.mouse_move(position, relative);}
        }

    private:
        this()
        {
            auto driver = VideoDriver.get;
            //GUI size is equal to screen size
            Vector2u max = Vector2u(driver.screen_width, driver.screen_height);
            super(null, Vector2i(0,0), max);
        }
}

///Enumerates states a button can be in.
enum ButtonState
{
    Normal,
    MouseOver,
    Clicked
}                   

///Simple clickable button with text.
class GUIButton : GUIElement
{
    private:
        //Struct for properties that vary between button states.
        struct State
        {
            Color border_color;
            Color text_color;
        }

        //Properties for each button state.
        State[ButtonState.max + 1] States;

        //Current button state.
        ButtonState CurrentState = ButtonState.Normal;
        
        //Button text.
        GUIStaticText Text;     

    public:
        ///Emitted when this button is pressed.
        mixin Signal!() pressed;

        ///Construct a button with specified parameters.
        this(GUIElement parent, Vector2i position, Vector2u size, string text)
        {
            super(parent, position, size);

            //initialize empty text
            Text = new GUIStaticText(this, Vector2i(0, 0), size, text, 
                                     "default", 12);
            Text.alignment_x = AlignX.Center;
            Text.alignment_y = AlignY.Center;

            //set default colors for button states
            States[ButtonState.Normal].border_color = Color(192, 192, 255, 96);
            States[ButtonState.Normal].text_color = Color(160, 160, 255, 192);
            States[ButtonState.MouseOver].border_color = Color(192, 192, 255, 160);
            States[ButtonState.MouseOver].text_color = Color(192, 192, 255, 192);
            States[ButtonState.Clicked].border_color = Color(192, 192, 255, 255);
            States[ButtonState.Clicked].text_color = Color(224, 224, 255, 255);

            set_state(ButtonState.Normal);
        }

        void die()
        {
            super.die();
            Text = null;
        }

        ///Set text color for specified button state.
        final void text_color(Color color, ButtonState state)
        {
            States[state].text_color = color;
            //if we're in this state right now, we need to update text element's color
            if(state == CurrentState){set_state(state);}
        }

        ///Set border color for specified button state.
        final void border_color(Color color, ButtonState state)
        {
            States[state].border_color = color;
            //if we're in this state right now, we need to update text element's color
            if(state == CurrentState){set_state(state);}
        }

    protected:    
        void mouse_key(KeyState state, MouseKey key, Vector2u position)
        {
            //ignore hidden elements
            if(!Visible){return;}

            //pass input to children
            foreach_reverse(ref child; Children)
            {
                child.mouse_key(state, key, position);
            }

            //handle click if clicked
            if(Bounds.intersect(Vector2i(position.x, position.y)))
            {
                if(key == MouseKey.Left)
                {
                    if(state == KeyState.Pressed)
                    {
                        set_state(ButtonState.Clicked);
                    }
                    //If the mouse is pressed _and_ released over the button,
                    //emit the signal
                    else if(state == KeyState.Released && 
                            CurrentState == ButtonState.Clicked)
                    {
                        pressed.emit();
                        set_state(ButtonState.MouseOver);
                    }
                }
                return;
            }
            set_state(ButtonState.Normal);
        }

        override void mouse_move(Vector2u position, Vector2i relative)
        {
            super.mouse_move(position, relative);

            //if clicked, keep that state so that we can drag mouse 
            //after clicking a button.
            if(CurrentState == ButtonState.Clicked){return;}
            //if the mouse is above the element
            if(Bounds.intersect(Vector2i(position.x, position.y)))
            {
                set_state(ButtonState.MouseOver);
            }
            else{set_state(ButtonState.Normal);}
        }

        override void draw()
        {
            if(!Visible){return;}

            //no need to draw the text here as it is a child

            if(DrawBorder)
            {
                Vector2f min = Vector2f(Bounds.min.x, Bounds.min.y);
                Vector2f max = Vector2f(Bounds.max.x, Bounds.max.y);
                draw_rectangle(min, max, States[CurrentState].border_color);
            }

            foreach(ref child; Children){child.draw();}
        }

    private:
        //Change button state and update text element accordingly.
        final void set_state(ButtonState state)
        {
            CurrentState = state;
            Text.text_color = States[CurrentState].text_color;
        }
}

///Horizontal alignments.
enum AlignX
{
    Right,
    Center,
    Left
}

///Vertical alignments.
enum AlignY
{
    Top,
    Center,
    Bottom
}

///Static text element. Text is broken down into lines to fit width.
class GUIStaticText : GUIElement
{
    private:
        //Single line of text drawn on screen.
        struct TextLine
        {
            //position relative to element position.
            Vector2i offset;
            //text of the line.
            string text;
        }

        //Text of the element. This is broken into TextLines according to width.
        string Text;

        AlignX AlignmentX = AlignX.Left;
        AlignY AlignmentY = AlignY.Top;
        
        //Lines of text to draw.
        TextLine[] Lines;

        Color FontColor = Color(255, 255, 255, 255);

        //Name of the font used.
        string Font;

        uint FontSize;
        
        //Distance between lines, in pixels
        uint LineGap;

        //True if Lines are aligned according to current settings, false otherwise.
        //(used to determine whether or not Lines need realigning before drawing)
        bool Aligned;

    public:
        ///Construct a static text with specified parameters.
        this(GUIElement parent, Vector2i position, Vector2u size, string text, 
             string font, uint font_size)
        {
            super(parent, position, size);
            text = expandtabs(text);
            DrawBorder = false;
            Font = font;
            FontSize = font_size;
            LineGap = max(2u, FontSize / 6);
            Text = text;
            realign();
            Aligned = true;
        }

        ///Set text color.
        void text_color(Color color)
        {
            FontColor = color;
        }

        ///Set size of this element in screen space.
        override void size(Vector2u size)
        {
            super.size(size);
            Aligned = false;
        }
        
        ///Set horizontal alignment.
        void alignment_x(AlignX alignment)
        {
            AlignmentX = alignment;
            Aligned = false;
        }

        ///Set vertical alignment.
        void alignment_y(AlignY alignment)
        {
            AlignmentY = alignment;
            Aligned = false;
        }

        ///Set distance between lines.
        void line_gap(uint gap)
        {
            LineGap = gap;
            Aligned = false;
        }

    protected:
        override void draw()
        {
            super.draw();
            //must realign if settings changed
            if(!Aligned)
            {
                realign();
                Aligned = true;
            }

            VideoDriver.get.font = Font;
            VideoDriver.get.font_size = FontSize;
            foreach(ref line; Lines)
            {
                Vector2i offset = Bounds.min + line.offset;
                VideoDriver.get.draw_text(offset, line.text, FontColor);
            }
        }

    private:
        
        //Add a TextLine from the text, and return rest of the text.
        string add_line(string text, uint y_offset_in, out uint y_offset_out)
        {
            //get leading space, if any, and following word from text
            string get_word()
            {
                uint end;
                foreach(i, dchar c; text){if(!iswhite(c)){end = i; break;}}
                foreach(dchar c; text[end .. $]){if(iswhite(c)){break;}++end;}
                return text[0 .. end];
            }

            //line we're constructing
            TextLine line;
            VideoDriver driver = VideoDriver.get;
            uint width = super.size.x;

            while(text.length > 0)
            {
                string word = get_word();

                //can we add word to the line without passing width?
                Vector2u line_size = driver.text_size(line.text ~ word);
                if(line_size.x > width)
                {
                    //line too wide, don't add the word and break
                    if(line.text.length == 0)
                    {
                        //word is too huge for a single line, 
                        //so add a line with only that word
                        line.text = word; 
                        text = text[word.length .. $];
                    }
                    //update y position to below this line
                    y_offset_out = y_offset_in + line_size.y + LineGap;
                    break;
                }
                else
                {
                    line.text ~= word;
                    text = text[word.length .. $];
                }
            }

            //align the line horizontally
            line.offset = Vector2i(0, y_offset_in);
            if(AlignmentX == AlignX.Right)
            {
                line.offset.x = width - driver.text_size(line.text).x;
            }
            if(AlignmentX == AlignX.Center)
            {
                line.offset.x = (width - driver.text_size(line.text).x) / 2;
            }
            Lines ~= line;
            //strip leading space so the next line doesn't start with space
            return stripl(text);
        }
        
        //Align lines verically.
        void align_vertical()
        {
            //if AlignY is Top, we're aligned as lines start at y == 0 by default
            if(Lines.length == 0 || AlignmentY == AlignY.Top){return;}
            uint text_height = FontSize * Lines.length + LineGap * (Lines.length - 1);
            int offset_y = super.size.y - text_height;
            if(AlignmentY == AlignY.Center){offset_y /= 2;}
            //move lines according to the offset
            foreach(ref line; Lines){line.offset.y += offset_y;}
        }

        //Break text down to lines and realign it.
        void realign()
        {
            string text = Text;

            //we need to set font to get information about drawn size of lines
            VideoDriver.get.font = Font;
            VideoDriver.get.font_size = FontSize;
            Lines = [];
            uint y_offset;
            while(text.length > 0)
            {
                text = add_line(text, y_offset, y_offset);
            }
            align_vertical();
        }
}               
