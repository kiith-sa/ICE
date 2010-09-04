module video.videodriver;


import video.texture;
import math.math;
import math.vector2;
import math.line2;
import math.rectangle;
import platform.platform;
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

        ///Draw a line between given points.
        void draw_line(Vector2f v1, Vector2f v2,
                       Color c1 = Color(255, 255, 255, 255), 
                       Color c2 = Color(255, 255, 255, 255));

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
}
