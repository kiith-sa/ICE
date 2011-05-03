
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


module video.videodriver;
@trusted


import std.math;

import video.texture;
import video.fontmanager;
import math.math;
import math.vector2;
import math.rectangle;
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
    ///Each draw is applied separately.
    Immediate,
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
        FontManager font_manager_;

    public:
        /**
         * Construct a VideoDriver.
         *
         * Params:  font_manager = Font manager to use for font rendering and management.
         */
        this(FontManager font_manager)
        {
            singleton_ctor();
            font_manager_ = font_manager;
        }

        ~this(){}

        ///Destroy the VideoDriver.
        void die(){singleton_dtor();}

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
        void set_video_mode(in uint width, in uint height, 
                            in ColorFormat format, in bool fullscreen);

        /**
         * Start drawing a frame. 
         *
         * Frame must not already be in progress. 
         * Must be called before any draw calls.
         */
        void start_frame();

        ///Finish drawing a frame. Must be called after start_frame.
        void end_frame();

        /**
         * Enable scissor test using specified rectangle as scissor area.
         *
         * Until the scissor test is disabled, only specified area of the screen
         * will be drawn to. This can be used e.g. for 2D clipping of GUI elements.
         *
         * Can only be called between start_frame and end_frame.
         *
         * Params:  scissor_area = Scissor area in screen coordinates.
         */
        void scissor(const ref Rectanglei scissor_area);

        /**
         * Disable scissor test.
         *
         * Can only be called between start_frame and end_frame.
         */
        void disable_scissor();

        /**
         * Draw a line between specified points with specified colors.
         *
         * Colors are interpolated from start to end of the line.
         *
         * Can only be called between start_frame and end_frame.
         *
         * Params:  v1 = Start point of the line.
         *          v2 = End point of the line.
         *          c1 = Color at the start point.
         *          c2 = Color at the end point.
         */
        void draw_line(in Vector2f v1, in Vector2f v2, in Color c1, in Color c2);

        /**
         * Draw a line strip through specified points with specified colors.
         *
         * Can only be called between start_frame and end_frame.
         *
         * Params:  v = Vertices of the strip.
         *          c = Colors of the vertices.
         */
        void draw_line_strip(in Vector2f[] v, in Color c)
        in{assert(v.length >= 2, "Must have at least 2 vertices to draw a line strip");}
        body
        {
            Vector2f start = v[0];
            foreach(const Vector2f end; v[1 .. $])
            {
                draw_line(start, end, c, c);
                start = end;
            }
        }

        /**
         * Draw a stroked circle.
         *
         * Can only be called between start_frame and end_frame.
         *
         * Params:  center       = Center of the circle.
         *          radius       = Radius of the circle.
         *          color        = Color of the circle stroke.
         *          vertex_count = Number of vertices in the circle.
         */
        void draw_circle(in Vector2f center, in float radius, in Color color,
                         in uint vertex_count = 32)
        in
        {
            assert(radius >= 0, "Can't draw a circle with negative radius");
            assert(vertex_count >= 3, "Can't draw a circle with less than 3 vertices");
            assert(vertex_count <= 8192, "Can't draw a circle with such absurd number of "
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
            Vector2f line_start = center + Vector2f(radius, 0);
            Vector2f line_end; 
            //angle per vertex
            const vertex_angle = 2 * PI / vertex_count;
            //total angle of current vertex
            float angle = 0;
            for(uint vertex = 0; vertex < vertex_count; ++vertex)
            {
                angle += vertex_angle;
                line_end.x = center.x + radius * cos(angle); 
                line_end.y = center.y + radius * sin(angle); 
                draw_line(line_start, line_end, color, color);
                line_start = line_end;
            }
        }

        /**
         * Draw a stroked rectangle.
         *
         * Can only be called between start_frame and end_frame.
         *
         * Params:  min   = Minimum extents of the rectangle.
         *          max   = Maximum extents of the rectangle.
         *          color = Color of the rectangle stroke.
         */
        void draw_rectangle(in Vector2f min, in Vector2f max, in Color color)
        in
        {
            assert(min.x <= max.x && min.y <= max.y, 
                  "Can't draw a rectangle with min bounds greater than max");
        }
        body
        {
            //this could be optimized by:
            //1:line loop in implementation(fixes OpenGL call overhead)
            //2:using a textured quad with a custom shader (fixes vertex count overhead)
            const max_min = Vector2f(max.x, min.y);
            const min_max = Vector2f(min.x, max.y);
            draw_line(max, max_min, color, color);
            draw_line(max_min, min, color, color);
            draw_line(min, min_max, color, color);
            draw_line(min_max, max, color, color);
        }

        /**
         * Draw a filled rectangle.
         *
         * Can only be called between start_frame and end_frame.
         *
         * Params:  min   = Minimum extents of the rectangle.
         *          max   = Maximum extents of the rectangle.
         *          color = Color of the rectangle.
         */
        void draw_filled_rectangle(in Vector2f min, in Vector2f max, in Color color);

        /**
         * Draw a texture.
         *
         * Can only be called between start_frame and end_frame.
         *
         * Params:  position = Position of the upper-left corner of the texture.
         *          texture  = Texture to draw.
         */
        void draw_texture(in Vector2i position, const ref Texture texture);
        
        /**
         * Draw a text string.
         *
         * Can only be called between start_frame and end_frame.
         *
         * Params:  position = Position to draw the text at.
         *          text     = Text to draw.
         *          color    = Text color.
         */
        void draw_text(in Vector2i position, in string text, in Color color = Color.white);

        /**
         * Set draw mode.
         *
         * Not all implementations support all draw modes. If specified
         * draw mode is not supported, video driver falls back to a supported
         * draw mode. Draw mode actually applied is returned.
         *
         * Must not be called between calls to start_frame and end_frame.
         *
         * Params:  mode = Draw mode to set.
         *
         * Returns: Draw mode that was actually set.
         */
        DrawMode draw_mode(in DrawMode mode);
        
        /**
         * Get the size a text string would have if it was drawn.
         *
         * Params:  text = Text to measure.
         *
         * Returns: Size of the text in pixels.
         */
        Vector2u text_size(in string text);

        ///Set line antialiasing.
        @property void line_aa(in bool aa);
        
        ///Set line width.
        @property void line_width(in float width);
        
        ///Set font to draw text with. If font_name is "default", default font will be used.
        @property void font(in string font_name);

        ///Set font size to draw text with.
        @property void font_size(in uint size);
        
        ///Set view zoom.
        @property void zoom(in real zoom);
        
        ///Get view zoom.
        @property real zoom() const;

        ///Set view offset.
        @property void view_offset(in Vector2d offset);

        ///Get view offset.
        @property Vector2d view_offset() const;

        ///Get screen width.
        @property uint screen_width() const;

        ///Get screen height.
        @property uint screen_height() const;

        /**
         * Get maximum square texture size supported with specified color format.
         *
         * Params:  format = Texture color format.
         *
         * Returns: Maximum square texture size supported with specified color format.
         */
        uint max_texture_size(in ColorFormat format) const;

        /**
         * Create a texture from given image.
         *
         * Params:  image      = Image to create a texture from.
         *          force_page = Force the texture to be on a separate texture page?
         *
         * Returns: Handle to the created texture.
         *
         * Throws:  TextureException if texture of needed size could not be created.
         */
        Texture create_texture(const ref Image image, in bool force_page = false);

        /**
         * Delete a texture.
         *
         * If deleted during a frame, this texture must not be used in drawing in that
         * frame.
         */
        void delete_texture(in Texture texture);

        /**
         * Capture a screenshot. Can't be called during an update.
         *
         * Must not be called between calls to start_frame and end_frame.
         *
         * Params:  image = Image to save screenshot to. Dimensions of the screenshot
         *                  will correspond to the image.
         */
        void screenshot(ref Image image);

        @property MonitorDataInterface monitor_data()
        {
            //This exists due to what appears to be a linker bug - linker
            //doesn't work if this is not implemented even for abstract class
            //(even though it's overriden by child)
            assert(false);
        }
}
