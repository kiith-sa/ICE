
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Base class for all widgets.
module gui.guielement;


import std.algorithm;
import std.conv;
import std.stdio;

import video.videodriver;
import math.vector2;
import math.rect;
import platform.platform;
import formats.mathparser;
import color;
import util.factory;
import util.weaksingleton;


//In future, this should be rewritten to support background and border(?) textures,
//and should be serializable. Border might be a separate class/struct that 
//would not be mandatory (e.g. RA2 style GUI needs no borders)
///Base class for all GUI elements. Can be used directly to draw empty elements.
class GUIElement
{
    private:
        ///Is this element dead (to be destroyed next update)?
        bool dead_ = false;

    protected:
        ///Parent element of this element.
        GUIElement parent_ = null;
        ///Children elements of this element.
        GUIElement[] children_;

        ///Color of the element's border.
        Color borderColor_ = rgba!"FFFFFF60";
        ///Bounds of this element in screen space.
        Recti bounds_;

        ///Is this element visible?
        bool visible_ = true;
        ///Draw border of this element?
        bool drawBorder_;
        ///Are the contents of this element aligned based on its current properties?
        bool aligned_ = false;

        ///Math expression used to calculate X position of the element.
        string xString_;
        ///Math expression used to calculate Y position of the element.
        string yString_;
        ///Math expression used to calculate width of the element.
        string widthString_;
        ///Math expression used to calculate height of the element.
        string heightString_;

    public:
        ///Destroy this element and all its children.
        final void die()
        {
            dead_ = true;
            foreach(child; children_){child.die();}
        }

        ///Destructor. Used to assert that the element was correctly destroyed using die().
        ~this()
        {
            assert(dead_ == true,
                   "Destroying a GUIElement that is not dead - "
                   "maybe die() wasn't called before the element was collected by GC");

            foreach(ref child; children_){clear(child);}
            clear(children_);
        }

        ///Get position in screen space.
        @property final Vector2i positionGlobal() const {return bounds_.min;}

        ///Get position relative to parent element.
        @property final Vector2i positionLocal() const
        {
            return bounds_.min - parent_.bounds_.min;
        }
        
        ///Get size of this element in screen space.
        @property final Vector2u size() const 
        {
            return bounds_.size.to!uint;
        }

        ///Get bounding rectangle of this GUI element in screen space.
        @property final Recti boundsGlobal() const {return bounds_;}

        /**
         * Add a child element. 
         *
         * A single child can't be added twice to the same element or to
         * two different GUI elements at the same time.
         *
         * Params:  child = Child to add.
         */
        final void addChild(GUIElement child)
        in
        {
            assert(!canFind!"a is b"(children_, child),
                   "Trying to add a child that is already a child of this GUI element.");
            assert(child.parent_ is null, "Trying to add a child that already has a parent");
        }
        body
        {
            children_ ~= child;
            child.parent_ = this;
        }

        ///Remove a child element. The specified element must be a child of this element.
        final void removeChild(GUIElement child)
        in
        {
            assert(canFind!"a is b"(children_, child) && child.parent_ is this,
                   "Trying to remove a child that is not a child of this GUI element.");
        }
        body
        {
            children_ = remove!((GUIElement a){return a is child;})(children_);
            child.parent_ = null;
        }

        ///Is this element visible?
        @property final bool visible() const {return visible_;}

        ///Hide this element and its children.
        @property final void hide(){visible_ = false;}

        ///Make this element and its children visible.
        @property final void show(){visible_ = true;}

    protected:
        /**
         * Construct a GUIElement with specified parameters.
         *
         * Params:  params = Parameters for construction of the GUIElement.
         */
        this(const GUIElementParams params)
        {
            with(params)
            {
                xString_      = x;
                yString_      = y;
                widthString_  = width;
                heightString_ = height;
                drawBorder_   = drawBorder;
            }
            aligned_ = false;
        }
        
        /**
         * Draw this GUIElement and its children, if visible.
         *
         * Params:  driver = Driver to draw with.
         */
        void draw(VideoDriver driver)
        {
            if(!visible_){return;}

            if(!aligned_){realign(driver);}

            if(drawBorder_)
            {
                driver.drawRect(bounds_.min.to!float, bounds_.max.to!float, 
                                     borderColor_);
            }

            drawChildren(driver);
        }

        ///Update this GUIElement and its children.
        void update(){updateChildren();}

        /**
         * Process keyboard input.
         *
         * Params:  state   = State of the key.
         *          key     = Keyboard key.
         *          unicode = Unicode value of the key.
         */
        void key(KeyState state, Key key, dchar unicode)
        {
            //ignore for hidden elements
            if(!visible_){return;}

            //pass input to the children
            foreach_reverse(ref child; children_){child.key(state, key, unicode);}
        }

        /**
         * Process mouse key input.
         *
         * Params:  state    = State of the key.
         *          key      = Mouse key.
         *          position = Position of the mouse.
         */
        void mouseKey(KeyState state, MouseKey key, Vector2u position)
        {
            //ignore hidden elements
            if(!visible_){return;}

            //pass input to the children
            foreach_reverse(ref child; children_){child.mouseKey(state, key, position);}
        }

        /**
         * Process mouse movement.
         *
         * Params:  position = Position of the mouse in screen coordinates.
         *          relative = Relative movement of the mouse.
         */
        void mouseMove(Vector2u position, Vector2i relative)
        {
            //ignore hidden elements
            if(!visible_){return;}

            //pass input to the children
            foreach_reverse(ref child; children_){child.mouseMove(position, relative);}
        }

        ///Realign contents of this element according to its dimensions.
        void realign(VideoDriver driver)
        {
            //process expressions for bounds coordinates.
            int[string] substitutions;

            //substitutions for window and parents' coordinates.
            substitutions["w_right"]  = driver.screenWidth;
            substitutions["w_bottom"] = driver.screenHeight;
            substitutions["p_left"]   = parent_ is null ? 0 : parent_.bounds_.min.x;
            substitutions["p_right"]  = parent_ is null ? 0 : parent_.bounds_.max.x;
            substitutions["p_top"]    = parent_ is null ? 0 : parent_.bounds_.min.y;
            substitutions["p_bottom"] = parent_ is null ? 0 : parent_.bounds_.max.y;
            substitutions["p_width"]  = parent_ is null ? 0 : parent_.bounds_.width;
            substitutions["p_height"] = parent_ is null ? 0 : parent_.bounds_.height;

            int width, height;

            //fallback to fixed dimensions to avoid complicated exception resolving.
            void fallback()
            {
                width = height = 64;
                writeln("Falling back to fixed dimensions: 64x64");
            }

            scope(failure){writeln("GUI dimension expression parsing failed: width: " 
                                    ~ widthString_ ~ ", height: " ~ heightString_);}

            try
            {
                bounds_.min = Vector2i(parseMath(xString_, substitutions), 
                                       parseMath(yString_, substitutions));

                width  = parseMath(widthString_, substitutions);
                height = parseMath(heightString_, substitutions);

                if(height < 0 || width < 0)
                {
                    writeln("Negative width and/or height of a GUI element! "   
                            "Probably caused by incorrect GUI math expressions.");
                    fallback();
                }
            }
            catch(MathParserException e)
            {
                writeln("Invalid GUI math expression.");
                writeln(e.msg);
                fallback();
            }

            bounds_.max = bounds_.min + Vector2i(width, height);

            //realign children
            foreach(ref child; children_) if(child.visible_)
            {
                child.realign(driver);
            }

            aligned_ = true;
        }

    private:
        /**
         * Draw children of this element.
         *
         * Params:  driver = VideoDriver to draw with.
         */
        final void drawChildren(VideoDriver driver)
        {
            foreach(ref child; children_)
            {
                assert(!child.dead_, 
                       "GUI element with dead child while drawing - it should "
                       "have been cleaned up during the previous collectDead()");
                child.draw(driver);
            }
        }

        ///Update children of this element.
        final void updateChildren()
        {
            foreach(ref child; children_)
            {
                assert(!child.dead_, 
                       "GUI element with dead child while updating - it should "
                       "have been cleaned up during the previous collectDead()");
                child.update();
            }
        }

        ///Remove dead GUI elements.
        final void collectDead()
        {
            auto l = 0;
            for(size_t childFrom = 0; childFrom < children_.length; ++childFrom)
            {
                auto child = children_[childFrom];
                if(child.dead_)
                {
                    clear(child);
                    continue;
                }
                child.collectDead();
                children_[l] = child;
                ++l;
            } 
            children_.length = l;
        }
}

///GUI root container. Contains drawing and input handling methods.
final class GUIRoot
{
    mixin WeakSingleton;
    private:
        ///The actual GUI root element.
        GUIElement root_;

    public:
        /**
         * Construct the GUI root.
         *
         * Size of the root GUI element will be identical to window size.
         *
         * Params:  platform = Platform to use for input.
         */
        this(Platform platform)
        {
            singletonCtor();

            //construct the root element.
            with(new GUIElementFactory)
            {
                x      = "0";
                y      = "0";
                width  = "w_right";
                height = "w_bottom";
                root_  = produce();
            }
            root_.drawBorder_ = false;

            platform.key.connect(&root_.key);
            platform.mouseMotion.connect(&root_.mouseMove);
            platform.mouseKey.connect(&root_.mouseKey);
        }

        ///Destroy the GUIRoot.
        ~this()
        {
            root_.die();
            clear(root_);
            singletonDtor();
        }

        /**
         * Draw the GUI.
         *
         * Params:  driver = VideoDriver to draw with.
         */
        void draw(VideoDriver driver)
        {
            scope(failure){writeln("Failure drawing GUI");}

            //save view zoom and offset
            const zoom   = driver.zoom;
            const offset = driver.viewOffset; 

            //set 1:1 zoom and zero offset for GUI drawing
            driver.zoom        = 1.0;
            driver.viewOffset = Vector2d(0.0, 0.0);
            //draw the elements
            root_.draw(driver);
            //restore zoom and offset
            driver.zoom        = zoom;
            driver.viewOffset = offset;
        }

        ///Get the root element of the GUI.
        @property GUIElement root(){return root_;}

        ///Update the GUI.
        void update()
        {
            root_.collectDead();
            root_.updateChildren();
        }

        ///Add a child element.
        void addChild(GUIElement child){root_.addChild(child);}

        ///Remove a child element.
        void removeChild(GUIElement child){root_.removeChild(child);}

        ///Realign the GUI.
        void realign(VideoDriver driver){root_.realign(driver);}
}

/**
 * Factory used for GUI element construction.
 *
 * See_Also: GUIElementFactoryBase
 */
final class GUIElementFactory : GUIElementFactoryBase!GUIElement
{
    public override GUIElement produce(){return new GUIElement(guiElementParams);}
}

/**
 * Template base class for all GUI element factories, template type T
 * specifies type of GUI element constructed by the factory.
 *
 * Position and size of GUI elements are specified with
 * strings containing simple math expressions which
 * are evaluated to determine the actual coordinates.
 *
 * Supported operators are +,-,*,/ as well as parentheses.
 *
 * Furthermore, there are builtin macros representing window and parent
 * coordinates. These are:
 *
 * w_right  : Window right end (left end is always 0, so this is window width)$(BR)
 * w_bottom : Window bottom end (top end is always 0, so this is window height)$(BR)
 * p_left   : Parent left end$(BR)
 * p_right  : Parent right end$(BR)
 * p_top    : Parent top end$(BR)
 * p_bottom : Parent bottom end$(BR)
 *
 * Params:  x           = X position math expression.
 *                        Default; "p_left"
 *          y           = Y position math expression. 
 *                        Default; "p_top"
 *          width       = Width math expression. 
 *                        Default; "64"
 *          height      = Height math expression. 
 *                        Default; "64"
 *          drawBorder = Draw border of the element?
 *                        Default; true
 * Examples:
 * Example of usage of GUIElementFactory, which is used
 * to construct instances of GUIElement, but the principle is
 * the same for every GUI element class factory.
 *
 * --------------------
 * //Assuming other is some GUI element we already have or root GUI element
 *
 * //construction of a GUI element:
 *
 * GUIElement element;
 *
 * with(new GUIElementFactory)
 * {
 *     x = "p_left + 96";
 *     y = "p_top + 16";
 *     width = "p_right - 192";
 *     height = "p_bottom - 32";
 *     element = produce();
 *     other.addChild(element);
 * }
 *
 *
 * //destruction:
 * other.removeChild(element);
 * element.die();
 * //(alternatively, we could just destroy other, which would also destroy element)
 * --------------------
 */
abstract class GUIElementFactoryBase(T)
{
    mixin(generateFactory(`string $ x           $ "p_left"`, 
                           `string $ y           $ "p_top"`, 
                           `string $ width       $ "64"`, 
                           `string $ height      $ "64"`,
                           `bool   $ drawBorder $ true`));
    private:
        alias std.conv.to to;

    protected:
        ///Return a struct containing factory parameters packaged for GUIElement ctor.
        final GUIElementParams guiElementParams() const
        {
            return GUIElementParams(x_, y_, width_, height_, drawBorder_);
        }

    public:
        /**                                          
         * Set dimensions of the element relative to the parent.
         *
         * Can be used instead of manually specifying x, y, width and height.
         * Works similarly to HTML margin, but only takes the parent to account,
         * NOT the siblings.
         *
         * Params:  top    = Width of top y margin relative to parent top y.
         *          right  = Width of right x margin relative to parent right y.
         *          bottom = Width of bottom y margin relative to parent bottom y.
         *          left   = Width of left y margin relative to parent left y.
         */
        final void margin(in int top, in int right, in int bottom, in int left)
        {
            x      = "p_left + "   ~ to!string(left);
            y      = "p_top + "    ~ to!string(top);
            width  = "p_width - "  ~ to!string(left + right);
            height = "p_height - " ~ to!string(top + bottom);
        }


        ///Return a new instance of the class produced by the factory with parameters of the factory.
        T produce();
}

///GUI element constructor parameters
immutable struct GUIElementParams
{
    private:
        ///Coordinates' math expressions.
        string x, y, width, height;
        ///Draw border of the GUI element?
        bool drawBorder;
}

