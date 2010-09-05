module video.texture;


import math.vector2;

align(1) struct Texture
{
    package:
        //These members should be package once we split to packages
        Vector2u size;
        uint index;
}
