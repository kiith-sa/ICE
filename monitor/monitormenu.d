module monitor.monitormenu;


import monitor.monitor;
import monitor.submonitor;
import gui.guielement;
import gui.guimenu;
import signal;


///Base class for monitor menus.
abstract class MonitorMenu
{
    private:
        ///GUI element displaying the menu.
        GUIMenu menu_;

    public:
        ///Signal used to return back to parent menu.
        mixin Signal!() back;
        ///Signal used to set monitor selected by this menu.
        mixin Signal!(SubMonitor) set_monitor;

        ///Get the menu GUI element.
        GUIMenu menu(){return menu_;}

        ///Destroy this MonitorMenu
        void die(){menu.die();}

    protected:
        /*
         * Construct a MonitorMenu.
         * 
         * Params:  factory = Factory used to build the menu.
         *                    Overriding class must add menu items to the factory.
         */
        this(GUIMenuFactory factory)
        {
            with(factory)
            {
                orientation = MenuOrientation.Horizontal;
                item_width = "44";
                item_height = "14";
                item_spacing = "4";
                item_font_size = Monitor.font_size;
                menu_ = produce();
            }
        }

        //Return back to parent menu.
        void back_to_parent(){back.emit();}
}

/**
 * Generate a MonitorMenu implementation class providing access to specified monitors.
 *
 * Note: To use this as a mixin, you have to import gui.guimenu .
 *
 * Used as a string mixin.
 * Output is a class like the following:
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
 *
 * Returns: Generated menu monitor implementation class.
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
    string header = "final package class " ~ name ~ "Monitor : MonitorMenu\n"
                    "{\n";
    string monitored = "    private " ~ name ~ " monitored_;\n" ;

    string ctor_start = "    public this(" ~ name ~ " monitored)\n"
                        "    {\n"
                        "        auto factory = new GUIMenuFactory;\n";
    string ctor_items = "        factory.add_item(\"Back\", &back_to_parent);\n";
    foreach(monitor; monitor_names)
    {
        ctor_items ~= "        factory.add_item(\"" ~ monitor ~ "\", &" ~ monitor ~ ");\n";
    }
    string ctor_end = "        super(factory);\n"
                      "        monitored_ = monitored;\n"
                      "    }\n";
    string setters = "    private:\n";
    for(uint monitor; monitor < monitor_names.length; monitor++)
    {
        setters ~= "        void " ~ monitor_names[monitor] ~ "()"
                  "{set_monitor.emit(new " ~ monitor_classes[monitor] ~ "(monitored_));}\n"; 
    }
    string footer = "}\n";

    return header ~ monitored ~ ctor_start ~ ctor_items ~ ctor_end ~ setters ~ footer; 
}
