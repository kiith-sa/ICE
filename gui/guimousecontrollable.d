
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module gui.guimousecontrollable;


import gui.guielement;
import platform.platform;
import math.vector2;
import util.signal;


/**
 * Provides logic for recognizing mouse input used for zooming and panning,
 * using signals for actual implementations of zooming/panning, so
 * user only needs to implement what is needed.
 *
 * Mouse wheel is used for zooming, movement with a mouse key pressed (dragging) for panning.
 * Also supports a mouse key used to return to default view when clicked.
 *
 * This is not a class to derive other GUI elements from. Rather, this should be used 
 * as a child of GUI elements that need mouse  zooming/panning logic.
 *
 * Also, the name is ugly. Need a better one.
 *
 * Signal:
 *     public mixin Signal!(float) zoom
 *
 *     Emitted when zooming. Float passed specifies zoom level change
 *     (-1 : zoom out 1 level, +1 : zoom in 1 level)
 *
 * Signal:
 *     public mixin Signal!(Vector2f) pan
 *
 *     Emitted when panning. Vector2f passed specifies relative change of panning.
 *
 * Signal:
 *     public mixin Signal!() reset_view
 *
 *     Emitted user presses a button to return to default view.
 */
final class GUIMouseControllable : GUIElement
{
    private:
        ///Mouse key used for panning (we're panning when dragging this key).
        immutable MouseKey pan_key_;
        ///Is the panning key pressed?
        bool pan_key_pressed_;
        ///Mouse key used to return to default view.
        immutable MouseKey reset_view_key_;

    public:
        /**
         * Emitted when zooming. Float passed specifies zoom level change
         * (-1 : zoom out 1 level, +1 : zoom in 1 level)
         */
        mixin Signal!(float) zoom;

        ///Emitted when panning. Vector2f passed specifies relative change of panning.
        mixin Signal!(Vector2f) pan;

        ///Emitted user presses a button to return to default view.
        mixin Signal!() reset_view;

        /**
         * Construct a GUIMouseControllable.
         *
         * Params:  pan_key        = Mouse key to use for panning when dragged.
         *          reset_view_key = Mouse key to reset view when clicked.
         */
        this(in MouseKey pan_key = MouseKey.Left, 
             in MouseKey reset_view_key = MouseKey.Right)
        {
            super(GUIElementParams("p_left", "p_top", "p_width", "p_height", false));
            pan_key_ = pan_key;
            reset_view_key_ = reset_view_key;
        }

        override void die()
        {
            zoom.disconnect_all();
            pan.disconnect_all();
            reset_view.disconnect_all();

            super.die();
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
            if(key == reset_view_key_ && state == KeyState.Pressed){reset_view.emit();}
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

///Basic GUIMouseControllable based mouse control code, good default for simple mouse control.
template MouseControl(real zoom_multiplier)
{
    static assert(zoom_multiplier > 1.0, "Mouse control zoom multiplier must be greater than 1");

    invariant(){assert(zoom_ >= 0.0, "MouseControl zoom must be greater than 0");}

    private:
        ///Current view offset.
        Vector2f offset_;
        ///Current zoom. 
        real zoom_ = 1.0;

    public:
        ///Initialize mouse control.
        void init()
        {
            //provides zooming/panning functionality
            auto mouse_control = new GUIMouseControllable;
            mouse_control.zoom.connect(&zoom);
            mouse_control.pan.connect(&pan);
            mouse_control.reset_view.connect(&reset_view);
            add_child(mouse_control);
        }

        /**
         * Zoom by specified number of levels.
         *
         * Params:  relative = Number of zoom levels (doesn't have to be an integer).
         */
        void zoom(float relative){zoom_ = zoom_ * pow(zoom_multiplier, relative);}

        /**
         * Pan view with specified offset.
         *
         * Params:  relative = Offset to pan the view by.
         */
        void pan(Vector2f relative){offset_ += relative;}

        ///Restore default view.
        void reset_view()
        {
            zoom_ = 1.0;
            offset_ = Vector2f(0.0f, 0.0f);
        }
}
