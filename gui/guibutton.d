
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Button widget.
module gui.guibutton;


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
            Color borderColor;
            ///Color of button text.
            Color textColor;
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

        ~this(){pressed.disconnectAll();}

    protected:
        /**
         * Construct a button with specified parameters.
         *
         * Params:  params    = Parameters for GUIElement constructor.
         *          text      = Button text.
         *          fontSize = Font size of the button text.
         *          states    = Color data for each button state.
         */
        this(in GUIElementParams params, const string text, 
             in uint fontSize, in State[ButtonState.max + 1] states)
        {
            super(params);

            //initialize button text
            auto factory = new GUIStaticTextFactory;
            factory.fontSize = fontSize;
            factory.text      = text;
            with(factory)
            {
                x       = "p_left";
                y       = "p_top";
                width   = "p_width";
                height  = "p_height";
                alignX = AlignX.Center;
                alignY = AlignY.Center;
                this.text_ = produce();
            }
            addChild(text_); 

            states_[] = states[];
            setState(ButtonState.Normal);
        }

        override void mouseKey(KeyState state, MouseKey key, Vector2u position)
        {
            super.mouseKey(state, key, position);

            //handle click if clicked
            if(bounds_.intersect(Vector2i(position.x, position.y)))
            {
                if(key == MouseKey.Left)
                {
                    if(state == KeyState.Pressed){setState(ButtonState.Clicked);}

                    //If the mouse is pressed _and_ released over the button,
                    //emit the signal
                    else if(state == KeyState.Released && state_ == ButtonState.Clicked)
                    {
                        setState(ButtonState.MouseOver);
                        pressed.emit();
                    }
                }
            }
            //set normal state if mouse is released (or pressed) outside the button.
            else{setState(ButtonState.Normal);}
        }

        override void mouseMove(Vector2u position, Vector2i relative)
        {
            super.mouseMove(position, relative);

            //if clicked, keep that state so that we can drag mouse after clicking a button.
            if(state_ == ButtonState.Clicked){return;}
            //if mouse above the element and not clicked, set mouseover
            //if mouse outside the element and not clicked, return to normal
            setState(bounds_.intersect(position.to!int) 
                      ? ButtonState.MouseOver : ButtonState.Normal);
        }

        override void draw(VideoDriver driver)
        {
            if(!visible_){return;}

            borderColor_ = states_[state_].borderColor;

            super.draw(driver);

            //no need to draw the text here as it is a child
        }

    private:
        ///Change button state and update text element accordingly.
        final void setState(in ButtonState state)
        {
            state_ = state;
            text_.textColor = states_[state_].textColor;
        }
}

/**
 * Factory used for button construction.
 *
 * SeeAlso: GUIElementFactoryBase
 *
 * Params:  text         = Button text.
 *                         Default; ""
 *          fontSize    = Font size of the button text.
 *          textColor   = Text color for specified button state.
 *          borderColor = Border color for specified button state.
 */
final class GUIButtonFactory : GUIElementFactoryBase!GUIButton
{
    mixin(generateFactory(`string $ text      $ ""`, 
                           `uint   $ fontSize $ GUIStaticText.defaultFontSize()`));
    private:
        ///Properties for each button state.
        GUIButton.State[ButtonState.max + 1] states_;

    public:
        ///Construct a GUIButtonFactory.
        this()
        {
            //Initialize default values for button colors.
            states_[ButtonState.Normal].borderColor    = rgba!"C0C0FF60";
            states_[ButtonState.Normal].textColor      = rgba!"A0A0FFC0";
            states_[ButtonState.MouseOver].borderColor = rgba!"C0C0FFA0";
            states_[ButtonState.MouseOver].textColor   = rgba!"C0C0FFC0";
            states_[ButtonState.Clicked].borderColor   = rgb!"C0C0FF";
            states_[ButtonState.Clicked].textColor     = rgb!"E0E0FF";
        }

        void textColor(in ButtonState state, in Color color)
        {
            states_[state].textColor = color;
        }

        void borderColor(in ButtonState state, in Color color)
        {
            states_[state].borderColor = color;
        }

        ///Produce a GUIButton with parameters of the factory.
        override GUIButton produce()
        {
            return new GUIButton(guiElementParams, text_, fontSize_, states_);
        }
}
