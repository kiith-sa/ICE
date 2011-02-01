module video.videodrivercontainer;


import video.videodriver;
import video.sdlglvideodriver;
import video.fontmanager;


///Class managing lifetime and dependencies of video driver..
class VideoDriverContainer
{
    private:
        //Video driver managed.
        VideoDriver video_driver_;

    public:
        ///Initialize video driver of specified type and return a reference to it.
        VideoDriver produce(T)()
        {
            static assert(is(T : VideoDriver));
            video_driver_ = new T;
            return video_driver_;
        }

        ///Destroy the video driver.
        void destroy()
        {
            video_driver_.die();
        }

        ///Destroy the container and any existing video driver dependencies.
        void die()
        {
        }
}
