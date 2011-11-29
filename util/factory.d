
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
 * Params:  parameter_strings = Array of strings representing factory members,
 *                              their types and default values.
 *
 * Returns: Generated code ready to be inserted into a factory class definition.
 */
string generate_factory(string[] parameter_strings ...)
{
    alias Tuple!(string, "type", string, "name", string, "def_value") Parameter;

    Parameter[] params;
    foreach(param; parameter_strings)
    { 
        string[] p = param.split("$");
        assert(p.length == 3, "Malformed parameter to generate factory code: " ~ param);
        params ~= Parameter(p[0].strip_ctfe(), p[1].strip_ctfe(), p[2].strip_ctfe());
    }

    string data, setters;
    foreach(p; params)
    {
        data    ~= p.type ~ " " ~ p.name ~ "_ = " ~ p.def_value ~ ";\n";
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
    assert(expected == generate_factory("string $ a $ \"default\"", "int $ b $ 42"),
           "Unexpected factory code generated");
}
