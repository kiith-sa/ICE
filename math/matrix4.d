
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///4x4 matrix struct.
module math.matrix4;


import std.math;

import math.math;
import math.vector2;


///4x4 column major OpenGL style matrix. Default initialized to indentity matrix.
struct Matrix4(T)
{
    private:
        ///Identity matrix array.
        static const T[16] identity_ = [1, 0, 0, 0, 
                                        0, 1, 0, 0,
                                        0, 0, 1, 0,
                                        0, 0, 0, 1];
        ///Matrix data.
        T[16] m_ = identity_;

    public:
        ///Get a pointer to matrix data. Useful for passing to OpenGL functions.
        @property T* ptr() pure {return m_.ptr;}

        ///Multiplication with a matrix.
        Matrix4!T opMul(const ref Matrix4!T m) const pure
        {
            Matrix4!T r;

            r.m_[0]  = m_[0] * m.m_[0]  + m_[4] * m.m_[1]  + m_[8]  * m.m_[2]  + m_[12] * m.m_[3];
            r.m_[1]  = m_[1] * m.m_[0]  + m_[5] * m.m_[1]  + m_[9]  * m.m_[2]  + m_[13] * m.m_[3];
            r.m_[2]  = m_[2] * m.m_[0]  + m_[6] * m.m_[1]  + m_[10] * m.m_[2]  + m_[14] * m.m_[3];
            r.m_[3]  = m_[3] * m.m_[0]  + m_[7] * m.m_[1]  + m_[11] * m.m_[2]  + m_[15] * m.m_[3];
            r.m_[4]  = m_[0] * m.m_[4]  + m_[4] * m.m_[5]  + m_[8]  * m.m_[6]  + m_[12] * m.m_[7];
            r.m_[5]  = m_[1] * m.m_[4]  + m_[5] * m.m_[5]  + m_[9]  * m.m_[6]  + m_[13] * m.m_[7];
            r.m_[6]  = m_[2] * m.m_[4]  + m_[6] * m.m_[5]  + m_[10] * m.m_[6]  + m_[14] * m.m_[7];
            r.m_[7]  = m_[3] * m.m_[4]  + m_[7] * m.m_[5]  + m_[11] * m.m_[6]  + m_[15] * m.m_[7];
            r.m_[8]  = m_[0] * m.m_[8]  + m_[4] * m.m_[9]  + m_[8]  * m.m_[10] + m_[12] * m.m_[11];
            r.m_[9]  = m_[1] * m.m_[8]  + m_[5] * m.m_[9]  + m_[9]  * m.m_[10] + m_[13] * m.m_[11];
            r.m_[10] = m_[2] * m.m_[8]  + m_[6] * m.m_[9]  + m_[10] * m.m_[10] + m_[14] * m.m_[11];
            r.m_[11] = m_[3] * m.m_[8]  + m_[7] * m.m_[9]  + m_[11] * m.m_[10] + m_[15] * m.m_[11];
            r.m_[12] = m_[0] * m.m_[12] + m_[4] * m.m_[13] + m_[8]  * m.m_[14] + m_[12] * m.m_[15];
            r.m_[13] = m_[1] * m.m_[12] + m_[5] * m.m_[13] + m_[9]  * m.m_[14] + m_[13] * m.m_[15];
            r.m_[14] = m_[2] * m.m_[12] + m_[6] * m.m_[13] + m_[10] * m.m_[14] + m_[14] * m.m_[15];
            r.m_[15] = m_[3] * m.m_[12] + m_[7] * m.m_[13] + m_[11] * m.m_[14] + m_[15] * m.m_[15];

            return r;
        }
}

/**
 * Create a translation matrix.
 *
 * Params:  translate = Translation coordinates.
 *
 * Returns: Resulting translation matrix.
 */
Matrix4!T translationMatrix(T)(const Vector2!T translate)
{
    Matrix4!T result;
    result.m_[12] = translate.x;
    result.m_[13] = translate.y;
    return result;
}

/**
 * Create an orthographic projection matrix.
 *
 * Params:  left   = Left clipping plane.
 *          right  = Right clipping plane.
 *          bottom = Bottom clipping plane.
 *          top    = Top clipping plane.
 *          near   = Near clipping plane.
 *          far    = Far clipping plane.
 *
 * Returns: Resulting projection matrix.
 */
Matrix4!T orthoMatrix(T)(const T left, const T right, const T bottom, 
                         const T top, const T near, const T far) pure
{
    Matrix4!T result;
    const T width = right - left;
    const T height = top - bottom;
    const T depth = far - near;
    with(result)
    {
        m_[0]  = cast(T)2.0 / width;
        m_[5]  = cast(T)2.0 / height;
        m_[10] = cast(T)-2.0 / depth;

        m_[12] = -(right + left) / width;
        m_[13] = -(top + bottom) / height;
        m_[14] = -(far + near) / depth;
    }
    return result;
}

///Matrix4 of floats.
alias Matrix4!float Matrix4f;
