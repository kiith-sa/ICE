
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module platform.platform;


import std.string;

public import platform.key;
import math.vector2;
import util.weaksingleton;
import util.signal;


///Handles platform specific functionality like input/output.
abstract class Platform
{
    mixin WeakSingleton;
    protected:
        bool[Key.max] keys_pressed_;

    private:
        bool run_ = true;
                 
    public:
        ///Emitted when a key is pressed. Passes the key, its state and unicode value.
        mixin Signal!(KeyState, Key, dchar) key;

        ///Emitted when a mouse button is pressed. Passes the key, its state and mouse position.
        mixin Signal!(KeyState, MouseKey, Vector2u) mouse_key;
        ///Emitted when mouse is moved. Passes mouse position and position change.
        mixin Signal!(Vector2u, Vector2i) mouse_motion;

        ///Construct Platform.
        this(){singleton_ctor();}

        ///Destroy the Platform.
        void die(){singleton_dtor();}
        
        ///Collect input and determine if the game should continue running.
        bool run(){return run_;}

        ///Quit the platform, i.e. the game.
        final void quit(){run_ = false;}

        ///Set window caption string to str.
        void window_caption(string str);

        ///Hide the mouse cursor.
        void hide_cursor();

        ///Show the mouse cursor.
        void show_cursor();

        ///Determine if specified key is pressed.
        final bool is_key_pressed(Key key){return keys_pressed_[cast(uint)key];}
}
