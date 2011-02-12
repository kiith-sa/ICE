
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module monitor.monitormenu;


import monitor.monitor;
import monitor.submonitor;
import gui.guielement;
import gui.guimenu;
import util.signal;
import stringctfe;


///Base class for monitor menus.
abstract class MonitorMenu
{
    private:
        ///GUI element displaying the menu.
        GUIMenuHorizontal menu_;

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
        this(GUIMenuHorizontalFactory factory)
        {
            with(factory)
            {
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
 * If the monitored class is templated, syntax "Monitored$T$U"
 * can be used to support templates. In that case, both the monitor menu
 * and monitors accessed will be templated with specified template types.
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
    string[] types = name.split('$');
    string monitored_type = types[0];

    //if the monitored class is templated, its template types will be here
    //in "!(T,U)" format. Otherwise, this will be empty.
    string templates;
    if(types.length > 1)
    {
        templates = "!(" ~ types[1];
        foreach(template_type; types[2 .. $]){templates ~= ", " ~ template_type;}
        templates ~= ")";
    }

    //monitored type with templates, if any
    string monitored_full = monitored_type ~ templates;

    string header = "final package class " ~ monitored_type ~ "Monitor" ~ 
                    (templates == "" ? "" : templates[1 .. $]) ~ " : MonitorMenu\n"
                    
                    "{\n";
    string monitored = "    private " ~ monitored_full ~ " monitored_;\n" ;

    string ctor_start = "    public this(" ~ monitored_full ~ " monitored)\n"
                        "    {\n"
                        "        auto factory = new GUIMenuHorizontalFactory;\n";
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
                  "{set_monitor.emit(new " ~ monitor_classes[monitor] ~ templates ~ "(monitored_));}\n"; 
    }
    string footer = "}\n";

    return header ~ monitored ~ ctor_start ~ ctor_items ~ ctor_end ~ setters ~ footer; 
}
unittest
{
    string expected =
        "final package class MonitoredMonitor : MonitorMenu\n"
        "{\n"
        "    private Monitored monitored_;\n" 
        "    public this(Monitored monitored)\n"
        "    {\n"
        "        auto factory = new GUIMenuHorizontalFactory;\n"
        "        factory.add_item(\"Back\", &back_to_parent);\n"
        "        factory.add_item(\"A\", &A);\n"
        "        factory.add_item(\"B\", &B);\n"
        "        super(factory);\n"
        "        monitored_ = monitored;\n"
        "    }\n"
        "    private:\n"
        "        void A(){set_monitor.emit(new AMonitor(monitored_));}\n"
        "        void B(){set_monitor.emit(new BMonitor(monitored_));}\n"
        "}\n";
    assert(expected == generate_monitor_menu("Monitored",
                                             ["A", "B"],
                                             ["AMonitor", "BMonitor"]),
           "Unexpected monitor menu code generated");
}
