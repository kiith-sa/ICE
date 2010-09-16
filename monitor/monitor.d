module monitor.monitor;


import video.videodriver;
import gui.guielement;
import gui.guibutton;
import math.vector2;
import math.math;


///Displays various debugging/profiling information about engine subsystems.
class Monitor : GUIElement
{
    private:
        GUIButton video_button_;
        GUIElement current_monitor_ = null;

    public:
        ///Construct a new monitor with specified parameters.
        this()
        {
            super();

            uint buttons = 0;

            void add_button(ref GUIButton button, string button_text, 
                            void delegate() deleg)
            {
                button = new GUIButton;
                with(button)
                {
                    position_x = "p_left + 4 + " ~ to_string(56 * buttons);
                    position_y = "p_top + 4";
                    width = "48";
                    height = "14";
                    text = button_text;
                    font_size = 8;
                }
                button.pressed.connect(deleg);
                add_child(button);
                ++buttons;
            }

            add_button(video_button_, "Video", &video);
        }

    private:
        //display videodriver monitor.
        void video(){submonitor(VideoDriver.get.monitor);}

        void submonitor(GUIElement monitor)
        {
            if(current_monitor_ !is null)
            {
                remove_child(current_monitor_);
                current_monitor_.die();
            }

            current_monitor_ = monitor;
            with(current_monitor_)
            {
                position_x = "p_left + 4";
                position_y = "p_top + 22";
                width = "p_right - p_left - 8";
                height = "p_bottom - p_top - 26";
            }
            add_child(current_monitor_);
        }
}
