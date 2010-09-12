module gui.guibutton;


import gui.guielement;
import gui.guistatictext;
import video.videodriver;
import math.vector2;
import platform.platform;
import color;
import signal;


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
        State[ButtonState.max + 1] states_;

        //Current button state.
        ButtonState state_ = ButtonState.Normal;
        
        //Button text.
        GUIStaticText text_;     

    public:
        ///Emitted when this button is pressed.
        mixin Signal!() pressed;

        ///Construct a button with specified parameters.
        this(GUIElement parent, Vector2i position, Vector2u size, string text)
        {
            super(parent, position, size);

            //initialize empty text
            text_ = new GUIStaticText(this, Vector2i(0, 0), size, text, "default", 12);
            text_.alignment_x = AlignX.Center;
            text_.alignment_y = AlignY.Center;

            //set default colors for button states
            states_[ButtonState.Normal].border_color = Color(192, 192, 255, 96);
            states_[ButtonState.Normal].text_color = Color(160, 160, 255, 192);
            states_[ButtonState.MouseOver].border_color = Color(192, 192, 255, 160);
            states_[ButtonState.MouseOver].text_color = Color(192, 192, 255, 192);
            states_[ButtonState.Clicked].border_color = Color(192, 192, 255, 255);
            states_[ButtonState.Clicked].text_color = Color(224, 224, 255, 255);

            set_state(ButtonState.Normal);
        }

        void die()
        {
            super.die();
            text_ = null;
        }

        ///Set text color for specified button state.
        final void text_color(Color color, ButtonState state)
        {
            states_[state].text_color = color;
            //if we're in this state right now, we need to update text element's color
            if(state == state_){set_state(state);}
        }

        ///Set border color for specified button state.
        final void border_color(Color color, ButtonState state)
        {
            states_[state].border_color = color;
            //if we're in this state right now, we need to update text element's color
            if(state == state_){set_state(state);}
        }

        ///Set font size of the button text.
        final void font_size(uint size)
        {
            text_.font_size = size;
        }

    protected:    
        void mouse_key(KeyState state, MouseKey key, Vector2u position)
        {
            super.mouse_key(state, key, position);

            //handle click if clicked
            if(bounds_.intersect(Vector2i(position.x, position.y)))
            {
                if(key == MouseKey.Left)
                {
                    if(state == KeyState.Pressed){set_state(ButtonState.Clicked);}

                    //If the mouse is pressed _and_ released over the button,
                    //emit the signal
                    else if(state == KeyState.Released && 
                            state_ == ButtonState.Clicked)
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
            if(state_ == ButtonState.Clicked){return;}
            //if the mouse is above the element
            if(bounds_.intersect(Vector2i(position.x, position.y)))
            {
                set_state(ButtonState.MouseOver);
            }
            else{set_state(ButtonState.Normal);}
        }

        override void draw()
        {
            if(!visible_){return;}

            //no need to draw the text here as it is a child

            if(draw_border_)
            {
                Vector2f min = Vector2f(bounds_.min.x, bounds_.min.y);
                Vector2f max = Vector2f(bounds_.max.x, bounds_.max.y);
                VideoDriver.get.draw_rectangle(min, max, 
                                               states_[state_].border_color);
            }

            draw_children();
        }

    private:
        //Change button state and update text element accordingly.
        final void set_state(ButtonState state)
        {
            state_ = state;
            text_.text_color = states_[state_].text_color;
        }
}
