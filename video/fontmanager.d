
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Font manager and text drawing code abstracted from the video driver.
module video.fontmanager;


import core.stdc.string;

import std.algorithm;
import std.stdio;
import std.typecons;

import derelict.freetype.ft;
import derelict.util.loader;
import derelict.util.exception;

import video.videodriver;
import video.font;
import video.texture;
import file.fileio;
import math.math;
import math.vector2;
import memory.memory;
import containers.vector;
import util.weaksingleton;
import color;
alias file.file.File File;


package:

///Used by VideoDriver implementations to draw a string.
align(4) struct FontRenderer
{
    private:
        ///Font we're drawing with.
        Font drawFont_;
        ///Does this font use kerning?
        bool kerning_;
        ///FreeType font face of the font.
        FT_Face fontFace_;
        ///Freetype index of the previously drawn glyph (0 at first glyph).
        uint previousIndex_;
        ///Current x position of the pen.
        uint PenX;

    public:
        ///Get height of the font we're drawing.
        @property uint height() const pure {return drawFont_.height;}

        ///Start drawing a string.
        void start()
        {
            fontFace_      = drawFont_.fontFace;
            kerning_        = drawFont_.kerning && kerning_;
            previousIndex_ = PenX = 0;
        }

        /**
         * Determine if the glyph of a character is loaded.
         *
         * Params:  c = Character to check.
         *
         * Returns: True if the glyph is loaded, false otherwise.
         */
        bool hasGlyph(const dchar c) const {return drawFont_.hasGlyph(c);}

        /**
         * Load glyph for a character.
         *
         * Will render the glyph and create a texture for it.
         * 
         * Params:  driver = Video driver to use for texture creation.
         *          c      = Character to load glyph for.
         *
         * Throws:  TextureException if the glyph texture could not be created.
         */
        void loadGlyph(VideoDriver driver, const dchar c){drawFont_.loadGlyph(driver, c);}

        /**
         * Get glyph texture and offset to draw a glyph at.
         *
         * Params:  c      = Character we're drawing.
         *          offset = Offset to draw the glyph at will be written here
         *                   (relative to string start).
         *
         * Returns: Pointer to the texture of the glyph.
         */
        const(Texture*) glyph(const dchar c, out Vector2u offset)
        {
            const glyph = drawFont_.getGlyph(c);
            const uint glyphIndex = glyph.freetypeIndex;

            //adjust pen with kering information
            if(kerning_ && previousIndex_ != 0 && glyphIndex != 0)
            {
                FT_Vector kerning;
                FT_Get_Kerning(fontFace_, previousIndex_, glyphIndex, 
                               FT_Kerning_Mode.FT_KERNING_DEFAULT, &kerning);
                PenX += kerning.x / 64;
            }

            offset.x        = PenX + glyph.offset.x;
            offset.y        = glyph.offset.y;
            previousIndex_ = glyphIndex;

            //move pen to the next glyph
            PenX += glyph.advance;
            return &glyph.texture;
        }

        /**
         * Get size of text as it would be drawn in pixels.
         *
         * Params:  text = Text to get size of.
         *
         * Returns: Size of the text in X and Y. Y might be slightly imprecise.
         */
        Vector2u textSize(const string text)
        {
            //Y size could be determined more precisely by getting
            //minimum and maximum extents of the text.
            return Vector2u(drawFont_.textWidth(text, kerning_), drawFont_.size);
        }
}

///Manages all font resources. 
final class FontManager
{
    mixin WeakSingleton;
    private:
        ///FreeType library handle.
        FT_Library freetypeLib_;

        ///All currently loaded fonts. fonts_[0] is the default font.
        Font[] fonts_;

        ///Buffers storing font file data indexed by file names.
        //Vector!(ubyte)[string] fontFiles_; //can't use this due to compiler bug
        alias Tuple!(string, "name", ubyte[], "data") FontData;
        FontData[] fontFiles_;
        
        ///Fallback font name.
        string defaultFontName_ = "DejaVuSans.ttf";
        ///Fallback font size.
        uint defaultFontSize_ = 12;

        ///Currently set font.
        Font currentFont_;
        ///Currently set font name.
        string fontName_;
        ///Currently set font size.
        uint fontSize_;

        /**
         * Default number of quickly accessible characters in fonts.
         * Glyphs up to this unicode index will be stored in a normal 
         * instead of associative array, speeding up their retrieval.
         * 512 covers latin with most important extensions.
         */
        uint fastGlyphs_ = 512;

        ///Is font antialiasing enabled?
        bool antialiasing_ = true;
        ///Is kerning enabled?
        bool kerning_ = true;
        
    public:
        /**
         * Construct the font manager, load default font.
         *
         * Throws:  FontException on failure.
         */
        this()
        {
            writeln("Initializing FontManager");
            scope(failure){writeln("FontManager initialization failed");}

            singletonCtor();
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
                if(FT_Init_FreeType(&freetypeLib_) != 0 || freetypeLib_ is null)
                {
                    throw new FontException("FreeType initialization error");
                }
                try
                {
                    loadFontFile(defaultFontName_);
                    //load default font.
                    fonts_ ~= new Font(freetypeLib_, getFont(defaultFontName_),
                                       defaultFontName_, defaultFontSize_, 
                                       fastGlyphs_, antialiasing_);
                    currentFont_ = fonts_[$ - 1];
                    fontName_    = defaultFontName_;
                    fontSize_    = defaultFontSize_;
                }
                catch(FileIOException e)
                {
                    throw new FontException("Could not open file with default font: " ~ e.msg);
                }
                catch(FontException e)
                {
                    throw new FontException("Could not load default font: " ~ e.msg);
                }
            }
            catch(SharedLibLoadException e)
            {
                throw new FontException("Could not load FreeType library: " ~ e.msg);
            }
        }

        /**
         * Delete all glyph textures from the video driver.
         *
         * Params:  driver = VideoDriver to unload textures from.
         */
        void unloadTextures(VideoDriver driver)
        {
            foreach(ref font; fonts_){font.unloadTextures(driver);}
        }

        /**
         * Load glyph textures back to the video driver.
         *
         * Params:  driver = VideoDriver to load textures to.
         *
         * Throws:  TextureException if the glyph textures could not be reloaded.
         */
        void reloadTextures(VideoDriver driver)
        {
            foreach(ref font; fonts_){font.reloadTextures(driver);}
        }

        /**
         * Destroy the FontManager. 
         *
         * To destroy all FontManager resources, unloadTextures must be called first.
         */
        ~this()
        {
            writeln("Destroying FontManager");
            foreach(ref font; fonts_){clear(font);}
            foreach(ref pair; fontFiles_){free(pair.data);}
            clear(fonts_);
            clear(fontFiles_);
            FT_Done_FreeType(freetypeLib_);
            DerelictFT.unload(); 
            singletonDtor();
        }

        /**
         * Set font to use.
         *
         * Params:  fontName  = Name of the font to set.
         *          forceLoad = Force the font to be set right now and loaded 
         *                       if it's not loaded yet.
         */
        void font(string fontName, const bool forceLoad = false)
        {
            //if "default", use default font
            if(fontName == "default"){fontName = defaultFontName_;}
            fontName_ = fontName;
            if(forceLoad){loadFont();}
        }

        /**
         * Set font size to use.
         *
         * Params:  size       = Font size to set.
         *          forceLoad = Force the font size to be set right now and font loaded
         *                       if it's not loaded yet.
         */
        void fontSize(uint size, const bool forceLoad = false)
        in{assert(size < 128, "Font sizes greater than 127 are not supported");}
        body
        {
            //In optimized build, we don't have the assert so force size to at most 127
            size = min(size, 127u);
            fontSize_ = size;
            if(forceLoad){loadFont();}
        }

        ///Return a renderer to draw text with.
        FontRenderer renderer()
        {
            loadFont();
            return FontRenderer(currentFont_, kerning_);
        }

        ///Is font antialiasing enabled?
        @property bool antialiasing() const pure {return antialiasing_;}
      
        ///Is kerning enabled?
        @property bool kerning() const pure {return kerning_;}

    private:
        //might be replaced by serious resource management.
        /**
         * Load font data from a file if it's not loaded yet. 
         *
         * Params:  name = Name of the font in the fonts/ directory.
         * 
         * Throws:  FileIOException if the font file name is invalid or it could not be opened.
         */
        void loadFontFile(const string name)
        {
            scope(failure){writeln("Could not read from font file: " ~ name);}

            //already loaded
            foreach(ref pair; fontFiles_) if(pair.name == name)
            {
                return;
            }

            File file = File("fonts/" ~ name, FileMode.Read);
            auto bytes = cast(ubyte[])file.data;
            fontFiles_ ~= FontData(name, cast(ubyte[])null);
            fontFiles_[$ - 1].data = allocArray!ubyte(bytes.length);
            fontFiles_[$ - 1].data[] = bytes[];
        }

        /**
         * Try to set font according to fontName_ and fontSize_.
         *
         * Will load the font if needed, and if it can't load, will
         * try to fall back to default font with fontSize_. If that can't
         * be done either, will set the default font and font size loaded at startup.
         */
        void loadFont()
        {
            //Font is already set
            if(currentFont_.name == fontName_ && currentFont_.size == fontSize_)
            {
                return;
            }

            bool findFont(ref Font font)
            {
                return font.name == fontName_ && font.size == fontSize_;
            }
            auto found = find!findFont(fonts_);

            //Font is already loaded, set it
            if(found.length > 0)
            {
                currentFont_ = found[0];
                return;
            }

            //fallback scenario when the font could not be loaded 
            void fallback(const string error)
            {
                writeln("Failed to load font: ", fontName_);
                writeln(error);

                //If we already have default font name and can't load it, 
                //try font 0 (default with default size)
                if(fontName_ == defaultFontName_)
                {
                    currentFont_ = fonts_[0];
                    return;
                }
                //Couldn't load the font, try default with our size
                fontName_ = defaultFontName_;
                loadFont();
            }

            //Font is not loaded, try to load it
            Font newFont;
            try
            {
                loadFontFile(fontName_);
                newFont = new Font(freetypeLib_, getFont(fontName_), fontName_, 
                                    fontSize_, fastGlyphs_, antialiasing_);
                //Font was succesfully loaded, set it
                fonts_ ~= newFont;
                currentFont_ = fonts_[$ - 1];
            }
            catch(FileIOException e){fallback("Font file could not be read: " ~ e.msg);}
            catch(FontException e){fallback("FreeType error: " ~ e.msg);}
        }

        ///Get data of font with specified name.
        ubyte[] getFont(string name)
        {
            foreach(ref pair; fontFiles_) if(name == pair.name)
            {
                return pair.data;
            }
            assert(false, "No font with name " ~ name);
        }
}
