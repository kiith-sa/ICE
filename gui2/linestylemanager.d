
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Style manager that draws widgets as line rectangles.
module gui2.linestylemanager;


import std.algorithm;
import std.array;
import std.conv;
import std.exception;

import color;
import gui2.exceptions;
import gui2.stylemanager;
import gui2.textbreaker;
import gui2.widgetutils;
import math.rect;
import math.vector2;
import video.texture;
import video.videodriver;
import util.resourcemanager;
import util.yaml;


/// Style manager that draws widgets as line rectangles.
///
/// Widgets with this style manager have a colored (usually transparent) background, 
/// with a border made of lines. This is the most basic style manager - 
/// it's a placeholder before something more elaborate is implemented.
class LineStyleManager: StyleManager
{
public:
    /// LineStyleManager style.
    struct Style
    {
        /// Style of the progress "bar".
        enum ProgressStyle
        {
            Horizontal,
            Vertical
        }
        /// Name of the style. "default" for default style.
        string name           = "default";
        /// Font used to draw text.
        string font           = "default";
        /// Color of widget border.
        Color borderColor     = rgba!"FFFFFF60";
        /// Background color.
        Color backgroundColor = rgba!"00000000";
        /// Color of font used to draw text.
        Color fontColor       = rgba!"FFFFFF60";
        /// Color of the filled part of the progress bar.
        Color progressColor   = rgba!"8080FF80";
        /// Font size in points.
        uint fontSize         = 12;
        /// Gap between text lines in pixels.
        uint lineGap          = 2;
        /// Draw border of the widget?
        bool drawBorder       = true;
        /// Style of the progress "bar".
        ProgressStyle progressStyle;
        /// Does this style have a background image?
        bool hasBackgroundTexture = false;
        /// If hasBackgroundTexture is true, used to access the background texture.
        ResourceID!Texture backgroundTexture;
        /// X alignment of any text drawn in the widget.
        AlignX textAlignX = AlignX.Center;

        /// Construct a LineStyleManager style.
        ///
        /// Params: yaml = YAML to load the style from.
        ///         name = Name of the style.
        ///
        /// Throws: StyleInitException on error.
        this(ref YAMLNode yaml, string name)
        {
            this.name       = name;
            drawBorder      = styleInitPropertyOpt(yaml, "drawBorder",      drawBorder);
            borderColor     = styleInitPropertyOpt(yaml, "borderColor",     borderColor);
            backgroundColor = styleInitPropertyOpt(yaml, "backgroundColor", backgroundColor);
            fontColor       = styleInitPropertyOpt(yaml, "fontColor",       fontColor);
            progressColor   = styleInitPropertyOpt(yaml, "progressColor",   progressColor);
            font            = styleInitPropertyOpt(yaml, "font",            font);
            fontSize        = styleInitPropertyOpt(yaml, "fontSize",        fontSize);
            lineGap         = styleInitPropertyOpt(yaml, "lineGap",         lineGap);

            auto textAlignXStr = styleInitPropertyOpt(yaml, "textAlignX", "center");
            switch(textAlignXStr)
            {
                case "right":  textAlignX = AlignX.Right;  break;
                case "left":   textAlignX = AlignX.Left;   break;
                case "center": textAlignX = AlignX.Center; break;
                default: 
                    throw new StyleInitException("Unsupported X alignment: " ~ textAlignXStr);
            }

            const backgroundImage = styleInitPropertyOpt(yaml, "backgroundImage", cast(string)null);
            if(backgroundImage !is null)
            {
                hasBackgroundTexture = true;
                backgroundTexture = ResourceID!Texture(backgroundImage);
            }
            const progressStyleString = 
                styleInitPropertyOpt(yaml, "progressStyle", "horizontal");
            enforce(["horizontal", "vertical"].canFind(progressStyleString),
                    new StyleInitException("Unknown progress style " ~ progressStyleString));
            switch(progressStyleString)
            {
                case "horizontal": progressStyle = ProgressStyle.Horizontal; break;
                case "vertical":   progressStyle = ProgressStyle.Vertical;   break;
                default: assert(false);
            }
        }
    }

private:
    // Styles managed (e.g. default, mouse over, etc.)
    Style[] styles_;
    // Currently used style.
    Style style_;

public:
    /// Construct a LineStyleManager with specified styles.
    ///
    /// Styles must contain the default style (with name "default").
    this(ref Style[] styles)
    in
    {
        foreach(i1, ref s1; styles) foreach(i2, ref s2; styles)
        {
            assert(i1 == i2 || s1.name != s2.name, 
                   "Two styles with identical names: \"" ~ s1.name ~ "\"");
        }
    }
    body
    {
        bool defStyle(ref Style s){return s.name == "default";}
        auto searchResult = styles.find!defStyle();
        assert(!searchResult.empty,
               "Trying to construct a LineStyleManager without a default style");
        style_  = searchResult.front;
        styles_ = styles;
    }

    override void setStyle(string name)
    {
        bool matchingStyle(ref Style s){return s.name == name;}
        auto findResult = find!matchingStyle(styles_);
        if(findResult.empty)
        {
            bool defStyle(ref Style s){return s.name == "default";}
            style_ = styles_.find!defStyle().front;
            return;
        }
        style_ = findResult.front;
    }

    override void drawWidgetRectangle(VideoDriver video, ref const Recti area)
    {
        const min = area.min.to!float;
        const max = area.max.to!float;
        if(style_.hasBackgroundTexture)
        {
            video.drawTexture
                (area.min, *(textureManager_.getResource(style_.backgroundTexture)));
        }
        video.drawFilledRect(area.min.to!float, area.max.to!float, style_.backgroundColor);
        if(!style_.drawBorder){return;}
        video.drawRect(area.min.to!float, area.max.to!float, style_.borderColor);
    }

    override void drawProgress
        (VideoDriver video, const float progress, ref const Recti area)
    {
        assert(progress >= 0.0f && progress <= 1.0f, "Progress out of range");

        auto min     = area.min.to!float + Vector2f(0.0f, 1.0f);
        auto max     = area.max.to!float - Vector2f(1.0f, 1.0f);
        final switch(style_.progressStyle) with(Style.ProgressStyle)
        {
            case Horizontal: max = Vector2f(min.x + progress * area.width, max.y);  break;
            case Vertical:   min = Vector2f(min.x, max.y - progress * area.height); break;
        }
        video.drawFilledRect(min, max, style_.progressColor);
    }

    override void drawText(VideoDriver video, const string text, ref const Recti area)
    {
        video.font     = style_.font;
        video.fontSize = style_.fontSize;

        const textSize = getTextSize(video, text);
        if(textSize.x > area.width)
        {
            drawTextMultiLine(video, text, area);
            return;
        }
        // At the moment, Y is always aligned to the center.
        int y = area.center.y - textSize.y / 2;
        int x = xTextPosition(area, textSize.x);
        video.drawText(Vector2i(x, y), text, style_.fontColor);
    }

private:
    // Draw text wider than the widget, breaking it into multiple lines.
    // 
    // VideoDriver font and font size are expected to be set already.
    //
    // Params:  video = VideoDriver to draw with.
    //          text  = Text to draw.
    //          area  = Area taken up by the text.
    void drawTextMultiLine(VideoDriver video, const string text, ref const Recti area)
    {
        // Determines if passed text is plain ASCII.
        bool asciiText(const string text)
        {
            foreach(dchar c; text) if(cast(uint) c > 127)
            {
                return false;
            }
            return true;
        }

        // Draws passed text, breaking it into lines to fit into the widget area.
        //
        // One code unit is always one character in this function.
        void drawBrokenText(S)(S text)
        {
            Vector2u textSizeWrap(S line)
            {
                return getTextSize(video, line);
            }

            // Break the text into lines.
            static TextBreaker!S breaker;
            breaker.parse(text, cast(uint)area.width, &textSizeWrap);
            if(breaker.lines.empty){return;}

            // Use the maximum line height of all lines in the text.
            uint lineGap = style_.lineGap;
            int lineHeight = 0;
            foreach(size; breaker.lineSizes) {lineHeight = max(lineHeight, size.y);}
            lineHeight += lineGap;

            int textHeight = 
                cast(int)((lineHeight + lineGap) * breaker.lines.length - lineGap);

            // At the moment, Y is always aligned to the center.
            int y = area.center.y - textHeight / 2;

            // Draw the lines.
            foreach(l, line; breaker.lines)
            {
                const width = breaker.lineSizes[l].x;
                const pos   = Vector2i(xTextPosition(area, width), y);
                const color = style_.fontColor;
                static if(is(T == string)) {video.drawText(pos, line, color);}
                else                       {video.drawText(pos, to!string(line), color);}
                y += lineHeight + lineGap;
            }
        }

        // Draw the text.
        if(!asciiText(text))
        {
            // To use slicing, we need one code point to be one character,
            // so convert to UTF-32 if we're not ASCII.
            auto text32 = to!dstring(text);
            drawBrokenText(text32);
            return;
        }
        drawBrokenText(text);
    }

    // Get the size of specified text when drawn on the screen.
    Vector2u getTextSize(S)(VideoDriver video, const S text)
    {
        // This could be cached based on text/font/fontSize combination
        video.font     = style_.font;
        video.fontSize = style_.fontSize;
        static if(is(S == string)) {return video.textSize(text);}
        else                       {return video.textSize(to!string(text));}
    }

    // Get X position of a text (using alignment).
    //
    // Params:  area = Area of the widget we're drawing text in.
    //          textWidth = Width of the text in pixels
    //
    // Returns: X position of the text (i.e. its left edge).
    int xTextPosition(ref const Recti area, const uint textWidth) @safe pure nothrow
    {
        final switch(style_.textAlignX) with(AlignX)
        {
            case Left:   return area.min.x;
            case Center: return area.center.x - textWidth / 2;
            case Right:  return area.max.x - textWidth;
        }
    }
}
