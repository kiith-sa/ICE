module video.fontmanager;


import std.c.string;

import derelict.freetype.ft;
import derelict.util.loader;
import derelict.util.exception;

import video.font;
import video.texture;
import math.math;
import math.vector2;
import singleton;
import color;
import arrayutil;
import allocator;


///Used by VideoDriver implementations to draw a string.
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
package final class FontManager
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
        in{assert(size < 128, "Font sizes greater than 127 are not supported");}
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
            return Vector2u(CurrentFont.text_width(text), CurrentFont.size);
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
