
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module video.glshader;


import std.string;
import std.file;
import std.stdio;

import derelict.opengl.gl;

import video.shader;
import file.fileio;
import util.exception;

           
///OpenGL (GLSL only right now) shader.
package struct GLShader
{
    invariant{assert(program_ != 0, "Shader program is null");}

    private:
        ///Linked GLSL shader program.
        GLuint program_ = 0;

    public:
        /**
         * Construct (load) a shader.
         *
         * Params:  name = File name of the shader in the "shaders/" subdirectory.
         * 
         * Returns: Loaded shader.
         *
         * Throws:  ShaderException if the shader could not be loaded or was invalid.
         */
        static GLShader opCall(string name)
        {
            GLShader shader;
            try{shader.load_GLSL("shaders/" ~ name ~ ".vert", "shaders/" ~ name ~ ".frag");}
            catch(FileIOException e){throw new Exception("Shader could not be read: " ~ e.msg);}
            catch(ShaderException e){writefln(e.msg); throw e;}
            return shader;
        }

        ///Destroy this shader.
        void die(){glDeleteProgram(program_);}

        ///Use this shader in following drawing commands.
        void start(){glUseProgram(program_);}
        
        /**
         * Get a handle to vertex attribute with specified name in the shader.
         *
         * Params:  name = Name of the attribute.
         * 
         * Returns: Handle to the attribute or -1 if not found in the shader.
         */
        GLint get_attribute(string name)
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
        GLint get_uniform(string name)
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
        void load_GLSL(string vfname, string ffname)
        {
            //opening and loading from files
            File vfile;
            File ffile;

            vfile = open_file(vfname, FileMode.Read);
            scope(exit){close_file(vfile);}
            ffile = open_file(ffname, FileMode.Read);
            scope(exit){close_file(ffile);}

            string vsource = cast(string)vfile.data;
            string fsource = cast(string)ffile.data;
            int vlength = cast(int)vsource.length; 
            int flength = cast(int)fsource.length; 
            char* vptr = vsource.ptr;
            char* fptr = fsource.ptr;
            
            //creating OpenGL objects for shaders
            GLuint vshader = glCreateShader(GL_VERTEX_SHADER);
            GLuint fshader = glCreateShader(GL_FRAGMENT_SHADER);

            //passing shader code to OpenGL
            glShaderSource(vshader, 1, &vptr, &vlength);
            glShaderSource(fshader, 1, &fptr, &flength);

            //compiling shaders
            int compiled;
            glCompileShader(vshader);
            glGetShaderiv(vshader, GL_COMPILE_STATUS, &compiled);
            enforceEx!(ShaderException)(compiled, "Couldn't compile vertex shader " ~ vfname);

            glCompileShader(fshader);
            glGetShaderiv(fshader, GL_COMPILE_STATUS, &compiled);
            enforceEx!(ShaderException)(compiled, "Couldn't compile fragment shader " ~ ffname);

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
