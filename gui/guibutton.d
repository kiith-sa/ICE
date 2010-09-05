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
            Text = new GUIStaticText(this, Vector2i(0, 0), size, text, "default", 12);
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
            super.mouse_key(state, key, position);

            //handle click if clicked
            if(Bounds.intersect(Vector2i(position.x, position.y)))
            {
                if(key == MouseKey.Left)
                {
                    if(state == KeyState.Pressed){set_state(ButtonState.Clicked);}

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
                VideoDriver.get.draw_rectangle(min, max, 
                                               States[CurrentState].border_color);
            }

            draw_children();
        }

    private:
        //Change button state and update text element accordingly.
        final void set_state(ButtonState state)
        {
            CurrentState = state;
            Text.text_color = States[CurrentState].text_color;
        }
}
