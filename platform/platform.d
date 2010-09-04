module platform.platform;


import std.string;

public import platform.key;
import math.vector2;
import singleton;
import signal;


///Handles platform specific functionality like input/output.
abstract class Platform
{
    mixin Singleton;
    protected:
        bool[Key.max] keys_pressed;

    private:
        bool Run = true;
                 
    public:
        ///Emitted when a key is pressed. Passes the key, its state and unicode value.
        mixin Signal!(KeyState, Key, dchar) key;

        ///Emitted when a mouse button is pressed. Passes the key, its state and mouse position.
        mixin Signal!(KeyState, MouseKey, Vector2u) mouse_key;
        ///Emitted when mouse is moved. Passes mouse position and position change.
        mixin Signal!(Vector2u, Vector2i) mouse_motion;

        void die();
        
        ///Collect input and determine if the game should continue running.
        bool run()
        {
            return Run;
        }

        ///Quit the platform, i.e. the game.
        void quit()
        {
            Run = false;
        }

        ///Set window caption string to str.
        void window_caption(string str);

        ///Hide the mouse cursor.
        void hide_cursor();

        ///Show the mouse cursor.
        void show_cursor();

        ///Determine if specified key is pressed.
        bool is_key_pressed(Key key)
        {
            return keys_pressed[cast(uint)key];
        }
}
