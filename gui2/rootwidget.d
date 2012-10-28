
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Root widget of a widget tree loadable from YAML.
module gui2.rootwidget;


import std.exception;

import math.rect;
import math.vector2;

import gui2.exceptions;
import gui2.guisystem;
import gui2.widget;
import gui2.widgetutils;
import util.yaml;

/// Uses opDispatch to build widget name strings to access widgets in a RootWidget.
struct WidgetAccess
{
private:
    /// RootWidget that constructed this WidgetAccess.
    RootWidget root_;
    //TODO recycle strings to avoid excessive per-frame allocation.
    /// Name of the widget to access.
    string name_;

public:
    /// Access a subwidget.
    ///
    /// If a type is specified by the user, this is the last subwidget 
    /// and we return that subwidget. Otherwise we return a WidgetAccess 
    /// for that subwidget, allowing to access its subwidgets.
    template opDispatch(string childName)
        if(validWidgetName(childName))
    {
        T opDispatch(T = WidgetAccess)() 
            if(is(T:Widget) || is(T == WidgetAccess))
        {
            static if(is(T == WidgetAccess))
            {
                return WidgetAccess(this, _fullName(childName));
            }
            else
            {
                return root_.get!T(this, _fullName(childName)); 
            }
        } 
    }

private:
    // No independent construction or copying.
    @disable this();
    @disable this(this);
    @disable void opAssign(ref WidgetAccess);

    /// Construct a WidgetAccess (done by the RootWidget).
    this(RootWidget root)
    {
        root_ = root;
        name_ = null;
    }

    /// Construct a WidgetAccess accessing a subwidget in a parent WidgetAccess.
    this(ref WidgetAccess parent, const string name)
    {
        name_ = name;
        root_ = parent.root_; 
    }

    /// Get the full name of a child widget with specified name.
    string _fullName(const string childName) pure const
    {
        return name_ is null ? childName : name_ ~ "." ~ childName;
    }
}

/// Root widget of a widget tree loadable from YAML.
///
/// Root widget is not the top of a widget hierarchy;
/// it is the root of a group of widget loaded from YAML, and can be
/// connected to a SlotWidget (such as the rootSlot widget in GUISystem).
/// Widget tree under a RootWidget can also contain more SlotWidgets 
/// where other RootWidgets can be connected.
///
/// A RootWidget is used to access all widgets in its tree;
/// other widgets can't do this. opDispatch is used to do this 
/// so widget names used in YAML can be used directly in code.
///
/// For example, if a widget tree contains a button widget called "bar"
/// that has no named parent widget, it can be accessed 
/// as rootWidget.bar!ButtonWidget (where rootWidget is the RootWidget).
/// If "bar" has a named parent "foo", change that to 
/// rootWidget.foo.bar!ButtonWidget .
class RootWidget: Widget
{
private:
    /// Builtin WidgetAccess to access direct subwidgets.
    WidgetAccess widgetAccess_ = WidgetAccess(cast(RootWidget)null);

    /// Maps widget addresses to widgets in the tree of this RootWidget.
    ///
    /// Doesn't include widgets in any RootWidget below this widget.
    Widget[string] addressToWidget_;
public:
    /// Load a RootWidget from YAML.
    ///
    /// Never call this directly; use GUISystem.loadWidgetTree instead.
    this(ref YAMLNode yaml)
    {
        widgetAccess_.root_ = this;
        super(yaml);
    }

    /// Access a subwidget.
    ///
    /// This is copied from WidgetAccess as alias this doesn't work.
    ///
    /// Throws: WidgetNotFoundException if the widget could not be found.
    ///         WidgetTypeException if the widget is not of type T.
    ///
    /// SeeAlso: WidgetAccess.opDispatch
    template opDispatch(string childName)
        if(validWidgetName(childName))
    {
        T opDispatch(T = WidgetAccess)() 
            if(is(T: Widget) || is(T == WidgetAccess))
        {
            static if(is(T == WidgetAccess))
            {
                return WidgetAccess(widgetAccess_, widgetAccess_._fullName(childName));
            }
            else
            {
                return widgetAccess_.root_.get!T(widgetAccess_._fullName(childName)); 
            }
        } 
    }

    /// Get a subwidget with specified name.
    ///
    /// Throws: WidgetNotFoundException if the widget could not be found.
    ///         WidgetTypeException if the widget is not of type T.
    T get(T)(const string fullName)
    {
        assert(validComposedWidgetName(name),
               "Trying to get a widget with invalid name: " ~ name);

        Widget* result = fullName in addressToWidget_;
        enforce(result !is null,
                new WidgetNotFoundException("Widget \"" ~ fullName ~ "\" could not be found"));
        T typedResult = cast(T)(*result);
        enforce(typedResult !is null,
                new WidgetTypeException
                ("Widget \"" ~ fullName ~ "\" has an unexpected type. Expected " ~ T.stringof));
        return typedResult;
    }

protected:
    override void postInit()
    {
        // Recursively generate addressToWidget_
        void widgetAddresses(Widget widget, string parentAddress)
        {
            foreach(child; widget.children_)
            {
                // Ignore unnamed widgets.
                // (widget.UNNAMED.subwidget is widget.subwidget)
                if(child.name is null)
                {
                    widgetAddresses(child, parentAddress);
                }
                else
                {
                    // Using slicing to limit allocation.
                    auto childName = parentAddress ~ child.name ~ ".";
                    addressToWidget_[childName[0 .. $ - 1]] = child;
                    widgetAddresses(child, childName);
                }
            }
        }
        widgetAddresses(this, "");
    }

package:
    /// Force the widgets in the tree to react as if the mouse disappeared.
    ///
    /// Called when disconnected from a SlotWidget.
    void mouseLeftTree()
    {
        void checkMouseOver(Widget widget)
        {
            if(widget.layout.bounds.intersect(guiSystem_.mousePosition.to!int))
            {
                widget.mouseLeft();
            }
            foreach(child; widget.children_)
            {
                checkMouseOver(child);
            }
        }
        checkMouseOver(this);
    }

    /// Force the widgets in the tree to react as if the mouse just appeared.
    ///
    /// Called when connected to a SlotWidget.
    void checkMouseEnteredTree()
    {
        void checkMouseEntered(Widget widget)
        {
            if(widget.layout.bounds.intersect(guiSystem_.mousePosition.to!int))
            {
                widget.mouseEntered();
            }
            foreach(child; widget.children_)
            {
                checkMouseEntered(child);
            }
        }
        checkMouseEntered(this);
    }
}
