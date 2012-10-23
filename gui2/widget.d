
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Base class for all widgets.
module gui2.widget;


import std.algorithm;
import std.typecons;

import gui2.event;
import gui2.exceptions;
import gui2.guisystem;
import gui2.layout;
import gui2.stylemanager;
import util.yaml;
import video.videodriver;

// TODO:
// - RootWidget.get
// - testing (with playerprofile XXX/TODO stuff)
// - user input
// - default/active(mouseOver)/clicked button styles (style, style_active, style_clicked)

/// Base class for all widgets.
abstract class Widget
{
private:
    // Name of the widget. null if no name. 
    string name_;
    // Has widget.init() been called?
    bool initialized_ = false;
    // Event handlers for each event type.
    //
    // Note: This is an associated array of arrays - pretty expensive.
    // Something more memory efficient/less GC expensive could be used
    // (maybe a single fixed-size array of deleg/classinfo tuples?)
    Flag!"DoneSinking" delegate(Event)[][ClassInfo] eventHandlers_;

package:
    // Child widgets of this widget. (Package to be accessible to RootWidget).
    Widget[] children_;

protected:
    // Reference to the GUI system (for passing global events, etc.).
    GUISystem guiSystem_;

    // Layout of the widget - determines widget size and position.
    Layout layout_;

    // Style manager of the widget. Contains styles of this widget and draws it.
    StyleManager styleManager_;

public:
    /// Construct a Widget. Contains setup code shared between widget types.
    ///
    /// Note: a constructed Widget is only fully initialized after a call to init().
    ///
    /// Params: yaml      = YAML definition of the widget.
    ///
    /// Throws: WidgetInitException on failure.
    this(ref YAMLNode yaml)
    {
        addEventHandler!MinimizeEvent(&minimizeHandler);
        addEventHandler!ExpandEvent(&expandHandler);
        addEventHandler!RenderEvent(&renderHandler);
    }

protected:
    /// Register an event handler delegate.
    final void addEventHandler(T)(Flag!"DoneSinking" delegate(T) handler)
        if(is(T: Event))
    {
        eventHandlers_[T.classinfo] ~=
            cast(Flag!"DoneSinking" delegate(Event))handler;
    }

    /// Add a child widget. Does _not_ update GUI layout. Caller needs to handle that.
    final void addChild(Widget child)
    {
        assert(initialized_, "Uninitialized widget: adding a child");
        children_ ~= child;
    }

    /// Remove a child widget. Does _not_ update GUI layout. Caller needs to handle that.
    ///
    /// The given widget must be a child of this widget.
    final void removeChild(Widget child)
    {
        assert(initialized_, "Uninitialized widget: removing a child");
        bool sameWidget(Widget c){return c is child;}
        assert(children_.canFind!sameWidget(), 
               "Trying to remove a widget that is not a child of this widget");
        children_ = children_.remove!sameWidget();
    }

    /// Render the widget with specified video driver.
    void render(VideoDriver video)
    {
        styleManager_.drawWidgetRectangle(video, layout_.bounds);
    }

    /// Called when the widget is fully initialized (at the end of the init() call).
    void postInit()
    {
    }

package:
    // Get widget layout - used by other widgets' layouts.
    @property Layout layout() pure nothrow 
    {
        assert(initialized_, "Uninitialized widget: layout getter");
        return layout_;
    }

    /// Handle an event, possibly propagating it to subwidgets.
    ///
    /// First, this widget handles this event as it's "sinking" down the tree.
    /// Then (unless our handler tells us we're done sinking) we sink it 
    /// further to the children.
    /// After that, we handle the event as it's "bubbling" up. If either this 
    /// widget or any child consumes the event, we return with Yes.DoneSinking.
    /// Then the event will continue to bubble back to the top of the tree, but
    /// won't sink into any other subwidgets.
    final Flag!"DoneSinking" handleEvent(Event e)
    {
        assert(initialized_, "Uninitialized widget: handling an event");
        e.status_ = Event.Status.Sinking;
        // This widget processing the event while sinking
        if(callEventHandler(e)) {return Yes.DoneSinking;}

        // We're done if a child has consumed the event.
        bool done = false;
        // Pass the event to children.
        foreach(child; children_)
        {
            // After being handled by a child, the event bubbles 
            // back here, so we need to set it to sinking for another child.
            e.status_   = Event.Status.Sinking;
            e.sunkFrom_ = this;
            done = done || child.handleEvent(e);
        }

        // This widget processing the event while bubbling (even if we're DoneSinking)
        e.sunkFrom_ = null;
        e.status_   = Event.Status.Bubbling;
        return (callEventHandler(e) || done) ? Yes.DoneSinking : No.DoneSinking;
    }

    /// Initialize the widget with separately constructed members.
    ///
    /// Called by YAML loading code after the widget is constructed.
    /// This must be called for the widget to be usable.
    ///
    /// Params: name         = Name of the widget. null if no name.
    ///         guiSystem    = A reference to the GUI system.
    ///         children     = Child widgets of this widget.
    ///         layout       = Layout of the widget.
    ///         styleManager = StyleManager of the widget.
    final void init(string name, GUISystem guiSystem, Widget[] children, 
                    Layout layout, StyleManager styleManager)
    {
        name_         = name;
        guiSystem_    = guiSystem;
        children_     = children;
        layout_       = layout;
        styleManager_ = styleManager;
        initialized_  = true;
        postInit();
    }

private:
    // Call event handlers for the specified event, if any.
    //
    // Looks for handlers for the exact class of given event first,
    // if none are found, looks for handlers of its parent class, and so on.
    Flag!"DoneSinking" callEventHandler(Event e)
    {
        /// Looking for a handler for the most specialized event class first,
        /// then moving up the class hierarchy.
        for(auto cInfo = e.classinfo; cInfo !is Object.classinfo; cInfo = cInfo.base) 
        {
            auto handlers = cInfo in eventHandlers_;
            if(handlers is null){continue;}
            bool done = false;
            foreach (handler; *handlers)
            {
                done = done || handler(e);
            }
            // Handlers of more specialized classes override less specialized ones.
            return done ? Yes.DoneSinking : No.DoneSinking;
        }
        return No.DoneSinking;
    }

    // Handle a minimize event (minimize the layout when bubbling up).
    Flag!"DoneSinking" minimizeHandler(MinimizeEvent event)
    {
        if(event.status == Event.Status.Bubbling)
        {
            layout_.minimize(children_);
        }
        return No.DoneSinking;
    }

    // Handle an expand event (expand the layout when bubbling up).
    Flag!"DoneSinking" expandHandler(ExpandEvent event)
    {
        if(event.status == Event.Status.Sinking)
        {
            layout_.expand(event.sunkFrom);
        }
        return No.DoneSinking;
    }

    // Handle a render event.
    Flag!"DoneSinking" renderHandler(RenderEvent event)
    {
        // First draw the topmost widgets, then its children, etc.
        if(event.status == Event.Status.Sinking)
        {
            render(event.videoDriver);
        }
        return No.DoneSinking;
    }
}
