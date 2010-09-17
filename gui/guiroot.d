module gui.guiroot;


import gui.guielement;
import video.videodriver;
import math.vector2;
import platform.platform;
import monitor.monitor;
import singleton;


///GUI root element singleton. Contains drawing and input handling methods.
final class GUIRoot : GUIElement
{
    invariant
    {
        assert(parent_ is null, "GUI root element must not have a parent");
    }

    mixin Singleton;

    public:
        //Construct the GUI root with size equal to screen size.
        this()
        {
            singleton_ctor();
            super();

            position_x = "0";
            position_y = "0";
            width = "w_right";
            height = "w_bottom";

            Platform.get.mouse_motion.connect(&mouse_move);
            Platform.get.mouse_key.connect(&mouse_key);
            Platform.get.key.connect(&key);
        }

        ///Draw the GUI.
        final void draw()
        {
            if(!visible_){return;}

            if(!aligned_){realign();}

            auto driver = VideoDriver.get;

            //save view zoom and offset
            real zoom = driver.zoom;
            auto offset = driver.view_offset; 

            //set 1:1 zoom and zero offset for GUI drawing
            driver.zoom = 1.0;
            driver.view_offset = Vector2d(0.0, 0.0);

            //draw the elements
            draw_children();

            //restore zoom and offset
            driver.zoom = zoom;
            driver.view_offset = offset;
        }

        final void update(){update_children();}

        ///Pass keyboard input to the GUI.
        void key(KeyState state, Key key, dchar unicode)
        {
            if(!visible_){return;}

            ///Global hardcoded keys when GUI is used.
            if(state == KeyState.Pressed)
            {
                switch(key)
                {
                    case Key.F10:
                        monitor_toggle();
                        break;
                    default:
                        break;
                }
            }
            super.key(state, key, unicode);
        }

        ///Pass mouse key press input to the GUI.
        void mouse_key(KeyState state, MouseKey key, Vector2u position)
        {
            if(!visible_){return;}
            super.mouse_key(state, key, position);
        }

        ///Pass mouse move input to the GUI.
        void mouse_move(Vector2u position, Vector2i relative)
        {
            if(!visible_){return;}
            super.mouse_move(position, relative);
        }

    private:
        void monitor_toggle()
        {
            static Monitor monitor = null;
            if(monitor is null)
            {
                monitor = new Monitor;
                with(monitor)
                {
                    position_x = "16";
                    position_y = "16";
                    width = "192 + w_right / 4";
                    height = "168 + w_bottom / 6";
                }
                add_child(monitor);
            }
            else
            {
                remove_child(monitor);
                monitor.die();
                monitor = null;
            }
        }
}
