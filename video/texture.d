module video.texture;


import math.vector2;


///Opague and immutable texture handle struct used by code outside video subsystem.
align(1) struct Texture
{
    package:
        Vector2u size;
        uint index;
}
