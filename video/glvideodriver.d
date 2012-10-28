
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///OpenGL 2 video driver.
module video.glvideodriver;


import std.algorithm;
import std.exception;
import std.stdio;
import std.conv;

import derelict.opengl.gl;
import derelict.opengl.exttypes;
import derelict.opengl.extfuncs;
import derelict.util.exception;
import dgamevfs._;

import video.binarytexturepacker;
import video.fontmanager;
import video.gldrawmode;
import video.glmonitor;
import video.glrenderer;
import video.glshader;
import video.gltexture;
import video.gltexturebackend;
import video.shader;
import video.texture;
import video.texturepage;
import video.videodriver;
import monitor.monitordata;
import monitor.submonitor;
import monitor.graphmonitor;
import math.math;
import math.vector2;
import math.rect;
import platform.platform;
import memory.memory;
import time.timer;
import util.signal;
import color;
import image;


/**
 * OpenGL 2.x based video driver.
 *
 * Most of the actual drawing is done by GLRenderer, GLVideoDriver basically
 * manages other GL video classes.
 * 
 * Signal:
 *     package mixin Signal!(Statistics) sendStatistics
 *
 *     Used to send statistics data to GL monitors.
 */
abstract class GLVideoDriver : VideoDriver
{
    protected:
        ///Video mode width in pixels.
        uint screenWidth_  = 0;
        ///Video mode height in pixels.
        uint screenHeight_ = 0;
        ///Video mode bit depth.
        uint screenDepth_  = 0;
        //Has GL been initialized (through initGL) ?
        bool glInitialized_;
    
    private:
        //Derelict OpenGL version.
        GLVersion glVersion_;

        //Shader used to draw lines and rectangles without textures.
        Shader plainShader_;
        //Shader used to draw textured surfaces.
        Shader textureShader_;
        //Shader used to draw fonts.
        Shader fontShader_;
        //Shaders.
        GLShader* [] shaders_;
        //Index of currently used shader; uint.max means none.
        uint currentShader_ = uint.max;
        //Shader directory.
        VFSDir shaderDir_;

        //Texture pages.
        GLTexturePage* [] pages_;
        //Index of currently used page; uint.max means none.
        uint currentPage_ = uint.max;
        //Textures.
        GLTexture* [] textures_;
                              
        //Statistics data for monitoring.
        Statistics statistics_;

        //Caches vertices and renders them at the end of frame.
        GLRenderer renderer_;

        //Are we between startFrame and endFrame?
        bool frameInProgress_;

        //Timer used to measure FPS.
        Timer fpsTimer_;

    package:
        ///Used to send statistics data to GL monitors.
        mixin Signal!Statistics sendStatistics;
        
    public:
        /**
         * Construct a GLVideoDriver.
         *
         * Params:  fontManager = Font manager to use for font rendering and management.
         *          gameDir     = Game data directory.
         *
         * Throws:  VFSException if the shader directory (shaders/) was not found in gameDir.
         */
        this(FontManager fontManager, VFSDir gameDir)
        {
            super(fontManager);
            try{shaderDir_ = gameDir.dir("shaders");}
            catch(VFSException e)
            {
                throw new VideoDriverException("Could not found the shader directory "
                                               "in the game directory");
            }
            //dummy delay, not used
            fpsTimer_ = Timer(1.0);
            DerelictGL.load();
        }

        ~this()
        {
            writeln("Destroying GLVideoDriver");
            if(glInitialized_)
            {
                clear(renderer_);

                deleteShader(plainShader_);
                deleteShader(textureShader_);
                deleteShader(fontShader_);
            }

            //delete any remaining texture pages
            foreach(ref page; pages_) if(page !is null)
            {
                free(page);
                page = null;
            }

            //delete any remaining textures
            foreach(ref texture; textures_) if(texture !is null)
            {
                free(texture);
                texture = null;
            }

            //delete any remaining shaders
            foreach(ref shader; shaders_) if(shader !is null)
            {
                free(shader);
                shader = null;
            }

            sendStatistics.disconnectAll();

            if(glInitialized_)
            {
                DerelictGL.unload();
                glInitialized_ = false;
            }
        }

        override void startFrame()
        {
            assert(!frameInProgress_, 
                   "GLVideoDriver.startFrame called, but a frame is already in progress");
            renderer_.reset();

            glClear(GL_COLOR_BUFFER_BIT);
            setupViewport();

            //disable current page and shader
            currentPage_ = currentShader_ = uint.max;

            const real age = fpsTimer_.age();
            fpsTimer_.reset();
            //avoid divide by zero
            statistics_.fps = age == 0.0L ? 0.0 : 1.0 / age;
            sendStatistics.emit(statistics_);
            statistics_.zero();

            frameInProgress_ = true;
        }

        override void endFrame()
        {
            assert(frameInProgress_, 
                   "GLVideoDriver.endFrame called, but no frame has been started");

            frameInProgress_ = false;

            renderer_.render(screenWidth_, screenHeight_);
            statistics_.vertices = renderer_.vertexCount();
            statistics_.indices  = renderer_.indexCount();
            statistics_.vgroups  = renderer_.vertexGroupCount();
            glFlush();
        }

        final override void scissor(const ref Recti scissorArea)
        {
            assert(frameInProgress_, "GLVideoDriver.scissor called outside a frame");

            //convert to GL coords (origin on the bottom-left instead of top-left)
            Recti translated = scissorArea;
            translated.min.y      = screenHeight_ - translated.max.y;
            translated.max.y      = translated.min.y + scissorArea.height;
            renderer_.scissor(translated);
        }

        final override void disableScissor()
        {
            assert(frameInProgress_, "GLVideoDriver.disableScissor called outside a frame");

            renderer_.disableScissor();
        }

        final override void drawLine(const Vector2f v1, const Vector2f v2, 
                                      const Color c1, const Color c2)
        {
            assert(frameInProgress_, "GLVideoDriver.drawLine called outside a frame");

            //can't draw zero-sized lines
            //optimized, fast comparison, but not fuzzy
            //if(v1 != v2)
            if(*(cast(ulong*)&v1) != *(cast(ulong*)&v2))
            {
                ++statistics_.lines;

                setShader(plainShader_);
                renderer_.drawLine(v1, v2, c1, c2);
            }
        }

        final override void drawFilledRect(const Vector2f min, const Vector2f max, 
                                                  const Color color)
        {
            assert(frameInProgress_, 
                   "GLVideoDriver.drawFilledRect called outside a frame");

            statistics_.rectangles++;

            setShader(plainShader_);

            renderer_.drawRect(min, max, color);
        }

        final override void drawTexture(const Vector2i position, const ref Texture texture)
        {
            assert(frameInProgress_, "GLVideoDriver.drawTexture called outside a frame");
            assert(texture.index < textures_.length, "Texture index out of bounds");

            ++statistics_.textures;

            setShader(textureShader_);

            GLTexture* glTexture = textures_[texture.index];
            assert(glTexture !is null, "Trying to draw a nonexistent texture");
            const uint pageIndex = glTexture.pageIndex;
            assert(pages_[pageIndex] !is null, "Trying to draw a texture from"
                                               " a nonexistent page");
            if(currentPage_ != pageIndex)
            {
                ++statistics_.page;
                currentPage_ = pageIndex;
                renderer_.setTexturePage(pages_[pageIndex]);
            }

            const Vector2f vmin = position.to!float;
            renderer_.drawTexture(vmin, vmin + texture.size.to!float,
                                   glTexture.texCoords.min, glTexture.texCoords.max);
        }

        final override void drawText(const Vector2i position, const string text, const Color color)
        {
            assert(frameInProgress_, "GLVideoDriver.drawText called outside a frame");
            scope(failure){writeln("Error drawing text: " ~ text);}

            ++statistics_.texts;

            //font textures are grayscale and use a shader
            //to convert grayscale to alpha
            setShader(fontShader_);

            FontRenderer renderer = fontManager_.renderer();
            renderer.start();

            //offset of the current character relative to position
            Vector2u offset;

            //vertices and texcoords for current character
            Vector2f vmin;
            Vector2f vmax;

            //make up for the fact that fonts are drawn from lower left corner
            //instead of upper left
            const pos = Vector2i(position.x, position.y + renderer.height);

                //iterating over utf-32 chars (conversion is automatic)
            try foreach(dchar c; text)
            {
                ++statistics_.characters;

                if(!renderer.hasGlyph(c)){renderer.loadGlyph(this, c);}
                const texture = renderer.glyph(c, offset);

                const glTexture = textures_[texture.index];
                const pageIndex = glTexture.pageIndex;

                //change texture page if needed
                if(currentPage_ != pageIndex)
                {
                    ++statistics_.page;
                    currentPage_ = pageIndex;
                    renderer_.setTexturePage(pages_[pageIndex]);
                }

                //generate vertices, texcoords
                vmin.x = pos.x  + cast(int)offset.x;
                vmin.y = pos.y  + cast(int)offset.y;
                vmax.x = vmin.x + cast(int)texture.size.x;
                vmax.y = vmin.y + cast(int)texture.size.y;

                renderer_.drawTexture(vmin, vmax, 
                                      glTexture.texCoords.min, 
                                      glTexture.texCoords.max, 
                                      color);
            }
            //error loading glyphs
            catch(TextureException e)
            {
                writeln(e.msg);
                return;
            }
        }

        final override DrawMode drawMode(const DrawMode mode)
        {
            assert(!frameInProgress_, "GLVideoDriver.drawMode called during a frame");

            final switch(mode)
            {
                case DrawMode.RAMBuffers:
                    renderer_.drawMode(GLDrawMode.VertexArray);
                    break;
                case DrawMode.VRAMBuffers:
                    renderer_.drawMode(GLDrawMode.VertexBuffer);
                    break;
            }
            return mode;
        }

        final override Vector2u textSize(const string text)
        {
            scope(failure){writeln("Error measuring text size: " ~ text);}

            auto renderer = fontManager_.renderer();
            //load any glyphs that aren't loaded yet
            try foreach(dchar c; text)
            {
                if(!renderer.hasGlyph(c)){renderer.loadGlyph(this, c);}
            }
            //error loading glyphs
            catch(TextureException e)
            {
                writeln(e.msg);
                return Vector2u(0,0);
            }
            return renderer.textSize(text);
        }

        @property final override void lineAA(const bool aa){renderer_.lineAA = aa;}

        @property final override void lineWidth(const float width)
        {
            assert(width >= 0.0, "Can't set negative line width");
            renderer_.lineWidth = width;
        }

        @property final override void font(const string fontName)
        {
            fontManager_.font = fontName;
        }

        @property final override void fontSize(const uint size)
        {
            fontManager_.fontSize = size;
        }

        @property final override void zoom(const real zoom)
        {
            renderer_.viewZoom = cast(float)zoom;
        }

        @property final override real zoom() const pure {return renderer_.viewZoom;}

        @property final override void viewOffset(const Vector2d offset) 
        {
            renderer_.viewOffset = offset.to!float;
        }

        @property final override Vector2d viewOffset() const
        {
            return renderer_.viewOffset.to!double;
        }

        @property final override uint screenWidth() const {return screenWidth_;}

        @property final override uint screenHeight() const {return screenHeight_;}

        final override uint maxTextureSize(const ColorFormat format) const
        {
            GLenum glFormat, type;
            GLint internalFormat;
            GLTextureBackend.glColorFormat(format, glFormat, type, internalFormat);

            uint size = 0;

            //try powers of two up to the maximum that works
            foreach(index; 0 .. powersOfTwo.length)
            {
                size = powersOfTwo[index];
                //Create a proxy texture.
                glTexImage2D(GL_PROXY_TEXTURE_2D, 0, internalFormat,
                             size, size, 0, glFormat, type, null);
                GLint width  = size;
                GLint height = size;

                //If the proxy width and height are zero, such texture is not supported.
                glGetTexLevelParameteriv(GL_PROXY_TEXTURE_2D, 0,
                                         GL_TEXTURE_WIDTH, &width);
                glGetTexLevelParameteriv(GL_PROXY_TEXTURE_2D, 0,
                                         GL_TEXTURE_HEIGHT, &height);

                if(width == 0 || height == 0)
                {
                    return index == 0 ? 0 : powersOfTwo[index - 1];
                }
            }
            return size;
        }

        final override Texture createTexture(const ref Image image, const bool forcePage)
        {
            if(forcePage)
            {
                assert(isPot(image.size.x) && isPot(image.size.y),
                       "When forcing a single texture to have its"
                       "own page, power of two texture is required");
            }

            //create new GLTexture with specified parameters.
            void newTexture(const size_t pageIndex, ref const Rectu pageArea,
                            const Vector2u pageSize)
            {
                textures_ ~= alloc!GLTexture(pageArea, pageSize, cast(uint)pageIndex);
            }

            //if the texture needs its own page
            if(forcePage)
            {
                Rectu pageArea;
                createPage(image.size, image.format, forcePage);
                pages_[$ - 1].insertTexture(image, pageArea);
                newTexture(pages_.length - 1, pageArea, pages_[$ - 1].size);
                assert(textures_[$ - 1].texCoords == Rectf(0.0, 0.0, 1.0, 1.0), 
                       "Texture coordinates of a single page texture must "
                       "span the whole texture");
                return Texture(image.size, cast(uint)textures_.length - 1);
            }

            //try to find a page to fit the new texture to
            foreach(index, ref page; pages_)
            {
                Rectu pageArea;
                if(page !is null && page.insertTexture(image, pageArea))
                {
                    newTexture(index, pageArea, page.size);
                    return Texture(image.size, cast(uint)textures_.length - 1);
                }
            }
            //if we're here, no page has space for our texture, so create
            //a new page. This will throw if we can't create a page large 
            //enough for the image.
            createPage(image.size, image.format);
            return createTexture(image, false);
        }

        final override void deleteTexture(const Texture texture)
        {
            GLTexture* glTexture = textures_[texture.index];
            assert(glTexture !is null, "Trying to delete a nonexistent texture");
            const uint pageIndex = glTexture.pageIndex;
            assert(pages_[pageIndex] !is null, "Trying to delete a texture from"
                                               " a nonexistent page");
            pages_[pageIndex].removeTexture(Rectu(glTexture.offset,
                                            glTexture.offset + texture.size));
            free(textures_[texture.index]);
            textures_[texture.index] = null;

            //If we have null textures at the end of the textures_ array, we
            //can remove them without messing up indices
            while(textures_.length > 0 && textures_[$ - 1] is null)
            {
                textures_ = textures_[0 .. $ - 1];
            }
            if(pages_[pageIndex].empty())
            {
                free(pages_[pageIndex]);
                pages_[pageIndex] = null;

                //If we have null pages at the end of the pages_ array, we
                //can remove them without messing up indices
                while(pages_.length > 0 && pages_[$ - 1] is null)
                {
                    pages_ = pages_[0 .. $ - 1];
                }
            }
        }

        final override void screenshot(ref Image image)
        {
            assert(!frameInProgress_, "GLVideoDriver.screenshot called during a frame");

            clear(image);
            image = Image(screenWidth_, screenHeight_, ColorFormat.RGB_8);

            GLenum glFormat, type;
            GLint internalFormat;
            GLTextureBackend.glColorFormat(image.format, glFormat, type, internalFormat);
            glPixelStorei(GL_PACK_ALIGNMENT, GLTextureBackend.packAlignment(image.format));

            //directly read from the front buffer if we can't use FBO.
            //won't resize if the image is larger/smaller than the screen resolution,
            //will just chop.
            void fallback()
            {
                writeln("Couldn't get screenshot using FBO: falling back to "
                         "glReadPixels from the framebuffer");

                //get front buffer as we do this after endFrame
                glReadBuffer(GL_FRONT);
                glReadPixels(0, 0, screenWidth, screenHeight,
                             glFormat, type, image.dataUnsafe.ptr);
            }

            if(DerelictGL.isExtensionLoaded("GL_EXT_framebuffer_object"))
            {
                //create FBO and RBO
                GLuint fbo, rbo;
                glGenFramebuffersEXT(1, &fbo);
                glGenRenderbuffersEXT(1, &rbo);
                glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fbo);
                glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, rbo);

                scope(exit)
                {
                    //clean up
                    glDeleteRenderbuffersEXT(1, &rbo);
                    glDeleteFramebuffersEXT(1, &fbo);
                }

                //init FBO and RBO
                glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, GL_RGBA8, 
                                         screenWidth_, screenHeight_);
                glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT,
                                             GL_RENDERBUFFER_EXT, rbo);

                if(glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT) == 
                   GL_FRAMEBUFFER_COMPLETE_EXT)
                {
                    //render the frame to the FBO
                    glClear(GL_COLOR_BUFFER_BIT);
                    renderer_.render(screenWidth_, screenHeight_);

                    //read to the image
                    glReadBuffer(GL_FRONT);
                    glReadPixels(0, 0, screenWidth_, screenHeight_, 
                                 glFormat, type, image.dataUnsafe.ptr);
                }
                //not frame buffer complete, maybe the color format is not supported
                else{fallback();}
            }
            else{fallback();}

            //GL y starts from bottom, our Image starts from top, so we need to flip.
            image.flipVertical();
        }

        @property override MonitorDataInterface monitorData()
        {
            SubMonitor function(GLVideoDriver)[string] ctors_;
            ctors_["FPS"]        = &newGraphMonitor!(GLVideoDriver, Statistics, "fps");
            ctors_["Draws"]      = &newGraphMonitor!(GLVideoDriver, Statistics, 
                                                     "lines", "textures", "texts", "rectangles");

            ctors_["Primitives"] = &newGraphMonitor!(GLVideoDriver, Statistics, 
                                                       "vertices", "indices", "characters"),
            ctors_["Cache"]      = &newGraphMonitor!(GLVideoDriver, Statistics, 
                                                     "vgroups");
            ctors_["Changes"]    = &newGraphMonitor!(GLVideoDriver, Statistics, 
                                                     "shader", "page");
            ctors_["Pages"]      = function SubMonitor(GLVideoDriver v)
                                                      {return new PageMonitor(v);};
            return new MonitorData!GLVideoDriver(this, ctors_);
        }

    package:
        ///Debugging: draw specified area of a texture page on the specified quad.
        final void drawPage(const uint pageIndex, const ref Rectf area,  
                             const ref Rectf quad)
        {
            setShader(textureShader_);

            assert(pages_[pageIndex] !is null, "Trying to draw a nonexistent page");
            if(currentPage_ != pageIndex)
            {
                ++statistics_.page;
                currentPage_ = pageIndex;
                renderer_.setTexturePage(pages_[pageIndex]);
            }

            const Vector2f pageSize = pages_[currentPage_].size.to!float;

            //texcoords
            Vector2f tmin = area.min / pageSize;
            Vector2f tmax = area.max / pageSize;

            renderer_.drawTexture(quad.min, quad.max, tmin, tmax);
        }

        @property GLTexturePage*[] pages() {return pages_;}

    protected:
        /**
         * Initialize OpenGL context.
         *
         * Throws:  VideoDriverException on failure.
         */
        final void initGL()
        {
            scope(failure){writeln("OpenGL initialization failed");}

            try
            {
                //Loads the newest available OpenGL version
                glVersion_ = DerelictGL.loadClassicVersions(GLVersion.GL20);

                DerelictGL.loadExtensions();
            }
            catch(DerelictException e)
            {
                throw new VideoDriverException("Could not load OpenGL: " ~ e.msg ~
                                               "\nPerhaps you need to install new graphics drivers?");
            } 

            glEnable(GL_CULL_FACE);
            glCullFace(GL_BACK);
            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            glClearColor(0.0f, 0.0f, 0.0f, 0.0f);

            renderer_ = GLRenderer(GLDrawMode.VertexBuffer);

            try
            {
                plainShader_   = createShader("line");
                scope(failure){deleteShader(plainShader_);}
                textureShader_ = createShader("texture");
                scope(failure){deleteShader(textureShader_);}
                fontShader_    = createShader("font");
                scope(failure){deleteShader(fontShader_);}
            }
            catch(ShaderException e)
            {
                throw new VideoDriverException("Could not load default shaders: " ~ e.msg);
            }

            const error = glGetError();
            if(error != GL_NO_ERROR)
            {
                writeln("GL error after GL initialization: ", to!string(error));
            }

            glInitialized_ = true;
        }

    private:
        //not ready for public interface yet- will take shader spec file in future
        /**
         * Load shader with specified name.
         *
         * Throws:  ShaderException if the shader could not be loaded.
         */
        final Shader createShader(const string name)
        {
            shaders_ ~= alloc!GLShader(name, shaderDir_);
            return Shader(cast(uint)shaders_.length - 1);
        }

        //not ready for public interface yet
        ///Delete a shader.
        final void deleteShader(const Shader shader)
        {
            assert(shaders_[shader.index] !is null, "Trying to delete a nonexistent shader");
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
        final void setShader(const Shader shader)
        {
            const uint index = shader.index;

            if(currentShader_ == index){return;}

            ++statistics_.shader;
            currentShader_ = index;
            renderer_.setShader(shaders_[index]);
        }

        /**
         * Create a texture page with at least specified size, color format
         *
         * Params:  sizeImage = Size of image we need to fit on the page, i.e.
         *                       minimum size of the page
         *          format     = Color format of the page.
         *          forceSize = Force page size to be exactly sizeImage.
         *
         * Throws:  TextureException if it's not possible to create a page with required parameters.
         */
        final void createPage(Vector2u sizeImage, const ColorFormat format, 
                               const bool forceSize = false)
        {
            //1/16 MiB grayscale, 1/4 MiB RGBA8
            static immutable uint sizeMin = 256;
            const supported = maxTextureSize(format);
            enforceEx!TextureException(sizeMin <= supported,
                                         "GL Video driver doesn't support minimum "
                                         "texture size for color format " ~ to!string(format));

            sizeImage.x = potCeil(sizeImage.x);
            sizeImage.y = potCeil(sizeImage.y);
            enforceEx!TextureException(sizeImage.x <= supported && sizeImage.y <= supported,
                                         "GL Video driver doesn't support requested "
                                         "texture size for specified color " ~ to!string(format));

            //determining recommended maximum page size:
            //we want at least 1024 but will settle for less if not supported.
            //if supported / 4 > 1024, we take that.
            //1024*1024 is 1 MiB grayscale, 4MiB RGBA8
            const uint maxRecommended = min(max(1024u, supported / 4), supported);

            Vector2u pageSize(size_t index)
            {
                auto size = Vector2u(sizeMin, sizeMin);
                index = min(powersOfTwo.length - 1, index);
                //every page has double the page area of the previous one.
                //i.e. page 0 is 255, 255, page 1 is 512, 255, etc;
                //until we reach maxRecommended, maxRecommended.
                //We only create pages greater than that if sizeImage
                //is greater.
                size.x *= powersOfTwo[index / 2 + index % 2];
                size.y *= powersOfTwo[index / 2];
                size.x = max(min(size.x, maxRecommended), sizeImage.x);
                size.y = max(min(size.y, maxRecommended), sizeImage.y);

                if(forceSize){size = sizeImage;}

                return size;
            }
            
            //Look for page indices with null pages to insert page there if possible
            foreach(index, ref page; pages_) if(page is null)
            {
                page = alloc!GLTexturePage(pageSize(index), format);
                return;
            }
            pages_ ~= alloc!GLTexturePage(pageSize(pages_.length), format);
        }

        ///Set up OpenGL viewport.
        final void setupViewport()
        {
            glViewport(0, 0, screenWidth_, screenHeight_);
        }
}
