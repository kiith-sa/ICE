
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Compile time traits.
module util.traits;


import std.traits;


///Determine if T is a "primitive" type, i.e. a bool, builtin numeric or string type.
template isPrimitive(T)
{
    enum bool isPrimitive = is(bool == T) || isNumeric!T || isSomeString!T;
}

///Convert a type tuple to an array of strings with its types' names.
string[] tupleToStrings(Types ...)() pure nothrow
{
    string[] result;
    foreach(T; Types){result ~= (Unqual!T).stringof;}
    return result;
}

