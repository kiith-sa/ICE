module video.videodriver;


import std.math;

import video.texture;
import math.math;
import math.vector2;
import math.line2;
import math.rectangle;
import platform.platform;
import test.subdebugger;
import singleton;
import color;
import image;


///Handles all drawing functionality.
abstract class VideoDriver
{
    mixin Singleton;
    public:
        ///Destroy the VideoDriver. Should only be called at shutdown.
        void die();

        /**
         * Sets video mode.
         *
         * Params:    width      = Screen _width to set in pixels;
         *            height     = Screen _height to set in pixels;
         *            format     = Color _format to use for screen.
         *            fullscreen = If true, use fullscreen, otherwise windowed.
         *
         * Throws: Exception on failure.   
         */ 
        void set_video_mode(uint width, uint height, ColorFormat format, 
                            bool fullscreen);

        ///Start drawing a frame. Must be called before any drawing calls.
        void start_frame();

        ///Finish drawing a frame.
        void end_frame();

        ///Draw a line between specified points.
        void draw_line(Vector2f v1, Vector2f v2,
                       Color c1 = Color(255, 255, 255, 255), 
                       Color c2 = Color(255, 255, 255, 255));

        ///Draw a circle with specified center, radius, color and number of vertices.
        final void draw_circle(Vector2f center, float radius, 
                               Color color = Color(255, 255, 255, 255), 
                               uint vertex_count = 32)
        in
        {
            assert(radius >= 0, "Can't draw a circle with negative radius");
            assert(vertex_count >= 3, "Can't draw a circle with less than 3 vertices");
            assert(vertex_count <= 8192, "Can't draw a circle with absurd number of "
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

        ///Draw a rectangle with specified extents and color.
        final void draw_rectangle(Vector2f min, Vector2f max,
                                  Color color = Color(255, 255, 255, 255))
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

        ///Draw a texture at given position.
        void draw_texture(Vector2i position, ref Texture texture);
        
        ///Draw a string of text at given position.
        void draw_text(Vector2i position, string text, 
                       Color color = Color(255, 255, 255, 255));
        
        ///Return the size a text string would have if it was drawn.
        Vector2u text_size(string text);

        ///Enable/disable line antialiasing.
        void line_aa(bool aa);
        
        ///Set line width.
        void line_width(float width);

        ///Set font to draw text with.
        void font(string font_name);

        ///Set font size to draw text with.
        void font_size(uint size);
        
        ///Set view zoom.
        void zoom(real zoom);
        
        ///Return view zoom.
        real zoom();

        ///Set view offset.
        void view_offset(Vector2d offset);

        ///Return view offset.
        Vector2d view_offset();

        ///Return screen width.
        uint screen_width();

        ///Return screen height.
        uint screen_height();

        ///Return maximum square texture size supported with given color format.
        uint max_texture_size(ColorFormat format);

        ///Returns a string containing information about texture pages.
        string pages_info();

        ///Create a texture from given image. Optionally force the texture to have its own texture page.
		Texture create_texture(ref Image image, bool force_page = false);

        ///Delete given texture.
        void delete_texture(Texture texture);

        ///Get debugger GUI element for the VideoDriver implementation.
        SubDebugger debugger(){return null;}
}
