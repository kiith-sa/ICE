module video.font;


import std.c.string;

import derelict.freetype.ft;

import video.fontmanager;
import video.videodriver;
import video.texture;
import math.vector2;
import math.math;
import color;
import file.fileio;
import image;
import allocator;


//use of bytes here limits font size to about 128 pixels,
//but it also decreases struct size to 20 bytes allowing faster copying.
///Immutable font glyph structure.
package align(4) struct Glyph
{
    Texture texture;
    //freetype glyph index
    uint freetype_index;
    //offset from pen to the bottom-left corner of glyph image
    Vector2b offset;
    //how much to advance the pen after drawing this glyph
    byte advance;
}

///Stores one font with one size (e.g. Inconsolata size 16 and 18 will be two Font objects).
package class Font
{
    private:
        //Default glyph to use when there is no glyph for a character.
        Glyph* default_glyph_ = null;
        //Array storing fast glyphs. These are first fast_glyph_count_ unicode characters.
        Glyph*[] fast_glyphs_;
        //Associative array storing other, "non-fast", glyphs.
        Glyph[dchar] glyphs_;

        string name_;
        //FreeType font face.
        FT_Face font_face_;

        //Height of the font in pixels.
        uint height_;
        //Does this font support kerning?
        bool kerning_;
        //Should the font be rendered with antialiasing?
        bool antialiasing_;

        //Number of glyphs accessible through normal instead of associative array.
        uint fast_glyph_count_;

        //File this font was loaded from. (stores loaded file data)
        File file_;

    public:
        /**
         * Load font with specified name, size and number of fast glyphs.
         *
         * Params:  freetype_lib = Handle to freetype library used to work with fonts.
         *          name         = Name of the font (file name in the fonts/ directory)
         *          size         = Size of the font in points.
         *          fast_glyphs  = Number of glyphs to store in faster accessible data,
         *                         from glyph 0. E.g. 128 means 0-127, i.e. ASCII.
         *          antialiasing = Should the font be antialiased?
         *
         * Throws:  Exception if the font could not be loaded.
         */
        this(FT_Library freetype_lib, string name, uint size, uint fast_glyphs, 
             bool antialiasing)
        {
            fast_glyphs_ = new Glyph*[fast_glyphs];
            fast_glyph_count_ = fast_glyphs;
            name_ = name;
            antialiasing_ = antialiasing;

            file_ = open_file("fonts/" ~ name, FileMode.Read);
            ubyte[] font_data = cast(ubyte[])file_.data;
            scope(failure){close_file(file_);}

            FT_Open_Args args;
            args.memory_base = font_data.ptr;
            args.memory_size = font_data.length;
            args.flags = FT_OPEN_MEMORY;
            args.driver = null;
            //we only support face 0 right now, so no bold, italic, etc. 
            //unless it is in a separate font file.
            int face = 0;
            
            //load face from memory buffer (font_data)
            if(FT_Open_Face(freetype_lib, &args, face, &font_face_) != 0) 
            {
                throw new Exception("Couldn't load font face from font " ~ file_.path);
            }
            
            //set font size in pixels
            //could use a better approach, but worked for all fonts so far.
            if(FT_Set_Pixel_Sizes(font_face_, 0, size) != 0)
            {
                throw new Exception("Couldn't set pixel size with font " ~ file_.path);
            }

            height_ = size;
            kerning_ = cast(bool)FT_HAS_KERNING(font_face_);
        }

        ///Returns size of the font in pixels.
        uint size(){return height_;}

        ///Returns height of the font in pixels. (currently the same as size)
        uint height(){return height_;}

        ///Returns name of the font.
        string name(){return name_;}

        ///Does the font support kerning?
        bool kerning(){return kerning_;}

        ///Returns FreeType font face of the font.
        FT_Face font_face(){return font_face_;}

        /**
         * Destroy the font and free its resources.
         * To free all used resources, delete_textures must be called before this.
         */
        void die()
        {    
            foreach(glyph; fast_glyphs_)
            {
                if(glyph !is null){free(glyph);}
            }
            FT_Done_Face(font_face_);
            close_file(file_);
            fast_glyphs_ = [];
            glyphs_ = null;
        }

        /**
         * Delete glyph textures.
         *
         * Textures have to be reloaded before any further
         * glyph rendering with the font.
         *
         * Params:  driver = Video driver used to delete the textures.
         */
        void unload_textures(VideoDriver driver)
        {
            foreach(glyph; fast_glyphs_)
            {
                if(glyph !is null)
                {
                    //some glyphs might share texture with default glyph
                    if(default_glyph_ !is null && glyph.texture != default_glyph_.texture)
                    {
                        driver.delete_texture(glyph.texture);
                    }
                }
            }
            foreach(glyph; glyphs_)
            {
                if(default_glyph_ !is null && glyph.texture != default_glyph_.texture)
                {
                    driver.delete_texture(glyph.texture);
                }
            }
            if(default_glyph_ !is null)
            {
                driver.delete_texture(default_glyph_.texture);
                free(default_glyph_);
                default_glyph_ = null;
            }
        }

        /**
         * Load glyph textures back to video driver.
         *
         * Can only be used after textures were unloaded.
         *
         * Params:  driver = Video driver used to delete the textures.
         */
        void reload_textures(VideoDriver driver)
        {
            foreach(c, glyph; fast_glyphs_)
            {
                if(glyph !is null){load_glyph(driver, c);}
            }
            foreach(c, glyph; glyphs_){load_glyph(driver, c);}
        }

    package:
        /**
         * Returns width of text as it would be drawn.
         * 
         * Params:  str         = Text to measure.
         *          use_kerning = Should kerning be used? 
         *                        Should only be true if the font supports kerning.
         *
         * Returns: Width of the text in pixels.
         */
        uint text_width(string str, bool use_kerning)
        in
        {
            assert(kerning_ ? true : !use_kerning, 
                   "Trying to use kerning with a font where it's unsupported.");
        }
        body
        {
            //previous glyph index, for kerning
			uint previous_index = 0;
			uint pen_x = 0;
            //current glyph index
            uint glyph_index;
            FT_Vector kerning;
            Glyph * glyph;
			
			foreach(dchar chr; str) 
            {
                glyph = get_glyph(chr);
				glyph_index = glyph.freetype_index;
				
				if(use_kerning && previous_index != 0 && glyph_index != 0) 
                {
					//adjust the pen for kerning
					FT_Get_Kerning(font_face_, previous_index, glyph_index, 
                                   FT_Kerning_Mode.FT_KERNING_DEFAULT, &kerning);
					pen_x += kerning.x / 64;
				}

                pen_x += glyph.advance;
			}
            return pen_x;
        }

        //not asserting here as it'd result in too much slowdown
        /** 
         * Access glyph for specified (UTF-32) character.
         * 
         * The glyph has to be loaded, otherwise a call to get_glyph
         * will result in undefined behavior.
         *
         * Params:  c = Character to get glyph for.
         *
         * Returns: Glyph corresponding to the character. 
         */
        Glyph* get_glyph(dchar c)
        {
            return c < fast_glyph_count_ ?  fast_glyphs_[c] : c in glyphs_;
        }

        /**
         * Determines if glyph for the specified character is loaded.
         *
         * Params:  c = Character to check for.
         *
         * Returns: True if the glyph is loaded, false otherwise.
         */
        bool has_glyph(dchar c)
        {
            return c < fast_glyph_count_ ? fast_glyphs_[c] !is null 
                                         : (c in glyphs_) !is null;
        }

        /**
         * Load glyph for specified character.
         *
         * Will render the glyph and create a texture for it.
         * 
         * Params:  driver = Video driver to use for texture creation.
         *          c      = Character to load glyph for.
         */
        void load_glyph(VideoDriver driver, dchar c)
        {
            if(c < fast_glyph_count_)
            {
                fast_glyphs_[c] = alloc!(Glyph)();
                *fast_glyphs_[c] = render_glyph(driver, c);
                return;
            }
            glyphs_[c] = render_glyph(driver, c);
        }

    private:
        /**
         * Get default glyph, initialize it if it does not exist.
         *
         * If the default glyph does not exist, this will render it and
         * create a texture for it.
         *
         * Params:  driver = Video driver to use for texture creation.
         */
        Glyph get_default_glyph(VideoDriver driver)
        {
            if(default_glyph_ is null)
            {
                scope Image image = new Image(height_ / 2, height_, ColorFormat.GRAY_8);
                default_glyph_ = alloc!(Glyph)();
                default_glyph_.texture = driver.create_texture(image);
                default_glyph_.offset = Vector2b(0, -height_);
                default_glyph_.advance = height_ / 2;
                default_glyph_.freetype_index = 0;
            }
            return *default_glyph_;
        }

        /**
         * Render a glyph for specified character and return it.
         *
         * Will create a texture for the glyph.
         *
         * Params:  driver = Video driver to use in texture creation.
         *          c      = Character to render glyph for.
         */
        Glyph render_glyph(VideoDriver driver, dchar c)
        {
            Glyph glyph;
            glyph.freetype_index = FT_Get_Char_Index(font_face_, c);
            
            //load the glyph to font_face_.glyph
            uint load_flags = FT_LOAD_TARGET_(render_mode()) | FT_LOAD_NO_BITMAP;
            if(FT_Load_Glyph(font_face_, glyph.freetype_index, load_flags) != 0) 
            { 
                return get_default_glyph(driver);
            }
			FT_GlyphSlot slot = font_face_.glyph;

            //convert the font_face_.glyph to image
			if(FT_Render_Glyph(slot, render_mode()) == 0) 
            {
                glyph.advance = font_face_.glyph.advance.x / 64;
                glyph.offset.x = slot.bitmap_left;
                glyph.offset.y = -slot.bitmap_top;

                FT_Bitmap bitmap = slot.bitmap;
                Vector2u size = Vector2u(bitmap.width, bitmap.rows);
                assert(size.x < 128 && size.y < 128, 
                       "Can't draw a glyph wider or taller than 127 pixels");
                //we don't want to crash or cause bugs in optimized builds
                if(size.x >= 128 || size.y >= 128 || size.x == 0 || size.y == 0)
                {
                    glyph.texture = get_default_glyph(driver).texture;
                    return glyph;
                }

                //image to create texture from
                scope Image image = new Image(size.x, size.y, ColorFormat.GRAY_8);

				//return 255 if the bit at (x,y) is set. 0 otherwise.
				ubyte bitmap_color(uint x, uint y) 
                {
                    ubyte b = bitmap.buffer[y * bitmap.pitch + (x / 8)];
					return (b & (0b10000000 >> (x % 8))) ? 255 : 0;
				}

                //copy freetype bitmap to our image
                if(antialiasing_)
                {
                    memcpy(image.data.ptr, bitmap.buffer, size.x * size.y);
                    //antialiasing makes the glyph appear darker
                    image.gamma_correct(1.2);
                }
                else
                {
                    for(uint y = 0; y < size.y; ++y) 
                    {
                        for(uint x = 0; x < size.x; ++x) 
                        {
                            image.set_pixel(x, y, bitmap_color(x, y));
                        }
                    }
                }

                glyph.texture = driver.create_texture(image);
                return glyph;
            }
            else{return get_default_glyph(driver);}
        }
        
        ///Get freetype render mode (antialiased or bitmap)
		FT_Render_Mode render_mode() 
        {
            return antialiasing_ ? FT_Render_Mode.FT_RENDER_MODE_NORMAL 
                                 : FT_Render_Mode.FT_RENDER_MODE_MONO;
		}
}
