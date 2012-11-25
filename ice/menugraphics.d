//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module ice.menugraphics;


import std.typecons;

import color;
import ice.graphicseffect;
import math.vector2;
import math.rect;
import video.videodriver;
import time.time;


/// Various graphics effects drawn when the main menu is displayed.
class MenuGraphics 
{
private:
    /// Manages graphics effects like the lines drawn in background.
    GraphicsEffectManager effectManager_;

public:
    /// Construct menu graphics.
    this()
    {
        // Initialize graphics effects.

        // Small background lines.
        effectManager_ = new GraphicsEffectManager();
        auto smallLines = new RandomLinesEffect(getTime(),
        (const real startTime, const real currentTime,
         ref RandomLinesEffect.Parameters params)
        {
            params.bounds   = Rectf(16, 16, 800 - 16, 600 - 16);
            params.minWidth = 0.225;
            params.maxWidth = 0.9;
            //This speed ensures we always see completely random lines.
            params.verticalScrollingSpeed = 225.0f;
            //Full screen width.
            params.minLength = 3.0f;
            params.maxLength = 12.0f;
            params.detailLevel = 1;
            params.linesPerPixel = 0.005;
            params.color = rgba!"D8D8FF18";
            return false;
        });
        // Larger, less frequent lines.
        auto largeLines = new RandomLinesEffect(getTime(),
        (const real startTime, const real currentTime,
         ref RandomLinesEffect.Parameters params)
        {
            params.bounds   = Rectf(0, 0, 800, 600);
            params.minWidth = 0.6;
            params.maxWidth = 1.0;
            //This speed ensures we always see completely random lines.
            params.verticalScrollingSpeed = 1200.0f;
            //Full screen width.
            params.minLength = 12.0f;
            params.maxLength = 24.0f;
            params.detailLevel = 3;
            params.linesPerPixel = 0.000004;
            params.color = rgba!"F8F8EC98";
            return false;
        });

        // Scrolling text in the background.
        auto scrollingText = new ScrollingTextLinesEffect(getTime(),
        (const real startTime, const real currentTime,
         ref ScrollingTextLinesEffect.Parameters params)
        {
            params.lineStrings       = 
            [
              "1",
              "2",
              "3",
              "4",
              "5",
              "6",
              "7",
              "8",
              "9",
              "10"
            ];
            params.randomOrder    = Yes.randomOrder;
            params.position       = Vector2i(16, -16);
            params.scrollingSpeed = -100.0f;
            params.fontColor      = rgba!"E8E8FF48";
            params.fontSize       = 12;
            params.randomOrder    = Yes.randomOrder;
            params.font           = "orbitron-bold.ttf";
            params.lineCount      = 48;
            return false;
        });
        effectManager_.addEffect(smallLines);
        effectManager_.addEffect(largeLines);
        effectManager_.addEffect(scrollingText);
    }

    /// Deinitialize menu graphics.
    ~this()
    {
        clear(effectManager_);
    }

    /// Draw the menu graphics.
    void draw(VideoDriver video)
    {
        effectManager_.draw(video, getTime());

        // Draw the "ICE" background text and version info.
        video.font = "orbitron-bold.ttf";
        video.fontSize = 128;
        string text = "ICE";
        const size = video.textSize(text);
        const position = Vector2i(312 - size.x / 2, 300 - size.y / 2 - 16);
        video.drawText(position, text, rgba!"FFFFFFA0");
        video.fontSize = 24;
        video.drawText(position + size.to!int, "v 0.1", rgba!"FFFFFFA0");
    }
}

