
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Font manager and text drawing code abstracted from the video driver.
module video.fontmanager;
@system


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
align(1) struct FontRenderer
{
    private:
        ///Font we're drawing with.
        Font draw_font_;
        ///Does this font use kerning?
        bool kerning_;
        ///FreeType font face of the font.
        FT_Face font_face_;
        ///Freetype index of the previously drawn glyph (0 at first glyph).
        uint previous_index_;
        ///Current x position of the pen.
        uint PenX;

    public:
        ///Get height of the font we're drawing.
        @property uint height() const {return draw_font_.height;}

        ///Start drawing a string.
        void start()
        {
            font_face_ = draw_font_.font_face;
            kerning_ = draw_font_.kerning && kerning_;
            previous_index_ = PenX = 0;
        }

        /**
         * Determine if the glyph of a character is loaded.
         *
         * Params:  c = Character to check.
         *
         * Returns: True if the glyph is loaded, false otherwise.
         */
        bool has_glyph(in dchar c) const {return draw_font_.has_glyph(c);}

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
        void load_glyph(VideoDriver driver, in dchar c){draw_font_.load_glyph(driver, c);}

        /**
         * Get glyph texture and offset to draw a glyph at.
         *
         * Params:  c      = Character we're drawing.
         *          offset = Offset to draw the glyph at will be written here
         *                   (relative to string start).
         *
         * Returns: Pointer to the texture of the glyph.
         */
        const(Texture*) glyph(in dchar c, out Vector2u offset)
        {
            const glyph = draw_font_.get_glyph(c);
            const uint glyph_index = glyph.freetype_index;

            //adjust pen with kering information
            if(kerning_ && previous_index_ != 0 && glyph_index != 0)
            {
                FT_Vector kerning;
                FT_Get_Kerning(font_face_, previous_index_, glyph_index, 
                               FT_Kerning_Mode.FT_KERNING_DEFAULT, &kerning);
                PenX += kerning.x / 64;
            }

            offset.x = PenX + glyph.offset.x;
            offset.y = glyph.offset.y;
            previous_index_ = glyph_index;

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
        Vector2u text_size(in string text)
        {
            //Y size could be determined more precisely by getting
            //minimum and maximum extents of the text.
            return Vector2u(draw_font_.text_width(text, kerning_), draw_font_.size);
        }
}

///Manages all font resources. 
final class FontManager
{
    mixin WeakSingleton;
    private:
        ///FreeType library handle.
        FT_Library freetype_lib_;

        ///All currently loaded fonts. fonts_[0] is the default font.
        Font[] fonts_;

        ///Buffers storing font file data indexed by file names.
        //Vector!(ubyte)[string] font_files_; //can't use this due to compiler bug
        alias Tuple!(string, "name", Vector!ubyte, "data") FontData;
        FontData[] font_files_;
        
        ///Fallback font name.
        string default_font_name_ = "DejaVuSans.ttf";
        ///Fallback font size.
        uint default_font_size_ = 12;

        ///Currently set font.
        Font current_font_;
        ///Currently set font name.
        string font_name_;
        ///Currently set font size.
        uint font_size_;

        /**
         * Default number of quickly accessible characters in fonts.
         * Glyphs up to this unicode index will be stored in a normal 
         * instead of associative array, speeding up their retrieval.
         * 512 covers latin with most important extensions.
         */
        uint fast_glyphs_ = 512;

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
                if(FT_Init_FreeType(&freetype_lib_) != 0 || freetype_lib_ is null)
                {
                    throw new FontException("FreeType initialization error");
                }
                try
                {
                    load_font_file(default_font_name_);
                    //load default font.
                    fonts_ ~= new Font(freetype_lib_, get_font(default_font_name_),
                                       default_font_name_, default_font_size_, 
                                       fast_glyphs_, antialiasing_);
                    current_font_ = fonts_[$ - 1];
                    font_name_ = default_font_name_;
                    font_size_ = default_font_size_;
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
        void unload_textures(VideoDriver driver)
        {
            foreach(ref font; fonts_){font.unload_textures(driver);}
        }

        /**
         * Load glyph textures back to the video driver.
         *
         * Params:  driver = VideoDriver to load textures to.
         *
         * Throws:  TextureException if the glyph textures could not be reloaded.
         */
        void reload_textures(VideoDriver driver)
        {
            foreach(ref font; fonts_){font.reload_textures(driver);}
        }

        /**
         * Destroy the FontManager. 
         *
         * To destroy all FontManager resources, unload_textures must be called first.
         */
        ~this()
        {
            writeln("Destroying FontManager");
            foreach(ref font; fonts_){clear(font);}
            foreach(ref pair; font_files_){clear(pair.data);}
            clear(fonts_);
            clear(font_files_);
            FT_Done_FreeType(freetype_lib_);
            DerelictFT.unload(); 
            singleton_dtor();
        }

        /**
         * Set font to use.
         *
         * Params:  font_name  = Name of the font to set.
         *          force_load = Force the font to be set right now and loaded 
         *                       if it's not loaded yet.
         */
        void font(string font_name, in bool force_load = false)
        {
            //if "default", use default font
            if(font_name == "default"){font_name = default_font_name_;}
            font_name_ = font_name;
            if(force_load){load_font();}
        }

        /**
         * Set font size to use.
         *
         * Params:  size       = Font size to set.
         *          force_load = Force the font size to be set right now and font loaded
         *                       if it's not loaded yet.
         */
        void font_size(uint size, in bool force_load = false)
        in{assert(size < 128, "Font sizes greater than 127 are not supported");}
        body
        {
            //In optimized build, we don't have the assert so force size to at most 127
            size = min(size, 127u);
            font_size_ = size;
            if(force_load){load_font();}
        }

        ///Return a renderer to draw text with.
        FontRenderer renderer()
        {
            load_font();
            return FontRenderer(current_font_, kerning_);
        }

        ///Is font antialiasing enabled?
        @property bool antialiasing() const {return antialiasing_;}
      
        ///Is kerning enabled?
        @property bool kerning() const {return kerning_;}

    private:
        //might be replaced by serious resource management.
        /**
         * Load font data from a file if it's not loaded yet. 
         *
         * Params:  name = Name of the font in the fonts/ directory.
         * 
         * Throws:  FileIOException if the font file name is invalid or it could not be opened.
         */
        void load_font_file(in string name)
        {
            scope(failure){writeln("Could not read from font file: " ~ name);}

            //already loaded
            foreach(ref pair; font_files_) if(pair.name == name)
            {
                return;
            }


            //TODO Get rid of Vector or improve it to be usable here
            // (according to std.container.array) 
            // - either use refcounting or disable copying/assignment
            File file = File("fonts/" ~ name, FileMode.Read);
            auto bytes = cast(ubyte[])file.data;
            font_files_ ~= FontData(name, Vector!ubyte());
            clear(font_files_[$ - 1].data);
            font_files_[$ - 1].data = Vector!ubyte(bytes);
        }

        /**
         * Try to set font according to font_name_ and font_size_.
         *
         * Will load the font if needed, and if it can't load, will
         * try to fall back to default font with font_size_. If that can't
         * be done either, will set the default font and font size loaded at startup.
         */
        void load_font()
        {
            //Font is already set
            if(current_font_.name == font_name_ && current_font_.size == font_size_)
            {
                return;
            }

            bool find_font(ref Font font)
            {
                return font.name == font_name_ && font.size == font_size_;
            }
            auto found = find!find_font(fonts_);

            //Font is already loaded, set it
            if(found.length > 0)
            {
                current_font_ = found[0];
                return;
            }

            //fallback scenario when the font could not be loaded 
            void fallback(in string error)
            {
                writeln("Failed to load font: ", font_name_);
                writeln(error);

                //If we already have default font name and can't load it, 
                //try font 0 (default with default size)
                if(font_name_ == default_font_name_)
                {
                    current_font_ = fonts_[0];
                    return;
                }
                //Couldn't load the font, try default with our size
                font_name_ = default_font_name_;
                load_font();
            }

            //Font is not loaded, try to load it
            Font new_font;
            try
            {
                load_font_file(font_name_);
                new_font = new Font(freetype_lib_, get_font(font_name_), font_name_, 
                                    font_size_, fast_glyphs_, antialiasing_);
                //Font was succesfully loaded, set it
                fonts_ ~= new_font;
                current_font_ = fonts_[$ - 1];
            }
            catch(FileIOException e){fallback("Font file could not be read: " ~ e.msg);}
            catch(FontException e){fallback("FreeType error: " ~ e.msg);}
        }

        ///Get data of font with specified name.
        ref Vector!ubyte get_font(string name)
        {
            foreach(ref pair; font_files_)
            {
                if(name == pair.name){return pair.data;}
            }
            assert(false, "No font with name " ~ name);
        }
}
