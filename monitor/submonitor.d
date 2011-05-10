
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Base class for submonitors provided by monitorables.
module monitor.submonitor;
@safe


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
        void die(){};

        ///Get a GUI view viewing this monitor.
        @property SubMonitorView view();
}

/**
 * Base class for SubMonitor GUI views.
 *
 * Signal:
 *     public mixin Signal!() toggle_pinned;
 *
 *     Emitted when the submonitor viewed should be pinned/unpinned.
 */
abstract class SubMonitorView : GUIElement
{
    private:
        ///Text showing whether or not the submonitor is pinned.
        GUIStaticText pinned_text_;

    protected:
        ///Main area of the view.
        GUIElement main_;

    public:
        ///Emitted when the submonitor viewed should be pinned/unpinned.
        mixin Signal!() toggle_pinned;

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
            add_child(main_);

            //construct the submonitor menu (common to all submonitors).
            with(new GUIMenuHorizontalFactory)
            {
                x = "p_left";
                y = "p_bottom - 22";
                item_width = "64";
                item_height = "14";
                item_spacing = "4";
                item_font_size = MonitorView.font_size;

                add_item("Toggle Pinned", &toggle_pinned_);
                add_child(produce());
            }
        }

        ///Update pinned text display.
        void set_pinned(in bool pinned)
        {
            if(pinned_text_ !is null)
            {
                pinned_text_.die();
                pinned_text_ = null;
            }
            if(pinned)
            {
                with(new GUIStaticTextFactory)
                {
                    x = "p_right - 32";
                    y = "p_bottom - 16";
                    width = "48";
                    height = "16";
                    font_size = MonitorView.font_size;
                    text = "Pinned";
                    pinned_text_ = produce();
                }
                add_child(pinned_text_);
            }
        }

    private
        ///Pin/unpin the submonitor viewed.
        void toggle_pinned_()
        {
            set_pinned(pinned_text_ is null);
            toggle_pinned.emit();
        }
}
