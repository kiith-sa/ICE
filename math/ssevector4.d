module math.ssevector4;


import math.vector2;


/*
 * An uniton used to prepare vector data for SSE usage.
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
