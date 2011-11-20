
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///OpenGL vertex buffer.
module video.glvertexbuffer;
@system


import derelict.opengl.gl;

import video.glvertex;
import video.gldrawmode;
import video.gltexturepage;
import video.glshader;
import math.vector2;
import containers.vector;


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
        ///Vertex data.
        Vector!Vertex vertices_;
        ///Index data.
        Vector!uint indices_;

        ///VBO handle, used in VBO mode.
        GLuint vbo_;
        ///IBO handle, used in VBO mode.
        GLuint ibo_;

        ///Draw mode of the buffer.
        GLDrawMode mode_;

    public:
        /**
         * Construct a GLVertexBuffer.
         *
         * Params:  mode = Draw mode of the buffer.
         */
        this(in GLDrawMode mode)
        in
        {
            assert(mode == GLDrawMode.Immediate || 
                   mode == GLDrawMode.VertexArray ||
                   mode == GLDrawMode.VertexBuffer, "Unsupported draw mode");
        }
        body
        {
            vertices_.reserve(8);
            indices_.reserve(8);
            mode_ = mode;
            if(mode_ == GLDrawMode.VertexBuffer){init_vbo();}
        }

        ///Destroy the GLVertexBuffer.
        ~this()
        {
            clear(vertices_);
            clear(indices_);
            if(mode_ == GLDrawMode.VertexBuffer){destroy_vbo();}
        }

        ///Start drawing with this buffer. Must be called before calls to draw().
        void start_draw()
        {
            if(mode_ == GLDrawMode.VertexBuffer)
            {
                const vertex_bytes = cast(uint)(Vertex.sizeof * vertices_.length);
                const index_bytes = cast(uint)(uint.sizeof * indices_.length);

                //bind the buffers
                glBindBuffer(GL_ARRAY_BUFFER, vbo_);
                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo_);
                //upload data to the buffers
                glBufferData(GL_ARRAY_BUFFER, vertex_bytes, vertices_.ptr, GL_STREAM_DRAW);
                glBufferData(GL_ELEMENT_ARRAY_BUFFER, index_bytes, indices_.ptr, GL_STREAM_DRAW);

                //unbind the buffers
                glBindBuffer(GL_ARRAY_BUFFER, 0);
                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
            }
        }

        ///End drawing with this buffer. Must be called after calls to draw().
        void end_draw()
        {
            //not necessary, just forcing the buffers not to be bound at the end of frame
            if(mode_ == GLDrawMode.VertexBuffer)
            {
                glBindBuffer(GL_ARRAY_BUFFER, 0);
                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
            }
        }

        ///Access vertex data as an array.
        @property Vertex[] vertices(){return vertices_.ptr_unsafe[0 .. vertices_.length];}

        ///Access index data as an array.
        @property uint[] indices(){return indices_.ptr_unsafe[0 .. vertices_.length];}

        ///Get number of vertices in the buffer.
        @property uint vertex_count() const {return cast(uint)vertices_.length;}

        ///Get number of indices in the buffer.
        @property uint index_count() const {return cast(uint)indices_.length;}

        ///Set number of vertices in the buffer (to add more vertices).
        @property void vertex_count(in size_t length)
        {
            if(vertices_.allocated < length)
            {
                vertices_.reserve(cast(size_t)(length * 1.5));
            }
            vertices_.length = length;
        }

        ///Set number of indices in the buffer (to add more indices).
        @property void index_count(in size_t length)
        {
            if(indices_.allocated < length)
            {
                indices_.reserve(cast(size_t)(length * 1.5));
            }
            indices_.length = length;
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
            assert(group.vertex_type == Vertex.vertex_type, 
                   "Incorrect vertex group vertex type to draw with this buffer");
        }
        body
        {
            static const textured = is(Vertex == GLVertex2DTextured);

            //get vertex attribute handles
            const position = group.shader.get_attribute("in_position");
            const color = group.shader.get_attribute("in_color");
            if(position < 0 || color < 0 ){return -1;}
            static if(textured)
            {
                const texcoord = group.shader.get_attribute("in_texcoord");
                if(texcoord < 0){return -1;}
            }

            if(mode_ == GLDrawMode.Immediate)
            {
                glBegin(GL_TRIANGLES);
                foreach(i; indices_[group.offset ..  group.offset + group.vertices])
                {
                    const Vertex* v = vertices_.ptr(i);
                    glVertexAttrib4Nubv(color, cast(ubyte*)&v.color);
                    static if(textured){glVertexAttrib2fv(texcoord, cast(float*)&v.texcoord);}
                    glVertexAttrib2fv(position, cast(float*)&v.vertex);
                }
                glEnd();
            }
            else
            {
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
                                      data + Vertex.vertex_offset);
                static if(textured)
                {
                    glVertexAttribPointer(texcoord, 2, GL_FLOAT, GL_FALSE, Vertex.sizeof, 
                                          data + Vertex.texcoord_offset);
                }                                 
                glVertexAttribPointer(color, 4, GL_UNSIGNED_BYTE, GL_TRUE, Vertex.sizeof, 
                                      data + Vertex.color_offset);
                
                //draw
                glDrawElements(GL_TRIANGLES, group.vertices, GL_UNSIGNED_INT, 
                               (mode_ == GLDrawMode.VertexArray ? indices_.ptr
                                                                : cast(void*)0) + group.offset);

                //clean up
                glDisableVertexAttribArray(position);
                glDisableVertexAttribArray(color);
                static if(textured){glDisableVertexAttribArray(texcoord);}
            }
            return 0;
        }

        ///Reset the buffer, deleting all vertices, indices.
        void reset()
        {
            vertices_.length = 0;
            indices_.length = 0;
        }

    private:
        ///Initialize OpenGL VBOs, only used in VertexBuffer draw mode.
        void init_vbo()
        {
            //generate names
            glGenBuffers(1, &vbo_);
            glGenBuffers(1, &ibo_);
            //bind
            glBindBuffer(GL_ARRAY_BUFFER, vbo_);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo_);
        }
        
        ///Destroy OpenGL VBOs, only used in VertexBuffer draw mode.
        void destroy_vbo()
        {
            //bind
            glBindBuffer(GL_ARRAY_BUFFER, vbo_);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo_);
            //BUG: On NVidia drivers, deleting buffer names will result in a
            //     crash once theyh are generated again. This might be some
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
package align(1) struct GLVertexGroup
{
    ///Shader used to draw the group.
    GLShader* shader;
    ///Texture page of the group if it uses texturing.
    TexturePage* texture_page;
    ///Scissor index of the group. uint.max means no scissor is used.
    uint scissor = uint.max;

    ///View zoom. 1.0 is normal, > 1.0 is zoomed in, < 1.0 is zoomed out.
    float view_zoom = 1.0;
    ///Current view offset in screen space.
    Vector2f view_offset;

    ///Offset to index buffer used.
    uint offset;
    ///Vertex count of the group, i.e. indices in index buffer used.
    uint vertices;

    ///Vertex type of the group.
    GLVertexType vertex_type;
}
