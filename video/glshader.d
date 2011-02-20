
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module video.glshader;


import std.string;
import std.file;
import std.stdio;

import derelict.opengl.gl;

import file.fileio;


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
         * Throws:  Exception if the shader could not be loaded or was invalid.
         */
        static GLShader opCall(string name)
        {
            GLShader shader;
            shader.load_GLSL("shaders/" ~ name ~ ".vert", "shaders/" ~ name ~ ".frag");
            return shader;
        }

        ///Use this shader in following drawing commands.
        void start(){glUseProgram(program_);}
        
        ///Destroy this shader.
        void die(){glDeleteProgram(program_);}
        
    private:
        /**
         * Load a GLSL shader.
         *
         * Params:  vfname = File name of the vertex shader.
         *          ffname = File name of the fragment shader.
         */
        void load_GLSL(string vfname, string ffname)
        {
            //opening and loading from files
            File vfile;
            File ffile;
            try
            {
                vfile = open_file(vfname, FileMode.Read);
                ffile = open_file(ffname, FileMode.Read);
            }
            catch(Exception e)
            {
                throw new Exception("Couldn't load shader " ~ vfname ~ " and/or " ~ ffname);
            }                                 
            scope(exit){close_file(vfile);}
            scope(exit){close_file(ffile);}
            string vsource = cast(string)vfile.data;
            string fsource = cast(string)ffile.data;
            int vlength = vsource.length; 
            int flength = fsource.length; 
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
			if(!compiled)
			{
				throw new Exception("Couldn't compile vertex shader " ~ vfname);
			}
			glCompileShader(fshader);
            glGetShaderiv(fshader, GL_COMPILE_STATUS, &compiled);
			if(!compiled)
			{
				throw new Exception("Couldn't compile fragment shader " ~ ffname);
			}

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
				throw new Exception("Couldn't link shaders " ~ vfname ~ " and " ~ ffname);
			}
        }
}
