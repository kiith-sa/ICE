module video.glmonitor;


import std.string;

import video.videodriver;
import video.glvideodriver;
import video.gltexturepage;
import gui.guielement;
import gui.guimenu;
import gui.guistatictext;
import gui.guilinegraph;
import graphdata;
import monitor.monitor;
import monitor.graphmonitor;
import monitor.monitormenu;
import monitor.submonitor;
import math.vector2;
import math.rectangle;
import math.math;
import color;
import signal;


///Used to gather statistics data to be sent by GLVideoDriver to GL monitors.
package struct Statistics
{
    //Draw calls.
    uint lines, textures, texts;
    //Drawing primitives.
    uint vertices, characters;
    //State changes.
    uint shader, page;

    //Reset the statistics gathered for the next frame.
    void zero()
    {    
        lines = textures = texts = vertices = characters = shader = page = 0;
    }
}

///Displays info about texture pages.
final package class PagesMonitor : SubMonitor
{
    private:
        alias std.string.toString to_string;

        ///GUI element used to view a texture page.
        class PageView : GUIElement
        {
            invariant{assert(zoom_ != 0.0, "Texture page display zoom must be nonzero");}

            //Movement step in screen pixels, used when navigating the page.
            real step_ = 64.0;
            //Current offset of the view on the page, in texture pixels.
            Vector2f offset_ = Vector2f(0, 0);
            //Zoom multiplier used when zooming in/out.
            real zoom_mult_ = 1.2;
            //Current zoom.
            real zoom_ = 1.0;

            this()
            {
                super("p_left + 28", "p_top + 2", 
                      "p_width - 106", "p_height - 4");
            }

            override void draw(VideoDriver driver)
            {
                if(!visible_){return;}
                super.draw(driver);

                //no page to draw
                if(driver_.pages.length == 0){return;}
                //current page was deleted, change to another one
                while(driver_.pages[current_page_] == null){next();}

                //draw the page view
                //texture area to draw, rectanglef quad to map the texture area on
                Rectanglef area = Rectanglef(0, 0, (size.x) / zoom_, 
                                             (size.y) / zoom_) + offset_; 
                //quad to map the texture area on
                Rectanglef quad = Rectanglef(to!(float)(bounds_.min) + Vector2f(1, 1),
                                             to!(float)(bounds_.max) - Vector2f(1, 1));
                driver_.draw_page(current_page_, area, quad);
            }

            void reset_view()
            {
                zoom_ = 1.0;
                offset_ = Vector2f(0, 0);
            }

            void left(){offset_.x -= step_ / zoom_;}
            void right(){offset_.x += step_ / zoom_;}
            void up(){offset_.y -= step_ / zoom_;}
            void down(){offset_.y += step_ / zoom_;}

            void zoom_in(){zoom_ *= zoom_mult_;}
            void zoom_out(){zoom_ /= zoom_mult_;}
        }

        //GLVideoDriver we're monitoring.
        GLVideoDriver driver_;
        
        PageView view_;

        GUIMenuVertical menu_;
        
        //Information about the page.
        GUIStaticText info_text_;

        //Currently viewed page index (in GLVideoDriver.pages).
        uint current_page_ = 0;

    public:
        this(GLVideoDriver driver)
        {
            super();

            driver_ = driver;
            init_view();
            init_menu();
            init_text();
        }

    protected:
        override void update()
        {
            super.update();
            update_text();
        }

    private:
        void init_view()
        {
            view_ = new PageView;
            add_child(view_);
        }

        void init_menu()
        {
            with(new GUIMenuVerticalFactory)
            {
                x = "p_left";
                y = "p_top";
                item_width = "24";
                item_height = "14";
                item_spacing = "2";
                item_font_size = Monitor.font_size;
                add_item("Next", &next);
                add_item("Prev", &prev);
                add_item("Left", &view_.left);
                add_item("Right", &view_.right);
                add_item("Up", &view_.up);
                add_item("Down", &view_.down);
                add_item("+", &view_.zoom_in);
                add_item("-", &view_.zoom_out);
                menu_ = produce();
            }
            add_child(menu_);
        }

        void init_text()
        {
            with(new GUIStaticTextFactory)
            {
                x = "p_right - 74";
                y = "p_top + 2";
                width = "72";
                height = "p_height - 4";
                font_size = Monitor.font_size;
                align_x = AlignX.Right;
                info_text_ = produce();
            }
            add_child(info_text_);
            update_text();
        }

        void next()
        {
            if(current_page_ >= driver_.pages.length - 1){current_page_ = 0;}
            else{++current_page_;}
            if(driver_.pages.length == 0){return;}
            if(driver_.pages[current_page_] == null)
            {
                next();
                return;
            }
            update_text();
            view_.reset_view();
        }

        void prev()
        {
            if(current_page_ == 0){current_page_ = driver_.pages.length - 1;}
            else{--current_page_;}
            if(driver_.pages.length == 0){return;}
            if(driver_.pages[current_page_] is null)
            {
                prev();
                return;
            }
            update_text();
            view_.reset_view();
        }

        void update_text()
        {
            if(driver_.pages.length == 0)
            {
                info_text_.text = "No pages";
                return;
            }
            while(driver_.pages[current_page_] == null){next();}

            string text = "page index: " ~ to_string(current_page_) ~ "\n" ~
                          driver_.pages[current_page_].info;

            if(info_text_.text != text){info_text_.text = text;}
        }
}

///Displays info about draw calls
final package class DrawsMonitor : GraphMonitor
{
    public:
        ///Construct a DrawsMonitor, set value names and colors.
        this(GLVideoDriver monitored)
        {
            mixin(generate_graph_monitor_ctor("lines", "textures", "texts"));
        }

    private:
        //Callback called by GLVideoDriver once per frame to update monitored statistics.
        mixin(generate_graph_fetch_statistics("lines", "textures", "texts"));
}
  
///Displays info about graphics primitives drawn
final package class PrimitivesMonitor : GraphMonitor
{
     public:
        ///Construct a PrimitivesMonitor.
        this(GLVideoDriver monitored)
        {
            mixin(generate_graph_monitor_ctor("vertices", "characters"));
        }

    private:
        //Callback called by GLVideoDriver once per frame to update monitored statistics.
        mixin(generate_graph_fetch_statistics("vertices", "characters"));
}            
          
///Displays info about state changes during the frame
final package class ChangesMonitor : GraphMonitor
{ 
    public:
        ///Construct a ChangesMonitor.
        this(GLVideoDriver monitored)
        {
            mixin(generate_graph_monitor_ctor("shader", "page"));
        }

    private:
        //Callback called by GLVideoDriver once per frame to update monitored statistics.
        mixin(generate_graph_fetch_statistics("shader", "page"));
}         

///GLVideoDriverMonitor class - a MonitorMenu implementation is generated here.
mixin(generate_monitor_menu("GLVideoDriver", 
                            ["Pages", "Draws", "Primitives", "Changes"], 
                            ["PagesMonitor", "DrawsMonitor", "PrimitivesMonitor",
                             "ChangesMonitor"]));
