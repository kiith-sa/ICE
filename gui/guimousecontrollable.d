module gui.guimousecontrollable;


import gui.guielement;
import platform.platform;
import math.vector2;
import util.signal;


/**
 * Provides logic for recognizing mouse input used for zooming and panning,
 * using callbacks for actual implementations of zooming/panning.
 *
 * This is not a class to derive other GUI elements from.
 * Rather, this should be used as a child of GUI elements that need mouse 
 * zooming/panning logic.
 */
final class GUIMouseControllable : GUIElement
{
    private:
        //Mouse key used for panning (we're panning when dragging this key)
        MouseKey pan_key_;
        //Is the key ussed for panning pressed?
        bool pan_key_pressed_;
        //Mouse key used to return to default view.
        MouseKey default_view_key_;

    public:
        /**
         * Emitted when zooming. Float passed specifies zoom level change
         * (-1 : zoom out 1 level, +1 : zoom in 1 level)
         */
        mixin Signal!(float) zoom;

        ///Emitted when panning. Vector2f passed specifies relative change of panning.
        mixin Signal!(Vector2f) pan;

        ///Emitted user presses a button to return to default view.
        mixin Signal!() default_view;

        this(MouseKey pan_key = MouseKey.Left, 
             MouseKey default_view_key = MouseKey.Right)
        {
            super(GUIElementParams("p_left", "p_top", "p_width", "p_height", false));
            pan_key_ = pan_key;
            default_view_key_ = default_view_key;
        }

    protected:
        override void mouse_key(KeyState state, MouseKey key, Vector2u position)
        {
            if(!visible_){return;}
            super.mouse_key(state, key, position);

            switch(key)
            {
                //mouse wheel handles zooming
                case MouseKey.WheelUp:
                    zoom.emit(1.0f);
                    break;
                case MouseKey.WheelDown:
                    zoom.emit(-1.0f);
                    break;
                default:
                    break;
            }
            if(key == pan_key_)
            {
                //can be either pressed or released
                pan_key_pressed_ = state == KeyState.Pressed ? true : false;
            }
            if(key == default_view_key_ && state == KeyState.Pressed){default_view.emit();}
        }

        override void mouse_move(Vector2u position, Vector2i relative)
        {
            if(!visible_){return;}
            super.mouse_move(position, relative);

            //ignore if mouse is outside of bounds
            if(!bounds_global.intersect(Vector2i(position.x, position.y)))
            {
                pan_key_pressed_ = false;
                return;
            }

            //panning 
            if(pan_key_pressed_){pan.emit(to!(float)(relative));}
        }
}
