/// utility and some wrappers for tango / phobos compatibility
module lodepng.util;


    //////////////////////////////////////////////////////////////////////////////////////
    //                                                                                  //
    //  This module provides some utility functions internal to lodepng and wraps or    //
    //  aliases a few phobos / tango dependent functions under a common api             //
    //                                                                                  //
    //////////////////////////////////////////////////////////////////////////////////////

version(Tango)
{
    import tango.stdc.stringz;
    import tango.text.Util;

    char[] _enforce(T)(char[] cond, char[] msg)
    {
        // HACK
        return `if (!(`~ cond ~`)) throw new `~ T.stringof ~` ( "`~ cond ~`: `~ msg ~` (in " ~
                `~ `__FILE__` ~` ~ ")" );`;
    }

    /+ TODO: implement this with toString
    char[] _enforce(T)(char[] cond, char[] msg)
    {
        // HACK
        return `if (!(`~ cond ~`)) throw new `~ T.stringof ~` ( "`~ cond ~`: `~ msg ~` (in " ~
                `~ `__FILE__` ~` ~ " at " ~ `~ `ToString!(__LINE__)` ~` ~ ")" );`;
    }
    +/

    alias toUtf8z toCString;
    alias tango.text.Util.locate!(char, char) strFind;

}
else
{
    public import std.metastrings;
    import std.string;


    char[] _enforce(T)(char[] cond, char[] msg)
    {
       return std.metastrings.Format!
       (
            `if (!(%s)) throw new %s (        "%s: %s (in " ~ %s ~ " at " ~ %s ~ ")" );`,
                   cond,          T.stringof, cond,msg,      `__FILE__`,   `std.metastrings.ToString!(__LINE__)`
       );
    }



    alias std.string.find strFind;
    alias toString toCString;
}






