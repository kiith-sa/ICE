
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
import gui.guimousecontrollable;
import monitor.monitor;
import monitor.submonitor;
import math.vector2;
import math.rectangle;
import math.math;
import util.signal;
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
    ///FPS this frame (inverse of frame length).
    real fps = 0.0;

    ///Reset the statistics gathered for the next frame.
    void zero()
    {    
        lines = textures = texts = rectangles 
              = vertices = indices = characters = shader = page;
        fps = 0.0;
    }
}

///Provides access to information about texture pages in GLVideoDriver.
final package class PageMonitor : SubMonitor
{
    public:
        ///Allows iteration over and access to texture pages in GLVideoDriver.
        final class PageIterator
        {
            private:
                ///Current page index.
                uint current_page_;

            public:
                ///Construct a PageIterator.
                this(){}

                ///Move to the next page (wraps to the first one). 
                void next()
                {
                    //Cycle back to first if we're at the last.
                    if(current_page_ >= cast(uint)driver_.pages.length - 1)
                    {
                        current_page_ = 0;
                    }
                    else{++current_page_;}

                    if(driver_.pages.length == 0){return;}
                    //If the page was destroyed, move to the next one.
                    if(driver_.pages[current_page_] == null)
                    {
                        next();
                        return;
                    }
                }

                ///Move to previous page (wraps to the last one).
                void prev()
                {
                    //Cycle back to last if we're at the first.
                    if(current_page_ == 0)
                    {
                        current_page_ = cast(uint)driver_.pages.length - 1;
                    }
                    else{--current_page_;}
                    if(driver_.pages.length == 0){return;}
                    //If the page was destroyed, move to the previous one.
                    if(driver_.pages[current_page_] is null)
                    {
                        prev();
                        return;
                    }
                }

                ///Get information text about the current page.
                string text()
                {
                    if(driver_.pages.length == 0){return "No pages";}

                    while(driver_.pages[current_page_] == null){next();}

                    string text = "page index: " ~ to_string(current_page_) ~ "\n" ~
                                  driver_.pages[current_page_].info;

                    return text;
                }

                /**
                 * Draw the current page.
                 *
                 * Will automatically switch to the next page if the current page
                 * has been destroyed. Won't draw anything if there are no pages.
                 *
                 * Params:  bounds = Screen space bounds to draw the page in.
                 *          offset = Offset into the page in texture pixels (wraps).
                 *          zoom   = Zoom factor.
                 */
                void draw(Rectanglei bounds, Vector2f offset, real zoom)
                {
                    //no page to draw
                    if(driver_.pages.length == 0){return;}
                    //current page was deleted, change to another one
                    while(driver_.pages[current_page_] == null){next();}

                    bounds.min = bounds.min + Vector2i(1, 1);
                    bounds.max = bounds.max - Vector2i(1, 1);

                    //draw the page view
                    //texture area to draw
                    auto area = Rectanglef(Vector2f(0, 0), 
                                           to!(float)(bounds.size) / zoom) - offset; 
                    //quad to map the texture area to
                    auto quad = Rectanglef(to!(float)(bounds.min), to!(float)(bounds.max));
                    driver_.draw_page(current_page_, area, quad);
                }
        }

    private:
        alias std.string.toString to_string;

        ///GLVideoDriver we're monitoring.
        GLVideoDriver driver_;

    public:
        ///Construct a GLMonitor monitoring specified GLVideoDriver.
        this(GLVideoDriver driver)
        {
            super();
            driver_ = driver;
        }

    protected:
        override SubMonitorView view(){return new PageMonitorView(new PageIterator());}
}

///GUI view for the PageMonitor.
final package class PageMonitorView : SubMonitorView
{
    private:
        ///GUI element used to view a texture page.
        class PageView : GUIElement
        {
            private:
                ///Provides mouse zooming and panning.
                mixin MouseControl!(1.1) mouse_;

            public:
                ///Construct a PageView.
                this()
                {
                    super(GUIElementParams("p_left + 28", "p_top + 2", 
                                           "p_width - 106", "p_height - 4", 
                                           true));
                    mouse_.init();
                }

                override void draw(VideoDriver driver)
                {
                    if(!visible_){return;}
                    super.draw(driver);

                    page_iterator_.draw(bounds_, offset_, zoom_);
                }
        }

        ///PageIterator used to access texture pages.
        PageMonitor.PageIterator page_iterator_;

        ///Page view widget.
        PageView view_;
        ///Information about the page.
        GUIStaticText info_text_;

    public:
        ///Construct a PageMonitorView using specified iterator to access texture pages.
        this(PageMonitor.PageIterator iterator)
        {
            super();

            page_iterator_ = iterator;

            main_.add_child(new PageView);
            init_menu();
            init_text();
        }

    protected:
        override void update()
        {
            string text = page_iterator_.text;
            if(text != info_text_.text){info_text_.text = text;}
            super.update();
        }

    private:
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
                item_font_size = MonitorView.font_size;
                add_item("Next", &page_iterator_.next);
                add_item("Prev", &page_iterator_.prev);
                main_.add_child(produce());
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
                font_size = MonitorView.font_size;
                align_x = AlignX.Right;
                text = page_iterator_.text;
                info_text_ = produce();
            }
            main_.add_child(info_text_);
        }
}
