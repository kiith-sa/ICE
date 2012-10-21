
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// A layout where widget extents are determined manually using math expressions.
module gui2.boxmanuallayout;


import std.stdio;

import gui2.layout;
import gui2.widget;
import gui2.widgetutils;
import math.rect;
import math.vector2;
import formats.mathparser;
import util.yaml;


/// A layout where widget extents are determined manually using math expressions.
///
/// Position and size of the widgets are defined by math expressions which
/// contain parent widgets' extents as variables.
class BoxManualLayout : Layout
{
private:
    /// Math expression used to calculate X position of the widget.
    string xExp_;
    /// Math expression used to calculate Y position of the widget.
    string yExp_;
    /// Math expression used to calculate width of the widget.
    string wExp_;
    /// Math expression used to calculate height of the widget.
    string hExp_;

public:
    /// Construct a BoxManualLayout from YAML.
    this(ref YAMLNode yaml)
    {
        xExp_ = layoutInitProperty!string(yaml, "x");
        yExp_ = layoutInitProperty!string(yaml, "y");
        wExp_ = layoutInitProperty!string(yaml, "w");
        hExp_ = layoutInitProperty!string(yaml, "h");
    }

    override void minimize(Widget[] children)
    {
        // Empty, BoxManualLayout computes dimensions relative to parent
    }

    override void expand(Widget parent)
    {
        const parentBounds = getLayout(parent).bounds;

        //Substitutions for window and parents' coordinates.
        static int[string] substitutions;
        substitutions["pLeft"]   = parentBounds.min.x;
        substitutions["pRight"]  = parentBounds.max.x;
        substitutions["pTop"]    = parentBounds.min.y;
        substitutions["pBottom"] = parentBounds.max.y;
        substitutions["pWidth"]  = parentBounds.width;
        substitutions["pHeight"] = parentBounds.height;

        int width, height;

        // Fallback to fixed dimensions to avoid complicated exception resolution.
        void fallback()
        {
            width = height = 64;
            writeln("Widget layout falling back to fixed dimensions: 64x64");
        }

        try
        {
            bounds_.min = Vector2i(parseMath(xExp_, substitutions), 
                                   parseMath(yExp_, substitutions));

            width  = parseMath(wExp_, substitutions);
            height = parseMath(hExp_, substitutions);

            if(height < 0 || width < 0)
            {
                writeln("Negative width and/or height of a widget! "   
                        "Probably caused by incorrect layout math expressions.");
                fallback();
            }
        }
        catch(MathParserException e)
        {
            writeln("Invalid widget layout math expression.");
            writeln(e.msg);
            fallback();
        }

        bounds_.max = bounds_.min + Vector2i(width, height);
    }
}
