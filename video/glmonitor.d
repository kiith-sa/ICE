module video.glmonitor;


import std.string;

import video.videodriver;
import video.glvideodriver;
import video.gltexturepage;
import gui.guielement;
import gui.guibutton;
import gui.guistatictext;
import math.vector2;
import math.rectangle;
import math.math;
import timer;


///Displays info about texture pages.
package class PagesMonitor : GUIElement
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

            override void draw()
            {
                if(!visible_){return;}
                super.draw();

                GLVideoDriver driver = cast(GLVideoDriver)VideoDriver.get;

                //no page to draw
                if(driver.pages_.length == 0){return;}
                //current page was deleted, change to another one
                while(driver.pages_[current_page_] == null){next();}

                //draw the page view
                //texture area to draw, rectanglef quad to map the texture area on
                Rectanglef area = Rectanglef(0, 0, (size.x) / zoom_, 
                                             (size.y) / zoom_) + offset_; 
                //quad to map the texture area on
                Rectanglef quad = Rectanglef(to!(float)(bounds_.min) + Vector2f(1, 1),
                                             to!(float)(bounds_.max) - Vector2f(1, 1));
                driver.draw_page(current_page_, area, quad);
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
        
        PageView view_;

        //Changing pages.
        GUIButton next_button_, prev_button_;
        //Navigating viewed page.
        GUIButton left_button_, right_button_, up_button_, down_button_;
        //Zooming viewed page.
        GUIButton zoom_in_button_, zoom_out_button_;
        
        //Information about the page.
        GUIStaticText info_text_;

        //Timer used to determine when to update the page info.
        Timer update_timer_;

        //Currently viewed page index (in GLVideoDriver.pages_).
        uint current_page_ = 0;

    public:
        this()
        {
            super();

            update_timer_ = Timer(0.5);

            init_view();
            init_buttons();
            init_text();
        }

    protected:
        override void update()
        {
            super.update();
            if(update_timer_.expired())
            {
                update_text();
                update_timer_.reset();
            }
        }

    private:
        void init_view()
        {
            view_ = new PageView;
            with(view_)
            {
                position_x = "p_left + 28";
                position_y = "p_top + 2";
                width = "p_right - p_left - 106";
                height = "p_bottom - p_top - 4";
            }
            add_child(view_);
        }

        void init_buttons()
        {
            uint buttons = 0;

            void add_button(ref GUIButton button, string button_text, 
                            void delegate() deleg)
            {
                button = new GUIButton;
                with(button)
                {
                    position_x = "p_left + 2";
                    position_y = "p_top + 2 + " ~ to_string(16 * buttons);
                    width = "24";
                    height = "14";
                    text = button_text;
                    font_size = 8;
                }
                button.pressed.connect(deleg);
                add_child(button);
                ++buttons;
            }

            add_button(next_button_, "Next", &next);
            add_button(prev_button_, "Prev", &prev);

            add_button(left_button_, "Left", &view_.left);
            add_button(right_button_, "Right", &view_.right);
            add_button(up_button_, "Up", &view_.up);
            add_button(down_button_, "Down", &view_.down);

            add_button(zoom_in_button_, "+", &view_.zoom_in);
            add_button(zoom_out_button_, "-", &view_.zoom_out);
        }

        void init_text()
        {
            info_text_ = new GUIStaticText;
            with(info_text_)
            {
                alignment_x = AlignX.Right;
                position_x = "p_right - 74";
                position_y = "p_top + 2";
                width = "72";
                height = "p_bottom - p_top - 4";
                font_size = 8;
            }
            add_child(info_text_);
            update_text();
        }

        void next()
        {
            GLVideoDriver driver = cast(GLVideoDriver)VideoDriver.get;
            if(current_page_ >= driver.pages_.length - 1){current_page_ = 0;}
            else{++current_page_;}
            if(driver.pages_.length == 0){return;}
            if(driver.pages_[current_page_] == null)
            {
                next();
                return;
            }
            update_text();
            view_.reset_view();
        }

        void prev()
        {
            GLVideoDriver driver = cast(GLVideoDriver)VideoDriver.get;
            if(current_page_ == 0){current_page_ = driver.pages_.length - 1;}
            else{--current_page_;}
            if(driver.pages_.length == 0){return;}
            if(driver.pages_[current_page_] is null)
            {
                prev();
                return;
            }
            update_text();
            view_.reset_view();
        }

        void update_text()
        {
            GLVideoDriver driver = cast(GLVideoDriver)VideoDriver.get;
            if(driver.pages_.length == 0)
            {
                info_text_.text = "No pages";
                return;
            }
            while(driver.pages_[current_page_] == null){next();}

            info_text_.text = "page index: " ~ to_string(current_page_) ~ "\n" ~
                              driver.pages_[current_page_].info;
        }
}

///Displays info about draw calls, state changes and primitives.
package class DrawsMonitor : GUIElement
{
    private:
        alias std.string.toString to_string;

        //text showing information about draws.
        GUIStaticText draws_text_;
        //timer used to determine when to update draws_text_.
        Timer update_timer_;

    public:
        this()
        {
            super();
            update_timer_ = Timer(0.5);
            draws_text_ = new GUIStaticText;
            with(draws_text_)
            {
                alignment_x = AlignX.Right;
                position_x = "p_left + 2";
                position_y = "p_top + 2";
                width = "96";
                height = "p_bottom - p_top - 4";
                font_size = 8;
            }
            add_child(draws_text_);
            update_text();
        }

    protected:
        override void update()
        {
            super.update();
            if(update_timer_.expired())
            {
                update_text();
                update_timer_.reset();
            }
        }

    private:
        //update shown drawing information.
        void update_text()
        {
            GLVideoDriver driver = cast(GLVideoDriver)VideoDriver.get;
            with(driver)
            {
                draws_text_.text = "draw calls/frame:\n" 
                                   "lines: " ~ to_string(line_draws_) ~ "\n"
                                   "textures: " ~ to_string(texture_draws_) ~ "\n"
                                   "texts: " ~ to_string(text_draws_) ~ "\n"
                                   "elements/frame:\n"
                                   "vertices: " ~ to_string(vertices_) ~ "\n"
                                   "characters: " ~ to_string(characters_) ~ "\n"
                                   "state changes/frame:\n"
                                   "shader: " ~ to_string(shader_changes_) ~ "\n"
                                   "texture page: " ~ to_string(page_changes_) ~ "\n";
            }
        }
}

///Displays info about GLVideoDriver.
package class GLMonitor : GUIElement
{
    private:
        GUIButton pages_button_;
        GUIButton draws_button_;
        GUIElement current_monitor_ = null;
        
    public:
        this()
        {
            super();

            uint buttons = 0;

            void add_button(ref GUIButton button, string button_text, 
                            void delegate() deleg)
            {
                button = new GUIButton;
                with(button)
                {
                    position_x = "p_left + 4";
                    position_y = "p_top + 4 + " ~ to_string(16 * buttons);
                    width = "40";
                    height = "12";
                    text = button_text;
                    font_size = 8;
                }
                button.pressed.connect(deleg);
                add_child(button);
                ++buttons;
            }

            add_button(pages_button_, "Pages", &pages);
            add_button(draws_button_, "Draws", &draws);
        }

        //display texture pages monitor
        void pages(){submonitor(new PagesMonitor);}

        //display draws monitor
        void draws(){submonitor(new DrawsMonitor);}

        void submonitor(GUIElement monitor)
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
}
