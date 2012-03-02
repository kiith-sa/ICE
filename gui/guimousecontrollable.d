
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Mouse zooming/panning support for GUI elements.
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
 *     public mixin Signal!() resetView
 *
 *     Emitted user presses a button to return to default view.
 */
final class GUIMouseControllable : GUIElement
{
    private:
        ///Mouse key used for panning (we're panning when dragging this key).
        immutable MouseKey panKey_;
        ///Is the panning key pressed?
        bool panKeyPressed_;
        ///Mouse key used to return to default view.
        immutable MouseKey resetViewKey_;

    public:
        /**
         * Emitted when zooming. Float passed specifies zoom level change
         * (-1 : zoom out 1 level, +1 : zoom in 1 level)
         */
        mixin Signal!float zoom;

        ///Emitted when panning. Vector2f passed specifies relative change of panning.
        mixin Signal!Vector2f pan;

        ///Emitted user presses a button to return to default view.
        mixin Signal!() resetView;

        /**
         * Construct a GUIMouseControllable.
         *
         * Params:  panKey        = Mouse key to use for panning when dragged.
         *          resetViewKey = Mouse key to reset view when clicked.
         */
        this(in MouseKey panKey = MouseKey.Left, 
             in MouseKey resetViewKey = MouseKey.Right)
        {
            super(GUIElementParams("p_left", "p_top", "p_width", "p_height", false));
            panKey_ = panKey;
            resetViewKey_ = resetViewKey;
        }

        ~this()
        {
            zoom.disconnectAll();
            pan.disconnectAll();
            resetView.disconnectAll();
        }

    protected:
        override void mouseKey(KeyState state, MouseKey key, Vector2u position)
        {
            if(!visible_){return;}
            super.mouseKey(state, key, position);

            switch(key)
            {
                //mouse wheel handles zooming
                case MouseKey.WheelUp:   zoom.emit(1.0f);  break;
                case MouseKey.WheelDown: zoom.emit(-1.0f); break;
                default: break;
            }
            if(key == panKey_)
            {
                //can be either pressed or released
                panKeyPressed_ = state == KeyState.Pressed;
            }
            if(key == resetViewKey_ && state == KeyState.Pressed){resetView.emit();}
        }

        override void mouseMove(Vector2u position, Vector2i relative)
        {
            if(!visible_){return;}
            super.mouseMove(position, relative);

            //ignore if mouse is outside of bounds
            if(!boundsGlobal.intersect(Vector2i(position.x, position.y)))
            {
                panKeyPressed_ = false;
                return;
            }

            //panning 
            if(panKeyPressed_){pan.emit(relative.to!float);}
        }
}

///Basic GUIMouseControllable based mouse control code, good default for simple mouse control.
template MouseControl(real zoomMultiplier)
{
    static assert(zoomMultiplier > 1.0, "Mouse control zoom multiplier must be greater than 1");

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
            auto mouseControl = new GUIMouseControllable;
            mouseControl.zoom.connect(&zoom);
            mouseControl.pan.connect(&pan);
            mouseControl.resetView.connect(&resetView);
            addChild(mouseControl);
        }

        /**
         * Zoom by specified number of levels.
         *
         * Params:  relative = Number of zoom levels (doesn't have to be an integer).
         */
        void zoom(float relative){zoom_ = zoom_ * pow(zoomMultiplier, relative);}

        /**
         * Pan view with specified offset.
         *
         * Params:  relative = Offset to pan the view by.
         */
        void pan(Vector2f relative){offset_ += relative;}

        ///Restore default view.
        void resetView()
        {
            zoom_ = 1.0;
            offset_ = Vector2f(0.0f, 0.0f);
        }
}
