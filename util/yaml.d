
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///ICE-specific YAML utilities.
module util.yaml;


import std.algorithm;
import std.conv;
import std.exception;
import std.functional;
import std.math;
import std.regex;
import std.stdio;
import std.stream;
import std.traits;

import dgamevfs._;

import dyaml.constructor;
import dyaml.dumper;
import dyaml.loader;
import dyaml.representer;
import dyaml.resolver;
import dyaml.style;

public import dyaml.exception;
public import dyaml.node : YAMLNode = Node;

import color;
import math.vector2;
import math.rect;


/**
 * Load a YAML file with support for ICE data types.
 *
 * Params:  file = File to load from.
 *
 * Throws:  YAMLException if the YAML could not be parsed or other YAML related
 *          errors. VFSException if the file could not be read from.
 */
YAMLNode loadYAML(VFSFile file)
{
    auto stream = VFSStream(file.input, file.bytes);
    auto loader = Loader(stream);
    loader.constructor = iceConstructor();
    loader.resolver    = iceResolver();

    return loader.load(); 
}

/**
 * Load YAML from a string.
 *
 * Params:  source = YAML source in string form.
 *
 * Throws:  YAMLException on a parsing error.
 */
YAMLNode loadYAML(string source)
{
    scope(failure)
    {
        writeln("YAML loading failed: ", source);
    }
    auto loader = Loader.fromString(source);
    loader.constructor = iceConstructor();
    loader.resolver    = iceResolver();
    return loader.load(); 
}

/**
 * Save to a YAML file with support for ICE data types.
 *
 * Params:  file = File to save to.
 *          yaml = YAML document to save.
 */
void saveYAML(VFSFile file, ref YAMLNode yaml)
{
    auto stream        = VFSStream(file.output);
    auto dumper        = Dumper(stream);
    dumper.resolver    = iceResolver();
    dumper.representer = iceRepresenter();
    dumper.dump(yaml);
}

/// Return a YAML constructor customized for ICE.
Constructor iceConstructor()
{
    auto constructor = new Constructor;
    constructor.addConstructorScalar("!color", &constructColorFromYAMLScalar);
    constructor.addConstructorScalar("!rotDeg", &constructDegreesRotation);
    return constructor;
}

/// Return a YAML resolver customized for ICE.
Resolver iceResolver()
{
    auto resolver = new Resolver;
    resolver.addImplicitResolver("!color", std.regex.regex(colorYAMLRegex),
                                 colorYAMLStartChars);
    resolver.addImplicitResolver("!rotDeg", std.regex.regex(rotationDegreesRegex),
                                 rotationDegreesStartChars);
    return resolver;
}

/// Return a YAML representer customized for ICE.
Representer iceRepresenter()
{
    auto representer   = new Representer();
    representer.defaultCollectionStyle = CollectionStyle.Block;
    return representer;
}

///Thrown when a YAML value is out of range or invalid.
class InvalidYAMLValueException : YAMLException 
{
    public this(string msg, string file = __FILE__, int line = __LINE__)
    {
        super(msg, file, line);
    }
}

/**
 * Utility function that loads a value froma YAML node, checking its validity.
 *
 * If cond is specified, it is used to validate the value (e.g. whether it is 
 * positive). 
 *
 *
 * Currently supported types: float, double, real, Vector2f.
 *
 * For floating point types, NaN values are automatically considered invalid.
 *
 * Params:  yaml    = YAML node to load from.
 *          context = Added to error message if the value if specified.
 *
 * Returns: Value loaded from YAML.
 *
 * Throws:  YAMLException if the value is invalid or has unexpected type.
 */
T fromYAML(T, string cond = "")(ref YAMLNode yaml, string context = "")
{
    alias InvalidYAMLValueException E;
    static if(isFloatingPoint!T)
    {
        T val = yaml.as!T;
        enforce(!isNaN(val), new E("NaN YAML value. Context: " ~ context));
    }
    else static if(is(T == Vector2f))
    {
        enforce(yaml.length == 2,
                new E("2D vector with an unexpected number of components. "
                      "Context: " ~ context));
        T val = Vector2f(fromYAML!float(yaml[0], context), 
                         fromYAML!float(yaml[1], context));
    }
    else static if(is(T == Rectf))
    {
        enforce(yaml.length == 4,
                new E("Rectangle with an unexpected number of components. "
                      "Context: " ~ context));
        T val = Rectf(fromYAML!float(yaml[0], context), 
                      fromYAML!float(yaml[1], context),
                      fromYAML!float(yaml[2], context),
                      fromYAML!float(yaml[3], context));
        enforce(val.valid,
                new E("Invalid rectangle (minimum x or y greater than" ~
                      "maximum). Context: " ~ context));
    }
    else static assert(false, "Unsupported type for fromYAML" ~ T.stringof);

    static if(cond != "")
    {
        enforce(unaryFun!cond(val),
                new E("YAML value out of range. Expected range: \"" ~ cond ~ 
                      "\" Context: " ~ context));
    }
    return val;
}

private:

/**
 * Constructs a rotation value from degrees.
 *
 * This actually translates a value in degrees suffixed by "deg"
 * into a float value in radians.
 */
float constructDegreesRotation(ref YAMLNode node)
{
    string value = node.as!string();

    enforce(value.endsWith("deg") && value.length > 3,
            new Exception("Invalid degree rotation: " ~ value));

    return (PI / 180.0f) * to!float(value[0 .. $ - 3]);
}

/**
 * Constructs a color from a scalar YAML value.
 *
 * Colors can be either in format rgbRRGGBB or rgbaRRGGBBAA where RR, GG, BB 
 * and AA are hexadecimal values of red, green, blue and alpha channels, just
 * like in CSS.
 */
Color constructColorFromYAMLScalar(ref YAMLNode node)
{
    string value = node.as!string;

    enforce(value.startsWith("rgb"),
            new Exception("Invalid color (unknown or unspecified format): " ~ value));

    if(value.startsWith("rgba"))
    {
        enforce(value.length == 12, new Exception("Invalid color: " ~ value));
        value = value[4 .. $];
    }
    else 
    {
        enforce(value.length == 9, new Exception("Invalid color: " ~ value));
        value = value[3 .. $];
    }

    return Color(hexColor(value[0 .. 2]),
                 hexColor(value[2 .. 4]),
                 hexColor(value[4 .. 6]),
                 value.length == 6 ? 255 : hexColor(value[6 .. 8]));
}
unittest
{
    auto n1 = YAMLNode("rgbFFFF00");
    auto n2 = YAMLNode("rgbaFFFF0080");
    assert(constructColorFromYAMLScalar(n1) == rgb!"FFFF00");
    assert(constructColorFromYAMLScalar(n2) == rgba!"FFFF0080");

    auto ne1 = YAMLNode("rabFFFF00");
    auto ne2 = YAMLNode("rgbbFFFF00");
    auto ne3 = YAMLNode("rgbaFFFF00");
    auto ne4 = YAMLNode("rgbFFFF00AA");
    auto ne5 = YAMLNode("rgbFFFF0AA");
    auto ne6 = YAMLNode("rgbFFFAA");
    auto ne7 = YAMLNode("rgoaFFFF00AA");
    auto ne8 = YAMLNode("rgbaFFFF0AA");
    auto ne9 = YAMLNode("rgbaFFFF0AAAA");

    assertThrown!Exception(constructColorFromYAMLScalar(ne1));
    assertThrown!Exception(constructColorFromYAMLScalar(ne2));
    assertThrown!Exception(constructColorFromYAMLScalar(ne3));
    assertThrown!Exception(constructColorFromYAMLScalar(ne4));
    assertThrown!Exception(constructColorFromYAMLScalar(ne5));
    assertThrown!Exception(constructColorFromYAMLScalar(ne6));
    assertThrown!Exception(constructColorFromYAMLScalar(ne7));
    assertThrown!Exception(constructColorFromYAMLScalar(ne8));
    assertThrown!Exception(constructColorFromYAMLScalar(ne9));
}

///Regular expression used to determine that a YAML scalar is a color.
immutable colorYAMLRegex            = "(?:rgb|rgba)(?:[0-9A-F]{6}|[0-9A-F]{8})";
///Possible starting characters of a color YAML scalar.
immutable colorYAMLStartChars       = "r";
//Regular expression used to determine that a YAML scalar is a rotation value in degrees.
immutable rotationDegreesRegex      = r"^-?\d+(\.\d+)?deg$";
///Possible starting characters of a degrees rotation YAML scalar.
immutable rotationDegreesStartChars = "-0123456789.";
