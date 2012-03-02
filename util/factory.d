
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Functions generating factory code.
module util.factory;
@safe


import std.string;
import std.typecons;

import util.stringctfe;

/**
 * Generates data members and setters used in factory classes.
 *
 * Each input string specifies a type, name and default value of a parameter,
 * delimited by the '$' character. E.g.:           
 * --------------------
 * "string $ width $ \"64\""
 * --------------------
 * will generate data member "width_" (notice trailing underscore)
 * of type string with default value of "64", and a setter "width", like this:
 * --------------------
 * protected string width_ = \"64\";
 * public void width(string width){width_ = width};
 * --------------------
 *
 * Params:  parameterStrings = Array of strings representing factory members,
 *                              their types and default values.
 *
 * Returns: Generated code ready to be inserted into a factory class definition.
 */
string generateFactory(string[] parameterStrings ...)
{
    alias Tuple!(string, "type", string, "name", string, "defValue") Parameter;

    //Preallocating because appending here causes a compiler error.
    Parameter[] params = new Parameter[parameterStrings.length];
    foreach(i, param; parameterStrings)
    { 
        string[] p = param.split("$");
        assert(p.length == 3, "Malformed parameter to generate factory code: " ~ param);
        params[i] = Parameter(p[0].stripCtfe(), p[1].stripCtfe(), p[2].stripCtfe());
    }

    string data, setters;
    foreach(p; params)
    {
        data    ~= p.type ~ " " ~ p.name ~ "_ = " ~ p.defValue ~ ";\n";
        setters ~= "void " ~ p.name ~ "(" ~ p.type ~ " " ~ p.name ~ "){" ~
                   p.name ~ "_ = " ~ p.name ~ ";}\n";
    }

    return "protected:\n" ~ data ~ "public:\n" ~ setters;
}
unittest
{
    string expected =
        "protected:\n"
        "string a_ = \"default\";\n"
        "int b_ = 42;\n"
        "public:\n"
        "void a(string a){a_ = a;}\n"
        "void b(int b){b_ = b;}\n";
    assert(expected == generateFactory("string $ a $ \"default\"", "int $ b $ 42"),
           "Unexpected factory code generated");
}

