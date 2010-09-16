module gui.guimenu;


import std.string;

import gui.guielement;
import gui.guibutton;
import video.videodriver;


enum MenuOrientation
{
    Horizontal,
    Vertical
}

class GUIMenu : GUIElement
{
    private:
        alias std.string.toString to_string;

        uint item_count_;

        GUIButton[] items_;

        MenuOrientation orientation_ = MenuOrientation.Vertical;

        string item_width_ = "128";
        string item_height_ = "24";
        string item_spacing_ = "4";

    protected:
        override void realign()
        {
            string spacing = "(" ~ item_spacing_ ~ ")";

            if(orientation_ == MenuOrientation.Horizontal)
            {
                string offset = "((" ~ item_width_ ~ ") + " ~ spacing ~ ")";
                foreach(index, ref item; items_)
                {
                    item.position_x = spacing ~ " + p_left + " ~ offset ~
                                      " * " ~ to_string(index);
                    item.position_y = "p_top + " ~ spacing;
                    item.width = item_width_;
                    item.height = item_height_;
                }
                width = spacing ~ " + " ~ offset ~ " * " ~ to_string(items_.length);
                height = spacing ~ " * 2 + (" ~ item_height_ ~ ")";
            }
            else if(orientation_ == MenuOrientation.Vertical)
            {
                string offset = "((" ~ item_height_ ~ ") + " ~ spacing ~ ")";
                foreach(index, item; items_)
                {
                    item.position_x = "p_left + " ~ spacing;
                    item.position_y = spacing ~ " + p_top + " ~ offset ~
                                      " * " ~ to_string(index);
                    item.width = item_width_;
                    item.height = item_height_;
                }
                width = spacing ~ " * 2 + (" ~ item_width_ ~ ")";
                height = spacing ~ " + " ~ offset ~ " * " ~ to_string(items_.length);
            }
            else{assert(false, "Unknown menu orientation");}
            super.realign();
        }

    public:
        this(){draw_border_ = false;}

        void orientation(MenuOrientation orientation)
        {
            orientation_ = orientation;
            aligned_ = false;
        }

        void item_width(string width)
        {
            item_width_ = width;
            aligned_ = false;
        }

        void item_height(string height)
        {
            item_height_ = height;
            aligned_ = false;
        }

        void item_spacing(string spacing)
        {
            item_spacing_ = spacing;
            aligned_ = false;
        }

        void item_font_size(uint size)
        {
            foreach(ref item; items_){item.font_size = size;}
            aligned_ = false;
        }

        void add_item(string text, void delegate() deleg)
        {
            auto button = new GUIButton;
            button.text = text;
            button.pressed.connect(deleg);
            items_ ~= button;
            add_child(button);
            aligned_ = false;
        }
}
