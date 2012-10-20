
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Base class for all widgets.
module gui2.widget;


import std.typecons;

import gui2.event;
import gui2.exceptions;
import gui2.guisystem;
import gui2.layout;
import util.yaml;


// TODO:
// - use layouts in widgets (through events),
// - then style, then loading from YAML and testing
// - Try to reuse event objects between frames, just chaning data members.

/// Base class for all widgets.
abstract class Widget
{
private:
    // Reference to the GUI system (for passing global events, etc.).
    GUISystem guiSystem_;
    // Layout of the widget - determines widget size and position.
    Layout layout_;

    // Child widgets of this widget.
    Widget[] children_;

    // Event handlers for each event type.
    //
    // Note: This is an associated array of arrays - pretty expensive.
    // Something more memory efficient/less GC expensive could be used
    // (maybe a single fixed-size array of deleg/classinfo tuples?)
    Flag!"DoneSinking" delegate(Event)[][ClassInfo] eventHandlers_;

public:
    /// Construct a Widget. Contains setup code shared between widget types.
    ///
    /// Params: yaml      = YAML definition of the widget.
    ///         guiSystem = Reference to the GUI system (for passing global events, etc.).
    ///
    /// Throws: WidgetInitException on failure.
    this(ref YAMLNode yaml, GUISystem guiSystem)
    {
        guiSystem_ = guiSystem;
        assert(false, "TODO attributes (?)");
        assert(false, "TODO layout");
        assert(false, "TODO subwidgets");
        registerHandler!MinimizeEvent(&minimizeHandler);
        registerHandler!ExpandEvent(&expandHandler);
    }

protected:
    /// Register an event handler delegate.
    void registerHandler(T)(Flag!"DoneSinking" delegate(T) handler)
        if(is(T: Event))
    {
        eventHandlers_[T.classinfo] ~=
            cast(Flag!"DoneSinking" delegate(Event))handler;
    }

package:
    // Get widget layout - used by other widgets' layouts.
    @property Layout layout() pure nothrow {return layout_;}

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
}