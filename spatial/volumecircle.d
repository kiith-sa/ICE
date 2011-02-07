module spatial.volumecircle;


import spatial.volume;
import math.vector2;


///Bounding circle.
final class VolumeCircle : Volume
{
    invariant{assert(radius > 0.0f, "Collision circle radius must be positive");}

    public:
        //Position of circle center in object space.
        Vector2f offset;
        //Radius of the circle.
        float radius;

    public:
        /**
         * Construct a bounding circle with specified parameters.
         *
         * Params:    offset = Position of circle's center in object space.
         *            radius = Radius of the circle. Must be greater than 0.
         */
        this(Vector2f offset, float radius)
        {
            this.offset = offset;
            this.radius = radius;
        }
}
