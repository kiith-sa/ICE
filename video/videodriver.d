
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module video.videodriver;


import std.math;

import video.texture;
import video.fontmanager;
import math.math;
import math.vector2;
import math.line2;
import math.rectangle;
import platform.platform;
import gui.guielement;
import monitor.monitormenu;
import monitor.monitorable;
import util.weaksingleton;
import color;
import image;


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
         * Throws: Exception on failure.   
         */ 
        void set_video_mode(uint width, uint height, ColorFormat format, bool fullscreen);

        ///Start drawing a frame. Must be called before any drawing calls.
        void start_frame();

        ///Finish drawing a frame.
        void end_frame();

        /**
         * Enable scissor test using specified rectangle as scissor area.
         *
         * Until the scissor test is disabled, only specified area of the screen
         * will be drawn to. This can be used e.g. for 2D clipping of GUI elements.
         *
         * Params:  scissor_area = Scissor area in screen coordinates.
         */
        void scissor(ref Rectanglei scissor_area);

        ///Disable scissor test.
        void disable_scissor();

        /**
         * Draw a line between specified points with specified colors.
         *
         * Colors are interpolated from start to end of the line.
         *
         * Params:  v1 = Start point of the line.
         *          v2 = End point of the line.
         *          c1 = Color at the start point.
         *          c2 = Color at the end point.
         */
        void draw_line(Vector2f v1, Vector2f v2, Color c1, Color c2);

        /**
         * Draw a line strip through specified points with specified colors.
         *
         * Params:  v = Vertices of the strip.
         *          c = Colors of the vertices.
         */
        void draw_line_strip(Vector2f[] v, Color c)
        in{assert(v.length >= 2, "Must have at least 2 vertices to draw a line strip");}
        body
        {
            Vector2f start = v[0];
            foreach(Vector2f end; v[1 .. $])
            {
                draw_line(start, end, c, c);
                start = end;
            }
        }

        /**
         * Draw a stroked circle.
         *
         * Params:  center       = Center of the circle.
         *          radius       = Radius of the circle.
         *          color        = Color of the circle stroke.
         *          vertex_count = Number of vertices in the circle.
         */
        void draw_circle(Vector2f center, float radius, 
                         Color color = Color.white, 
                         uint vertex_count = 32)
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
            float vertex_angle = 2 * PI / vertex_count;
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
         * Params:  min   = Minimum extents of the rectangle.
         *          max   = Maximum extents of the rectangle.
         *          color = Color of the rectangle stroke.
         */
        void draw_rectangle(Vector2f min, Vector2f max, Color color = Color.white)
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
            Vector2f max_min = Vector2f(max.x, min.y);
            Vector2f min_max = Vector2f(min.x, max.y);
            draw_line(max, max_min, color, color);
            draw_line(max_min, min, color, color);
            draw_line(min, min_max, color, color);
            draw_line(min_max, max, color, color);
        }

        /**
         * Draw a filled rectangle.
         *
         * Params:  min   = Minimum extents of the rectangle.
         *          max   = Maximum extents of the rectangle.
         *          color = Color of the rectangle.
         */
        void draw_filled_rectangle(Vector2f min, Vector2f max, Color color = Color.white);

        /**
         * Draw a texture.
         *
         * Params:  position = Position of the upper-left corner of the texture.
         *          texture  = Texture to draw.
         */
        void draw_texture(Vector2i position, ref Texture texture);
        
        /**
         * Draw a text string.
         *
         * Params:  position = Position to draw the text at.
         *          text     = Text to draw.
         *          color    = Text color.
         */
        void draw_text(Vector2i position, string text, Color color = Color.white);
        
        /**
         * Get the size a text string would have if it was drawn.
         *
         * Params:  text = Text to measure.
         *
         * Returns: Size of the text in pixels.
         */
        Vector2u text_size(string text);

        ///Set line antialiasing.
        void line_aa(bool aa);
        
        ///Set line width.
        void line_width(float width);
        
        ///Set font to draw text with. If font_name is "default", default font will be used.
        void font(string font_name);

        ///Set font size to draw text with.
        void font_size(uint size);
        
        ///Set view zoom.
        void zoom(real zoom);
        
        ///Get view zoom.
        real zoom();

        ///Set view offset.
        void view_offset(Vector2d offset);

        ///Get view offset.
        Vector2d view_offset();

        ///Get screen width.
        uint screen_width();

        ///Get screen height.
        uint screen_height();

        /**
         * Get maximum square texture size supported with specified color format.
         *
         * Params:  format = Texture color format.
         *
         * Returns: Maximum square texture size supported with specified color format.
         */
        uint max_texture_size(ColorFormat format);

        /**
         * Create a texture from given image.
         *
         * Params:  image      = Image to create a texture from.
         *          force_page = Force the texture to be on a separate texture page?
         *
         * Returns: Handle to the created texture.
         *
         * Throws:  Exception if texture of needed size could not be created.
         */
        Texture create_texture(ref Image image, bool force_page = false);

        ///Delete a texture.
        void delete_texture(Texture texture);

        ///Capture a screenshot. Can't be called during an update.
        Image screenshot();

        override MonitorMenu monitor_menu()
        {
            //This exists due to what appears to be a linker bug - linker
            //doesn't work if this is not implemented even for abstract class
            //(even though it's overriden by child)
            assert(false);
        }
}
