
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///OpenGL shader.
module video.glshader;


import std.conv;
import std.exception;
import std.stdio;
import std.string;

import derelict.opengl.gl;
import dgamevfs._;

import memory.memory;
import video.shader;

           
///OpenGL (GLSL only right now) shader.
package struct GLShader
{
    private:
        ///Linked GLSL shader program.
        GLuint program_ = 0;

    public:
        /**
         * Construct (load) a shader.
         *
         * Params:  name      = File name of the shader in the "shaders/" subdirectory.
         *          shaderDir = Shader data directory.
         * 
         * Throws:  ShaderException if the shader could not be loaded or was invalid.
         */
        this(string name, VFSDir shaderDir)
        {
            scope(failure){writefln("Shader initialization failed: " ~ name);}

            try
            {
                loadGLSL(shaderDir.file(name ~ ".vert"), 
                         shaderDir.file(name ~ ".frag"));
            }
            catch(VFSException e)
            {
                throw new ShaderException("Shader could not be read: " ~ e.msg);
            }
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
        GLint getAttribute(const string name) const
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
        GLint getUniform(const string name) const
        {
            return glGetUniformLocation(program_, toStringz(name));
        }

    private:
        /**
         * Load a GLSL shader.
         *
         * Params:  vertex   = File to read the vertex shader from.
         *          fragment = File to read the fragment shader from.
         *
         * Throws:  VFSException   if a shader file could not be read from.
         *          ShaderException if the shader could not be loaded, compiled or linked.
         */
        void loadGLSL(VFSFile vertex, VFSFile fragment)
        {
            auto error = glGetError();
            if(error != GL_NO_ERROR)
            {
                writeln("GL error before loading shader: ", to!string(error));
            }

            GLuint loadShader(GLenum type, VFSFile file)
            {
                const typeStr = type == GL_VERTEX_SHADER   ? "vertex"   : 
                                type == GL_FRAGMENT_SHADER ? "fragment" :
                                                             null;
                assert(typeStr !is null, "Unknown shader type");

                char[] source = allocArray!char(file.bytes);
                scope(exit){free(source);}

                file.input.read(cast(void[])source);

                //opening and loading from files
                const srcLength = cast(int)source.length; 
                const srcPtr    = source.ptr;
                
                //creating OpenGL objects for shaders
                const GLuint shader = glCreateShader(type);
                scope(failure){glDeleteShader(shader);}
                if(shader == 0)
                {
                    auto msg = 
                        "Could not create " ~ typeStr ~ " shader object when loading "
                        "shader " ~ file.path ~ ". This is not the shader's fault. "
                        "Most likely the graphics drivers are old.";
                    throw new ShaderException(msg);
                }

                //passing shader code to OpenGL
                glShaderSource(shader, 1, &srcPtr, &srcLength);
                error = glGetError();
                if(error != GL_NO_ERROR)
                {
                    auto msg = 
                        "Error loading " ~ typeStr ~ " shader source from file " ~ 
                        file.path ~ " : " ~ to!string(error);
                    throw new ShaderException(msg);
                }

                //compiling shaders
                int compiled;
                glCompileShader(shader);
                glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
                if(!compiled)
                {
                    char[1024] log;
                    GLsizei logLength;
                    glGetShaderInfoLog(shader, log.length,  &logLength, log.ptr);

                    auto msg = 
                        "Couldn't compile " ~ typeStr ~ " shader " ~ 
                        file.path ~ ": info log: " ~ cast(string)log[0 .. logLength];  
                    throw new ShaderException(msg);
                }

                return shader;
            }


            const vshader = loadShader(GL_VERTEX_SHADER, vertex);
            scope(failure){glDeleteShader(vshader);}
            const fshader = loadShader(GL_FRAGMENT_SHADER, fragment);
            scope(failure){glDeleteShader(fshader);}

            program_ = glCreateProgram();
            scope(failure){glDeleteProgram(program_);}

            //passing shaders to the program
            glAttachShader(program_, vshader);
            scope(failure){glDetachShader(program_, vshader);}
            glAttachShader(program_, fshader);
            scope(failure){glDetachShader(program_, fshader);}

            //linking shaders
            int linked;
            glLinkProgram(program_);
            glGetProgramiv(program_, GL_LINK_STATUS, &linked);
            if(!linked)
            {
                throw new ShaderException("Couldn't link shaders " ~ vertex.path ~ 
                                          " and " ~ fragment.path);
            }
        }
}
