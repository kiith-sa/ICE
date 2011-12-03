
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///OpenGL shader.
module video.glshader;
@system


import std.exception;
import std.stdio;
import std.string;

import derelict.opengl.gl;

import video.shader;
import file.fileio;

           
///OpenGL (GLSL only right now) shader.
package struct GLShader
{
    //commented out due to compiler bug
    //invariant(){assert(program_ != 0, "Shader program is null");}

    private:
        alias file.file.File File;

        ///Linked GLSL shader program.
        GLuint program_ = 0;

    public:
        /**
         * Construct (load) a shader.
         *
         * Params:  name = File name of the shader in the "shaders/" subdirectory.
         * 
         * Throws:  ShaderException if the shader could not be loaded or was invalid.
         */
        this(in string name)
        {
            scope(failure){writefln("Shader initialization failed: " ~ name);}

            try{load_GLSL("shaders/" ~ name ~ ".vert", "shaders/" ~ name ~ ".frag");}
            catch(FileIOException e)
            {
                throw new ShaderException("Shader could not be read: " ~ e.msg);
            }
            catch(ShaderException e){writefln(e.msg); throw e;}
        }

        ///Destroy this shader.
        ~this(){glDeleteProgram(program_);}

        ///Use this shader in following drawing commands.
        void start(){glUseProgram(program_);}
        
        /**
         * Get a handle to vertex attribute with specified name in the shader.
         *
         * Params:  name = Name of the attribute.
         * 
         * Returns: Handle to the attribute or -1 if not found in the shader.
         */
        GLint get_attribute(in string name) const
        {
            return glGetAttribLocation(program_, toStringz(name));
        }
        
        /**
         * Get a handle to uniform variable with specified name in the shader.
         *
         * Params:  name = Name of the uniform.
         * 
         * Returns: Handle to the uniform or -1 if not found in the shader.
         */
        GLint get_uniform(in string name) const
        {
            return glGetUniformLocation(program_, toStringz(name));
        }

    private:
        /**
         * Load a GLSL shader.
         *
         * Params:  vfname = File name of the vertex shader.
         *          ffname = File name of the fragment shader.
         *
         * Throws:  FileIOException if a shader file could not be found or file name is invalid.
         *          ShaderException if the shader could not be loaded, compiled or linked.
         */
        void load_GLSL(in string vfname, in string ffname)
        {
            //opening and loading from files
            File vfile    = File(vfname, FileMode.Read);
            File ffile    = File(ffname, FileMode.Read);

            const vsource = cast(string)vfile.data;
            const fsource = cast(string)ffile.data;
            const vlength = cast(int)vsource.length; 
            const flength = cast(int)fsource.length; 
            const vptr    = vsource.ptr;
            const fptr    = fsource.ptr;
            
            //creating OpenGL objects for shaders
            const GLuint vshader = glCreateShader(GL_VERTEX_SHADER);
            const GLuint fshader = glCreateShader(GL_FRAGMENT_SHADER);

            //passing shader code to OpenGL
            glShaderSource(vshader, 1, &vptr, &vlength);
            glShaderSource(fshader, 1, &fptr, &flength);

            //compiling shaders
            int compiled;
            glCompileShader(vshader);
            glGetShaderiv(vshader, GL_COMPILE_STATUS, &compiled);
            enforceEx!ShaderException(compiled, "Couldn't compile vertex shader " ~ vfname);

            glCompileShader(fshader);
            glGetShaderiv(fshader, GL_COMPILE_STATUS, &compiled);
            enforceEx!ShaderException(compiled, "Couldn't compile fragment shader " ~ ffname);

            program_ = glCreateProgram();

            //passing shaders to the program
            glAttachShader(program_, vshader);
            glAttachShader(program_, fshader);

            //linking shaders
            int linked;
            glLinkProgram(program_);
            glGetProgramiv(program_, GL_LINK_STATUS, &linked);
            if(!linked)
            {
                glDeleteProgram(program_);
                throw new ShaderException("Couldn't link shaders " ~ vfname ~ " and " ~ ffname);
            }
        }
}
