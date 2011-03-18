
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module video.glmonitor;


import std.string;
import std.math;

import video.videodriver;
import video.glvideodriver;
import video.gltexturepage;
import gui.guielement;
import gui.guimenu;
import gui.guistatictext;
import gui.guilinegraph;
import gui.guimousecontrollable;
import graphdata;
import monitor.monitor;
import monitor.graphmonitor;
import monitor.monitormenu;
import monitor.submonitor;
import math.vector2;
import math.rectangle;
import math.math;
import color;


///Statistics data sent by GLVideoDriver to GL monitors.
package struct Statistics
{
    ///Draw calls.
    uint lines, textures, texts, rectangles;
    ///Drawing primitives.
    uint vertices, indices, characters;
    ///State changes.
    uint shader, page;

    ///Reset the statistics gathered for the next frame.
    void zero()
    {    
        lines = textures = texts = rectangles 
              = vertices = indices = characters = shader = page = 0;
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
            invariant
            {
                assert(zoom_mult_ >= 1.0, "Page view zoom multiplier must be greater than 1");
                assert(zoom_ >= 0.0, "Page view display zoom must be greater than zero");
            }

            private:
                ///Current offset of the view on the page, in texture pixels.
                Vector2f offset_ = Vector2f(0, 0);
                ///Zoom multiplier used when zooming in/out.
                real zoom_mult_ = 1.2;
                ///Current zoom.
                real zoom_ = 1.0;

            public:
                ///Construct a PageView.
                this()
                {
                    super(GUIElementParams("p_left + 28", "p_top + 2", 
                                           "p_width - 106", "p_height - 4", 
                                           true));

                    //provides zooming/panning functionality
                    auto mouse_control = new GUIMouseControllable;
                    mouse_control.zoom.connect(&zoom);
                    mouse_control.pan.connect(&pan);
                    mouse_control.reset_view.connect(&reset_view);

                    add_child(mouse_control);
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
                    //texture area to draw
                    Rectanglef area = Rectanglef(0, 0, size.x / zoom_, 
                                                 size.y / zoom_) - offset_; 
                    //quad to map the texture area on
                    Rectanglef quad = Rectanglef(to!(float)(bounds_.min) + Vector2f(1, 1),
                                                 to!(float)(bounds_.max) - Vector2f(1, 1));
                    driver_.draw_page(current_page_, area, quad);
                }

            private:
                ///Zoom by specified number of levels.
                void zoom(float relative){zoom_ = zoom_ * pow(zoom_mult_, relative);}

                ///Pan view with specified offset.
                void pan(Vector2f relative){offset_ += relative / zoom_;}

                ///Reset view back to default.
                void reset_view()
                {
                    zoom_ = 1.0;
                    offset_ = Vector2f(0.0f, 0.0f);
                }
        }

        ///GLVideoDriver we're monitoring.
        GLVideoDriver driver_;
        
        ///Page view widget.
        PageView view_;
        ///Information about the page.
        GUIStaticText info_text_;

        ///Currently viewed page index (in GLVideoDriver.pages_).
        uint current_page_ = 0;

    public:
        ///Construct a GLMonitor monitoring specified GLVideoDriver.
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
        ///Initialize page view.
        void init_view()
        {
            view_ = new PageView;
            add_child(view_);
        }

        ///Initialize menu.
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
                add_child(produce());
            }
        }

        ///Initialize info text.
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

        ///Show next page.
        void next()
        {
            //Cycle back to first if we're at the last.
            if(current_page_ >= cast(uint)driver_.pages.length - 1){current_page_ = 0;}
            else{++current_page_;}

            if(driver_.pages.length == 0){return;}
            //If the page was destroyed, move to next one.
            if(driver_.pages[current_page_] == null)
            {
                next();
                return;
            }
            update_text();
            view_.reset_view();
        }

        ///Show previous page.
        void prev()
        {
            //Cycle back to last if we're at the first.
            if(current_page_ == 0){current_page_ = cast(uint)driver_.pages.length - 1;}
            else{--current_page_;}
            if(driver_.pages.length == 0){return;}
            //If the page was destroyed, move to previous one.
            if(driver_.pages[current_page_] is null)
            {
                prev();
                return;
            }
            update_text();
            view_.reset_view();
        }

        ///Update text with information about the page.
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

///Graph showing numbers of draw calls.
alias SimpleGraphMonitor!(GLVideoDriver, Statistics, 
                          "lines", "textures", "texts", "rectangles") DrawsMonitor;
  
///Graph showing numbers of graphics primitives drawn.
alias SimpleGraphMonitor!(GLVideoDriver, Statistics, 
                          "vertices", "indices", "characters") PrimitivesMonitor;

///Graph showing numbers of state changes during the frame 
alias SimpleGraphMonitor!(GLVideoDriver, Statistics, "shader", "page") ChangesMonitor;

///GLVideoDriverMonitor class - a MonitorMenu implementation is generated here.
mixin(generate_monitor_menu("GLVideoDriver", 
                            ["Pages", "Draws", "Primitives", "Changes"], 
                            ["PagesMonitor", "DrawsMonitor", "PrimitivesMonitor",
                             "ChangesMonitor"]));
