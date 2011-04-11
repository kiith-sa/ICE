
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module util.string;


import std.string;
import std.conv;

import containers.array;


/**
 * Convert a variable to a string.
 *
 * Params:  val = Variable to convert.
 *
 * Returns: Result of conversion.
 */
string to_string(T)(T val)
{
    static if(is(T == string)){return val;}
    else{return std.string.toString(val);}
}

/**
 * Convert an array to a string.
 *
 * Params:  vals = Array to convert.
 *
 * Returns: Result of conversion.
 */
string to_string(T)(T[] vals)
{
    if(vals.length == 0){return "";}
    string result = to_string(vals[0]);
    foreach(val; vals){result ~= "," ~ to_string(val);}
    return result;
}

/**
 * Convert a string to a value of specified format.
 *
 * Params:  str = String to convert.
 *
 * Returns: Converted value.
 *
 * Throws:  ConvError if the string could not be parsed.
 */
T to(T)(string str){static assert(false, "Unsupported format for conversion from string");}

//type specializations of to()
T to(T : string)(string str){return str;}
T to(T : ulong) (string str){return toUlong(str);}
T to(T : long)  (string str){return toLong(str);}
T to(T : uint)  (string str){return toUint(str);}
T to(T : int)   (string str){return toInt(str);}
T to(T : ushort)(string str){return toUshort(str);}
T to(T : short) (string str){return toShort(str);}
T to(T : ubyte) (string str){return toUbyte(str);}
T to(T : byte)  (string str){return toByte(str);}
T to(T : float) (string str){return toFloat(str);}
T to(T : double)(string str){return toDouble(str);}
T to(T : real)  (string str){return toReal(str);}
T to(T : bool)  (string str)
{
    if(["Yes", "yes", "YES", "On", "on", "ON", "True", "true", "TRUE", 
        "Y", "y", "T", "t", "1"].contains(str))
    {
        return true;
    }
    else if(["No", "no", "NO", "Off", "off", "OFF", "False", "false", "FALSE", 
             "N", "n", "F", "f", "0"].contains(str))
    {
        return false;
    }

    throw new ConvError("Could not parse string as bool: " ~ str);
}
