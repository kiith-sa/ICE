module texture;


import vector2;

align(1) struct Texture
{
    //These members should be package once we split to packages
    Vector2u size;
    uint index;
}
