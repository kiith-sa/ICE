
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Video driver base class.
module video.videodriver;


import std.conv;
import std.math;

import video.texture;
import video.fontmanager;
import math.math;
import math.vector2;
import math.rect;
import platform.platform;
import monitor.monitordata;
import monitor.monitorable;
import util.weaksingleton;
import color;
import image;


///Exception thrown at video driver related errors.
class VideoDriverException : Exception{this(string msg){super(msg);}} 

/**
 * Video driver draw modes. 
 *
 * Implementations do not need to support all draw modes,
 * but must support at least one and be able to fall back to
 * a supported draw mode.
 */
enum DrawMode
{
    ///Draws are merged into buffers stored in RAM and applied together.
    RAMBuffers,
    ///Draws are merged into buffers stored in video RAM and applied together.
    VRAMBuffers
}

///Handles all drawing functionality.
abstract class VideoDriver : Monitorable
{
    mixin WeakSingleton;
    protected:
        ///FontManager used to work with fonts.
        FontManager fontManager_;

    public:
        /**
         * Construct a VideoDriver.
         *
         * Params:  fontManager = Font manager to use for font rendering and management.
         */
        this(FontManager fontManager)
        {
            singletonCtor();
            fontManager_ = fontManager;
        }

        ///Destroy the VideoDriver.
        ~this()
        {
            import std.stdio;
            writeln("Destroying VideoDriver");
            singletonDtor();
        }

        /**
         * Sets video mode.
         *
         * Params:  width      = Video mode width in pixels;
         *          height     = Video mode height in pixels;
         *          format     = Video mode color format.
         *          fullscreen = If true, use fullscreen, otherwise windowed.
         *
         * Throws: VideoDriverException on failure.   
         */ 
        void setVideoMode(const uint width, const uint height, 
                            const ColorFormat format, const bool fullscreen);

        /**
         * Start drawing a frame. 
         *
         * Frame must not already be in progress. 
         * Must be called before any draw calls.
         */
        void startFrame();

        ///Finish drawing a frame. Must be called after startFrame.
        void endFrame();

        /**
         * Enable scissor test using specified rectangle as scissor area.
         *
         * Until the scissor test is disabled, only specified area of the screen
         * will be drawn to. This can be used e.g. for 2D clipping of GUI elements.
         *
         * Can only be called between startFrame and endFrame.
         *
         * Params:  scissorArea = Scissor area in screen coordinates.
         */
        void scissor(const ref Recti scissorArea);

        /**
         * Disable scissor test.
         *
         * Can only be called between startFrame and endFrame.
         */
        void disableScissor();

        /**
         * Draw a line between specified points with specified colors.
         *
         * Colors are interpolated from start to end of the line.
         *
         * Can only be called between startFrame and endFrame.
         *
         * Params:  v1 = Start point of the line.
         *          v2 = End point of the line.
         *          c1 = Color at the start point.
         *          c2 = Color at the end point.
         */
        void drawLine(const Vector2f v1, const Vector2f v2, const Color c1, const Color c2);

        /**
         * Draw a line strip through specified points with specified colors.
         *
         * Can only be called between startFrame and endFrame.
         *
         * Params:  v = Vertices of the strip.
         *          c = Colors of the vertices.
         */
        void drawLineStrip(const Vector2f[] v, const Color c)
        in{assert(v.length >= 2, "Must have at least 2 vertices to draw a line strip");}
        body
        {
            Vector2f start = v[0];
            foreach(const Vector2f end; v[1 .. $])
            {
                drawLine(start, end, c, c);
                start = end;
            }
        }

        /**
         * Draw a stroked circle.
         *
         * Can only be called between startFrame and endFrame.
         *
         * Params:  center       = Center of the circle.
         *          radius       = Radius of the circle.
         *          color        = Color of the circle stroke.
         *          vertexCount = Number of vertices in the circle.
         */
        void drawCircle(const Vector2f center, const float radius, const Color color,
                         const uint vertexCount = 32)
        in
        {
            assert(radius >= 0, "Can't draw a circle with negative radius");
            assert(vertexCount >= 3, "Can't draw a circle with less than 3 vertices");
            assert(vertexCount <= 8192, "Can't draw a circle with such absurd number of "
                                         "vertices (more than 8192)");
        }
        body
        {
            //this could be optimized by:
            //1:lookup tables (fixes function overhead)
            //2:line loop in implementation (fixes OpenGL call overhead)
            //3:single high-detail VBO for all circles in implementation (-||-)
            //4:using a textured quad with a custom shader (fixes vertex count overhead)

            //The first vertex is right above center. 
            Vector2f lineStart = center + Vector2f(radius, 0);
            Vector2f lineEnd; 
            //angle per vertex
            const vertexAngle = 2 * PI / vertexCount;
            //total angle of current vertex
            float angle = 0;
            foreach(vertex; 0 .. vertexCount)
            {
                angle      += vertexAngle;
                lineEnd.x = center.x + radius * cos(angle); 
                lineEnd.y = center.y + radius * sin(angle); 
                drawLine(lineStart, lineEnd, color, color);
                lineStart = lineEnd;
            }
        }

        /**
         * Draw a stroked rectangle.
         *
         * Can only be called between startFrame and endFrame.
         *
         * Params:  min   = Minimum extents of the rectangle.
         *          max   = Maximum extents of the rectangle.
         *          color = Color of the rectangle stroke.
         */
        void drawRect(const Vector2f min, const Vector2f max, const Color color)
        in
        {
            assert(min.x <= max.x && min.y <= max.y, 
                  "Can't draw a rectangle with min bounds greater than max\n"
                  "min: " ~ to!string(min) ~ "\nmax: " ~ to!string(max));
        }
        body
        {
            //this could be optimized by:
            //1:line loop in implementation(fixes OpenGL call overhead)
            //2:using a textured quad with a custom shader (fixes vertex count overhead)
            const maxMin = Vector2f(max.x, min.y);
            const minMax = Vector2f(min.x, max.y);
            drawLine(max, maxMin, color, color);
            drawLine(maxMin, min, color, color);
            drawLine(min, minMax, color, color);
            drawLine(minMax, max, color, color);
        }

        /**
         * Draw a filled rectangle.
         *
         * Can only be called between startFrame and endFrame.
         *
         * Params:  min   = Minimum extents of the rectangle.
         *          max   = Maximum extents of the rectangle.
         *          color = Color of the rectangle.
         */
        void drawFilledRect(const Vector2f min, const Vector2f max, const Color color);

        /**
         * Draw a texture.
         *
         * Can only be called between startFrame and endFrame.
         *
         * Params:  position = Position of the upper-left corner of the texture.
         *          texture  = Texture to draw.
         */
        void drawTexture(const Vector2i position, const ref Texture texture);
        
        /**
         * Draw a text string.
         *
         * Can only be called between startFrame and endFrame.
         *
         * Params:  position = Position to draw the text at.
         *          text     = Text to draw.
         *          color    = Text color.
         */
        void drawText(const Vector2i position, const string text, const Color color = Color.white);

        /**
         * Set draw mode.
         *
         * Not all implementations support all draw modes. If specified
         * draw mode is not supported, video driver falls back to a supported
         * draw mode. Draw mode actually applied is returned.
         *
         * Must not be called between calls to startFrame and endFrame.
         *
         * Params:  mode = Draw mode to set.
         *
         * Returns: Draw mode that was actually set.
         */
        DrawMode drawMode(const DrawMode mode);
        
        /**
         * Get the size a text string would have if it was drawn.
         *
         * Params:  text = Text to measure.
         *
         * Returns: Size of the text in pixels.
         */
        Vector2u textSize(const string text);

        ///Set line antialiasing.
        @property void lineAA(const bool aa);
        
        ///Set line width.
        @property void lineWidth(const float width);
        
        ///Set font to draw text with. If fontName is "default", default font will be used.
        @property void font(const string fontName);

        ///Set font size to draw text with.
        @property void fontSize(const uint size);
        
        ///Set view zoom.
        @property void zoom(const real zoom);
        
        ///Get view zoom.
        @property real zoom() const;

        ///Set view offset.
        @property void viewOffset(const Vector2d offset);

        ///Get view offset.
        @property Vector2d viewOffset() const;

        ///Get screen width.
        @property uint screenWidth() const;

        ///Get screen height.
        @property uint screenHeight() const;

        /**
         * Get maximum square texture size supported with specified color format.
         *
         * Params:  format = Texture color format.
         *
         * Returns: Maximum square texture size supported with specified color format.
         */
        uint maxTextureSize(const ColorFormat format) const;

        /**
         * Create a texture from given image.
         *
         * Params:  image      = Image to create a texture from.
         *          forcePage = Force the texture to be on a separate texture page?
         *
         * Returns: Handle to the created texture.
         *
         * Throws:  TextureException if texture of needed size could not be created.
         */
        Texture createTexture(const ref Image image, const bool forcePage = false);

        /**
         * Delete a texture.
         *
         * If deleted during a frame, this texture must not be used in drawing in that
         * frame.
         */
        void deleteTexture(const Texture texture);

        /**
         * Capture a screenshot. Can't be called during an update.
         *
         * Must not be called between calls to startFrame and endFrame.
         *
         * Params:  image = Image to save screenshot to. Dimensions of the screenshot
         *                  will correspond to the image.
         */
        void screenshot(ref Image image);

        @property MonitorDataInterface monitorData()
        {
            //This exists due to what appears to be a linker bug - linker
            //doesn't work if this is not implemented even for abstract class
            //(even though it's overriden by child)
            assert(false);
        }
}
