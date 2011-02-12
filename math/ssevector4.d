
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module math.ssevector4;


import math.vector2;


/*
 * An union used to prepare vector data for SSE usage.
 * Can be used either as a 4D float vector or a pair of 2D float vectors.
 */
align(1) union SSEVector4f
{
    static align(1) struct Vector
    {
        //disabling default initialization for maximum speed
        float x = void;
        float y = void;
        float z = void;
        float w = void;
    }

    Vector v;

    Vector2f[2] half;
}
