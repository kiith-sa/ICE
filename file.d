module file;


import std.file;


///A simple function to load a text file to a string.
string load_text_file(string fname)
{
    return cast(string)read(fname);
}

///A simple function to load a file to a buffer.
ubyte[] load_file(string fname)
{
    return cast(ubyte[])read(fname);
}
