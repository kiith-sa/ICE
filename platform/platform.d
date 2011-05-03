
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


module platform.platform;
@safe


public import platform.key;
import math.vector2;
import util.weaksingleton;
import util.signal;


///Exception thrown at platform related errors.
class PlatformException : Exception{this(string msg){super(msg);}} 

/**
 * Handles platform specific functionality like input/output.
 *
 *
 * Signal:
 *     public mixin Signal!(KeyState, Key, dchar) key
 *
 *     Emitted when a key is pressed. Passes the key, its state and unicode value.
 *
 * Signal:
 *     public mixin Signal!(KeyState, MouseKey, Vector2u) mouse_key 
 *
 *     Emitted when a mouse button is pressed. Passes the key, its state and mouse position.
 *
 * Signal:
 *     public mixin Signal!(Vector2u, Vector2i) mouse_motion
 *
 *     Emitted when mouse is moved. Passes mouse position and position change. 
 */
abstract class Platform
{
    mixin WeakSingleton;
    protected:
        ///Array of bools for each key specifying if the key is currently pressed.
        bool[Key.max] keys_pressed_;

    private:
        ///Continue to run?
        bool run_ = true;
                 
    public:
        ///Emitted when a key is pressed. Passes the key, its state and unicode value.
        mixin Signal!(KeyState, Key, dchar) key;
        ///Emitted when a mouse button is pressed. Passes the key, its state and mouse position.
        mixin Signal!(KeyState, MouseKey, Vector2u) mouse_key;
        ///Emitted when mouse is moved. Passes mouse position and position change.
        mixin Signal!(Vector2u, Vector2i) mouse_motion;

        /**
         * Construct Platform.
         *
         * Throws:  PlatformException on failure.
         */
        this(){singleton_ctor();}

        ///Destroy the Platform.
        void die()
        {
            key.disconnect_all();
            mouse_key.disconnect_all();
            mouse_motion.disconnect_all();

            singleton_dtor();
        }
        
        ///Collect input and determine if the game should continue to run.
        bool run(){return run_;}

        ///Quit the platform, i.e. the game.
        final void quit(){run_ = false;}

        ///Set window caption string to str.
        @property void window_caption(in string str);

        ///Hide the mouse cursor.
        void hide_cursor();

        ///Show the mouse cursor.
        void show_cursor();

        ///Determine if specified key is pressed.
        final bool is_key_pressed(in Key key) const 
        {
            return keys_pressed_[cast(uint)key];
        }
}
