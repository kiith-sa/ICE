
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module util.factory;


import stringctfe;


/**
 * Generates data members and setters used in factory classes.
 *
 * Each input string specifies a type, name and deault value of a parameter,
 * delimited by the '$' character. E.g.: 
 * "string $ width $ \"64\""
 * will result in generation of data member width_ (followed by an underscore)
 * of type string with default value of "64", and a setter for it, like this:
 *
 * private string width_ = \"64\";
 * public void width(string width){width_ = width};
 *                               
 * Params:  parameter_strings = Array of strings representing factory members,
 *                              their types and default values.
 *
 * Returns: Generated code ready to be inserted into a factory class definition.
 */
string generate_factory(string parameter_strings []...)
{
    Parameter[] parameters;
    foreach(parameter; parameter_strings)
    { 
        string[] p = parameter.split('$');
        assert(p.length == 3, "Malformed parameter in generated factory code: " ~ parameter);
        parameters ~= Parameter(p[0].strip(), p[1].strip(), p[2].strip());
    }

    string data;
    foreach(p; parameters){data ~= p.type ~ " " ~ p.name ~ "_ = " ~ p.def_value ~ ";\n";}

    string setters;
    foreach(p; parameters)
    {
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

private: 

//Used in parameter string parsing, stores parameter data.
struct Parameter
{
    //Type of the parameter.
    string type;
    //Name of the parameter.
    string name;
    //Default value of the parameter.
    string def_value;
}
