module video.sdlglvideodriver;


import derelict.sdl.sdl;

import video.glvideodriver;
import color;


///Handles all drawing functionality.
final class SDLGLVideoDriver : GLVideoDriver
{
    public:
        this(){singleton_ctor();}

        override void set_video_mode(uint width, uint height, 
                                     ColorFormat format, bool fullscreen)
        in
        {
            assert(width > 160 && width < 65536, 
                   "Can't set video mode with ridiculous width");
            assert(height > 120 && width < 49152, 
                   "Can't set video mode with ridiculout height");
        }
        body
        {
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

            uint bit_depth = red + green + blue + alpha;

            uint flags = SDL_OPENGL;
            if(fullscreen){flags |= SDL_FULLSCREEN;}

            if(SDL_SetVideoMode(width, height, bit_depth, flags) is null)
            {
                throw new Exception("Could not initialize video mode");
            }

            ScreenWidth = width;
            ScreenHeight = height;
            
            init_gl();
        }

        override void end_frame()
        {
            super.end_frame();
            SDL_GL_SwapBuffers();
        }
}
