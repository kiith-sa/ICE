
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module video.glvideodriver;


import std.string;
import std.stdio;

import derelict.opengl.gl;
import derelict.util.exception;

import video.videodriver;
import video.glshader;
import video.gltexture;
import video.gltexturepage;
import video.glrenderer;
import video.gldrawmode;
import video.shader;
import video.texture;
import video.fontmanager;
import video.glmonitor;
import math.math;
import math.vector2;
import math.line2;
import math.rectangle;
import platform.platform;
import gui.guielement;
import monitor.monitormenu;
import color;
import image;
import memory.memory;
import util.signal;
import util.exception;


/**
 * OpenGL (currently a mix of 1.x and 2.x, planning to be purely 2.x) based video driver.
 *
 * Most of the actual drawing is done by GLRenderer, GLVideoDriver basically
 * manages other GL video classes.
 * 
 * Signal:
 *     package mixin Signal!(Statistics) send_statistics
 *
 *     Used to send statistics data to GL monitors.
 */
abstract class GLVideoDriver : VideoDriver
{
    protected:
        ///Video mode width in pixels.
        uint screen_width_ = 0;
        ///Video mode height in pixels.
        uint screen_height_ = 0;
    
    private:
        ///Derelict OpenGL version.
        GLVersion version_;

        ///Shader used to draw lines and rectangles without textures.
        Shader plain_shader_;
        ///Shader used to draw textured surfaces.
        Shader texture_shader_;
        ///Shader used to draw fonts.
        Shader font_shader_;
        ///Shaders.
        GLShader* [] shaders_;
        ///Index of currently used shader; uint.max means none.
        uint current_shader_ = uint.max;

        ///Texture pages.
        TexturePage* [] pages_;
        ///Index of currently used page; uint.max means none.
        uint current_page_ = uint.max;
        ///Textures.
        GLTexture* [] textures_;
                              
        ///Statistics data for monitoring.
        Statistics statistics_;


        ///Caches vertices and draws them at the end of frame.
        GLRenderer renderer_;

    package:
        ///Used to send statistics data to GL monitors.
        mixin Signal!(Statistics) send_statistics;
        
    public:
        /**
         * Construct a GLVideoDriver.
         *
         * Params:  font_manager = Font manager to use for font rendering and management.
         */
        this(FontManager font_manager)
        {
            super(font_manager);
            DerelictGL.load();
        }

        override void die()
        {
            super.die();

            if(renderer_.initialized){renderer_.die();}

            delete_shader(plain_shader_);
            delete_shader(texture_shader_);
            delete_shader(font_shader_);

            //delete any remaining texture pages
            foreach(ref page; pages_)
            {
                if(page !is null)
                {
                    free(page);
                    page = null;
                }
            }

            //delete any remaining textures
            foreach(ref texture; textures_)
            {
                if(texture !is null)
                {
                    free(texture);
                    texture = null;
                }
            }

            //delete any remaining shaders
            foreach(ref shader; shaders_)
            {
                if(shader !is null)
                {
                    free(shader);
                    shader = null;
                }
            }

            pages_ = [];
            textures_ = [];
            shaders_ = [];

            send_statistics.disconnect_all();

            DerelictGL.unload();
        }

        override void start_frame()
        {
            glClear(GL_COLOR_BUFFER_BIT);
            setup_viewport();

            //disable current page
            current_page_ = uint.max;
            //disable current shader
            current_shader_ = uint.max;

            renderer_.reset();

            send_statistics.emit(statistics_);
            statistics_.zero();
        }

        override void end_frame()
        {
            renderer_.render(screen_width_, screen_height_);
            glFlush();
        }

        final override void scissor(ref Rectanglei scissor_area)
        {
            //convert to GL coords (origin on the bottom-left instead of top-left)
            Rectanglei translated = scissor_area;
            translated.min.y = screen_height_ - translated.max.y;
            translated.max.y = translated.min.y + scissor_area.height;
            renderer_.scissor(translated);
        }

        final override void disable_scissor(){renderer_.disable_scissor();}

        final override void draw_line(Vector2f v1, Vector2f v2, Color c1, Color c2)
        {
            //can't draw zero-sized lines
            //optimized, fast comparison, but not fuzzy
            //if(v1 != v2)
            if(*(cast(ulong*)&v1) != *(cast(ulong*)&v2))
            {
                ++statistics_.lines;

                set_shader(plain_shader_);
                renderer_.draw_line(v1, v2, c1, c2);
            }
        }

        final override void draw_filled_rectangle(Vector2f min, Vector2f max, Color color)
        {
            statistics_.rectangles += 1;
            statistics_.vertices += 4;

            set_shader(plain_shader_);

            renderer_.draw_rectangle(min, max, color);
        }

        final override void draw_texture(Vector2i position, ref Texture texture)
        {
            assert(texture.index < textures_.length, "Texture index out of bounds");

            ++statistics_.textures;
            statistics_.vertices += 4;

            set_shader(texture_shader_);

            GLTexture* gl_texture = textures_[texture.index];
            assert(gl_texture !is null, "Trying to draw a nonexistent texture");
            uint page_index = gl_texture.page_index;
            assert(pages_[page_index] !is null, "Trying to draw a texture from"
                                               " a nonexistent page");
            if(current_page_ != page_index)
            {
                ++statistics_.page;
                current_page_ = page_index;
                renderer_.set_texture_page(pages_[page_index]);
            }

            Vector2f vmin = to!(float)(position);
            renderer_.draw_texture(vmin, vmin + to!(float)(texture.size), 
                                   gl_texture.texcoords.min, gl_texture.texcoords.max);
        }
        
        final override void draw_text(Vector2i position, string text, Color color)
        {
            ++statistics_.texts;

            //font textures are grayscale and use a shader
            //to convert grayscale to alpha
            set_shader(font_shader_);

            FontRenderer renderer = font_manager_.renderer();
            renderer.start();

            //offset of the current character relative to position
            Vector2u offset;

            Texture* texture;
            GLTexture* gl_texture;
            uint page_index;

            //vertices and texcoords for current character
            Vector2f vmin;
            Vector2f vmax;
            Vector2f tmin;
            Vector2f tmax;

            //make up for the fact that fonts are drawn from lower left corner
            //instead of upper left
            position.y += renderer.height;

            glColor4ub(color.r, color.g, color.b, color.a);

            try
            {
                //iterating over utf-32 chars (conversion is automatic)
                foreach(dchar c; text)
                {
                    ++statistics_.characters;
                    statistics_.vertices += 4;

                    if(!renderer.has_glyph(c)){renderer.load_glyph(this, c);}
                    texture = renderer.glyph(c, offset);

                    gl_texture = textures_[texture.index];
                    page_index = gl_texture.page_index;

                    //change texture page if needed
                    if(current_page_ != page_index)
                    {
                        ++statistics_.page;
                        current_page_ = page_index;
                        renderer_.set_texture_page(pages_[page_index]);
                    }

                    //generate vertices, texcoords
                    vmin.x = position.x + offset.x;
                    vmin.y = position.y + offset.y;
                    vmax.x = vmin.x + texture.size.x;
                    vmax.y = vmin.y + texture.size.y;

                    renderer_.draw_texture(vmin, vmax, 
                                           gl_texture.texcoords.min, 
                                           gl_texture.texcoords.max, 
                                           color);
                }
            }
            //error loading glyphs
            catch(TextureException e)
            {
                writefln("Error drawing text: " ~ text);
                writefln(e.msg);
                return;
            }
        }

        final override DrawMode draw_mode(DrawMode mode)
        {
            switch(mode)
            {
                case DrawMode.Immediate:
                    renderer_.draw_mode(GLDrawMode.Immediate);
                    break;
                case DrawMode.RAMBuffers:
                    renderer_.draw_mode(GLDrawMode.VertexArray);
                    break;
                case DrawMode.VRAMBuffers:
                    renderer_.draw_mode(GLDrawMode.VertexBuffer);
                    break;
                default:
                    assert(false, "Unknown draw mode");
            }
            return mode;
        }
        
        final override Vector2u text_size(string text)
        {
            auto renderer = font_manager_.renderer();
            try
            {
                //load any glyphs that aren't loaded yet
                foreach(dchar c; text)
                {
                    if(!renderer.has_glyph(c)){renderer.load_glyph(this, c);}
                }
            }
            //error loading glyphs
            catch(TextureException e)
            {
                writefln("Error measuring text size: " ~ text);
                writefln(e.msg);
                return Vector2u(0,0);
            }
            return renderer.text_size(text);
        }

        final override void line_aa(bool aa){renderer_.line_aa = aa;}
        
        final override void line_width(float width)
        {
            assert(width >= 0.0, "Can't set negative line width");
            renderer_.line_width = width;
        }

        final override void font(string font_name){font_manager_.font = font_name;}

        final override void font_size(uint size){font_manager_.font_size = size;}
        
        final override void zoom(real zoom){renderer_.view_zoom = cast(float)zoom;}
        
        final override real zoom(){return renderer_.view_zoom;}

        final override void view_offset(Vector2d offset)
        {
            renderer_.view_offset = to!(float)(offset);
        }

        final override Vector2d view_offset()
        {
            return to!(double)(renderer_.view_offset);
        }

        final override uint screen_width(){return screen_width_;}

        final override uint screen_height(){return screen_height_;}

        final override uint max_texture_size(ColorFormat format)
        {
            GLenum gl_format, type;
            GLint internal_format;
            gl_color_format(format, gl_format, type, internal_format);

            uint size = 0;

            //try powers of two up to the maximum that works
            for(uint index; index < powers_of_two.length; ++index)
            {
                size = powers_of_two[index];
                glTexImage2D(GL_PROXY_TEXTURE_2D, 0, internal_format,
                             size, size, 0, gl_format, type, null);
                GLint width = size;
                GLint height = size;
                glGetTexLevelParameteriv(GL_PROXY_TEXTURE_2D, 0,
                                         GL_TEXTURE_WIDTH, &width);
                glGetTexLevelParameteriv(GL_PROXY_TEXTURE_2D, 0,
                                         GL_TEXTURE_HEIGHT, &height);

                if(width == 0 || height == 0){return powers_of_two[index - 1];}
            }
            return size;
        }

        final override Texture create_texture(ref Image image, bool force_page)
        {
            if(force_page)
            {
                assert(is_pot(image.size.x) && is_pot(image.size.y),
                       "When forcing a single texture to have its"
                       "own page, power of two texture is required");
            }

            Rectanglef texcoords;
            //offset of the texture on the page
            Vector2u offset;

            //create new GLTexture with specified parameters.
            void new_texture(size_t page_index)
            {
                textures_ ~= alloc_struct!(GLTexture)(texcoords, offset, page_index);
            }

            //if the texture needs its own page
            if(force_page)
            {
                create_page(image.size, image.format, force_page);
                pages_[$ - 1].insert_texture(image, texcoords, offset);
                new_texture(pages_.length - 1);
                assert(textures_[$ - 1].texcoords == Rectanglef(0.0, 0.0, 1.0, 1.0), 
                       "Texture coordinates of a single page texture must "
                       "span the whole texture");
                return Texture(image.size, cast(uint)textures_.length - 1);
            }

            //try to find a page to fit the new texture to
            foreach(index, ref page; pages_)
            {
                if(page !is null && page.insert_texture(image, texcoords, offset))
                {
                    new_texture(index);
                    return Texture(image.size, cast(uint)textures_.length - 1);
                }
            }
            //if we're here, no page has space for our texture, so create
            //a new page. This will throw if we can't create a page large 
            //enough for the image.
            create_page(image.size, image.format);
            return create_texture(image, false);
        }

        final override void delete_texture(Texture texture)
        {
            GLTexture* gl_texture = textures_[texture.index];
            assert(gl_texture !is null, "Trying to delete a nonexistent texture");
            uint page_index = gl_texture.page_index;
            assert(pages_[page_index] !is null, "Trying to delete a texture from"
                                               " a nonexistent page");
            pages_[page_index].remove_texture(Rectangleu(gl_texture.offset,
                                                         gl_texture.offset + 
                                                         texture.size));
            free(textures_[texture.index]);
            textures_[texture.index] = null;

            //If we have null textures at the end of the textures_ array, we
            //can remove them without messing up indices
            while(textures_.length > 0 && textures_[$ - 1] is null)
            {
                textures_ = textures_[0 .. $ - 1];
            }
            if(pages_[page_index].empty())
            {
                free(pages_[page_index]);
                pages_[page_index] = null;

                //If we have null pages at the end of the pages_ array, we
                //can remove them without messing up indices
                while(pages_.length > 0 && pages_[$ - 1] is null)
                {
                    pages_ = pages_[0 .. $ - 1];
                }
            }
        }

        final override Image screenshot()
        {
            ColorFormat format = ColorFormat.RGB_8;

            Image image = new Image(screen_width_, screen_height_, format);

            GLenum gl_format, type;
            GLint internal_format;
            gl_color_format(format, gl_format, type, internal_format);

            glPixelStorei(GL_PACK_ALIGNMENT, 1);
            //get front buffer as we do this after end_frame
            glReadBuffer(GL_FRONT);
            glReadPixels(0, 0, screen_width_, screen_height_, gl_format, type, image.data.ptr);

            //GL y starts from bottom, our Image starts from top, so we need to flip.
            image.flip_vertical();

            return image;
        }

        override MonitorMenu monitor_menu(){return new GLVideoDriverMonitor(this);}

    package:
        ///Debugging: draw specified area of a texture page on the specified quad.
        final void draw_page(uint page_index, ref Rectanglef area, ref Rectanglef quad)
        {
            statistics_.vertices += 4;  

            set_shader(texture_shader_);

            assert(pages_[page_index] !is null, "Trying to draw a nonexistent page");
            if(current_page_ != page_index)
            {
                ++statistics_.page;
                current_page_ = page_index;
                renderer_.set_texture_page(pages_[page_index]);
            }

            Vector2f page_size = to!(float)(pages_[current_page_].size);

            //texcoords
            Vector2f tmin = area.min / page_size;
            Vector2f tmax = area.max / page_size;

            renderer_.draw_texture(quad.min, quad.max, tmin, tmax);
        }

        TexturePage*[] pages(){return pages_;}

    protected:
        /**
         * Initialize OpenGL context.
         *
         * Throws:  VideoDriverException on failure.
         */
        final void init_gl()
        {
            try
            {
                //Loads the newest available OpenGL version
                version_ = DerelictGL.availableVersion();
                enforceEx!(VideoDriverException)(version_ >= GLVersion.Version20,
                                                 "Could not load OpenGL 2.0 or greater. "
                                                 "Try updating graphics card driver.");
            }
            catch(SharedLibProcLoadException e)
            {
                throw new VideoDriverException("Could not load OpenGL: " ~ e.msg);
            } 

            glEnable(GL_CULL_FACE);
            glCullFace(GL_BACK);
            glEnable(GL_BLEND);
            glEnable(GL_TEXTURE_2D);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            glClearColor(0.0f, 0.0f, 0.0f, 0.0f);

            renderer_ = GLRenderer(GLDrawMode.VertexBuffer);

            try
            {
                plain_shader_ = create_shader("line");
                scope(failure){delete_shader(plain_shader_);}
                texture_shader_ = create_shader("texture");
                scope(failure){delete_shader(texture_shader_);}
                font_shader_ = create_shader("font");
                scope(failure){delete_shader(font_shader_);}
            }
            catch(ShaderException e)
            {
                throw new VideoDriverException("Could not load default shaders: " ~ e.msg);
            }
        }


    private:
        //not ready for public interface yet- will take shader spec file in future
        /**
         * Load shader with specified name.
         *
         * Throws:  ShaderException if the shader could not be loaded.
         */
        final Shader create_shader(string name)
        {
            shaders_ ~= alloc_struct!(GLShader)(name);
            return Shader(cast(uint)shaders_.length - 1);
        }

        //not ready for public interface yet
        ///Delete a shader.
        final void delete_shader(Shader shader)
        {
            GLShader* gl_shader = shaders_[shader.index];
            assert(gl_shader !is null, "Trying to delete a nonexistent shader");
            free(shaders_[shader.index]);
            shaders_[shader.index] = null;

            //If we have null shaders at the end of the shaders_ array, we
            //can remove them without messing up indices
            while(shaders_.length > 0 && shaders_[$ - 1] is null)
            {
                shaders_ = shaders_[0 .. $ - 1];
            }
        }

        //not ready for public interface yet
        ///Use specified shader for drawing.
        final void set_shader(Shader shader)
        {
            uint index = shader.index;

            if(current_shader_ == index){return;}

            ++statistics_.shader;
            current_shader_ = index;
            renderer_.set_shader(shaders_[index]);
        }

        /**
         * Create a texture page with at least specified size, color format
         *
         * Params:  size_image = Size of image we need to fit on the page, i.e.
         *                       minimum size of the page
         *          format     = Color format of the page.
         *          force_size = Force page size to be exactly size_image.
         *
         * Throws:  TextureException if it's not possible to create a page with required parameters.
         */
        final void create_page(Vector2u size_image, ColorFormat format, bool force_size = false)
        {
            //1/16 MiB grayscale, 1/4 MiB RGBA8
            static uint size_min = 256;
            uint supported = max_texture_size(format);
            enforceEx!(TextureException)(size_min <= supported,
                                         "GL Video driver doesn't support minimum "
                                         "texture size for color format " ~ to_string(format));

            size_image.x = pot_ceil(size_image.x);
            size_image.y = pot_ceil(size_image.y);
            enforceEx!(TextureException)(size_image.x <= supported && size_image.y <= supported,
                                         "GL Video driver doesn't support requested "
                                         "texture size for specified color " ~ to_string(format));

            //determining recommended maximum page size:
            //we want at least 1024 but will settle for less if not supported.
            //if supported / 4 > 1024, we take that.
            //1024*1024 is 1 MiB grayscale, 4MiB RGBA8
            uint max_recommended = min(max(1024u, supported / 4), supported);

            Vector2u size = Vector2u(size_min, size_min);

            void page_size(size_t index)
            {
                index = min(powers_of_two.length - 1, index);
                //every page has double the page area of the previous one.
                //i.e. page 0 is 255, 255, page 1 is 512, 255, etc;
                //until we reach max_recommended, max_recommended.
                //We only create pages greater than that if size_image
                //is greater.
                size.x *= powers_of_two[index / 2 + index % 2];
                size.y *= powers_of_two[index / 2];
                size.x = max(min(size.x, max_recommended), size_image.x);
                size.y = max(min(size.y, max_recommended), size_image.y);

                if(force_size){size = size_image;}
            }
            
            //Look for page indices with null pages to insert page there if possible
            foreach(index, ref page; pages_)
            {
                if(page is null)
                {
                    page_size(index);
                    page = alloc_struct!(TexturePage)(size, format);
                    return;
                }
            }
            page_size(pages_.length);
            pages_ ~= alloc_struct!(TexturePage)(size, format);
        }

        ///Set up OpenGL viewport.
        final void setup_viewport(){glViewport(0, 0, screen_width_, screen_height_);}
}
