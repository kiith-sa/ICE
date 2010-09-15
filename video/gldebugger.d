module video.gldebugger;


import std.string;

import video.videodriver;
import video.glvideodriver;
import video.gltexturepage;
import test.subdebugger;
import gui.guibutton;
import gui.guistatictext;
import math.vector2;
import math.rectangle;
import math.math;
import timer;


///Displays info about texture pages.
package class PagesDebugger : SubDebugger
{
    invariant{assert(zoom_ != 0.0, "Texture page display zoom must be nonzero");}

    private:
        alias std.string.toString to_string;

        //changing pages.
        GUIButton next_button_, prev_button_;

        //navigating viewed page.
        GUIButton left_button_, right_button_, up_button_, down_button_;

        //zooming viewed page.
        GUIButton zoom_in_button_, zoom_out_button_;
        
        //information about the page.
        GUIStaticText info_text_;
        //timer used to determine when to update the page info.
        Timer update_timer_;

        //currently viewed page index (in GLVideoDriver.pages_).
        uint current_page_ = 0;

        //movement step in screen pixels, used when navigating the page.
        real step_ = 128.0;
        //current offset of the view on the page, in texture pixels.
        Vector2f offset_ = Vector2f(0, 0);
        
        //zoom multiplier used when zooming in/out.
        real zoom_mult_ = 1.2;
        //current zoom.
        real zoom_ = 1.0;
        
    public:
        this()
        {
            super();

            update_timer_ = Timer(0.5);

            Vector2u button_size = Vector2u(24, 16);
            uint font_size = 8;

            next_button_ = new GUIButton(this, Vector2i(2, 2), button_size, "Next");
            next_button_.font_size = font_size;
            next_button_.pressed.connect(&next);
            prev_button_ = new GUIButton(this, Vector2i(2, 20), button_size, "Prev");
            prev_button_.font_size = font_size;
            prev_button_.pressed.connect(&prev);

            left_button_ = new GUIButton(this, Vector2i(2, 38), button_size, "Left");
            left_button_.font_size = font_size;
            left_button_.pressed.connect(&left);
            right_button_ = new GUIButton(this, Vector2i(2, 56), button_size, "Right");
            right_button_.font_size = font_size;
            right_button_.pressed.connect(&right);
            up_button_ = new GUIButton(this, Vector2i(2, 74), button_size, "Up");
            up_button_.font_size = font_size;
            up_button_.pressed.connect(&up);
            down_button_ = new GUIButton(this, Vector2i(2, 92), button_size, "Down");
            down_button_.font_size = font_size;
            down_button_.pressed.connect(&down);

            zoom_in_button_ = new GUIButton(this, Vector2i(2, 110), button_size, "+");
            zoom_in_button_.font_size = font_size;
            zoom_in_button_.pressed.connect(&zoom_in);
            zoom_out_button_ = new GUIButton(this, Vector2i(2, 128), button_size, "-");
            zoom_out_button_.font_size = font_size;
            zoom_out_button_.pressed.connect(&zoom_out);

            info_text_ = new GUIStaticText(this, Vector2i(0, 0), Vector2u(72, 256), 
                                           "placeholder", "default", font_size);
            info_text_.alignment_x(AlignX.Right);

            update_text();
        }

    protected:
        override void draw()
        {
            if(!visible_){return;}
            
            if(update_timer_.expired())
            {
                update_text();
                update_timer_.reset();
            }

            super.draw();

            GLVideoDriver driver = cast(GLVideoDriver)VideoDriver.get;

            //no page to draw
            if(driver.pages_.length == 0){return;}

            while(driver.pages_[current_page_] == null){next();}

            //draw the page view
            //texture area to draw, rectanglef quad to map the texture area on
            Rectanglef area = Rectanglef(0, 0, (size.x - 108) / zoom_, 
                                         (size.y - 6) / zoom_) + offset_; 
            //quad to map the texture area on
            Rectanglef quad = Rectanglef(bounds_.min.x + 30, bounds_.min.y + 3,
                                         bounds_.max.x - 78, bounds_.max.y - 3); 
            driver.draw_page(current_page_, area, quad);

            //draw a border around the page view
            VideoDriver.get.draw_rectangle(quad.min - Vector2f(1, 1), 
                                           quad.max + Vector2f(1, 1), border_color_);
        }

        override void realign()
        {
            info_text_.size = Vector2u(72, max(cast(int)size.y - 4, 0));
            info_text_.position_local = Vector2i(size.x - 76, 2);
        }

    private:
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
            reset_view();
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
            reset_view();
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
package class DrawsDebugger : SubDebugger
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
            draws_text_ = new GUIStaticText(this, Vector2i(2, 2), Vector2u(80, 256), 
                                            "placeholder", "default", 8);
            draws_text_.alignment_x(AlignX.Right);
            update_text();
        }

    protected:
        override void draw()
        {
            if(!visible_){return;}

            if(update_timer_.expired())
            {
                update_text();
                update_timer_.reset();
            }

            super.draw();
        }

        override void realign()
        {
            draws_text_.size = Vector2u(96, max(cast(int)size.y - 4, 0));
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
package class GLDebugger : SubDebugger
{
    private:
        GUIButton pages_button_;
        GUIButton draws_button_;
        SubDebugger current_debugger_ = null;
        
    public:
        this()
        {
            super();

            Vector2u button_size = Vector2u(40, 12);
            uint font_size = 8;

            pages_button_ = new GUIButton(this, Vector2i(4, 4), button_size, "Pages");
            pages_button_.font_size = font_size;
            pages_button_.pressed.connect(&pages);

            draws_button_ = new GUIButton(this, Vector2i(4, 20), button_size, "Draws");
            draws_button_.font_size = font_size;
            draws_button_.pressed.connect(&draws);
        }

        void subdebugger(SubDebugger debugger)
        {
            disconnect_current();
            current_debugger_ = debugger;
            add_child(current_debugger_);
            current_debugger_.position_local = Vector2i(48, 4);
            current_debugger_.size = Vector2u(size.x - 52, size.y - 8);
        }

        void pages(){subdebugger(new PagesDebugger);}

        void draws(){subdebugger(new DrawsDebugger);}

        void disconnect_current()
        {
            if(current_debugger_ !is null)
            {
                remove_child(current_debugger_);
                current_debugger_.die();
                current_debugger_ = null;
            }
        }

    protected:
        override void realign()
        {
            if(current_debugger_ is null){return;}
            current_debugger_.size = Vector2u(max(cast(int)size.x - 52, 0), 
                                              max(cast(int)size.y - 8, 0));
        }
}
