
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///SDL platform implementation.
module platform.sdlplatform;


import std.conv;
import std.stdio;
import std.string;

import derelict.sdl.sdl;
import derelict.util.exception;

import platform.key;
import platform.platform;
import math.vector2;


///Platform implementation based on SDL 1.2 .
class SDLPlatform : Platform
{
    public:
        /**
         * Construct an SDLPlatform. 
         *
         * Initializes SDL.
         *
         * Throws:  PlatformException on failure.
         */
        this()
        {
            writeln("Initializing SDLPlatform");
            scope(failure){writeln("SDLPlatform initialization failed");}

            super();

            try
            {
                DerelictSDL.load();
            }
            catch(SharedLibLoadException e)
            {
                throw new PlatformException("SDL library not found: " ~ e.msg);
            }
            catch(SymbolLoadException e)
            {
                throw new PlatformException("Unsupported SDL version: " ~ e.msg);
            }

            if(SDL_Init(SDL_INIT_VIDEO) < 0)
            {
                DerelictSDL.unload();
                throw new PlatformException("Could not initialize SDL: " 
                                            ~ to!string(SDL_GetError()));
            }
            SDL_EnableUNICODE(SDL_ENABLE);
        }

        ~this()
        {
            writeln("Destroying SDLPlatform");
            SDL_Quit();
            DerelictSDL.unload();
        }

        override bool run()
        {
            SDL_Event event;

            while(SDL_PollEvent(&event)) switch(event.type)
            {
                case SDL_QUIT:
                    quit();
                    break;
                case SDL_KEYDOWN:
                case SDL_KEYUP:
                    processKey(event.key);
                    break;
                case SDL_MOUSEBUTTONDOWN:
                case SDL_MOUSEBUTTONUP:
                    processMouseKey(event.button);
                    break;
                case SDL_MOUSEMOTION:
                    processMouseMotion(event.motion);
                    break;
                default:
                    break;
            }
            return super.run();
        }

        @property override void windowCaption(const string str)
        {
            SDL_WM_SetCaption(toStringz(str), null); 
        }

        override void hideCursor(){SDL_ShowCursor(0);}

        override void showCursor(){SDL_ShowCursor(1);}

    package:
        ///Process a keyboard event.
        void processKey(const SDL_KeyboardEvent event)
        {
            KeyState state = KeyState.Pressed;
            keysPressed_[event.keysym.sym] = true;
            if(event.type == SDL_KEYUP)
            {
                state = KeyState.Released;
                keysPressed_[event.keysym.sym] = false;
            }
            key.emit(state, cast(Key)event.keysym.sym, event.keysym.unicode);
        }

        ///Process a mouse button event.
        void processMouseKey(const SDL_MouseButtonEvent event) 
        {
            const state = event.type == SDL_MOUSEBUTTONUP ? KeyState.Released 
                                                          : KeyState.Pressed;

            //Convert SDL button to MouseKey enum.
            MouseKey key;
            switch(event.button)
            {
                case(SDL_BUTTON_LEFT): key = MouseKey.Left;           break;
                case(SDL_BUTTON_MIDDLE): key = MouseKey.Middle;       break;
                case(SDL_BUTTON_RIGHT): key = MouseKey.Right;         break;
                case(SDL_BUTTON_WHEELUP): key = MouseKey.WheelUp;     break;
                case(SDL_BUTTON_WHEELDOWN): key = MouseKey.WheelDown; break;
                default: break;
            }

            const position = Vector2u(event.x, event.y);

            mouseKey.emit(state, key, position);
        }

        ///Process a mouse motion event.
        void processMouseMotion(const SDL_MouseMotionEvent event) 
        {
            const position = Vector2u(event.x, event.y);
            const positionRelative = Vector2i(event.xrel, event.yrel);
            mouseMotion.emit(position, positionRelative);
        }
}
