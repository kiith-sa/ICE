module gui.guiroot;


import gui.guielement;
import video.videodriver;
import math.vector2;
import platform.platform;
import singleton;


///GUI root element singleton. Contains drawing and input handling methods.
final class GUIRoot : GUIElement, Singleton
{
    invariant
    {
        assert(Parent is null, "GUI root element must not have a parent");
    }

    mixin SingletonMixin;
    public:
        ///Draw the GUI.
        void draw()
        {
            if(!Visible){return;}

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

        ///Pass keyboard input to the GUI.
        void key(KeyState state, Key key, dchar unicode)
        {
            super.key(state, key, unicode);
        }

        ///Pass mouse key press input to the GUI.
        void mouse_key(KeyState state, MouseKey key, Vector2u position)
        {
            super.mouse_key(state, key, position);
        }

        ///Pass mouse move input to the GUI.
        void mouse_move(Vector2u position, Vector2i relative)
        {
            super.mouse_move(position, relative);
        }

    private:
        this()
        {
            auto driver = VideoDriver.get;
            //GUI size is equal to screen size
            Vector2u max = Vector2u(driver.screen_width, driver.screen_height);
            super(null, Vector2i(0,0), max);
        }
}
