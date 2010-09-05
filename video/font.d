module video.font;


import std.c.string;
import std.stdio;

import derelict.freetype.ft;
import derelict.util.loader;
import derelict.util.exception;

import video.videodriver;
import video.texture;
import math.vector2;
import math.math;
import singleton;
import color;
import file;
import image;
import arrayutil;
import allocator;


//use of bytes here limits font size to about 128 pixels,
//but it also decreases struct size to 20 bytes allowing faster copying.
///Single font glyph.
private align(4) struct Glyph
{
    Texture texture;
    //freetype glyph index
    uint freetype_index;
    //offset from pen to the bottom-left corner of glyph image
    Vector2b offset;
    //how much to advance the pen after drawing this glyph
    byte advance;
}

///Used by VideoDriver implementation to draw a string.
package align(1) struct FontRenderer
{
    private:
        //Font we're drawing with.
        Font DrawFont;
        //FreeType font face of the font.
        FT_Face FontFace;
        //Does this font use kerning?
        bool UseKerning;
        //Freetype index of the previously drawn glyph (0 at first glyph).
        uint PreviousIndex;
        //Current x position of the pen.
        uint PenX;

    public:
        ///Return height of the font we're drawing.
        uint height(){return DrawFont.height;}

        ///Start drawing a string.
        void start()
        {
            FontFace = DrawFont.font_face;
            UseKerning = DrawFont.kerning && FontManager.get.kerning;
            PreviousIndex = PenX = 0;
        }

        ///Get texture, offset (relative to string start) to draw a character at.
        Texture* glyph(dchar c, out Vector2u offset)
        {
            Glyph* glyph = DrawFont.get_glyph(c);
            uint glyph_index = glyph.freetype_index;

            //adjust pen with kering information
            if(UseKerning && PreviousIndex != 0 && glyph_index != 0)
            {
                FT_Vector kerning;
                FT_Get_Kerning(FontFace, PreviousIndex, glyph_index, 
                               FT_Kerning_Mode.FT_KERNING_DEFAULT, &kerning);
                PenX += kerning.x / 64;
            }

            offset.x = PenX + glyph.offset.x;
            offset.y = glyph.offset.y;
            PreviousIndex = glyph_index;

            //move pen to the next glyph
            PenX += glyph.advance;
            return &glyph.texture;
        }
}

///Handles all font resources. 
package class FontManager
{
    mixin Singleton;
    private:
        static FT_Library FreeTypeLib;
        Font[] Fonts;
        
        //Fallback font: Fonts[0] will be loaded with these parameters.
        string DefaultFontName = "DejaVuSans.ttf";
        uint DefaultFontSize = 12;

        //Currently set font.
        Font CurrentFont;

        //Currently set font name and size
        string FontName;
        uint FontSize;

        //Default number of quickly accessible characters in fonts.
        //Glyphs up to this unicode index will be stored in a normal 
        //instead of associative array, speeding up their retrieval.
        //512 covers latin with most important extensions.
        uint FastGlyphs = 512;

        //Is font antialiasing enabled?
        bool Antialiasing = true;
        //Is kerning enabled?
        bool Kerning = true;
        
    public:
        //Construct the font manager, load default font.
        this()
        {
            singleton_ctor();
            try
            {
                //sometimes FreeType is missing a function we don't use, 
                //we don't want to crash in that case.
                Derelict_SetMissingProcCallback(function bool(string a, string b)
                                                {return true;});
                //load FreeType library
                DerelictFT.load(); 
                Derelict_SetMissingProcCallback(null);
                //initialize FreeType
                if(FT_Init_FreeType(&FreeTypeLib) != 0 || FreeTypeLib is null)
                {
                    throw new Exception("FreeType initialization error");
                }
                try
                {
                    //load default font.
                    Fonts ~= Font(DefaultFontName, DefaultFontSize, FastGlyphs);
                    CurrentFont = Fonts[$ - 1];
                    FontName = DefaultFontName;
                    FontSize = DefaultFontSize;
                }
                catch
                {
                    throw new Exception("Could not load default font.");
                }
            }
            catch(SharedLibLoadException e)
            {
                throw new Exception("Could not load FreeType library");
            }
        }

        ///Destroy the FontManager. Should only be called at shutdown.
        void die()
        {
            foreach(ref font; Fonts){font.die();}
            Fonts = [];
            FT_Done_FreeType(FreeTypeLib);
            DerelictFT.unload(); 
        }

        ///Set font to use. force_load will set font (load if needed) immediately.
        void font(string font_name, bool force_load = false)
        {
            //use default font
            if(font_name == "default"){font_name = DefaultFontName;}
            FontName = font_name;
            if(force_load){load_font();}
        }

        ///Set font size to use. force_load will set font (load if needed) immediately.
        void font_size(uint size, bool force_load = false)
        in
        {
            assert(size < 128, "Font sizes greater than 127 are not supported");
        }
        body
        {
            //In optimized build, we don't have the assert so force size to at most 127
            size = min(size, 127u);
            FontSize = size;
            if(force_load){load_font();}
        }

        ///Get size of text as it would be drawn in pixels.
        Vector2u text_size(string text)
        {
            load_font();
            return Vector2u(CurrentFont.text_width(text), 
                            CurrentFont.size);
        }

        ///Return renderer to draw text with.
        FontRenderer renderer()
        {
            load_font();
            return FontRenderer(CurrentFont);
        }

        ///Try to set font according to FontName and FontSize.
        /**
         * Will load the font if needed, and if it can't load, will
         * try to fall back to default font with FontSize. If that can't
         * be done either, will set the default font loaded at startup.
         */
        void load_font()
        {
            //Font is already set
            if(CurrentFont.name == FontName && CurrentFont.size == FontSize)
            {
                return;
            }

            bool find_font(ref Font font)
            {
                return font.name == FontName && font.size == FontSize;
            }
            int index = Fonts.find(&find_font);

            //Font is already loaded, set it
            if(index >= 0)
            {
                CurrentFont = Fonts[index];
                return;
            }

            //Font is not loaded, try to load it
            Font new_font;
            try
            {
                new_font = Font(FontName, FontSize, FastGlyphs);
                //Font was succesfully loaded, set it
                Fonts ~= new_font;
                CurrentFont = Fonts[$ - 1];
            }
            catch
            {
                //If we already have default font name and can't load it, 
                //try font 0 (default with default size)
                if(FontName == DefaultFontName)
                {
                    CurrentFont = Fonts[0];
                    return;
                }
                //Couldn't load the font, try default with our size
                FontName = DefaultFontName;
                load_font();
            }
        }
    
        ///Return handle to FreeType library used by the manager.
        static FT_Library freetype(){return FreeTypeLib;}

        ///Return bool specifying whether or not font antialiasing is enabled.
        bool antialiasing(){return Antialiasing;}
      
        ///Return bool specifying whether or not font antialiasing is enabled.
        bool kerning(){return Kerning;}
}

///Stores one font with one size (e.g. Inconsolata size 16 and 18 will be two Font objects).
private struct Font
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
        static Font opCall(string name, uint size, uint fast_glyphs)
        {
            Font font;
            font.ctor(name, size, fast_glyphs);
            return font;
        }

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

    private:
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
            else
            {
                return DefaultGlyph;
            }
        }
        
        ///Get freetype render mode (antialiased or bitmap)
		FT_Render_Mode render_mode() 
        {
			if(FontManager.get.Antialiasing)
            {
                return FT_Render_Mode.FT_RENDER_MODE_NORMAL;
            }
            else{return FT_Render_Mode.FT_RENDER_MODE_MONO;}
		}
}
