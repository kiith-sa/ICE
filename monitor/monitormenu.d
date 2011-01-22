module monitor.monitormenu;


import monitor.monitor;
import gui.guielement;
import gui.guimenu;
import signal;


///Base class for monitor menus.
abstract class MonitorMenu : GUIMenu
{
    public:
        //Construct a MonitorMenu.
        this()
        {
            add_item("Back", &back_to_parent);
            position_x = "p_left";
            position_y = "p_top";
            orientation = MenuOrientation.Horizontal;
            item_font_size = Monitor.font_size;
            item_width = "44";
            item_height = "14";
            item_spacing = "4";

            super();
        }

        ///Signal used to return back to parent menu.
        mixin Signal!() back;
        ///Signal used to set monitor selected by this menu.
        mixin Signal!(GUIElement) set_monitor;

    private:
        ///Return back to parent menu.
        void back_to_parent(){back.emit();}
}

/**
 * Generate a MonitorMenu implementation class providing access to specified monitors.
 *
 * Used as a string mixin.
 * Result will be a class like the following:
 *
 * final package class ExampleMonitor : MonitoMenu
 * {
 *     private:
 *         //monitored object
 *         MonitoredClass monitored_;
 *     public:
 *         this()
 *         {
 *             //usual ctor stuff
 *             //add menu buttons for each monitor
 *         }
 *     private:    
 *         //callback methods used by the menu buttons to send monitors to set_monitor signal.
 * }
 *
 * Params:  name            = Name of the monitored class. 
 *                            Generated class will be named name~Monitor.
 *          monitor_names   = Button texts of menu items corresponding to respective monitors.
 *          monitor_classes = Names of monitor classes accessed through the menu.
 */
string generate_monitor_menu(string name, string[] monitor_names, 
                             string[] monitor_classes)
in
{
    assert(monitor_names.length == monitor_classes.length, 
           "Monitor name and class counts don't match");
}
body
{
    string result = "final package class " ~ name ~ "Monitor : MonitorMenu"
                    "{"
                        "private " ~ name ~ " monitored_;"
                        "public this(" ~ name ~ " monitored)"
                        "{"
                            "super();"
                            "monitored_ = monitored;";
    
    foreach(monitor; monitor_names)
    {
        result ~= "add_item(\"" ~ monitor ~ "\",&" ~ monitor ~ ");";
    }

    result ~= "}private:";

    for(uint monitor; monitor < monitor_names.length; monitor++)
    {
        result ~= "void " ~ monitor_names[monitor] ~ "()"
                  "{set_monitor.emit(new " ~ monitor_classes[monitor] ~ "(monitored_));}"; 
    }

    result ~= "}";

    return result;
}
