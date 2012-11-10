
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///OpenGL vertex buffer.
module video.glvertexbuffer;


import derelict.opengl.gl;

import containers.vector;
import math.vector2;
import memory.memory;
import video.gldrawmode;
import video.glshader;
import video.gltexturebackend;
import video.glvertex;


/**
 * Buffer storing vertices of specified type.
 *
 * Also handles passing vertex data to OpenGL and drawing it.
 *
 * Vertices are drawn using an index array as triangles - i.e. every
 * 3 indices specify a triangle.
 */ 
package struct GLVertexBuffer(Vertex)
    if(is(Vertex == GLVertex2DColored) || is(Vertex == GLVertex2DTextured))
{
    private:
        ///Memory allocated for vertices.
        Vertex[] verticesAllocated_ = null;
        ///Vertex data.
        Vertex[] vertices_;

        ///Memory allocated for indices.
        uint[] indicesAllocated_ = null;
        ///Index data.
        uint[] indices_;

        ///VBO handle, used in VBO mode.
        GLuint vbo_;
        ///IBO handle, used in VBO mode.
        GLuint ibo_;

        ///Draw mode of the buffer.
        GLDrawMode mode_;

        ///Is this vertex buffer null (uninitialized)?
        bool isNull_ = true;

    public:
        /**
         * Construct a GLVertexBuffer.
         *
         * Params:  mode        = Draw mode of the buffer.
         *          preallocate = Number of vertices to preallocate space for.
         *                        Avoids unnecessary reallocations.
         *                        Will preallocate 2 times as many indices.
         */
        this(const GLDrawMode mode, const size_t preallocate)
        in
        {
            assert(mode == GLDrawMode.VertexArray ||
                   mode == GLDrawMode.VertexBuffer, "Unsupported draw mode");
        }
        body
        {
            verticesAllocated_ = allocArray!Vertex(preallocate);
            indicesAllocated_  = allocArray!uint(preallocate * 2);
            vertices_          = verticesAllocated_[0 .. 0];
            indices_           = indicesAllocated_[0 .. 0];
            mode_              = mode;
            isNull_            = false;
            if(mode_ == GLDrawMode.VertexBuffer){initVBO();}
        }

        ///Destroy the GLVertexBuffer.
        ~this()
        {
            if(isNull_){return;}
            free(verticesAllocated_);
            free(indicesAllocated_);
            if(mode_ == GLDrawMode.VertexBuffer){destroyVBO();}
        }

        ///Start drawing with this buffer. Must be called before calls to draw().
        void startDraw()
        {
            if(mode_ == GLDrawMode.VertexBuffer)
            {
                const vertexBytes = cast(uint)(Vertex.sizeof * vertices_.length);
                const indexBytes = cast(uint)(uint.sizeof * indices_.length);

                //bind the buffers
                glBindBuffer(GL_ARRAY_BUFFER, vbo_);
                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo_);
                //upload data to the buffers
                glBufferData(GL_ARRAY_BUFFER, vertexBytes, vertices_.ptr, GL_STREAM_DRAW);
                glBufferData(GL_ELEMENT_ARRAY_BUFFER, indexBytes, indices_.ptr, GL_STREAM_DRAW);

                //unbind the buffers
                glBindBuffer(GL_ARRAY_BUFFER, 0);
                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
            }
        }

        ///End drawing with this buffer. Must be called after calls to draw().
        void endDraw()
        {
            //not necessary, just forcing the buffers not to be bound at the end of frame
            if(mode_ == GLDrawMode.VertexBuffer)
            {
                glBindBuffer(GL_ARRAY_BUFFER, 0);
                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
            }
        }

        ///Access vertex data as an array.
        @property Vertex[] vertices(){return vertices_;}

        ///Access index data as an array.
        @property uint[] indices(){return indices_;}

        ///Get number of vertices in the buffer.
        @property uint vertexCount() const {return cast(uint)vertices_.length;}

        ///Get number of indices in the buffer.
        @property uint indexCount() const {return cast(uint)indices_.length;}

        ///Set number of vertices in the buffer (to add more vertices).
        @property void vertexCount(const size_t len)
        {
            if(verticesAllocated_.length < len)
            {
                verticesAllocated_ = 
                    realloc(verticesAllocated_, verticesAllocated_.length * 2);
            }
            vertices_ = verticesAllocated_[0 .. len];
        }

        ///Set number of indices in the buffer (to add more indices).
        @property void indexCount(const size_t len)
        {
            if(indicesAllocated_.length < len)
            {
                indicesAllocated_ = 
                    realloc(indicesAllocated_, indicesAllocated_.length * 2);
            }
            indices_ = indicesAllocated_[0 .. len];
        }

        /**
         * Draw a vertex group using data stored in this buffer.
         *
         * Vertex group passed must be using data in this buffer, otherwise
         * undefined behavior might occur.
         *
         * This will only draw the vertices - other state such as shader,
         * texture page or scissor rectangle must be set before this call.
         *
         * Params:  group = Vertex group to draw.
         *
         * Returns: 0 if drawing was succesful.
         *          -1 if a required shader attribute was not found in group's shader.
         */
        int draw(const ref GLVertexGroup group)
        in
        {
            assert(group.vertexType == Vertex.vertexType, 
                   "Incorrect vertex group vertex type to draw with this buffer");
        }
        body
        {
            static const textured = is(Vertex == GLVertex2DTextured);

            //get vertex attribute handles
            const position = group.shader.getAttribute("in_position");
            const color = group.shader.getAttribute("in_color");
            if(position < 0 || color < 0 ){return -1;}
            static if(textured)
            {
                const texcoord = group.shader.getAttribute("in_texcoord");
                if(texcoord < 0){return -1;}
            }

            //enable vertex attrib array for attibutes used
            glEnableVertexAttribArray(position);
            glEnableVertexAttribArray(color);
            static if(textured){glEnableVertexAttribArray(texcoord);}                                 

            if(mode_ == GLDrawMode.VertexBuffer)
            {
                glBindBuffer(GL_ARRAY_BUFFER, vbo_);
                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo_);
            }

            //pointer to data for vertex arrays, offset in buffer for VBOs
            const void* data = mode_ == GLDrawMode.VertexArray 
                                        ? cast(void*)vertices_.ptr 
                                        : cast(void*)0;

            //specify data formats, locations
            glVertexAttribPointer(position, 2, GL_FLOAT, GL_FALSE, Vertex.sizeof, 
                                  data + Vertex.vertexOffset);
            static if(textured)
            {
                glVertexAttribPointer(texcoord, 2, GL_FLOAT, GL_FALSE, Vertex.sizeof, 
                                      data + Vertex.texcoordOffset);
            }
            glVertexAttribPointer(color, 4, GL_UNSIGNED_BYTE, GL_TRUE, Vertex.sizeof, 
                                  data + Vertex.colorOffset);

            //draw
            glDrawElements(GL_TRIANGLES, group.vertices, GL_UNSIGNED_INT, 
                           (mode_ == GLDrawMode.VertexArray ? indices_.ptr
                                                            : cast(void*)0) + group.offset);

            //clean up
            glDisableVertexAttribArray(position);
            glDisableVertexAttribArray(color);
            static if(textured){glDisableVertexAttribArray(texcoord);}
            return 0;
        }

        ///Reset the buffer, deleting all vertices, indices.
        void reset()
        {
            vertices_ = verticesAllocated_[0 .. 0];
            indices_  = indicesAllocated_[0 .. 0];
        }

    private:
        ///Initialize OpenGL VBOs, only used in VertexBuffer draw mode.
        void initVBO()
        {
            //generate names
            glGenBuffers(1, &vbo_);
            glGenBuffers(1, &ibo_);
            //bind
            glBindBuffer(GL_ARRAY_BUFFER, vbo_);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo_);
        }
        
        ///Destroy OpenGL VBOs, only used in VertexBuffer draw mode.
        void destroyVBO()
        {
            //bind
            glBindBuffer(GL_ARRAY_BUFFER, vbo_);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_);
            //BUG: On NVidia binary drivers, deleting buffer names will result in a
            //     crash once they are generated again. This might be some
            //     insidious bug in our code, but this has not been confirmed yet.
            //
            //     We are at least using glBufferData to deallocate buffer storage
            //     in GPU memory.
            //
            //     Not deleting buffer names is unlikely to cause problems, though, as
            //     we only use few buffer names during the entire run time.
            //deallocate
            glBufferData(GL_ARRAY_BUFFER, 0, null, GL_STATIC_DRAW);
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, 0, null, GL_STATIC_DRAW);
            //unbind
            glBindBuffer(GL_ARRAY_BUFFER, 0);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
            ////delete names
            //glDeleteBuffers(1, &vbo_);
            //glDeleteBuffers(1, &ibo_);
            vbo_ = 0;
            ibo_ = 0;
        }
}

/**
 * Vertex group.
 *
 * Stores state shared by all of its vertices (texture page, shader, scissor) 
 * and can be drawn in one function call in some draw modes.
 *
 * Individual draw calls are merged into vertex groups.
 */
package struct GLVertexGroup
{
    ///Shader used to draw the group.
    GLShader* shader;
    ///Texture page of the group if it uses texturing.
    GLTexturePage* texturePage;
    ///Scissor index of the group. uint.max means no scissor is used.
    uint scissor = uint.max;

    ///View zoom. 1.0 is normal, > 1.0 is zoomed in, < 1.0 is zoomed out.
    float viewZoom = 1.0;
    ///Current view offset in screen space.
    Vector2f viewOffset;

    ///Offset to index buffer used.
    uint offset;
    ///Vertex count of the group, i.e. indices in index buffer used.
    uint vertices;

    ///Vertex type of the group.
    GLVertexType vertexType;
}
