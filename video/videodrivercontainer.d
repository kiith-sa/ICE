
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Class managing video driver dependencies.
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
        FontManager fontManager_;
        ///Video driver managed.
        VideoDriver videoDriver_;

    public:
        /**
         * Construct a VideoDriverContainer.
         *
         * Throws:  VideoDriverException on failure.
         */
        this()
        {
            try{fontManager_ = new FontManager;}
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
        VideoDriver produce(Driver)(const uint width, const uint height, 
                                    const ColorFormat format, const bool fullscreen)
            if(is(Driver: VideoDriver))
        {
            scope(failure)
            {
                clear(videoDriver_);
                videoDriver_ = null;
                writeln("VideoDriver initialization failed");
            }
            videoDriver_ = new Driver(fontManager_);
            videoDriver_.setVideoMode(width, height, format, fullscreen);

            try{fontManager_.reloadTextures(videoDriver_);}
            catch(TextureException e)
            {
                throw new VideoDriverException("Video driver construction error: "
                                               "Font textures could not be reloaded: " ~ e.msg);
            }
            return videoDriver_;
        }

        ///Destroy the video driver.
        void destroy()
        {
            fontManager_.unloadTextures(videoDriver_);
            clear(videoDriver_);
            videoDriver_ = null;
        }

        /**
         * Destroy the container.
         *
         * Destroys any video driver dependencies.
         * Video driver must be destroyed first by calling destroy().
         */
        ~this()
        in{assert(videoDriver_ is null, "VideoDriver must be destroyed before its container");}
        body{clear(fontManager_);}
}
