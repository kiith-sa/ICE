
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


module video.shader;
@trusted


///Exception thrown at shader related errors.
class ShaderException : Exception{this(string msg){super(msg);}} 

///Opague and immutable shader handle used used by code outside video subsystem.
align(1) struct Shader
{
    package:
        ///Index of the shader in VideoDriver implementation.
        uint index;
}
