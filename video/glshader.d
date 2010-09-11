module video.glshader;


import std.string;
import std.file;
import std.stdio;

import derelict.opengl.gl;

import file.fileio;

package struct GLShader
{
    invariant{assert(program_ != 0, "Shader program is null");}

    private:
		//GLSL linked shader program.
        GLuint program_ = 0;

        //Load specified shader.
        void ctor(string name)
        {
            load_GLSL("shaders/" ~ name ~ ".vert", "shaders/" ~ name ~ ".frag");
        }

    public:
        ///Fake constructor. Load shader with given name.
        static GLShader opCall(string name)
        {
            GLShader shader;
            shader.ctor(name);
            return shader;
        }

        ///use this shader in following drawing commands.
        void start(){glUseProgram(program_);}
        
        ///Destroy this shader.
        void die(){glDeleteProgram(program_);}
        
    private:
        //Load a GLSL shader
        void load_GLSL(string vfname, string ffname)
        {
            File vfile;
            File ffile;
            try
            {
                vfile = open_file(vfname, FileMode.Read);
                ffile = open_file(ffname, FileMode.Read);
            }
            catch(Exception e)
            {
                throw new Exception("Couldn't load shader " ~ vfname ~
                                    " and/or " ~ ffname);
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
				throw new Exception("Couldn't link shaders " ~ vfname ~ " and "
                                     ~ ffname);
			}
        }
}
