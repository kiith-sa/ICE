
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module video.gldrawmode;

///OpenGL draw mode.
enum GLDrawMode
{
    /**
     * Immediate mode. Each vertex needs to be drawn in a separate function call.
     *
     * Obsolete, but good for old GPUs, some open source drivers and software GL.
     */
    Immediate,
    /**
     * Vertex arrays. Client memory (RAM) arrays drawn in a single function call.
     *
     * Deprecated in OpenGL 3.x, but well supported and fast for geometry 
     * generated at run time.
     */
    VertexArray,
    /**
     * Vertex buffer. Server memory (VRAM or RAM) arrays drawn in a single function call.
     *
     * Only drawing method supported in OpenGL 3.x (core) and onwards.
     * Fast for static geometry, good enough for streaming as well.
     */
    VertexBuffer
}

