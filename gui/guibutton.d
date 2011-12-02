
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Button widget.
module gui.guibutton;
@safe


import gui.guielement;
import gui.guistatictext;
import video.videodriver;
import math.vector2;
import platform.platform;
import color;
import util.signal;
import util.factory;


///States a button can be in.
enum ButtonState
{
    ///Normal (default) state.
    Normal,
    ///Mouse is above the button.
    MouseOver,
    ///Mouse is clicking or holding the button.
    Clicked
}                   

/**
 * Simple clickable button with text.
 *
 * Signal:
 *     public mixin Signal!() pressed
 *
 *     Emitted when this button is pressed. 
 */
class GUIButton : GUIElement
{
    private:
        ///Struct for properties that vary between button states.
        static struct State
        {
            ///Color of button border.
            Color border_color;
            ///Color of button text.
            Color text_color;
        }

        ///Properties for each button state.
        State[ButtonState.max + 1] states_;
        ///Current button state.
        ButtonState state_ = ButtonState.Normal;
        
        ///Button text.
        GUIStaticText text_;     

    public:
        ///Emitted when this button is pressed.
        mixin Signal!() pressed;

        ~this(){pressed.disconnect_all();}

    protected:    
        /**
         * Construct a button with specified parameters.
         *
         * Params:  params    = Parameters for GUIElement constructor.
         *          text      = Button text.
         *          font_size = Font size of the button text.
         *          states    = Color data for each button state.
         */
        this(in GUIElementParams params, in string text, 
             in uint font_size, in State[ButtonState.max + 1] states)
        {
            super(params);

            //initialize button text
            auto factory = new GUIStaticTextFactory;
            factory.font_size = font_size;
            factory.text      = text;
            with(factory)
            {
                x       = "p_left";
                y       = "p_top";
                width   = "p_width";
                height  = "p_height";
                align_x = AlignX.Center;
                align_y = AlignY.Center;
                this.text_ = produce();
            }
            add_child(text_); 

            states_[] = states[];
            set_state(ButtonState.Normal);
        }

        override void mouse_key(KeyState state, MouseKey key, Vector2u position)
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
                    else if(state == KeyState.Released && state_ == ButtonState.Clicked)
                    {
                        set_state(ButtonState.MouseOver);
                        pressed.emit();
                    }
                }
            }
            //set normal state if mouse is released (or pressed) outside the button.
            else{set_state(ButtonState.Normal);}
        }

        override void mouse_move(Vector2u position, Vector2i relative)
        {
            super.mouse_move(position, relative);

            //if clicked, keep that state so that we can drag mouse after clicking a button.
            if(state_ == ButtonState.Clicked){return;}
            //if mouse above the element and not clicked, set mouseover
            //if mouse outside the element and not clicked, return to normal
            set_state(bounds_.intersect(math.vector2.to!int(position)) 
                      ? ButtonState.MouseOver : ButtonState.Normal);
        }

        override void draw(VideoDriver driver)
        {
            if(!visible_){return;}

            border_color_ = states_[state_].border_color;

            super.draw(driver);

            //no need to draw the text here as it is a child
        }

    private:
        ///Change button state and update text element accordingly.
        final void set_state(in ButtonState state)
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
 *                         Default; ""
 *          font_size    = Font size of the button text.
 *          text_color   = Text color for specified button state.
 *          border_color = Border color for specified button state.
 */
final class GUIButtonFactory : GUIElementFactoryBase!GUIButton
{
    mixin(generate_factory(`string $ text      $ ""`, 
                           `uint   $ font_size $ GUIStaticText.default_font_size()`));
    private:
        ///Properties for each button state.
        GUIButton.State[ButtonState.max + 1] states_;

    public:
        ///Construct a GUIButtonFactory.
        this()
        {
            //Initialize default values for button colors.
            states_[ButtonState.Normal].border_color    = rgba!"C0C0FF60";
            states_[ButtonState.Normal].text_color      = rgba!"A0A0FFC0";
            states_[ButtonState.MouseOver].border_color = rgba!"C0C0FFA0";
            states_[ButtonState.MouseOver].text_color   = rgba!"C0C0FFC0";
            states_[ButtonState.Clicked].border_color   = rgb!"C0C0FF";
            states_[ButtonState.Clicked].text_color     = rgb!"E0E0FF";
        }

        void text_color(in ButtonState state, in Color color)
        {
            states_[state].text_color = color;
        }

        void border_color(in ButtonState state, in Color color)
        {
            states_[state].border_color = color;
        }

        ///Produce a GUIButton with parameters of the factory.
        override GUIButton produce()
        {
            return new GUIButton(gui_element_params, text_, font_size_, states_);
        }
}
