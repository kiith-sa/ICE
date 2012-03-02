
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Base class for submonitors provided by monitorables.
module monitor.submonitor;

import monitor.monitormanager;
import gui.guielement;
import gui.guimenu;
import gui.guistatictext;
import util.signal;


///Base class for monitors belonging to engine subsystems.
abstract class SubMonitor
{
    public:
        ///Construct a SubMonitor.
        this(){}

        ///Destroy the SubMonitor.
        ~this(){};

        ///Get a GUI view viewing this monitor.
        @property SubMonitorView view();
}

/**
 * Base class for SubMonitor GUI views.
 *
 * Signal:
 *     public mixin Signal!() togglePinned;
 *
 *     Emitted when the submonitor viewed should be pinned/unpinned.
 */
abstract class SubMonitorView : GUIElement
{
    private:
        ///Text showing whether or not the submonitor is pinned.
        GUIStaticText pinnedText_;

    protected:
        ///Main area of the view.
        GUIElement main_;

    public:
        ///Emitted when the submonitor viewed should be pinned/unpinned.
        mixin Signal!() togglePinned;

        ///Construct a SubMonitorView.
        this()
        {
            //SubMonitorViews are placed in their parent MonitorView.
            super(GUIElementParams("p_left", "p_top", "p_width", "p_height", false));

            with(new GUIElementFactory)
            {
                margin(22, 4, 22, 4);
                main_ = produce();
            }
            addChild(main_);

            //construct the submonitor menu (common to all submonitors).
            with(new GUIMenuHorizontalFactory)
            {
                x              = "p_left";
                y              = "p_bottom - 22";
                itemWidth     = "64";
                itemHeight    = "14";
                itemSpacing   = "4";
                itemFontSize = MonitorView.fontSize;

                addItem("Toggle Pinned", &togglePinned_);
                addChild(produce());
            }
        }

        ///Update pinned text display.
        void setPinned(const bool pinned)
        {
            if(pinnedText_ !is null)
            {
                pinnedText_.die();
                pinnedText_ = null;
            }
            if(pinned)
            {
                with(new GUIStaticTextFactory)
                {
                    x            = "p_right - 32";
                    y            = "p_bottom - 16";
                    width        = "48";
                    height       = "16";
                    fontSize    = MonitorView.fontSize;
                    text         = "Pinned";
                    pinnedText_ = produce();
                }
                addChild(pinnedText_);
            }
        }

    private
        ///Pin/unpin the submonitor viewed.
        void togglePinned_()
        {
            setPinned(pinnedText_ is null);
            togglePinned.emit();
        }
}
