
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Font class.
module video.font;


import core.stdc.string;

import std.stdio;

import derelict.freetype.ft;

import video.fontmanager;
import video.videodriver;
import video.texture;
import math.vector2;
import math.math;
import memory.memory;
import containers.vector;
import color;
import image;


///Exception thrown at font related errors.
class FontException : Exception{this(string msg){super(msg);}} 

///Immutable font glyph structure.
package align(4) struct Glyph
{
    ///Texture handle of the glyph.
    Texture texture;
    ///Freetype glyph index.
    uint freetypeIndex;
    ///Offset from the pen to the bottom-left corner of glyph image.
    Vector2s offset;
    ///Pixels to advance the pen after drawing this glyph.
    short advance;
}
static assert(Glyph.sizeof <= 24);

///Stores one font with one size (e.g. Inconsolata size 16 and 18 will be two Font objects).
package final class Font
{
    private:
        ///Default glyph to use when there is no glyph for a character.
        Glyph* defaultGlyph_ = null;
        ///Number of fast glyphs.
        uint fastGlyphCount_;
        ///Array storing fast glyphs. These are the first fastGlyphCount_ unicode indices.
        Glyph*[] fastGlyphs_;
        ///Associative array storing other, "non-fast", glyphs.
        Glyph[dchar] glyphs_;

        ///Name of the font (file name in the fonts/ directory) .
        string name_;
        ///FreeType font face.
        FT_Face fontFace_;

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
         * Params:  freetypeLib = Handle to the freetype library used to work with fonts.
         *          fontData    = Font data (loaded from a font file).
         *          name         = Name of the font.
         *          size         = Size of the font in points.
         *          fastGlyphs  = Number of glyphs to store in fast access array,
         *                         from glyph 0. E.g. 128 means 0-127, i.e. ASCII.
         *          antialiasing = Should the font be antialiased?
         *
         * Throws:  FontException if the font could not be loaded.
         */
        this(FT_Library freetypeLib, ubyte[] fontData, const string name, 
             const uint size, const uint fastGlyphs, const bool antialiasing)
        {
            scope(failure){writeln("Could not load font " ~ name);}

            fastGlyphs_ = new Glyph*[fastGlyphs];
            fastGlyphCount_ = fastGlyphs;

            name_ = name;
            antialiasing_ = antialiasing;

            FT_Open_Args args;
            args.memory_base = fontData.ptr;
            args.memory_size = fontData.length;
            args.flags       = FT_OPEN_MEMORY;
            args.driver      = null;
            //we only support face 0 right now, so no bold, italic, etc. 
            //unless it is in a separate font file.
            const face = 0;
            
            //load face from memory buffer (fontData)
            if(FT_Open_Face(freetypeLib, &args, face, &fontFace_) != 0) 
            {
                throw new FontException("Couldn't load font face from font " ~ name);
            }
            
            //set font size in pixels
            //could use a better approach, but worked for all fonts so far.
            if(FT_Set_Pixel_Sizes(fontFace_, 0, size) != 0)
            {
                throw new FontException("Couldn't set pixel size with font " ~ name);
            }

            height_ = size;
            kerning_ = cast(bool)FT_HAS_KERNING(fontFace_);
        }

        /**
         * Destroy the font and free its resources.
         *
         * To free all used resources, unloadTextures() must be called before this.
         */
        ~this()
        {    
            foreach(glyph; fastGlyphs_) if(glyph !is null)
            {
                free(glyph);
            }
            FT_Done_Face(fontFace_);
            clear(fastGlyphs_);
            clear(glyphs_);
        }

        ///Get size of the font in pixels.
        @property uint size() const pure {return height_;}

        ///Get height of the font in pixels (currently the same as size).
        @property uint height() const pure {return height_;}

        ///Get name of the font.
        @property string name() const pure {return name_;}

        ///Does the font support kerning?
        @property bool kerning() const pure {return kerning_;}

        ///Get FreeType font face of the font.
        @property FT_Face fontFace() pure {return fontFace_;}

        /**
         * Delete glyph textures.
         *
         * Textures have to be reloaded before any further
         * glyph rendering with the font.
         *
         * Params:  driver = Video driver to delete textures from.
         */
        void unloadTextures(VideoDriver driver)
        {
            foreach(glyph; fastGlyphs_) if(glyph !is null)
            {
                //some glyphs might share texture with default glyph
                if(defaultGlyph_ !is null && glyph.texture == defaultGlyph_.texture)
                {
                    continue;
                }
                driver.deleteTexture(glyph.texture);
            }
            foreach(glyph; glyphs_)
            {
                //some glyphs might share texture with default glyph
                if(defaultGlyph_ !is null && glyph.texture == defaultGlyph_.texture)
                {
                    continue;
                }
                driver.deleteTexture(glyph.texture);
            }
            if(defaultGlyph_ !is null)
            {
                driver.deleteTexture(defaultGlyph_.texture);
                free(defaultGlyph_);
                defaultGlyph_ = null;
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
        void reloadTextures(VideoDriver driver)
        {
            foreach(c, glyph; fastGlyphs_) if(glyph !is null)
            {
                loadGlyph(driver, cast(dchar)c);
            }
            foreach(c, glyph; glyphs_){loadGlyph(driver, c);}
        }

    package:
        /**
         * Returns width of text as it would be drawn.
         * 
         * Params:  str         = Text to measure.
         *          useKerning = Should kerning be used? 
         *                        Should only be true if the font supports kerning.
         *
         * Returns: Width of the text in pixels.
         */
        uint textWidth(const string str, const bool useKerning)
        in
        {
            assert(kerning_ ? true : !useKerning, 
                   "Trying to use kerning with a font where it's unsupported.");
        }
        body
        {
            //previous glyph index, for kerning
            uint previousIndex = 0;
            uint penX = 0;
            //current glyph index
            uint glyphIndex;
            FT_Vector kerning;
            
            foreach(dchar chr; str) 
            {
                const glyph = getGlyph(chr);
                glyphIndex = glyph.freetypeIndex;
                
                if(useKerning && previousIndex != 0 && glyphIndex != 0) 
                {
                    //adjust the pen for kerning
                    FT_Get_Kerning(fontFace_, previousIndex, glyphIndex, 
                                   FT_Kerning_Mode.FT_KERNING_DEFAULT, &kerning);
                    penX += kerning.x / 64;
                }

                penX += glyph.advance;
            }
            return penX;
        }

        //not asserting glyph existence here as it'd result in too much slowdown
        /** 
         * Access glyph of a (UTF-32) character.
         * 
         * The glyph has to be loaded, otherwise a call to getGlyph()
         * will result in undefined behavior.
         *
         * Params:  c = Character to get glyph for.
         *
         * Returns: Pointer to glyph corresponding to the character. 
         */
        const(Glyph*) getGlyph(const dchar c) const
        {
            return c < fastGlyphCount_ ? fastGlyphs_[c] : c in glyphs_;
        }

        /**              
         * Determines if the glyph of a character is loaded.
         *
         * Params:  c = Character to check for.
         *
         * Returns: True if the glyph is loaded, false otherwise.
         */
        bool hasGlyph(const dchar c) const
        {
            return c < fastGlyphCount_ ? fastGlyphs_[c] !is null : (c in glyphs_) !is null;
        }

        /**
         * Load glyph of a character.
         *
         * Params:  driver = Video driver to use for texture creation.
         *          c      = Character to load glyph for.
         *
         * Throws:  TextureException if the glyph texture could not be created.
         */
        void loadGlyph(VideoDriver driver, const dchar c)
        {
            if(c < fastGlyphCount_)
            {
                if(fastGlyphs_[c] is null)
                {
                    auto newGlyph  = alloc!Glyph();
                    scope(failure){free(newGlyph);}
                    *newGlyph = renderGlyph(driver, c);
                    fastGlyphs_[c] = newGlyph;
                    return;
                }
                *fastGlyphs_[c] = renderGlyph(driver, c);
                return;
            }
            glyphs_[c] = renderGlyph(driver, c);
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
        Glyph getDefaultGlyph(VideoDriver driver)
        {
            if(defaultGlyph_ is null)
            {
                //empty image is transparent
                auto image         = Image(height_ / 2, height_, ColorFormat.GRAY_8);
                auto defaultGlyph  = alloc!Glyph();
                scope(failure){free(defaultGlyph);}
                defaultGlyph.texture = driver.createTexture(image);
                defaultGlyph.offset  = Vector2s(0, cast(short)-height_);
                defaultGlyph.advance = cast(short)(height_ / 2);
                defaultGlyph.freetypeIndex = 0;
                defaultGlyph_ = defaultGlyph;
            }
            return *defaultGlyph_;
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
        Glyph renderGlyph(VideoDriver driver, const dchar c)
        {
            Glyph glyph;
            glyph.freetypeIndex = FT_Get_Char_Index(fontFace_, c);
            
            //load the glyph to fontFace_.glyph
            const uint loadFlags = FT_LOAD_TARGET_(renderMode()) | FT_LOAD_NO_BITMAP;
            if(FT_Load_Glyph(fontFace_, glyph.freetypeIndex, loadFlags) != 0) 
            { 
                return getDefaultGlyph(driver);
            }
            FT_GlyphSlot slot = fontFace_.glyph;

            //convert fontFace_.glyph to image
            if(FT_Render_Glyph(slot, renderMode()) == 0) 
            {
                glyph.advance  = cast(short)(fontFace_.glyph.advance.x / 64);
                glyph.offset.x = cast(short)slot.bitmap_left;
                glyph.offset.y = cast(short)-slot.bitmap_top;

                FT_Bitmap bitmap = slot.bitmap;
                const size = Vector2u(bitmap.width, bitmap.rows);

                if(size.x == 0 || size.y == 0)
                {
                    glyph.texture = getDefaultGlyph(driver).texture;
                    return glyph;
                }

                //image to create texture from
                auto image = Image(size.x, size.y, ColorFormat.GRAY_8);

                //return 255 if the bit at (x,y) is set. 0 otherwise.
                ubyte bitmapColor(uint x, uint y) 
                {
                    ubyte b = bitmap.buffer[y * bitmap.pitch + (x / 8)];
                    return cast(ubyte)((b & (0b10000000 >> (x % 8))) ? 255 : 0);
                }

                //copy freetype bitmap to our image
                if(antialiasing_)
                {
                    memcpy(image.dataUnsafe.ptr, bitmap.buffer, size.x * size.y);
                    //antialiasing makes the glyph appear darker so we make it lighter
                    image.gammaCorrect(1.2);
                }
                else
                {
                    foreach(y; 0 .. size.y) foreach(x; 0 .. size.x)
                    {
                        image.setPixelGray8(x, y, bitmapColor(x, y));
                    }
                }

                try{glyph.texture = driver.createTexture(image);}
                catch(TextureException e)
                {
                    writeln("Could not create glyph texture, falling back to default");
                    return getDefaultGlyph(driver);
                }

                return glyph;
            }
            else{return getDefaultGlyph(driver);}
        }
        
        ///Get freetype render mode (antialiased or bitmap)
        @property FT_Render_Mode renderMode() const pure
        {
            return antialiasing_ ? FT_Render_Mode.FT_RENDER_MODE_NORMAL 
                                 : FT_Render_Mode.FT_RENDER_MODE_MONO;
        }
}
