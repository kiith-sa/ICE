module physics.physicsmonitor;

import physics.physicsengine;
import monitor.graphmonitor;
import gui.guielement;
import gui.guimenu;
import gui.guigraph;
import color;


///Graph showing values related to fine collision detection.
final package class ContactMonitor : GraphMonitor
{
    public:
        ///Construct a ContactMonitor, set value names and colors.
        this()
        {
            super("contacts", "penetration", "response");

            PhysicsEngine.get.send_statistics.connect(&fetch_statistics);
            color("contacts", Color(255, 255, 0, 255));
            color("penetration", Color(255, 0, 0, 255));
            color("response", Color(255, 128, 0, 255));
            add_mode_buttons();
        }

    private:
        ///Callback called by PhysicsMonitor once per frame to update monitored statistics.
        void fetch_statistics(PhysicsEngine.Statistics statistics)
        {
            with(statistics)
            {             
                add_value("contacts", contacts);
                add_value("penetration", penetration_iterations);
                add_value("response", response_iterations);
            }
        }
}

///Graph showing values related to coarse collision detection.
final package class CoarseContactMonitor : GraphMonitor
{
    public:
        ///Construct a CoarseContactMonitor, set value names and colors.
        this()
        {
            super("tests");

            PhysicsEngine.get.send_statistics.connect(&fetch_statistics);
            color("tests", Color(255, 0, 0, 255));
            mode(GraphMode.Average);
            add_mode_buttons();
        }

    private:
        ///Callback called by PhysicsMonitor once per frame to update monitored statistics.
        void fetch_statistics(PhysicsEngine.Statistics statistics)
        {
            add_value("tests", statistics.tests);
        }
}

///Graph showing statistics about physics bodies.
final package class BodiesMonitor : GraphMonitor
{
    public:
        ///Construct a BodiesMonitor, set value names and colors.
        this()
        {
            super("bodies", "col_bodies");

            PhysicsEngine.get.send_statistics.connect(&fetch_statistics);
            color("bodies", Color(255, 255, 0, 255));
            color("col_bodies", Color(255, 0, 0, 255));
            mode(GraphMode.Average);
        }

    private:
        ///Callback called by PhysicsMonitor once per frame to update monitored statistics.
        void fetch_statistics(PhysicsEngine.Statistics statistics)
        {
            add_value("bodies", statistics.bodies);
            add_value("col_bodies", statistics.collision_bodies);
        }
}

final package class PhysicsMonitor : GUIElement
{
    private:
        GUIMenu menu_;
        GUIElement current_monitor_ = null;

    public:
        this()
        {
            super();

            menu_ = new GUIMenu;
            with(menu_)
            {
                position_x = "p_left";
                position_y = "p_top";

                add_item("Bodies", &bodies);
                add_item("Contact", &contact);
                add_item("Coarse", &coarse);

                item_font_size = PhysicsMonitor.font_size;
                item_width = "40";
                item_height = "12";
                item_spacing = "4";
            }
            add_child(menu_);
        }

        //Display bodies monitor.
        void bodies(){monitor(new BodiesMonitor);}

        //Display fine collision monitor.
        void contact(){monitor(new ContactMonitor);}

        //Display coarse collision monitor.
        void coarse(){monitor(new CoarseContactMonitor);}

        //Display specified submonitor.
        void monitor(GUIElement monitor)
        {
            if(current_monitor_ !is null)
            {
                remove_child(current_monitor_);
                current_monitor_.die();
            }

            current_monitor_ = monitor;
            with(current_monitor_)
            {
                position_x = "p_left + 48";
                position_y = "p_top + 4";
                width = "p_right - p_left - 52";
                height = "p_bottom - p_top - 8";
            }
            add_child(current_monitor_);
        }

        static uint font_size(){return 8;}
}
