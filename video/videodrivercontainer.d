
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module video.videodrivercontainer;


import video.videodriver;
import video.sdlglvideodriver;
import video.fontmanager;
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
        ///Construct a VideoDriverContainer.
        this(){font_manager_ = new FontManager;}

        /**
         * Initialize video driver of specified type and return a reference to it.
         *
         * Params:  width      = Width of initial video mode.
         *          height     = Height of initial video mode.
         *          format     = Color format of initial video mode.
         *          fullscreen = Should initial video mode be fullscreen?
         */
        VideoDriver produce(T)(uint width, uint height, ColorFormat format, bool fullscreen)
        {
            static assert(is(T : VideoDriver));
            video_driver_ = new T(font_manager_);
            video_driver_.set_video_mode(width, height, format, fullscreen);
            font_manager_.reload_textures(video_driver_);
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
