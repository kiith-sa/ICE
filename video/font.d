module video.font;


import std.c.string;

import derelict.freetype.ft;

import video.fontmanager;
import video.videodriver;
import video.texture;
import math.vector2;
import math.math;
import color;
import file;
import image;
import arrayutil;
import allocator;


//use of bytes here limits font size to about 128 pixels,
//but it also decreases struct size to 20 bytes allowing faster copying.
///Single font glyph.
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
package struct Font
{
    private:
        //Default glyph to use when there is no glyph for a character.
        Glyph DefaultGlyph;
        //Array storing fast glyphs. These are first FastGlyphCount unicode characters.
        Glyph*[] FastGlyphs;
        //Associative array storing other, "non-fast", glyphs.
        Glyph[dchar] Glyphs;

        string Name;
        //FreeType font face.
        FT_Face FontFace;

        //Height of the font in pixels.
        uint Height;
        //Does this font support kerning?
        bool UseKerning;

        //Number of glyphs accessible through normal instead of associative array.
        uint FastGlyphCount;

    public:
        ///Fake constructor. Loads font with specified name, size and number of glyphs.
        static Font opCall(string name, uint size, uint fast_glyphs)
        {
            Font font;
            font.ctor(name, size, fast_glyphs);
            return font;
        }

        ///Returns size of the font in pixels.
        uint size(){return Height;}

        ///Returns height of the font in pixels. (currently the same as size)
        uint height(){return Height;}

        ///Returns name of the font.
        string name(){return Name;}

        ///Does the font support kerning?
        bool kerning(){return UseKerning;}

        ///Returns FreeType font face of the font.
        FT_Face font_face(){return FontFace;}

        ///Returns width of text as it would be drawn.
        uint text_width(string str)
        {
            //previous glyph index, for kerning
			uint previous_index = 0;
			uint pen_x = 0;
            //current glyph index
            uint glyph_index;
            bool use_kerning = UseKerning && FontManager.get.kerning;
            FT_Vector kerning;
            Glyph * glyph;
			
			foreach(dchar chr; str) 
            {
                glyph = get_glyph(chr);
				glyph_index = glyph.freetype_index;
				
				if(use_kerning && previous_index != 0 && glyph_index != 0) 
                {
					//adjust the pen for kerning
					FT_Get_Kerning(FontFace, previous_index, glyph_index, 
                                   FT_Kerning_Mode.FT_KERNING_DEFAULT, &kerning);
					pen_x += kerning.x / 64;
				}

                pen_x += glyph.advance;
			}
            return pen_x;
        }

        ///Destroy the font and free its resources.
        void die()
        {
            foreach(glyph; FastGlyphs)
            {
                if(glyph !is null)
                {
                    //some glyphs might share texture with default glyph
                    if(glyph.texture != DefaultGlyph.texture)
                    {
                        VideoDriver.get.delete_texture(glyph.texture);
                    }
                    free(glyph);
                    glyph = null;
                }
            }
            foreach(glyph; Glyphs)
            {
                VideoDriver.get.delete_texture(glyph.texture);
            }

            VideoDriver.get.delete_texture(DefaultGlyph.texture);
            FT_Done_Face(FontFace);
        }

    package:
        ///Access glyph for specified (UTF-32) character.
        Glyph* get_glyph(dchar c)
        {
            //if c has a fast glyph (first FastGlyphCount characters)
            if(c < FastGlyphCount)
            {
                //if this glyph doesn't exist yet, render and add it
                if(FastGlyphs[c] is null)
                {
                    FastGlyphs[c] = alloc!(Glyph)();
                    *FastGlyphs[c] = render_glyph(c);
                }
                return FastGlyphs[c];
            }

            //if c does not have a fast glyph, get if from the associative array
            Glyph* glyph = c in Glyphs;
            //if this glyph doesn't exist yet, render and add it
            if(glyph is null)
            {
                Glyphs[c] = render_glyph(c);
                return c in Glyphs;
            }
            return glyph;
        }

    private:
        //Load font with specified name, size and number of fast glyphs.
        void ctor(string name, uint size, uint fast_glyphs)
        {
            FastGlyphs = new Glyph*[fast_glyphs];
            FastGlyphCount = fast_glyphs;
            Name = name;

            //this should be replaced by the resource manager later
            name = "./data/fonts/" ~ name;
            ubyte[] FontData = load_file(name);

            FT_Open_Args args;
            args.memory_base = FontData.ptr;
            args.memory_size = FontData.length;
            args.flags = FT_OPEN_MEMORY;
            args.driver = null;
            //we only support face 0 right now, so no bold, italic, etc. 
            //unless it is in a separate font file.
            int face = 0;
            
            //load face from memory buffer (FontData)
            if(FT_Open_Face(FontManager.freetype, &args, face, &FontFace) != 0) 
            {
                throw new Exception("Couldn't load font face from font: " ~ name);
            }
            
            //set font size in pixels
            //could use a better approach, but worked for all fonts so far.
            if(FT_Set_Pixel_Sizes(FontFace, 0, size) != 0)
            {
                throw new Exception("Couldn't set pixel size with font: " ~ name);
            }

            Height = size;
            UseKerning = cast(bool)FT_HAS_KERNING(FontFace);
            init_default_glyph();
        }

        ///Initialize default (placeholder) glyph.
        void init_default_glyph()
        {
            scope Image image = new Image(Height / 2, Height);
            DefaultGlyph.texture = VideoDriver.get.create_texture(image);
            DefaultGlyph.offset = Vector2b(0, -Height);
            DefaultGlyph.advance = Height / 2;
            DefaultGlyph.freetype_index = 0;
        }

        ///Render a glyph for specified character and return it.
        Glyph render_glyph(dchar c)
        {
            Glyph glyph;
            glyph.freetype_index = FT_Get_Char_Index(FontFace, c);
            
            //load the glyph to FontFace.glyph
            uint load_flags = FT_LOAD_TARGET_(render_mode()) | FT_LOAD_NO_BITMAP;
            if(FT_Load_Glyph(FontFace, glyph.freetype_index, load_flags) != 0) 
            { 
                return DefaultGlyph;
            }
			FT_GlyphSlot slot = FontFace.glyph;

            //convert the FontFace.glyph to image
			if(FT_Render_Glyph(slot, render_mode()) == 0) 
            {
                glyph.advance = FontFace.glyph.advance.x / 64;
                glyph.offset.x = slot.bitmap_left;
                glyph.offset.y = -slot.bitmap_top;

                FT_Bitmap bitmap = slot.bitmap;
                Vector2u size = Vector2u(bitmap.width, bitmap.rows);
                assert(size.x < 128 && size.y < 128, 
                       "Can't draw a glyph wider or taller than 127 pixels");
                //we don't want to crash or cause bugs in optimized builds
                if(size.x >= 128 || size.y >= 128 || size.x == 0 || size.y == 0)
                {
                    glyph.texture = DefaultGlyph.texture;
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
                if(FontManager.get.antialiasing)
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

                glyph.texture = VideoDriver.get.create_texture(image);
                return glyph;
            }
            else{return DefaultGlyph;}
        }
        
        ///Get freetype render mode (antialiased or bitmap)
		FT_Render_Mode render_mode() 
        {
			if(FontManager.get.antialiasing)
            {
                return FT_Render_Mode.FT_RENDER_MODE_NORMAL;
            }
            else{return FT_Render_Mode.FT_RENDER_MODE_MONO;}
		}
}
