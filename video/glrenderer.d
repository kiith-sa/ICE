
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///OpenGL draw cache/renderer.
module video.glrenderer;


import std.stdio;

import derelict.opengl.gl;

import video.glvertex;
import video.glvertexbuffer;
import video.gldrawmode;
import video.glshader;
import video.gltexture;
import video.gltexturebackend;
import math.vector2;
import math.matrix4;
import math.rect;
import containers.vector;
import color;


/**
 * Caches rendering commands and executes them at the end of the frame.
 *
 * GLRenderer works as a rendering cache. Every draw call generates vertices
 * which are stored in buffers passed to OpenGL at the end of the frame.
 * State changes (shader, texture, scissor) are also recorded. Everything is rendered
 * in order of draw calls used.
 */
package struct GLRenderer
{
    private:
        ///Buffer for colored vertices (without texcoords).
        GLVertexBuffer!GLVertex2DColored coloredBuffer_;
        ///Buffer for vertices with texcoords.
        GLVertexBuffer!GLVertex2DTextured texturedBuffer_;
        ///Vertex groups, ordered from earliest to latest draws.
        Vector!GLVertexGroup vertexGroups_;

        ///Vertex group we're currently adding vertices to.
        GLVertexGroup currentGroup_;

        /**
         * Do we need to flush the current group (add it to vertexGroups_)? 
         *
         * True if group specific state (e.g. shader) has changed.
         */
        bool flushGroup_;

        ///Scissor areas of scissor calls during the frame.
        Vector!Recti scissorAreas_;
        ///If true, current group is using scissor. (the last element of scissorAreas_)
        bool scissor_;
        ///Shader of the current group.
        GLShader* shader_ = null;
        ///Texture page of the current group.
        GLTexturePage* texturePage_ = null;
        ///View zoom of the current group.
        Vector2f viewOffset_ = Vector2f(0.0f, 0.0f);
        ///View offset of the current group.
        float viewZoom_ = 1.0f;
        
        ///Current line width.
        float lineWidth_ = 1.0f;
        ///Is line antialiasing enabled?
        bool lineAA_ = false;

        ///Has the renderer been initialized?
        bool initialized_ = false;

    public:
        /**
         * Construct a GLRenderer.
         *
         * Params:  mode = Draw mode to use.
         */
        this(const GLDrawMode mode)
        {
            flushGroup_ = true;
            initialized_ = true;
            initBuffers(mode);
        }

        ///Reset all frame state. (end the frame)
        void reset()
        {
            coloredBuffer_.reset();
            texturedBuffer_.reset();

            texturePage_ = null;
            shader_      = null;
            scissor_     = false;

            scissorAreas_.length = 0;
            vertexGroups_.length = 0;

            currentGroup_.vertices = 0;
            flushGroup_            = true;

            //we're not resetting zoom, view offset - those keep their values between frames
        }

        ///Get number of vertices used during the frame so far.
        @property uint vertexCount() const 
        {
            return coloredBuffer_.vertexCount + texturedBuffer_.vertexCount;
        }

        ///Get number of indices used during the frame so far.
        @property uint indexCount() const
        {
            return coloredBuffer_.indexCount + texturedBuffer_.indexCount;
        }

        ///Get number of vertex groups created during the frame so far.
        @property uint vertexGroupCount() const 
        {
            return cast(uint)vertexGroups_.length;
        }

        ///Set draw mode. Should not be called during a frame.
        @property void drawMode(const GLDrawMode mode)
        {
            clear(coloredBuffer_);
            clear(texturedBuffer_);
            initBuffers(mode);
        }

        ///Is the GLRenderer initialized?
        @property bool initialized() const pure  {return initialized_;}

        ///Set shader to use in following draw calls.
        void setShader(GLShader* shader) pure 
        {
            shader_     = shader;
            flushGroup_ = true;
        }

        ///Set texture page to use in following draw calls.
        void setTexturePage(GLTexturePage* page) pure 
        {
            texturePage_ = page;
            flushGroup_  = true;
        }

        ///Set scissor area to use in following draw calls. Only this area will be drawn to.
        void scissor(const ref Recti scissorArea) 
        {
            scissor_ = true;
            scissorAreas_ ~= scissorArea;
            flushGroup_ = true;
        }

        ///Disable scissor test for following draw calls.
        void disableScissor() pure 
        {
            scissor_     = false;
            flushGroup_ = true;
        }

        ///Set view zoom for following draw calls.
        @property void viewZoom(const float zoom) pure 
        {
            viewZoom_   = zoom;
            flushGroup_ = true;
        }

        ///Get view zoom.
        @property real viewZoom() const pure  {return viewZoom_;}

        ///Set view offset for following draw calls.
        @property void viewOffset(const Vector2f offset) pure 
        {
            viewOffset_ = offset;
            flushGroup_ = true;
        }

        ///Get view offset.
        @property Vector2f viewOffset() const pure  {return viewOffset_;}

        ///Set line width for following draw calls.
        @property void lineWidth(const real width) pure {lineWidth_ = width;}

        ///Set line antialiasing (on or off) for following draw calls.
        @property void lineAA(const bool aa) pure {lineAA_ = aa;}

        /**
         * Draw a line.
         *
         * Color will be linearly interpolated from start to end point.
         *
         * Line start and end point should never be the same -
         * passing identical start and end point will result in undefined behavior.
         *
         * Params:  v1 = Start point of the line.
         *          v2 = End point of the line.
         *          c1 = Color at the start point of the line.
         *          c2 = Color at the end point of the line.
         */
        void drawLine(const Vector2f v1, const Vector2f v2, const Color c1, const Color c2)
        {
            //The line is drawn as a rectangle with width slightly smaller than
            //lineWidth_ to prevent artifacts.

            alias GLVertex2DColored Vertex;

            //ensure we have the needed vertex type in the current group
            updateGroup(Vertex.vertexType);

            //equivalent to (v2 - v1).normal;
            const offsetBase = Vector2f(v1.y - v2.y, v2.x - v1.x).normalized; 
            const halfWidth  = lineWidth_ * 0.5;
            //offset of line vertices from start and end point of the line
            Vector2f offset = offsetBase * halfWidth;

            //get current vertex, index count in colored buffer
            const v = coloredBuffer_.vertexCount;
            uint  i = coloredBuffer_.indexCount;
            //enlarge colored buffer to fit new vertices, indices
            coloredBuffer_.vertexCount = lineAA_ ? v + 8 : v + 4;
            coloredBuffer_.indexCount  = lineAA_ ? i + 18 : i + 6;
            currentGroup_.vertices      += lineAA_ ? 18 : 6;
            //get access to arrays to add vertices, indices to
            auto vertices = coloredBuffer_.vertices;
            auto indices = coloredBuffer_.indices;

            if(lineAA_)
            {
                //offsets of AA vertices from start and end point of the line
                const offsetAA = offsetBase * (halfWidth + 0.4);
                //colors of AA vertices
                Color c3 = c1;
                Color c4 = c2;
                c3.a = 0;
                c4.a = 0;

                //AA vertices
                vertices[v]     = Vertex(v1 + offsetAA, c3);
                vertices[v + 1] = Vertex(v2 + offsetAA, c4);
                //line vertices         
                vertices[v + 2] = Vertex(v1 + offset, c1);
                vertices[v + 3] = Vertex(v2 + offset, c2);
                vertices[v + 4] = Vertex(v1 - offset, c1);
                vertices[v + 5] = Vertex(v2 - offset, c2);
                //AA vertices           
                vertices[v + 6] = Vertex(v1 - offsetAA, c3);
                vertices[v + 7] = Vertex(v2 - offsetAA, c4);

                //indices, each line specifies a triangle.
                indices[i++] = v;     indices[i++] = v + 1; indices[i++] = v + 2;
                indices[i++] = v + 2; indices[i++] = v + 1; indices[i++] = v + 3;

                indices[i++] = v + 2; indices[i++] = v + 3; indices[i++] = v + 4;
                indices[i++] = v + 4; indices[i++] = v + 3; indices[i++] = v + 5;

                indices[i++] = v + 4; indices[i++] = v + 5; indices[i++] = v + 6;
                indices[i++] = v + 6; indices[i++] = v + 5; indices[i++] = v + 7;
            }
            else
            {
                //line vertices             
                vertices[v]     = Vertex(v1 + offset, c1);
                vertices[v + 1] = Vertex(v1 - offset, c1);
                vertices[v + 2] = Vertex(v2 + offset, c2);
                vertices[v + 3] = Vertex(v2 - offset, c2);

                //indices, each line specifies a triangle.
                indices[i++] = v;     indices[i++] = v + 2; indices[i++] = v + 1;
                indices[i++] = v + 1; indices[i++] = v + 2; indices[i++] = v + 3;
            }
        }

        /**
         * Draw a rectangle.
         *
         * Params:  min   = Minimum dimensions of the rectangle.
         *          max   = Maximum dimensions of the rectangle.
         *          color = Rectangle color.
         */
        void drawRect(const Vector2f min, const Vector2f max, const Color color)
        {
            alias GLVertex2DColored Vertex;

            //ensure we have the needed vertex type in the current group
            updateGroup(Vertex.vertexType);

            //get current vertex, index count in colored buffer
            const v = coloredBuffer_.vertexCount;
            auto i = coloredBuffer_.indexCount;
            //enlarge colored buffer to fit new vertices, indices
            coloredBuffer_.vertexCount = v + 4;
            coloredBuffer_.indexCount = i + 6;
            currentGroup_.vertices += 6;
            //get access to arrays to add vertices, indices to
            auto vertices = coloredBuffer_.vertices;
            auto indices = coloredBuffer_.indices;

            //add vertices
            vertices[v]     = Vertex(min, color);
            vertices[v + 1] = Vertex(Vector2f(max.x, min.y), color);
            vertices[v + 2] = Vertex(Vector2f(min.x, max.y), color);
            vertices[v + 3] = Vertex(max, color);
            //indices, each line specifies a triangle.
            indices[i++] = v;     indices[i++] = v + 2; indices[i++] = v + 1;
            indices[i++] = v + 1; indices[i++] = v + 2; indices[i++] = v + 3;
        }

        /**
         * Draw a textured rectangle.
         *
         * Params:  min   = Minimum dimensions of the rectangle.
         *          max   = Maximum dimensions of the rectangle.
         *          tMix = Minimum texture coordinates of the rectangle.
         *          tMax = Maximum texture coordinates of the rectangle.
         *          color = Base rectangle color.
         */
        void drawTexture(const Vector2f min, const Vector2f max, 
                          const Vector2f tMin, const Vector2f tMax,
                          const Color color = rgb!"FFFFFF")
        {
            alias GLVertex2DTextured Vertex;

            //ensure we have the needed vertex type in the current group
            updateGroup(Vertex.vertexType);

            //get current vertex, index count in textured buffer
            const v = texturedBuffer_.vertexCount;
            auto i = texturedBuffer_.indexCount;
            //enlarge textured buffer to fit new vertices, indices
            texturedBuffer_.vertexCount = v + 4;
            currentGroup_.vertices += 6;
            texturedBuffer_.indexCount = i + 6;
            //get access to arrays to add vertices, indices to
            auto vertices = texturedBuffer_.vertices;
            auto indices = texturedBuffer_.indices;

            alias Vector2f V;

            //add vertices
            vertices[v]     = Vertex(min, tMin, color);
            vertices[v + 1] = Vertex(V(max.x, min.y), V(tMax.x, tMin.y), color);
            vertices[v + 2] = Vertex(V(min.x, max.y), V(tMin.x, tMax.y), color);
            vertices[v + 3] = Vertex(max, tMax, color);
            //indices, each line specifies a triangle.
            indices[i++] = v;     indices[i++] = v + 2; indices[i++] = v + 1;
            indices[i++] = v + 1; indices[i++] = v + 2; indices[i++] = v + 3;
        }

        /**
         * Render out data specified with previous draw calls.
         *
         * Params:  screenWidth  = Video mode width.
         *          screenHeight = Video mode height.
         */
        void render(const uint screenWidth, const uint screenHeight)
        {
            //if we have an unfinished group, add it
            if(currentGroup_.vertices > 0){vertexGroups_ ~= currentGroup_;}

            //start drawing with the buffers
            coloredBuffer_.startDraw();
            texturedBuffer_.startDraw();

            foreach(ref group; vertexGroups_)
            {
                //uint.max means no scissor
                if(group.scissor != uint.max)
                {
                    Recti scissor = scissorAreas_[group.scissor];
                    glEnable(GL_SCISSOR_TEST);
                    glScissor(scissor.min.x, scissor.min.y,
                              scissor.width, scissor.height);
                }
                scope(exit)
                {
                    if(group.scissor != uint.max){glDisable(GL_SCISSOR_TEST);}
                }

                //enable shader of the group
                group.shader.start();

                auto modelview = translationMatrix(-group.viewOffset /
                                                    Vector2f(screenWidth, screenHeight));
                auto projection = orthoMatrix(0.0f, screenWidth / group.viewZoom,
                                               screenHeight / group.viewZoom, 0.0f,
                                               -1.0f, 1.0f);

                //model-view-projection
                const mvp = group.shader.getUniform("mvp_matrix");
                if(mvp < 0)
                {
                    writeln("Missing uniform mvp_matrix in shader");
                    continue;
                }

                glUniformMatrix4fv(mvp, 1, GL_FALSE, (modelview * projection).ptr);

                //determine which buffer the group belongs to
                final switch(group.vertexType)
                {
                    case GLVertexType.Colored:
                        if(coloredBuffer_.draw(group) < 0)
                        {
                            writeln("Missing shader attribute");
                        }
                        break;
                    case GLVertexType.Textured:
                        group.texturePage.start();  
                        if(texturedBuffer_.draw(group) < 0)
                        {
                            writeln("Missing shader attribute");
                        }
                        break;
                }
            }

            //end drawing with the buffers
            coloredBuffer_.endDraw();
            texturedBuffer_.endDraw();
        }

    private:
        /**
         * Ensure current group is a group with specified vertex type and flush it if needed.
         *
         * Params:  type = Vertex type we need.
         */
        void updateGroup(const GLVertexType type)
        in
        {
            assert(type == GLVertexType.Colored || type == GLVertexType.Textured,
                   "Unsupported vertex type");
        }
        body
        {
            if(!flushGroup_ && currentGroup_.vertexType == type){return;}

            //After the frame starts, flushGroup is true but we don't want to add an unitialized 
            //group, so ignore it. Also, adding an empty group is useless anyway.
            if(currentGroup_.vertices > 0)
            {
                //add the current group
                vertexGroups_ ~= currentGroup_;
            }

            //reset current group with current settings and specified vertex type
            with(currentGroup_)
            {
                vertexType = type;

                offset = type == GLVertexType.Colored ? cast(uint)coloredBuffer_.indexCount
                                                      : cast(uint)texturedBuffer_.indexCount;
                vertices = 0;

                viewZoom = viewZoom_;
                viewOffset = viewOffset_;

                scissor = scissor_ ? cast(uint)scissorAreas_.length - 1 : uint.max;
                shader = shader_;
                texturePage = type == GLVertexType.Textured ? texturePage_ : null;
            }

            flushGroup_ = false;
        }

        ///Initialize vertex buffers with specified draw mode.
        void initBuffers(const GLDrawMode drawMode_)
        {
            coloredBuffer_  = GLVertexBuffer!GLVertex2DColored(drawMode_, 512 * 1024);
            texturedBuffer_ = GLVertexBuffer!GLVertex2DTextured(drawMode_, 64 * 1024);
        }
}
