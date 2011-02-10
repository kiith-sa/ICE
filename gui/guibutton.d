module gui.guibutton;


import gui.guielement;
import gui.guistatictext;
import video.videodriver;
import math.vector2;
import platform.platform;
import color;
import util.signal;
import util.factory;


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
        static align(1) struct State
        {
            //Color of button border.
            Color border_color;
            //Color of button text.
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

        void die()
        {
            super.die();
            text_ = null;
        }

        final void text(string text){text_.text = text;}

    protected:    
        /*
         * Construct a button with specified parameters.
         *
         * Params:  params    = Parameters for GUIElement constructor.
         *          text      = Button text.
         *          font_size = Font size of the button text.
         *          states    = Color data for each button state.
         */
        this(GUIElementParams params, string text, 
             uint font_size, State[ButtonState.max + 1] states)
        {
            super(params);

            auto factory = new GUIStaticTextFactory;
            factory.font_size = font_size;
            with(factory)
            {
                x = "p_left";
                y = "p_top";
                width = "p_width";
                height = "p_height";
                align_x = AlignX.Center;
                align_y = AlignY.Center;
                this.text_ = produce();
            }
            text_.text = text;
            add_child(text_); 

            states_[ButtonState.Normal] = states[ButtonState.Normal];
            states_[ButtonState.MouseOver] = states[ButtonState.MouseOver];
            states_[ButtonState.Clicked] = states[ButtonState.Clicked];
            set_state(ButtonState.Normal);
        }

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
                        set_state(ButtonState.MouseOver);
                        pressed.emit();
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

        override void draw(VideoDriver driver)
        {
            if(!visible_){return;}

            //no need to draw the text here as it is a child

            if(draw_border_)
            {
                Vector2f min = Vector2f(bounds_.min.x, bounds_.min.y);
                Vector2f max = Vector2f(bounds_.max.x, bounds_.max.y);
                driver.draw_rectangle(min, max, states_[state_].border_color);
            }

            draw_children(driver);
        }

    private:
        //Change button state and update text element accordingly.
        final void set_state(ButtonState state)
        {
            state_ = state;
            text_.text_color = states_[state_].text_color;
        }
}

/**
 * Factory used for button construction.
 *
 * See_Also: GUIElementFactoryBase
 *
 * Params:  text         = Button text.
 *                         Default: ""
 *          font_size    = Font size of the button text.
 *          text_color   = Text color for specified button state.
 *          border_color = Border color for specified button state.
 */
final class GUIButtonFactory : GUIElementFactoryBase!(GUIButton)
{
    mixin(generate_factory("string $ text $ \"\"", 
                           "uint $ font_size $ GUIStaticText.default_font_size()"));
    private:
        //Properties for each button state.
        GUIButton.State[ButtonState.max + 1] states_;
    public:
        this()
        {
            states_[ButtonState.Normal].border_color = Color(192, 192, 255, 96);
            states_[ButtonState.Normal].text_color = Color(160, 160, 255, 192);
            states_[ButtonState.MouseOver].border_color = Color(192, 192, 255, 160);
            states_[ButtonState.MouseOver].text_color = Color(192, 192, 255, 192);
            states_[ButtonState.Clicked].border_color = Color(192, 192, 255, 255);
            states_[ButtonState.Clicked].text_color = Color(224, 224, 255, 255);
        }

        void text_color(ButtonState state, Color color){states_[state].text_color = color;}
        void border_color(ButtonState state, Color color){states_[state].border_color = color;}

        ///Produce a GUIButton with parameters of the factory.
        override GUIButton produce()
        {
            return new GUIButton(gui_element_params, text_, font_size_, states_);
        }
}
