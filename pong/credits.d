//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Credits screen.
module pong.credits;


import gui.guielement;
import gui.guibutton;
import gui.guistatictext;
import util.signal;


/**
 * Credits screen.
 *
 * Signal:
 *     public mixin Signal!() closed
 *
 *     Emitted when this credits dialog is closed.
 */
class Credits
{
    private:
        ///Credits text.
        static immutable credits_ = 
            "Credits\n"
            ".\n"
            "DPong was written by Ferdinand Majerech aka Kiith-Sa in the D Programming language\n"
            ".\n"
            "Other tools used to create Pong:\n"
            ".\n"
            "OpenGL graphics programming API\n"
            "SDL library\n"
            "The Freetype Project\n"
            "Derelict D bindings\n"
            "CDC build script\n"
            "Linux OS\n"
            "Vim the text editor\n"
            "Valgrind debugging and profiling suite\n"
            "Git revision control system\n"
            ".\n"
            "Pong is released under the terms of the Boost license.";

        ///Parent of the container.
        GUIElement parent_;

        ///GUI element containing all elements of the credits screen.
        GUIElement container_;
        ///Button used to close the screen.
        GUIButton closeButton_;
        ///Credits text.
        GUIStaticText text_;

    public:
        ///Emitted when this credits dialog is closed.
        mixin Signal!() closed;

        /**
         * Construct a Credits screen.
         *
         * Params:  parent = GUI element to attach the credits screen to.
         */
        this(GUIElement parent)
        {
            parent_ = parent;

            with(new GUIElementFactory)
            {
                margin(16, 96, 16, 96);
                container_ = produce();
            }
            parent_.addChild(container_);

            with(new GUIStaticTextFactory)
            {
                margin(16, 16, 40, 16);
                text = credits_;
                this.text_ = produce();
            }

            with(new GUIButtonFactory)
            {
                x      = "p_left + p_width / 2 - 72";
                y      = "p_bottom - 32";
                width  = "144";
                height = "24";
                text   = "Close";
                closeButton_ = produce();
            }

            container_.addChild(text_);
            container_.addChild(closeButton_);
            closeButton_.pressed.connect(&closed.emit);
        }

        ///Destroy this credits screen.
        ~this()
        {
            container_.die();
            closed.disconnectAll();
        }
}
