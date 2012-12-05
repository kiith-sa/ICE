
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Style manager that draws widgets as line rectangles.
module gui2.linestylemanager;


import std.algorithm;
import std.array;
import std.exception;

import color;
import gui2.exceptions;
import gui2.stylemanager;
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
        /// Name of the style. Empty for default style.
        string name;
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
        ///         name = Name of the style (empty string for default).
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
    /// Styles must contain the default style (with name "").
    this(ref Style[] styles)
    in
    {
        foreach(i1, ref s1; styles) foreach(i2, ref s2; styles)
        {
            assert(i1 == i2 || s1.name != s2.name, 
                   "Two styles with identical names");
        }
    }
    body
    {
        bool defStyle(ref Style s){return s.name == "";}
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
            bool defStyle(ref Style s){return s.name == "";}
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
        int x;
        // At the moment, Y is always aligned to the center.
        int y = area.center.y - textSize.y / 2;
        final switch(style_.textAlignX) with(AlignX)
        {
            case Left:   x = area.min.x;                     break;
            case Center: x = area.center.x - textSize.x / 2; break;
            case Right:  x = area.max.x - textSize.x;        break;
        }
        video.drawText(Vector2i(x, y), text, style_.fontColor);
    }

protected:
    override Vector2u getTextSize(VideoDriver video, const string text)
    {
        // This could be cached based on text/font/fontSize combination
        video.font     = style_.font;
        video.fontSize = style_.fontSize;
        return video.textSize(text);
    }
}
