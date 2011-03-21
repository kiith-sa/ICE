
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module video.glrenderer;


import std.stdio;

import derelict.opengl.gl;

import video.glvertex;
import video.glvertexbuffer;
import video.gldrawmode;
import video.glshader;
import video.gltexture;
import video.gltexturepage;
import math.vector2;
import math.matrix4;
import math.rectangle;
import containers.vector;
import color;


/**
 * Caches draws and executes them at the end of the frame.
 *
 * GLRenderer is basically a massive render cache. Every draw call
 * generates vertices used by that draw (a line, texture draw or whatever),
 * which are added to a buffer that is passed to OpenGL at the end of the frame.
 * State changes (shader, texture, scissor) are also recorded. Everything is rendered
 * in the order of draw calls used.
 */
package struct GLRenderer
{
    private:
        ///Buffer for colored vertices (without texcoords).
        GLVertexBuffer!(GLVertex2DColored) colored_buffer_;
        ///Buffer for vertices with texcoords.
        GLVertexBuffer!(GLVertex2DTextured) textured_buffer_;
        ///Vertex groups, ordered from earliest to latest draws.
        Vector!(GLVertexGroup) vertex_groups_;

        ///Vertex group we're currently adding vertices to.
        GLVertexGroup current_group_;
        /**
         * Do we need to flush the current group (add it to vertex_groups_)? 
         *
         * True if group specific state (e.g. shader) has changed.
         */
        bool flush_group_;

        ///Scissor areas of scissor calls during the frame.
        Vector!(Rectanglei) scissor_areas_;
        ///If true, current group is using scissor. (the last element of scissor_areas_)
        bool scissor_;
        ///Shader of the current group.
        GLShader* shader_ = null;
        ///Texture page of the current group.
        TexturePage* texture_page_ = null;
        ///View zoom of the current group.
        Vector2f view_offset_ = Vector2f(0.0f, 0.0f);
        ///View offset of the current group.
        float view_zoom_ = 1.0f;
        
        ///Current line width.
        float line_width_ = 1.0f;
        ///Is line antialiasing enabled?
        bool line_aa_ = false;

        ///Has the renderer been initialized?
        bool initialized_ = false;

    public:
        /**
         * Construct a GLRenderer.
         *
         * Params:  mode = Draw mode to use.
         *  
         * Returns: Constructed GLRenderer.
         */
        static GLRenderer opCall(GLDrawMode mode)
        {
            GLRenderer cache;
            cache.vertex_groups_ = Vector!(GLVertexGroup)();
            cache.scissor_areas_ = Vector!(Rectanglei)();
            cache.flush_group_ = true;
            cache.initialized_ = true;
            cache.init_buffers(mode);
            return cache;
        }

        ///Destroy the GLRenderer.
        void die()
        {
            vertex_groups_.die();
            destroy_buffers();
            scissor_areas_.die();
        }

        ///Reset all frame state. (end the frame)
        void reset()
        {
            colored_buffer_.reset();
            textured_buffer_.reset();

            texture_page_ = null;
            shader_ = null;
            scissor_ = false;

            scissor_areas_.length = 0;
            vertex_groups_.length = 0;

            current_group_.vertices = 0;
            flush_group_ = true;

            //we're not resetting zoom, view offset - those keep their values between frames
        }

        ///Get number of vertices used during the frame so far.
        uint vertex_count()
        {
            return colored_buffer_.vertex_count + textured_buffer_.vertex_count;
        }

        ///Get number of indices used during the frame so far.
        uint index_count()
        {
            return colored_buffer_.index_count + textured_buffer_.index_count;
        }

        ///Set draw mode. Should not be called during a frame.
        void draw_mode(GLDrawMode mode)
        {
            destroy_buffers();
            init_buffers(mode);
        }

        ///Is the GLRenderer initialized?
        bool initialized(){return initialized_;}

        ///Set shader to use in following draw calls.
        void set_shader(GLShader* shader)
        {
            shader_ = shader;
            flush_group_ = true;
        }

        ///Set texture page to use in following draw calls.
        void set_texture_page(TexturePage* page)
        {
            texture_page_ = page;
            flush_group_ = true;
        }

        ///Set scissor area to use in following draw calls. Only this area will be drawn to.
        void scissor(ref Rectanglei scissor_area)
        {
            scissor_ = true;
            scissor_areas_ ~= scissor_area;
            flush_group_ = true;
        }

        ///Disable scissor test for following draw calls.
        void disable_scissor()
        {
            scissor_ = false;
            flush_group_ = true;
        }

        ///Set view zoom for following draw calls.
        void view_zoom(float zoom)
        {
            view_zoom_ = zoom;
            flush_group_ = true;
        }

        ///Get view zoom.
        real view_zoom(){return view_zoom_;}

        ///Set view offset for following draw calls.
        void view_offset(Vector2f offset)
        {
            view_offset_ = offset;
            flush_group_ = true;
        }

        ///Get view offset.
        Vector2f view_offset(){return view_offset_;}

        ///Set line width for following draw calls.
        void line_width(real width){line_width_ = width;}

        ///Set line antialiasing (on or off) for following draw calls.
        void line_aa(bool aa){line_aa_ = aa;}

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
        void draw_line(Vector2f v1, Vector2f v2, Color c1, Color c2)
        {
            //The line is drawn as a rectangle with width slightly smaller than
            //line_width_ to prevent artifacts.

            alias GLVertex2DColored Vertex;

            //ensure we have the needed vertex type in the current group
            update_group(Vertex.vertex_type);

            //equivalent to (v2 - v1).normal;
            Vector2f offset_base = Vector2f(v1.y - v2.y, v2.x - v1.x); 
            offset_base.normalize();
            float half_width = line_width_ * 0.5;
            //offset of line vertices from start and end point of the line
            Vector2f offset = offset_base * half_width;

            //get current vertex, index count in colored buffer
            uint v = colored_buffer_.vertex_count;
            uint i = colored_buffer_.index_count;
            //enlarge colored buffer to fit new vertices, indices
            colored_buffer_.vertex_count = line_aa_ ? v + 8 : v + 4;
            colored_buffer_.index_count =  line_aa_ ? i + 18 : i + 6;
            current_group_.vertices +=     line_aa_ ? 18 : 6;
            //get access to arrays to add vertices, indices to
            auto vertices = colored_buffer_.vertices;
            auto indices = colored_buffer_.indices;

            if(line_aa_)
            {
                //offsets of AA vertices from start and end point of the line
                Vector2f offset_aa = offset_base * (half_width + 0.4);
                //colors of AA vertices
                Color c3 = c1;
                Color c4 = c2;
                c3.a = 0;
                c4.a = 0;

                //AA vertices
                vertices[v]     = Vertex(v1 + offset_aa, c3);
                vertices[v + 1] = Vertex(v2 + offset_aa, c4);
                //line vertices         
                vertices[v + 2] = Vertex(v1 + offset, c1);
                vertices[v + 3] = Vertex(v2 + offset, c2);
                vertices[v + 4] = Vertex(v1 - offset, c1);
                vertices[v + 5] = Vertex(v2 - offset, c2);
                //AA vertices           
                vertices[v + 6] = Vertex(v1 - offset_aa, c3);
                vertices[v + 7] = Vertex(v2 - offset_aa, c4);

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
        void draw_rectangle(Vector2f min, Vector2f max, Color color)
        {
            alias GLVertex2DColored Vertex;

            //ensure we have the needed vertex type in the current group
            update_group(Vertex.vertex_type);

            //get current vertex, index count in colored buffer
            auto v = colored_buffer_.vertex_count;
            auto i = colored_buffer_.index_count;
            //enlarge colored buffer to fit new vertices, indices
            colored_buffer_.vertex_count = v + 4;
            colored_buffer_.index_count = i + 6;
            current_group_.vertices += 6;
            //get access to arrays to add vertices, indices to
            auto vertices = colored_buffer_.vertices;
            auto indices = colored_buffer_.indices;

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
         *          t_mix = Minimum texture coordinates of the rectangle.
         *          t_max = Maximum texture coordinates of the rectangle.
         *          color = Base rectangle color.
         */
        void draw_texture(Vector2f min, Vector2f max, Vector2f t_min, Vector2f t_max,
                          Color color = Color(255, 255, 255, 255))
        {
            alias GLVertex2DTextured Vertex;

            //ensure we have the needed vertex type in the current group
            update_group(Vertex.vertex_type);

            //get current vertex, index count in textured buffer
            auto v = textured_buffer_.vertex_count;
            auto i = textured_buffer_.index_count;
            //enlarge textured buffer to fit new vertices, indices
            textured_buffer_.vertex_count = v + 4;
            current_group_.vertices += 6;
            textured_buffer_.index_count = i + 6;
            //get access to arrays to add vertices, indices to
            auto vertices = textured_buffer_.vertices;
            auto indices = textured_buffer_.indices;

            alias Vector2f V;

            //add vertices
            vertices[v] =     Vertex(min, t_min, color);
            vertices[v + 1] = Vertex(V(max.x, min.y), V(t_max.x, t_min.y), color);
            vertices[v + 2] = Vertex(V(min.x, max.y), V(t_min.x, t_max.y), color);
            vertices[v + 3] = Vertex(max, t_max, color);
            //indices, each line specifies a triangle.
            indices[i++] = v;     indices[i++] = v + 2; indices[i++] = v + 1;
            indices[i++] = v + 1; indices[i++] = v + 2; indices[i++] = v + 3;
        }

        /**
         * Render out data specified with previous draw calls.
         *
         * Params:  screen_width  = Video mode width.
         *          screen_height = Video mode height.
         */
        void render(uint screen_width, uint screen_height)
        {
            //if we have an unfinished group, add it
            if(current_group_.vertices > 0){vertex_groups_ ~= current_group_;}

            //start drawing with the buffers
            colored_buffer_.start_draw();
            textured_buffer_.start_draw();

            foreach(ref group; vertex_groups_)
            {
                //uint.max means no scissor
                if(group.scissor != uint.max)
                {
                    Rectanglei scissor = scissor_areas_[group.scissor];
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

                auto modelview = translation_matrix(-group.view_offset /
                                                    Vector2f(screen_width, screen_height));
                auto projection = ortho_matrix(0.0f, screen_width / group.view_zoom,
                                               screen_height / group.view_zoom, 0.0f,
                                               -1.0f, 1.0f);

                //model-view-projection
                auto mvp = group.shader.get_uniform("mvp_matrix");
                if(mvp < 0)
                {
                    writefln("Missing uniform mvp_matrix in shader");
                    continue;
                }

                glUniformMatrix4fv(mvp, 1, GL_FALSE, (modelview * projection).ptr);

                //determine which buffer the group belongs to
                switch(group.vertex_type)
                {
                    case GLVertexType.Colored:
                        if(colored_buffer_.draw(group) < 0)
                        {
                            writefln("Missing shader attribute");
                        }
                        break;
                    case GLVertexType.Textured:
                        group.texture_page.start();  
                        if(textured_buffer_.draw(group) < 0)
                        {
                            writefln("Missing shader attribute");
                        }
                        break;
                    default:
                        assert(false, "Unknown vertex type");
                }
            }

            //end drawing with the buffers
            colored_buffer_.end_draw();
            textured_buffer_.end_draw();
        }

    private:
        /**
         * Ensure current group is a group with specified vertex type and flush it if needed.
         *
         * Params:  type = Vertex type we need.
         */
        void update_group(GLVertexType type)
        in
        {
            assert(type == GLVertexType.Colored || type == GLVertexType.Textured,
                   "Unsupported vertex type");
        }
        body
        {
            if(!flush_group_ && current_group_.vertex_type == type){return;}

            //After the frame starts, flush_group is true but we don't want to add an unitialized 
            //group, so ignore it. Also, adding an empty group is useless anyway.
            if(current_group_.vertices > 0)
            {
                //add the current group
                vertex_groups_ ~= current_group_;
            }

            //reset current group with current settings and specified vertex type
            with(current_group_)
            {
                vertex_type = type;

                offset = type == GLVertexType.Colored ? cast(uint)colored_buffer_.index_count
                                                      : cast(uint)textured_buffer_.index_count;
                vertices = 0;

                view_zoom = view_zoom_;
                view_offset = view_offset_;

                scissor = scissor_ ? cast(uint)scissor_areas_.length - 1 : uint.max;
                shader = shader_;
                texture_page = type == GLVertexType.Textured ? texture_page_ : null;
            }

            flush_group_ = false;
        }

        ///Initialize vertex buffers with specified draw mode.
        void init_buffers(GLDrawMode draw_mode_)
        {
            colored_buffer_ = GLVertexBuffer!(GLVertex2DColored)(draw_mode_);
            textured_buffer_ = GLVertexBuffer!(GLVertex2DTextured)(draw_mode_);
        }

        ///Destroy vertex buffers.
        void destroy_buffers()
        {
            colored_buffer_.die();
            textured_buffer_.die();
        }
}
