module gui.guimenu;


import std.string;

import gui.guielement;
import gui.guibutton;
import gui.guistatictext;
import video.videodriver;
import factory;


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

        //Font size of the buttons in the menu.
        uint font_size_ = GUIStaticText.default_font_size();

        GUIButton[] items_;

        MenuOrientation orientation_ = MenuOrientation.Vertical;

        //Math expression used to calculate width of a menu element.
        string item_width_;
        //Math expression used to calculate height of a menu element.
        string item_height_;
        //Math expression used to calculate spacing between menu elements.
        string item_spacing_;

    protected:
        /*
         * Construct a menu with specified parameters.
         *
         * See_Also: GUIElement.this 
         *
         * Params:  x              = X position math expression.
         *          y              = Y position math expression. 
         *          width          = Width math expression. 
         *          height         = Height math expression. 
         *          orientation    = Menu orientation (horizontal or vertical)
         *          item_width     = Menu item width math expression.
         *          item_height    = Menu item height math expression.
         *          item_spacing   = Math expression used to calculate spacing between menu items.
         *          item_font_size = Font size of menu items.
         *          items          = Names and function callbacks of menu items.
         */
        this(string x, string y, string width, string height, 
             MenuOrientation orientation, 
             string item_width, string item_height, string item_spacing, 
             uint item_font_size, void delegate()[string] items)
        {
            super(x, y, width, height);
            draw_border_ = false;
            orientation_ = orientation;
            item_width_ = item_width;
            item_height_ = item_height;
            item_spacing_ = item_spacing;
            font_size_ = item_font_size;
            aligned_ = false;

            foreach(text; items.keys){add_item(text, items[text]);}
        }

        override void realign()
        {
            string spacing = "(" ~ item_spacing_ ~ ")";

            if(orientation_ == MenuOrientation.Horizontal)
            {
                string offset = "((" ~ item_width_ ~ ") + " ~ spacing ~ ")";
                width_string_ = spacing ~ " + " ~ offset ~ " * " ~ to_string(items_.length);
                height_string_ = spacing ~ " * 2 + (" ~ item_height_ ~ ")";
            }
            else if(orientation_ == MenuOrientation.Vertical)
            {

                string offset = "((" ~ item_height_ ~ ") + " ~ spacing ~ ")";
                width_string_ = spacing ~ " * 2 + (" ~ item_width_ ~ ")";
                height_string_ = spacing ~ " + " ~ offset ~ " * " ~ to_string(items_.length);
            }
            else{assert(false, "Unknown menu orientation");}
            super.realign();
        }

    private:
        /**
         * Add a menu item to the menu.
         * 
         * Note: Should only be used by GUIMenu.this
         *
         * Params:  text  = Text of the menu item.
         *          deleg = Function to call when the menu item is clicked.
         */
        void add_item(string text, void delegate() deleg)
        {
            auto factory = new GUIButtonFactory;
            factory.text = text;
            with(factory)
            {
                x = new_item_x;
                y = new_item_y;
                width = item_width_;
                height = item_height_;
                font_size = this.font_size_;
            }
            auto button = factory.produce();

            button.pressed.connect(deleg);
            items_ ~= button;
            add_child(button);
            aligned_ = false;
        }

        ///Get math expression for X position of a new item.
        string new_item_x()
        {
            string spacing = "(" ~ item_spacing_ ~ ")";
            if(orientation_ == MenuOrientation.Horizontal)
            {
                string offset = "((" ~ item_width_ ~ ") + " ~ spacing ~ ")";
                return spacing ~ " + p_left + " ~ offset ~ " * " ~ to_string(items_.length);
            }
            else{return "p_left + " ~ spacing;}
        }

        ///Get math expression for Y position of a new item.
        string new_item_y()
        {
            string spacing = "(" ~ item_spacing_ ~ ")";
            if(orientation_ == MenuOrientation.Horizontal){return "p_top + " ~ spacing;}
            else
            {
                string offset = "((" ~ item_height_ ~ ") + " ~ spacing ~ ")";
                return spacing ~ " + p_top + " ~ offset ~ " * " ~ to_string(items_.length);
            }
        }
}

/**
 * Factory used for menu construction.
 *
 * See_Also: GUIElementFactoryBase
 *
 * Params:  orientation    = Menu orientation (horizontal or vertical)
 *          item_width     = Menu item width math expression.
 *          item_height    = Menu item height math expression.
 *          item_spacing   = Math expression used to calculate spacing between menu items.
 *          item_font_size = Font size of menu items.
 *          add_item       = Add a menu item with specified text and callback to 
 *                           be called when the item is clicked.
 */
final class GUIMenuFactory : GUIElementFactoryBase!(GUIMenu)
{
    mixin(generate_factory("MenuOrientation $ orientation $ MenuOrientation.Vertical", 
                           "string $ item_width $ \"128\"", 
                           "string $ item_height $ \"24\"",
                           "string $ item_spacing $ \"4\"",
                           "uint $ item_font_size $ GUIStaticText.default_font_size()"));
    private:
        void delegate()[string] items_;
    public:
        void add_item(string text, void delegate() deleg){items_[text] = deleg;}

        override GUIMenu produce()
        {
            return new GUIMenu(x_, y_, width_, height_, orientation_, item_width_, 
                               item_height_, item_spacing_, item_font_size_, items_);
        }
}
