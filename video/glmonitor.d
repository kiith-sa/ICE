
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Monitor viewing OpenGL video driver state.
module video.glmonitor;


import std.conv;
import std.math;

import video.videodriver;
import video.glvideodriver;
import gui.guielement;
import gui.guimenu;
import gui.guistatictext;
import gui.guimousecontrollable;
import monitor.monitormanager;
import monitor.submonitor;
import math.vector2;
import math.rect;
import math.math;
import util.signal;
import color;


///Statistics data sent by GLVideoDriver to GL monitors.
package struct Statistics
{
    ///Draw calls.
    uint lines, textures, texts, rectangles;
    ///Drawing primitives.
    uint vertices, indices, characters, vgroups;
    ///State changes.
    uint shader, page;
    ///FPS this frame (inverse of frame length).
    real fps = 0.0;

    ///Reset the statistics gathered for the next frame.
    void zero() pure
    {    
        lines = textures = texts = rectangles = vertices = indices = characters 
              = vgroups = shader = page = 0;
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
                uint currentPage_;

            public:
                ///Construct a PageIterator.
                this(){}

                ///Move to the next page (wraps to the first one). 
                void next()
                {
                    //Cycle back to first if we're at the last.
                    if(currentPage_ >= cast(uint)driver_.pages.length - 1)
                    {
                        currentPage_ = 0;
                    }
                    else{++currentPage_;}

                    if(driver_.pages.length == 0){return;}
                    //If the page was destroyed, move to the next one.
                    if(driver_.pages[currentPage_] == null)
                    {
                        next();
                        return;
                    }
                }

                ///Move to previous page (wraps to the last one).
                void prev()
                {
                    //Cycle back to last if we're at the first.
                    if(currentPage_ == 0)
                    {
                        currentPage_ = cast(uint)driver_.pages.length - 1;
                    }
                    else{--currentPage_;}
                    if(driver_.pages.length == 0){return;}
                    //If the page was destroyed, move to the previous one.
                    if(driver_.pages[currentPage_] is null)
                    {
                        prev();
                        return;
                    }
                }

                ///Get information text about the current page.
                @property string text()
                {
                    if(driver_.pages.length == 0){return "No pages";}

                    while(driver_.pages[currentPage_] == null){next();}

                    string text = "page index: " ~ to!string(currentPage_) ~ "\n" ~
                                  driver_.pages[currentPage_].info;

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
                void draw(Recti bounds, const Vector2f offset, const real zoom)
                {
                    //no page to draw
                    if(driver_.pages.length == 0){return;}
                    //current page was deleted, change to another one
                    while(driver_.pages[currentPage_] == null){next();}

                    bounds.min = bounds.min + Vector2i(1, 1);
                    bounds.max = bounds.max - Vector2i(1, 1);

                    //draw the page view
                    //texture area to draw
                    const area = Rectf(Vector2f(0, 0), 
                                            bounds.size.to!float / zoom) - offset; 
                    //quad to map the texture area to
                    const quad = Rectf(bounds.min.to!float, bounds.max.to!float);
                    driver_.drawPage(currentPage_, area, quad);
                }
        }

    private:
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
        @property override SubMonitorView view()
        {
            return new PageMonitorView(new PageIterator());
        }
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
                mixin MouseControl!1.1 mouse_;

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

                    pageIterator_.draw(bounds_, offset_, zoom_);
                }
        }

        ///PageIterator used to access texture pages.
        PageMonitor.PageIterator pageIterator_;

        ///Page view widget.
        PageView view_;
        ///Information about the page.
        GUIStaticText infoText_;

    public:
        ///Construct a PageMonitorView using specified iterator to access texture pages.
        this(PageMonitor.PageIterator iterator)
        {
            super();

            pageIterator_ = iterator;

            main_.addChild(new PageView);
            initMenu();
            initText();
        }

    protected:
        override void update()
        {
            infoText_.text = pageIterator_.text;
            super.update();
        }

    private:
        ///Initialize menu.
        void initMenu()
        {
            with(new GUIMenuVerticalFactory)
            {
                x              = "p_left";
                y              = "p_top";
                itemWidth     = "24";
                itemHeight    = "14";
                itemSpacing   = "2";
                itemFontSize = MonitorView.fontSize;
                addItem("Next", &pageIterator_.next);
                addItem("Prev", &pageIterator_.prev);
                main_.addChild(produce());
            }
        }

        ///Initialize info text.
        void initText()
        {
            with(new GUIStaticTextFactory)
            {
                x          = "p_right - 74";
                y          = "p_top + 2";
                width      = "72";
                height     = "p_height - 4";
                fontSize  = MonitorView.fontSize;
                alignX    = AlignX.Right;
                text       = pageIterator_.text;
                infoText_ = produce();
            }
            main_.addChild(infoText_);
        }
}
