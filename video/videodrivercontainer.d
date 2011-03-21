
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module video.videodrivercontainer;


import std.stdio;

import video.videodriver;
import video.sdlglvideodriver;
import video.fontmanager;
import video.font;
import video.texture;
import color;


///Class managing lifetime and dependencies of video driver.
class VideoDriverContainer
{
    private:
        ///FontManager used by the VideoDriver.
        FontManager font_manager_;
        ///Video driver managed.
        VideoDriver video_driver_;

    public:
        /**
         * Construct a VideoDriverContainer.
         *
         * Throws:  VideoDriverException on failure.
         */
        this()
        {
            try{font_manager_ = new FontManager;}
            catch(FontException e)
            {
                throw new VideoDriverException("VideoDriverContainer could not be "
                                               "initialized: " ~ e.msg);
            }
        }

        /**
         * Initialize video driver of specified type and return a reference to it.
         *
         * Params:  width      = Width of initial video mode.
         *          height     = Height of initial video mode.
         *          format     = Color format of initial video mode.
         *          fullscreen = Should initial video mode be fullscreen?
         *
         * Throws:  VideoDriverException if the video driver could not be initialized.
         */
        VideoDriver produce(T)(uint width, uint height, ColorFormat format, bool fullscreen)
        {
            static assert(is(T : VideoDriver));
            video_driver_ = new T(font_manager_);
            scope(failure)
            {
                video_driver_.die();
                video_driver_ = null;
                writefln("VideoDriver initialization failed");
            }
            video_driver_.set_video_mode(width, height, format, fullscreen);

            try{font_manager_.reload_textures(video_driver_);}
            catch(TextureException e)
            {
                throw new VideoDriverException("Video driver construction error: "
                                               "Font textures could not be reloaded: " ~ e.msg);
            }
            return video_driver_;
        }

        ///Destroy the video driver.
        void destroy()
        {
            font_manager_.unload_textures(video_driver_);
            video_driver_.die();
            video_driver_ = null;
        }

        /**
         * Destroy the container.
         *
         * Destroys any video driver dependencies.
         * Video driver must be destroyed first by calling destroy().
         */
        void die()
        in{assert(video_driver_ is null, "VideoDriver must be destroyed before its container");}
        body{font_manager_.die();}
}
