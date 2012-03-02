
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Menu widget.
module gui.guimenu;


import std.conv;

import gui.guielement;
import gui.guibutton;
import gui.guistatictext;
import video.videodriver;
import util.factory;


///Base class for GUI menus.
abstract class GUIMenu : GUIElement
{
    protected:
        ///Menu items (buttons).
        GUIButton[] items_;

        ///Math expression used to calculate menu item width.
        string itemWidth_;
        ///Math expression used to calculate menu item height.
        string itemHeight_;
        ///Math expression used to calculate spacing between menu items.
        string itemSpacing_;

    private:
        ///Menu item font size.
        uint fontSize_ = GUIStaticText.defaultFontSize();

    protected:
        /**
         * Construct a menu with specified parameters.
         *
         * Params:  params         = Parameters for GUIElement constructor.
         *          itemWidth     = Menu item width math expression.
         *          itemHeight    = Menu item height math expression.
         *          itemSpacing   = Math expression used to calculate spacing between menu items.
         *          itemFontSize = Menu item font size.
         *          items_         = Names and callback functions of menu items.
         */
        this(in GUIElementParams params,
             in string itemWidth, in string itemHeight, in string itemSpacing, 
             in uint itemFontSize, MenuItemData[] items)
        {
            super(params);
            //parentheses prevent unwanted operator precedence, simplify realigning code
            itemWidth_   = "(" ~ itemWidth ~ ")";
            itemHeight_  = "(" ~ itemHeight ~ ")";
            itemSpacing_ = "(" ~ itemSpacing ~ ")";
            fontSize_    = itemFontSize;
            aligned_      = false;

            foreach(ref item; items)
            {
                addItem(item.text, item.deleg);
            }
        }

        ///Create math expression for X position of a new item.
        string newItemX() const;

        ///Create math expression for Y position of a new item.
        string newItemY() const;

    private:
        /**
         * Add a menu item to the menu (delegate version).
         * 
         * Note: Should only be used by GUIMenu.this.
         *
         * Params:  text  = Text of the menu item.
         *          deleg = Function to call when the menu item is clicked.
         */
        void addItem(in string text, void delegate() deleg)
        {
            //construct the new item
            auto factory = new GUIButtonFactory;
            factory.text = text;
            with(factory)
            {
                x         = newItemX();
                y         = newItemY();
                width     = itemWidth_;
                height    = itemHeight_;
                fontSize = this.fontSize_;
            }
            auto button = factory.produce();

            //connect and add the new item
            button.pressed.connect(deleg);
            items_ ~= button;
            addChild(button);
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
         *          itemWidth     = Menu item width math expression.
         *          itemHeight    = Menu item height math expression.
         *          itemSpacing   = Math expression used to calculate spacing between menu items.
         *          itemFontSize = Menu item font size.
         *          items          = Names and callback functions of menu items.
         */
        this(in GUIElementParams params,
             in string itemWidth, in string itemHeight, in string itemSpacing, 
             in uint itemFontSize, MenuItemData[] items)
        {
            super(params, itemWidth, itemHeight, itemSpacing, itemFontSize, items);
        }

        override void realign(VideoDriver driver)
        {
            //offset = itemWidth_ + itemSpacing_
            const offset = "(" ~ itemWidth_ ~ " + " ~ itemSpacing_ ~ ")";
            //width = itemSpacing_ + offset * items_.length
            widthString_ = itemSpacing_ ~ " + " ~ offset ~ " * " ~ to!string(items_.length);
            //height = itemSpacing_ * 2 + itemHeight_
            heightString_ = itemSpacing_ ~ " * 2 + " ~ itemHeight_;
            super.realign(driver);
        }

        override string newItemX() const
        {
            //offset = itemWidth_ + itemSpacing_
            const offset = "(" ~ itemWidth_ ~ " + " ~ itemSpacing_ ~ ")";
            //return itemSpacing_ + parent_.bounds_.min.x + offset * items_.length
            return itemSpacing_ ~ " + p_left + " ~ offset ~ " * " ~ to!string(items_.length);
        }

        override string newItemY() const
        {
            //return parent_.bounds_.min.y + itemSpacing_
            return "p_top + " ~ itemSpacing_;
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
         *          itemWidth     = Menu item width math expression.
         *          itemHeight    = Menu item height math expression.
         *          itemSpacing   = Math expression used to calculate spacing between menu items.
         *          itemFontSize = Menu item font size.
         *          items          = Names and callback functions of menu items.
         */
        this(in GUIElementParams params,
             in string itemWidth, in string itemHeight, in string itemSpacing, 
             in uint itemFontSize, MenuItemData[] items)
        {
            super(params, itemWidth, itemHeight, itemSpacing, itemFontSize, items);
        }

        override void realign(VideoDriver driver)
        {
            //offset = itemHeight_ + itemSpacing_
            const offset = "(" ~ itemHeight_ ~ " + " ~ itemSpacing_ ~ ")";
            //width = itemSpacing_ * 2 + itemWidth_
            widthString_ = itemSpacing_ ~ " * 2 + " ~ itemWidth_;
            //height = itemSpacing_ + offset * items_.length
            heightString_ = itemSpacing_ ~ " + " ~ offset ~ " * " ~ to!string(items_.length);
            super.realign(driver);
        }

        override string newItemX() const
        {
            //return parent_.bounds_.min.x + itemSpacing_
            return "p_left + " ~ itemSpacing_;
        }

        override string newItemY() const
        {
            //offset = itemHeight_ + itemSpacing_
            const offset = "(" ~ itemHeight_ ~ " + " ~ itemSpacing_ ~ ")";
            //return itemSpacing_ + parent_.bounds_.min.y + offset * items_.length
            return itemSpacing_ ~ " + p_top + " ~ offset ~ " * " ~ to!string(items_.length);
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
 * Params:  drawBorder    = Draw border of this menu? 
 *                           Default;  false
 *          itemWidth     = Menu item width math expression.
 *                           Default;  128
 *          itemHeight    = Menu item height math expression.
 *                           Default;  24
 *          itemSpacing   = Math expression used to calculate spacing between menu items.
 *                           Default;  4
 *          itemFontSize = Font size of menu items.
 *          addItem       = Add a menu item with specified text and callback
 *                           to be called when the item is clicked.
 */
class GUIMenuFactory(T) : GUIElementFactoryBase!T
{
    mixin(generateFactory(`string $ itemWidth     $ "128"`, 
                           `string $ itemHeight    $ "24"`,
                           `string $ itemSpacing   $ "4"`,
                           `uint   $ itemFontSize $ GUIStaticText.defaultFontSize()`));
    private:
        ///Text and callback for each menu item.
        MenuItemData[] items_;
    public:
        ///Construct a GUIMenuFactory and initialize defaults.
        this(){drawBorder_ = false;}

        void addItem(in string text, void delegate() deleg)
        {
            items_ ~= MenuItemData(text, deleg);
        }

        override T produce()
        {
            return new T(guiElementParams, itemWidth_, 
                         itemHeight_, itemSpacing_, itemFontSize_, items_);
        }
}

/**
 * Factory used for horizontal menu construction.
 *
 * See_Also: GUIMenuFactory
 */
alias GUIMenuFactory!GUIMenuHorizontal GUIMenuHorizontalFactory;

/**
 * Factory used for vertical menu construction.
 *
 * See_Also: GUIMenuFactory
 */
alias GUIMenuFactory!GUIMenuVertical GUIMenuVerticalFactory;

private:
///Data structure holding data needed to create a menu item.
struct MenuItemData
{
    ///Text of the menu item.
    string text;
    ///Function to call when the item is clicked. If null, Action is used for this item instead.
    void delegate() deleg = null;
}
