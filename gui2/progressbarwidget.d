
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Simple progressbar widget.
module gui2.progressbarwidget;


import std.stdio;
import std.typecons;

import gui2.event;
import gui2.guisystem;
import gui2.layout;
import gui2.stylemanager;
import gui2.widget;
import gui2.widgetutils;
import math.math;
import math.vector2;
import platform.key;
import util.signal;
import util.yaml;
import video.videodriver;


/// Simple progressbar widget.
class ProgressBarWidget: Widget
{
private:
    // Current progress, between 0 and 1.
    float progress_;

public:
    /// Load a ProgressBarWidget from YAML.
    ///
    /// Do not call directly.
    this(ref YAMLNode yaml)
    {
        progress_ = widgetInitProperty!float(yaml, "progress");
        if(progress_ < 0.0f || progress > 1.0f)
        {
            writeln("WARNING: ProgressBar progress out of range - must be between 1 and 0.\n"
                    "Closest possible value will be used.");
        }
        progress_ = clamp(progress_, 0.0f, 1.0f);
        focusable_ = false;
        super(yaml);
    }

    override void render(VideoDriver video)
    {
        styleManager_.drawProgress(video, progress_, layout_.bounds);
        super.render(video);
    }

    /// Get current progress.
    @property float progress() const pure nothrow {return progress_;}

    /// Set current progress.
    @property void progress(float rhs) pure nothrow 
    {
        assert(rhs >= 0.0f && rhs <= 1.0f, 
               "Trying to set progress outside of <0.0, 1.0>");
        progress_ = rhs;
    }
}

