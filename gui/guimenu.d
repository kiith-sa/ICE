
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module gui.guimenu;


import std.string;

import gui.guielement;
import gui.guibutton;
import gui.guistatictext;
import video.videodriver;
import util.factory;
import util.action;


///Base class for GUI menus.
abstract class GUIMenu : GUIElement
{
    alias std.string.toString to_string;
    protected:
        ///Actions used for callbacks (if any).
        ActionBase[] actions_;    

        ///Menu items (buttons).
        GUIButton[] items_;

        ///Math expression used to calculate menu item width.
        string item_width_;
        ///Math expression used to calculate menu item height.
        string item_height_;
        ///Math expression used to calculate spacing between menu items.
        string item_spacing_;

    private:
        ///Menu item font size.
        uint font_size_ = GUIStaticText.default_font_size();

    protected:
        /**
         * Construct a menu with specified parameters.
         *
         * Params:  params         = Parameters for GUIElement constructor.
         *          item_width     = Menu item width math expression.
         *          item_height    = Menu item height math expression.
         *          item_spacing   = Math expression used to calculate spacing between menu items.
         *          item_font_size = Menu item font size.
         *          items_         = Names and callback functions of menu items.
         */
        this(GUIElementParams params,
             string item_width, string item_height, string item_spacing, 
             uint item_font_size, MenuItemData[] items)
        {
            super(params);
            //parentheses prevent unwanted operator precedence, simplify realigning code
            item_width_ = "(" ~ item_width ~ ")";
            item_height_ = "(" ~ item_height ~ ")";
            item_spacing_ = "(" ~ item_spacing ~ ")";
            font_size_ = item_font_size;
            aligned_ = false;

            foreach(ref item; items)
            {
                if(item.deleg is null){add_item(item.text, item.action);}
                else{add_item(item.text, item.deleg);}
            }
        }

        ///Create math expression for X position of a new item.
        string new_item_x();

        ///Create math expression for Y position of a new item.
        string new_item_y();

    private:
        /**
         * Add a menu item to the menu (delegate version).
         * 
         * Note: Should only be used by GUIMenu.this.
         *
         * Params:  text  = Text of the menu item.
         *          deleg = Function to call when the menu item is clicked.
         */
        void add_item(string text, void delegate() deleg)
        {
            //construct the new item
            auto factory = new GUIButtonFactory;
            factory.text = text;
            with(factory)
            {
                x = new_item_x();
                y = new_item_y();
                width = item_width_;
                height = item_height_;
                font_size = this.font_size_;
            }
            auto button = factory.produce();

            //connect and add the new item
            button.pressed.connect(deleg);
            items_ ~= button;
            add_child(button);
            aligned_ = false;
        }

        /**
         * Add a menu item to the menu (Action version).
         * 
         * Note: Should only be used by GUIMenu.this .
         *
         * Params:  text   = Text of the menu item.
         *          action = Action to call when the menu item is clicked.
         */
        void add_item(string text, ActionBase action)
        {
            //construct the new item
            auto factory = new GUIButtonFactory;
            factory.text = text;
            with(factory)
            {
                x = new_item_x();
                y = new_item_y();
                width = item_width_;
                height = item_height_;
                font_size = this.font_size_;
            }
            auto button = factory.produce();

            actions_ ~= action;

            //connect and add the new item
            button.pressed.connect(&action.opCall);
            items_ ~= button;
            add_child(button);
            aligned_ = false;
        }
}

///Horizontal menu.
class GUIMenuHorizontal : GUIMenu
{
    protected:
        /**
         * Construct a horizontal menu with specified parameters.
         *
         * Params:  params         = Parameters for GUIElement constructor.
         *          item_width     = Menu item width math expression.
         *          item_height    = Menu item height math expression.
         *          item_spacing   = Math expression used to calculate spacing between menu items.
         *          item_font_size = Menu item font size.
         *          items          = Names and callback functions of menu items.
         */
        this(GUIElementParams params,
             string item_width, string item_height, string item_spacing, 
             uint item_font_size, MenuItemData[] items)
        {
            super(params, item_width, item_height, item_spacing, item_font_size, items);
        }

        override void realign(VideoDriver driver)
        {
            //offset = item_width_ + item_spacing_
            string offset = "(" ~ item_width_ ~ " + " ~ item_spacing_ ~ ")";
            //width = item_spacing_ + offset * items_.length
            width_string_ = item_spacing_ ~ " + " ~ offset ~ " * " ~ to_string(items_.length);
            //height = item_spacing_ * 2 + item_height_
            height_string_ = item_spacing_ ~ " * 2 + " ~ item_height_;
            super.realign(driver);
        }

        override string new_item_x()
        {
            //offset = item_width_ + item_spacing_
            string offset = "(" ~ item_width_ ~ " + " ~ item_spacing_ ~ ")";
            //return item_spacing_ + parent_.bounds_.min.x + offset * items_.length
            return item_spacing_ ~ " + p_left + " ~ offset ~ " * " ~ to_string(items_.length);
        }

        override string new_item_y()
        {
            //return parent_.bounds_.min.y + item_spacing_
            return "p_top + " ~ item_spacing_;
        }
}

///Vertical menu.
class GUIMenuVertical : GUIMenu
{
    protected:
        /**
         * Construct a vertical menu with specified parameters.
         *
         * Params:  params         = Parameters for GUIElement constructor.
         *          item_width     = Menu item width math expression.
         *          item_height    = Menu item height math expression.
         *          item_spacing   = Math expression used to calculate spacing between menu items.
         *          item_font_size = Menu item font size.
         *          items          = Names and callback functions of menu items.
         */
        this(GUIElementParams params,
             string item_width, string item_height, string item_spacing, 
             uint item_font_size, MenuItemData[] items)
        {
            super(params, item_width, item_height, item_spacing, item_font_size, items);
        }

        override void realign(VideoDriver driver)
        {
            //offset = item_height_ + item_spacing_
            string offset = "(" ~ item_height_ ~ " + " ~ item_spacing_ ~ ")";
            //width = item_spacing_ * 2 + item_width_
            width_string_ = item_spacing_ ~ " * 2 + " ~ item_width_;
            //height = item_spacing_ + offset * items_.length
            height_string_ = item_spacing_ ~ " + " ~ offset ~ " * " ~ to_string(items_.length);
            super.realign(driver);
        }

        override string new_item_x()
        {
            //return parent_.bounds_.min.x + item_spacing_
            return "p_left + " ~ item_spacing_;
        }

        override string new_item_y()
        {
            //offset = item_height_ + item_spacing_
            string offset = "(" ~ item_height_ ~ " + " ~ item_spacing_ ~ ")";
            //return item_spacing_ + parent_.bounds_.min.y + offset * items_.length
            return item_spacing_ ~ " + p_top + " ~ offset ~ " * " ~ to_string(items_.length);
        }
}

/**
 * Factory used for menu construction.
 *
 * GUIMenuHorizontalFactory and GUIMenuVerticalFactory are just aliases of this
 * class with GUIMenuHorizontal and GUIMenuVertical as the template parameter,
 * so documentation of this class applies to both of them.
 *
 * See_Also: GUIElementFactoryBase
 *
 * Params:  draw_border    = Draw border of this menu? 
 *                           Default;  false
 *          item_width     = Menu item width math expression.
 *                           Default;  128
 *          item_height    = Menu item height math expression.
 *                           Default;  24
 *          item_spacing   = Math expression used to calculate spacing between menu items.
 *                           Default;  4
 *          item_font_size = Font size of menu items.
 *          add_item       = Add a menu item with specified text and callback
 *                           (either a delegate or an action) to 
 *                           be called when the item is clicked.
 */
class GUIMenuFactory(T) : GUIElementFactoryBase!(T)
{
    mixin(generate_factory("string $ item_width $ \"128\"", 
                           "string $ item_height $ \"24\"",
                           "string $ item_spacing $ \"4\"",
                           "uint $ item_font_size $ GUIStaticText.default_font_size()"));
    private:
        ///Text and callback for each menu item.
        MenuItemData[] items_;
    public:
        ///Construct a GUIMenuFactory and initialize defaults.
        this(){draw_border_ = false;}

        void add_item(string text, void delegate() deleg){items_ ~= MenuItemData(text, deleg);}

        void add_item(string text, ActionBase action){items_ ~= MenuItemData(text, null, action);}

        override T produce()
        {
            return new T(gui_element_params, item_width_, 
                         item_height_, item_spacing_, item_font_size_, items_);
        }
}

/**
 * Factory used for horizontal menu construction.
 *
 * See_Also: GUIMenuFactory
 */
alias GUIMenuFactory!(GUIMenuHorizontal) GUIMenuHorizontalFactory;

/**
 * Factory used for vertical menu construction.
 *
 * See_Also: GUIMenuFactory
 */
alias GUIMenuFactory!(GUIMenuVertical) GUIMenuVerticalFactory;

private:
///Data structure holding data needed to create a menu item.
struct MenuItemData
{
    ///Text of the menu item.
    string text;
    //either deleg or action is used never both
    ///Function to call when the item is clicked. If null, Action is used for this item instead.
    void delegate() deleg = null;
    ///Action to execute when the item is clicked.
    ActionBase action;
}
