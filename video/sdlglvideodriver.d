
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///GLVideoDriver using SDL to set up video mode.
module video.sdlglvideodriver;


import std.stdio;
import std.string;

import derelict.sdl.sdl;
import dgamevfs._;

import video.videodriver;
import video.glvideodriver;
import video.fontmanager;
import color;


///GLVideoDriver implementation using SDL to set up video mode.
final class SDLGLVideoDriver : GLVideoDriver
{
    public:
        /**
         * Construct a SDLGLVideoDriver.
         *
         * Params:  fontManager = Font manager to use for font rendering and management.
         *          gameDir     = Game data directory.
         *
         * Throws:  VFSException if the shader directory (shaders/) was not found in gameDir.
         */
        this(FontManager fontManager, VFSDir gameDir)
        {
            writeln("Initializing SDLGLVideoDriver");
            super(fontManager, gameDir);
        }

        ~this()
        {
            writeln("Destroying SDLGLVideoDriver");
        }

        override void setVideoMode(const uint width, const uint height, 
                                   const ColorFormat format, const bool fullscreen)
        {
            assert(width >= 80 && width <= 65536, 
                   "Can't set video mode with such ridiculous width");
            assert(height >= 60 && width <= 49152, 
                   "Can't set video mode with such ridiculous height");

            //determine bit depths of color channels.
            uint red, green, blue, alpha;
            switch(format)
            {
                case ColorFormat.RGB_565:
                    red = 5;
                    green = 6;
                    blue = 5;
                    alpha = 0;
                    break;
                case ColorFormat.RGBA_8:
                    red = 8;
                    green = 8;
                    blue = 8;
                    alpha = 8;
                    break;
                default:
                    assert(false, "Unsupported video mode color format");
            }

            SDL_GL_SetAttribute(SDL_GL_RED_SIZE, red);
            SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, green);
            SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, blue);
            SDL_GL_SetAttribute(SDL_GL_ALPHA_SIZE, alpha);
            SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

            const uint bitDepth = red + green + blue + alpha;

            uint flags = SDL_OPENGL;
            if(fullscreen){flags |= SDL_FULLSCREEN;}

            if(SDL_SetVideoMode(width, height, bitDepth, flags) is null)
            {
                string msg = std.string.format("Could not set video mode: %d %d %dbpp",
                                               width, height, bitDepth);
                writeln(msg);
                throw new VideoDriverException(msg);
            }

            screenWidth_ = width;
            screenHeight_ = height;
            
            initGL();
        }

        override void endFrame()
        {
            super.endFrame();
            SDL_GL_SwapBuffers();
        }
}
