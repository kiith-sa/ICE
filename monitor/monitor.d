module monitor.monitor;


import video.videodriver;
import gui.guielement;
import gui.guimenu;
import math.vector2;
import math.math;


///Displays various debugging/profiling information about engine subsystems.
final class Monitor : GUIElement
{
    private:
        GUIMenu menu_;
        GUIElement current_monitor_ = null;

    public:
        ///Construct a new monitor with specified parameters.
        this()
        {
            super();

            menu_ = new GUIMenu;
            with(menu_)
            {
                position_x = "p_left";
                position_y = "p_top";
                orientation = MenuOrientation.Horizontal;

                add_item("Video", &video);

                item_font_size = 8;
                item_width = "48";
                item_height = "14";
                item_spacing = "4";
            }
            add_child(menu_);
        }

    private:
        //Display videodriver monitor.
        void video(){monitor(VideoDriver.get.monitor);}

        //Display specified monitor.
        void monitor(GUIElement monitor)
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
