module video.glvideodriver;


import std.string;

import derelict.opengl.gl;
import derelict.util.exception;

import video.videodriver;
import video.glshader;
import video.gltexture;
import video.gltexturepage;
import video.shader;
import video.texture;
import video.fontmanager;
import video.gldebugger;
import math.math;
import math.vector2;
import math.line2;
import math.rectangle;
import test.subdebugger;
import platform.platform;
import color;
import image;
import allocator;



///Handles all drawing functionality.
abstract class GLVideoDriver : VideoDriver
{
    invariant{assert(view_zoom_ > 0.0);}

    protected:
        uint screen_width_ = 0;
        uint screen_height_ = 0;

    private:
        GLVersion version_;

        real view_zoom_ = 0.0;
        Vector2d view_offset_ = Vector2d(0.0, 0.0);

        //Is line antialiasing enabled?
        bool line_aa_ = false;
        float line_width_ = 1.0;

        Shader line_shader_;
        Shader texture_shader_;
        Shader font_shader_;

        GLShader* [] shaders_;
        //Index of currently used shader; uint.max means none.
        uint current_shader = uint.max;

        //Texture pages
        TexturePage* [] pages_;
        //Index of currently used page; uint.max means none.
        uint current_page_ = uint.max;

        //Textures
        GLTexture* [] textures_;

    public:
        this()
        {
            singleton_ctor();
            DerelictGL.load();
            view_zoom_ = 1.0;
        }

        override void die()
        {
            delete_shader(line_shader_);
            delete_shader(texture_shader_);
            delete_shader(font_shader_);

            FontManager.get.die();

            //delete any remaining texture pages
            foreach(ref page; pages_)
            {
                if(page !is null)
                {
                    page.die();
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
            DerelictGL.unload();
        }

        override void set_video_mode(uint width, uint height, 
                                     ColorFormat format, bool fullscreen);

        override void start_frame()
        {
            glClear(GL_COLOR_BUFFER_BIT);
            setup_viewport();
            current_page_ = uint.max;
        }

        override void end_frame(){glFlush();}

        final override void draw_line(Vector2f v1, Vector2f v2, Color c1, Color c2)
        {
            set_shader(line_shader_);
            //The line is drawn as a rectangle with width slightly lower than
            //line_width_ to prevent artifacts.
            Vector2f offset_base = (v2 - v1).normal.normalized;
            float half_width = line_width_ / 2.0;
            Vector2f offset = offset_base * (half_width);
            Vector2f r1, r2, r3, r4;
            r1 = v1 + offset;
            r2 = v1 - offset;
            r3 = v2 + offset;
            r4 = v2 - offset;

            if(line_aa_)
            {
                //If AA is on, add two transparent vertices to the sides of the 
                //rectangle.
                Vector2f offset_aa = offset_base * (half_width + 0.4);
                Vector2f aa1, aa2, aa3, aa4;
                aa1 = v1 + offset_aa;
                aa2 = v1 - offset_aa;
                aa3 = v2 + offset_aa;
                aa4 = v2 - offset_aa;

                glBegin(GL_TRIANGLE_STRIP);
                glColor4ub(c1.r, c1.g, c1.b, 0);
                glVertex2f(aa1.x, aa1.y);
                glColor4ub(c2.r, c2.g, c2.b, 0);
                glVertex2f(aa3.x, aa3.y);

                glColor4ub(c1.r, c1.g, c1.b, c1.a);
                glVertex2f(r1.x, r1.y);
                glColor4ub(c2.r, c2.g, c2.b, c2.a);
                glVertex2f(r3.x, r3.y);
                glColor4ub(c1.r, c1.g, c1.b, c1.a);
                glVertex2f(r2.x, r2.y);
                glColor4ub(c2.r, c2.g, c2.b, c2.a);
                glVertex2f(r4.x, r4.y);

                glColor4ub(c1.r, c1.g, c1.b, 0);
                glVertex2f(aa2.x, aa2.y);
                glColor4ub(c2.r, c2.g, c2.b, 0);
                glVertex2f(aa4.x, aa4.y);
                glEnd();
            }
            else
            {
                glBegin(GL_TRIANGLE_STRIP);
                glColor4ub(c1.r, c1.g, c1.b, c1.a);
                glVertex2f(r1.x, r1.y);
                glColor4ub(c2.r, c2.g, c2.b, c2.a);
                glVertex2f(r3.x, r3.y);
                glColor4ub(c1.r, c1.g, c1.b, c1.a);
                glVertex2f(r2.x, r2.y);
                glColor4ub(c2.r, c2.g, c2.b, c2.a);
                glVertex2f(r4.x, r4.y);
                glEnd();
            }
        }

        final override void draw_texture(Vector2i position, ref Texture texture)
        in{assert(texture.index < textures_.length);}
        body
        {
            set_shader(texture_shader_);

            GLTexture* gl_texture = textures_[texture.index];
            assert(gl_texture !is null, "Trying to draw a nonexistent texture");
            uint page_index = gl_texture.page_index;
            assert(pages_[page_index] !is null, "Trying to draw a texture from"
                                               " a nonexistent page");
            if(current_page_ != page_index)
            {
                pages_[page_index].start();
                current_page_ = page_index;
            }

            Vector2f vmin = to!(float)(position);
            Vector2f vmax = vmin + to!(float)(texture.size);

            Vector2f tmin = gl_texture.texcoords.min;
            Vector2f tmax = gl_texture.texcoords.max;

            glColor4ub(255, 255, 255, 255);
            glBegin(GL_TRIANGLE_STRIP);
            glTexCoord2f(tmin.x, tmin.y);
            glVertex2f(vmin.x, vmin.y);
            glTexCoord2f(tmin.x, tmax.y);
            glVertex2f(vmin.x, vmax.y);
            glTexCoord2f(tmax.x, tmin.y);
            glVertex2f(vmax.x, vmin.y);
            glTexCoord2f(tmax.x, tmax.y);
            glVertex2f(vmax.x, vmax.y);
            glEnd();
        }
        
        final override void draw_text(Vector2i position, string text, Color color)
        {
            //font textures are grayscale and use a shader
            //to convert grayscale to alpha
            set_shader(font_shader_);

            FontRenderer renderer = FontManager.get.renderer();
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

            //iterating over utf-32 chars (conversion is automatic)
            foreach(dchar c; text)
            {
                texture = renderer.glyph(c, offset);
                gl_texture = textures_[texture.index];
                page_index = gl_texture.page_index;

                //change texture page if needed
                if(current_page_ != page_index)
                {
                    pages_[page_index].start();
                    current_page_ = page_index;
                }

                //generate vertices, texcoords
                vmin.x = position.x + offset.x;
                vmin.y = position.y + offset.y;
                vmax.x = vmin.x + texture.size.x;
                vmax.y = vmin.y + texture.size.y;
                tmin = gl_texture.texcoords.min;
                tmax = gl_texture.texcoords.max;

                //draw the character
                glBegin(GL_TRIANGLE_STRIP);
                glTexCoord2f(tmin.x, tmin.y);
                glVertex2f(vmin.x, vmin.y);
                glTexCoord2f(tmin.x, tmax.y);
                glVertex2f(vmin.x, vmax.y);
                glTexCoord2f(tmax.x, tmin.y);
                glVertex2f(vmax.x, vmin.y);
                glTexCoord2f(tmax.x, tmax.y);
                glVertex2f(vmax.x, vmax.y);
                glEnd();
            }
        }
        
        final override Vector2u text_size(string text)
        {
            return FontManager.get.text_size(text);
        }

        final override void line_aa(bool aa){line_aa_ = aa;}
        
        final override void line_width(float width){line_width_ = width;}

        final override void font(string font_name){FontManager.get.font = font_name;}

        final override void font_size(uint size){FontManager.get.font_size = size;}
        
        final override void zoom(real zoom)
        in
        {
            assert(zoom > 0.0001, "Can't zoom out further than 0.0001x");
            assert(zoom < 100.0, "Can't zoom in further than 100x");
        }
        body
        {
            view_zoom_ = zoom;
            setup_ortho();
        }
        
        final override real zoom(){return view_zoom_;}

        final override void view_offset(Vector2d offset)
        {
            view_offset_ = offset;
            setup_ortho();
        }

        final override Vector2d view_offset(){return view_offset_;}

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

        final override string pages_info()
        {
            string info = "Pages: " ~ std.string.toString(pages_.length) ~ "\n"; 
            foreach(index, page; pages_)
            {
                info ~= std.string.toString(index) ~ ": \n";

                if(page is null){info ~= "null\n";}
                else{info ~= page.info ~ "\n";}
            }
            return info;
        }

		final override Texture create_texture(ref Image image, bool force_page)
        in
        {
            if(force_page)
            {
                assert(is_pot(image.size.x) && is_pot(image.size.y),
                       "When forcing a single texture to have its"
                       "own page, power of two texture is required");
            }
        }
        body
		{
            Rectanglef texcoords;
            //offset of the texture on the page
            Vector2u offset;

            //create new GLTexture with specified parameters.
            void new_texture(uint page_index)
            {
                GLTexture* texture = alloc!(GLTexture)();
                texture.texcoords = texcoords;
                texture.offset = offset;
                texture.page_index = page_index;
                textures_ ~= texture;
            }

            //if the texture needs its own page
            if(force_page)
            {
                create_page(image.size, image.format, force_page);
                pages_[$ - 1].insert_texture(image, texcoords, offset);
                new_texture(pages_.length - 1);
                assert(textures_[$ - 1].texcoords == 
                       Rectanglef(0.0, 0.0, 1.0, 1.0), 
                       "Texture coordinates of a single page texture must "
                       "span the whole texture");
                return Texture(image.size, textures_.length - 1);
            }

            //try to find a page to fit the new texture to
            foreach(index, ref page; pages_)
            {
                if(page !is null && 
                   page.insert_texture(image, texcoords, offset))
                {
                    new_texture(index);
                    return Texture(image.size, textures_.length - 1);
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
                pages_[page_index].die();
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

        SubDebugger debugger(){return new GLDebugger;}

    protected:
        //Initialize OpenGL context.
        final void init_gl()
        {
            //Force font manager to load if not yet loaded. 
            //Placed here because font manager ctor needs working videodriver
            //and a call to font manager ctor from videodriver ctor would
            //result in infinite recursion.
            FontManager.initialize!(FontManager);
            try
            {
                //Loads the newest available OpenGL version
                version_ = DerelictGL.availableVersion();
                if(version_ < GLVersion.Version20)
                {
                    throw new Exception("Could not load OpenGL 2.0 or greater."
                                        " Try updating graphics card driver.");
                }
            }
            catch(SharedLibProcLoadException e)
            {
                throw new Exception("Could not load OpenGL. Try updating graphics "
                                    "card driver.");
            } 

            glEnable(GL_CULL_FACE);
            glCullFace(GL_BACK);
			glEnable(GL_BLEND);
            glEnable(GL_TEXTURE_2D);
			glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            glClearColor(0.0f, 0.0f, 0.0f, 0.0f);

            line_shader_ = create_shader("line");
            texture_shader_ = create_shader("texture");
            font_shader_ = create_shader("font");
        }

    private:
        //not ready for public interface yet- will take shader spec file in future
        //Load shader with specified name.
        final Shader create_shader(string name)
        {
            GLShader* gl_shader = alloc!(GLShader)();
            *gl_shader = GLShader(name);
            shaders_ ~= gl_shader;
            return Shader(shaders_.length - 1);
        }

        //not ready for public interface yet
        //Delete a shader.
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
        //Use specified shader for drawing.
        final void set_shader(Shader shader)
        {
            uint index = shader.index;

            if(current_shader != index)
            {
                shaders_[index].start;
                current_shader = index;
            }
        }

        ///Create a texture page with at least specified size, color format
        /**
         * Throws an exception if it's not possible to create a page with
         * required parameters.
         * @param size_image Size of image we need to fit on the page, i.e.
         *                   minimum size of the page
         * @param format     Color format of the page.
         * @param force_size Force page size to be exactly size_image.
         */
        final void create_page(Vector2u size_image, ColorFormat format, 
                               bool force_size = false)
        {
            //1/16 MiB grayscale, 1/4 MiB RGBA8
            static uint size_min = 256;
            uint supported = max_texture_size(format);
            if(size_min > supported)
            {
                throw new Exception("GL Video driver doesn't support minimum "
                                    "texture size for specified color format.");
            }

            size_image.x = pot_greater_equal(size_image.x);
            size_image.y = pot_greater_equal(size_image.y);
            if(size_image.x > supported || size_image.y > supported)
            {
                throw new Exception("GL Video driver doesn't support requested "
                                    "texture size for specified color format.");
            }
            //determining recommended maximum page size:
            //we want at least 1024 but will settle for less if not supported.
            //if supported / 4 > 1024, we take that.
            //1024*1024 is 1 MiB grayscale, 4MiB RGBA8
            uint max_recommended = min(max(1024u, supported / 4), supported);

            Vector2u size = Vector2u(size_min, size_min);

            void page_size(uint index)
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
                    page = alloc!(TexturePage)();
                    *page = TexturePage(size, format);
                    return;
                }
            }
            page_size(pages_.length);
            pages_ ~= alloc!(TexturePage)();
            *pages_[$ - 1] = TexturePage(size, format);
        }

        //Set up OpenGL viewport.
        final void setup_viewport()
        {
            glViewport(0, 0, screen_width_, screen_height_);
            setup_ortho();
        }

        //Set up orthographic projection.
        final void setup_ortho()
        {
            glMatrixMode(GL_PROJECTION);
            glLoadIdentity();
            glOrtho(0.0f, screen_width_ / view_zoom_, screen_height_ / view_zoom_, 
                    0.0f, -1.0f, 1.0f);
            glMatrixMode(GL_MODELVIEW);
            glLoadIdentity();
            glTranslatef(-view_offset_.x, -view_offset_.y, 0.0f);
        }
}
