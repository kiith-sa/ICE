
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Font class.
module video.font;
@system


import core.stdc.string;

import std.stdio;

import derelict.freetype.ft;

import video.fontmanager;
import video.videodriver;
import video.texture;
import math.vector2;
import math.math;
import file.fileio;
import memory.memory;
import containers.vector;
import color;
import image;


///Exception thrown at font related errors.
class FontException : Exception{this(string msg){super(msg);}} 

//use of bytes here limits font size to about 128 pixels,
//but it also decreases struct size to 20 bytes allowing faster copying.
///Immutable font glyph structure.
package align(4) struct Glyph
{
    ///Texture handle of the glyph.
    Texture texture;
    ///Freetype glyph index.
    uint freetype_index;
    ///Offset from the pen to the bottom-left corner of glyph image.
    Vector2b offset;
    ///Pixels to advance the pen after drawing this glyph.
    byte advance;
}

///Stores one font with one size (e.g. Inconsolata size 16 and 18 will be two Font objects).
package final class Font
{
    private:
        ///Default glyph to use when there is no glyph for a character.
        Glyph* default_glyph_ = null;
        ///Number of fast glyphs.
        uint fast_glyph_count_;
        ///Array storing fast glyphs. These are the first fast_glyph_count_ unicode indices.
        Glyph*[] fast_glyphs_;
        ///Associative array storing other, "non-fast", glyphs.
        Glyph[dchar] glyphs_;

        ///Name of the font (file name in the fonts/ directory) .
        string name_;
        ///FreeType font face.
        FT_Face font_face_;

        ///Height of the font in pixels.
        uint height_;
        ///Does this font support kerning?
        bool kerning_;
        ///Should the font be rendered with antialiasing?
        bool antialiasing_;

    public:
        /**
         * Construct a font.
         *
         * Params:  freetype_lib = Handle to the freetype library used to work with fonts.
         *          font_data    = Font data (loaded from a font file).
         *          name         = Name of the font.
         *          size         = Size of the font in points.
         *          fast_glyphs  = Number of glyphs to store in fast access array,
         *                         from glyph 0. E.g. 128 means 0-127, i.e. ASCII.
         *          antialiasing = Should the font be antialiased?
         *
         * Throws:  FontException if the font could not be loaded.
         */
        this(FT_Library freetype_lib, ref Vector!(ubyte) font_data, in string name, 
             in uint size, in uint fast_glyphs, in bool antialiasing)
        {
            scope(failure){writefln("Could not load font " ~ name);}

            fast_glyphs_ = new Glyph*[fast_glyphs];
            fast_glyph_count_ = fast_glyphs;

            name_ = name;
            antialiasing_ = antialiasing;

            FT_Open_Args args;
            args.memory_base = font_data.ptr_unsafe;
            args.memory_size = font_data.length;
            args.flags = FT_OPEN_MEMORY;
            args.driver = null;
            //we only support face 0 right now, so no bold, italic, etc. 
            //unless it is in a separate font file.
            const face = 0;
            
            //load face from memory buffer (font_data)
            if(FT_Open_Face(freetype_lib, &args, face, &font_face_) != 0) 
            {
                throw new FontException("Couldn't load font face from font " ~ name);
            }
            
            //set font size in pixels
            //could use a better approach, but worked for all fonts so far.
            if(FT_Set_Pixel_Sizes(font_face_, 0, size) != 0)
            {
                throw new FontException("Couldn't set pixel size with font " ~ name);
            }

            height_ = size;
            kerning_ = cast(bool)FT_HAS_KERNING(font_face_);
        }

        /**
         * Destroy the font and free its resources.
         *
         * To free all used resources, unload_textures() must be called before this.
         */
        ~this()
        {    
            foreach(glyph; fast_glyphs_) if(glyph !is null)
            {
                free(glyph);
            }
            FT_Done_Face(font_face_);
            clear(fast_glyphs_);
            clear(glyphs_);
        }

        ///Get size of the font in pixels.
        @property uint size() const {return height_;}

        ///Get height of the font in pixels (currently the same as size).
        @property uint height() const {return height_;}

        ///Get name of the font.
        @property string name() const {return name_;}

        ///Does the font support kerning?
        @property bool kerning() const {return kerning_;}

        ///Get FreeType font face of the font.
        @property FT_Face font_face(){return font_face_;}

        /**
         * Delete glyph textures.
         *
         * Textures have to be reloaded before any further
         * glyph rendering with the font.
         *
         * Params:  driver = Video driver to delete textures from.
         */
        void unload_textures(VideoDriver driver)
        {
            foreach(glyph; fast_glyphs_)
            {
                if(glyph !is null)
                {
                    //some glyphs might share texture with default glyph
                    if(default_glyph_ !is null && glyph.texture == default_glyph_.texture)
                    {
                        continue;
                    }
                    driver.delete_texture(glyph.texture);
                }
            }
            foreach(glyph; glyphs_)
            {
                //some glyphs might share texture with default glyph
                if(default_glyph_ !is null && glyph.texture == default_glyph_.texture)
                {
                    continue;
                }
                driver.delete_texture(glyph.texture);
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
         * Params:  driver = Video driver to load textures to.
         *
         * Throws:  TextureException if the glyph textures could not be reloaded.
         */
        void reload_textures(VideoDriver driver)
        {
            foreach(c, glyph; fast_glyphs_)
            {
                if(glyph !is null){load_glyph(driver, cast(dchar)c);}
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
        uint text_width(in string str, in bool use_kerning)
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
            
            foreach(dchar chr; str) 
            {
                auto glyph = get_glyph(chr);
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

        //not asserting glyph existence here as it'd result in too much slowdown
        /** 
         * Access glyph of a (UTF-32) character.
         * 
         * The glyph has to be loaded, otherwise a call to get_glyph()
         * will result in undefined behavior.
         *
         * Params:  c = Character to get glyph for.
         *
         * Returns: Pointer to glyph corresponding to the character. 
         */
        const(Glyph*) get_glyph(in dchar c) const
        {
            return c < fast_glyph_count_ ? fast_glyphs_[c] : c in glyphs_;
        }

        /**              
         * Determines if the glyph of a character is loaded.
         *
         * Params:  c = Character to check for.
         *
         * Returns: True if the glyph is loaded, false otherwise.
         */
        bool has_glyph(in dchar c) const
        {
            return c < fast_glyph_count_ ? fast_glyphs_[c] !is null : (c in glyphs_) !is null;
        }

        /**
         * Load glyph of a character.
         *
         * Params:  driver = Video driver to use for texture creation.
         *          c      = Character to load glyph for.
         *
         * Throws:  TextureException if the glyph texture could not be created.
         */
        void load_glyph(VideoDriver driver, in dchar c)
        {
            if(c < fast_glyph_count_)
            {
                if(fast_glyphs_[c] is null){fast_glyphs_[c] = alloc!(Glyph)();}
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
         *
         * Throws:  TextureException if the glyph texture could not be created.
         */
        Glyph get_default_glyph(VideoDriver driver)
        {
            if(default_glyph_ is null)
            {
                //empty image is transparent
                auto image = Image(height_ / 2, height_, ColorFormat.GRAY_8);
                default_glyph_ = alloc!(Glyph)();
                default_glyph_.texture = driver.create_texture(image);
                default_glyph_.offset = Vector2b(0, cast(byte)-height_);
                default_glyph_.advance = cast(byte)(height_ / 2);
                default_glyph_.freetype_index = 0;
            }
            return *default_glyph_;
        }

        /**
         * Render a glyph of a character and return it.
         *
         * Will create a texture for the glyph, or use default glyph 
         * if the character has no glyph or its texture could not be created.
         *
         * Params:  driver = Video driver to use in texture creation.
         *          c      = Character to render glyph for.
         *
         * Throws:  TextureException if default glyph texture could not be created.
         */
        Glyph render_glyph(VideoDriver driver, in dchar c)
        {
            Glyph glyph;
            glyph.freetype_index = FT_Get_Char_Index(font_face_, c);
            
            //load the glyph to font_face_.glyph
            const uint load_flags = FT_LOAD_TARGET_(render_mode()) | FT_LOAD_NO_BITMAP;
            if(FT_Load_Glyph(font_face_, glyph.freetype_index, load_flags) != 0) 
            { 
                return get_default_glyph(driver);
            }
            FT_GlyphSlot slot = font_face_.glyph;

            //convert font_face_.glyph to image
            if(FT_Render_Glyph(slot, render_mode()) == 0) 
            {
                glyph.advance = cast(byte)(font_face_.glyph.advance.x / 64);
                glyph.offset.x = cast(byte)slot.bitmap_left;
                glyph.offset.y = cast(byte)-slot.bitmap_top;

                FT_Bitmap bitmap = slot.bitmap;
                const size = Vector2u(bitmap.width, bitmap.rows);
                assert(size.x < 128 && size.y < 128, 
                       "Can't draw a glyph wider or taller than 127 pixels");
                //we don't want to crash or cause bugs in optimized builds
                if(size.x >= 128 || size.y >= 128 || size.x == 0 || size.y == 0)
                {
                    glyph.texture = get_default_glyph(driver).texture;
                    return glyph;
                }

                //image to create texture from
                auto image = Image(size.x, size.y, ColorFormat.GRAY_8);

                //return 255 if the bit at (x,y) is set. 0 otherwise.
                ubyte bitmap_color(uint x, uint y) 
                {
                    ubyte b = bitmap.buffer[y * bitmap.pitch + (x / 8)];
                    return cast(ubyte)((b & (0b10000000 >> (x % 8))) ? 255 : 0);
                }

                //copy freetype bitmap to our image
                if(antialiasing_)
                {
                    memcpy(image.data_unsafe.ptr, bitmap.buffer, size.x * size.y);
                    //antialiasing makes the glyph appear darker so we make it lighter
                    image.gamma_correct(1.2);
                }
                else
                {
                    for(uint y = 0; y < size.y; ++y) 
                    {
                        for(uint x = 0; x < size.x; ++x) 
                        {
                            image.set_pixel_gray8(x, y, bitmap_color(x, y));
                        }
                    }
                }

                try{glyph.texture = driver.create_texture(image);}
                catch(TextureException e)
                {
                    writefln("Could not create glyph texture, falling back to default");
                    return get_default_glyph(driver);
                }

                return glyph;
            }
            else{return get_default_glyph(driver);}
        }
        
        ///Get freetype render mode (antialiased or bitmap)
        @property FT_Render_Mode render_mode() 
        {
            return antialiasing_ ? FT_Render_Mode.FT_RENDER_MODE_NORMAL 
                                 : FT_Render_Mode.FT_RENDER_MODE_MONO;
        }
}
