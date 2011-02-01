module video.videodriver;


import std.math;

import video.texture;
import math.math;
import math.vector2;
import math.line2;
import math.rectangle;
import platform.platform;
import gui.guielement;
import monitor.monitormenu;
import monitor.monitorable;
import weaksingleton;
import color;
import image;


///Handles all drawing functionality.
abstract class VideoDriver : Monitorable
{
    mixin WeakSingleton;
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

        /**
         * Enable scissor test using specified rectangle as scissor area.
         *
         * Until scissor test is disabled, only specified area of the screen
         * will be drawn to. This can be used e.g. for 2D clipping of GUI.
         *
         * Params:  scissor_area = Scissor area in screen coordinates.
         */
        void scissor(ref Rectanglei scissor_area);

        ///Disable scissor test.
        void disable_scissor();

        /**
         * Draw a line between specified points, with specified colors.
         *
         * Colors are interpolated from start to end of the line.
         * If the points specified are identical, drawn result is undefined.
         *
         * Params:  v1 = Start point of the line.
         *          v2 = End point of the line.
         *          c1 = Color at the start point.
         *          c2 = Color at the end point.
         */
        void draw_line(Vector2f v1, Vector2f v2, Color c1, Color c2);

        /**
         * Draw a line strip through specified points with specified color.
         *
         * Params:  v = Vertices of the strip.
         *          c = Color of the strip.
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

        ///Draw a circle with specified center, radius, color and number of vertices.
        void draw_circle(Vector2f center, float radius, 
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
        void draw_rectangle(Vector2f min, Vector2f max, Color color = Color(255, 255, 255, 255))
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

        
        ///Set font to draw text with. If font_name is "default", default font will be used.
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

        ///Create a texture from given image. Optionally force the texture to have its own texture page.
		Texture create_texture(ref Image image, bool force_page = false);

        ///Delete given texture.
        void delete_texture(Texture texture);

        MonitorMenu monitor_menu()
        {
            //This exists due to what appears to be a linker bug - linker
            //doesn't work if this is not implemented even for abstract class
            //(even though it's overriden by child)
            return null;
        }
}
