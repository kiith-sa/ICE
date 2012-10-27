
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Widget utility functions.
module gui2.widgetutils;


import std.algorithm;
import std.ascii;

import gui2.exceptions;
import util.yaml;


/// Is the given string a valid widget name?
bool validWidgetName(const string name)
{
    return !(name.length == 0  ||
             !isAlpha(name[0]) ||
             canFind!((dchar c){return !isAlphaNum(c) && c != '_';})(name));
}

/// Is the given string a valid composed widget name (name of a subwidget)?
bool validComposedWidgetName(const string name) 
{
    return !canFind!((string n){return !validWidgetName(n);})(name.splitter("."));
}

/// Parse a non-optional widget property at widget initialization.
T widgetInitProperty(T)(ref YAMLNode yaml, string name)
{
    return property!(T, WidgetInitException)(yaml, name);
}

/// Parse a non-optional layout property at layout initialization.
T layoutInitProperty(T)(ref YAMLNode yaml, string name)
{
    return property!(T, LayoutInitException)(yaml, name);
}

/// Parse an optional style initialization property, with a default if not specified.
T styleInitPropertyOpt(T)(ref YAMLNode yaml, string name, auto ref T defValue)
{
    return optionalProperty!(T, StyleInitException)(yaml, name, defValue);
}

/// Parse an optional widget initialization property, with a default if not specified.
T widgetInitPropertyOpt(T)(ref YAMLNode yaml, string name, auto ref T defValue)
{
    return optionalProperty!(T, WidgetInitException)(yaml, name, defValue);
}

private:

/// Parse a (non-optional) property from YAML and return its value.
T property(T, E)(ref YAMLNode yaml, string name)
{
    try
    {
        return yaml[name].as!T;
    }
    catch(YAMLException e)
    {
        throw new E("Failed to parse property " ~ name ~ ": " ~ e.msg);
    }
}

/// Parse an optional property from YAML.
///
/// Params: yaml     = YAML mapping containing the property.
///         name     = Name of the property.
///         defValue = Default value of the property.
T optionalProperty(T, E)(ref YAMLNode yaml, string name, ref T defValue)
{
    try 
    {
        return yaml.containsKey(name) ? yaml[name].as!T : defValue;
    }
    catch(YAMLException e)
    {
        throw new E("Failed to parse optional property " ~ name ~ ": " ~ e.msg);
    }
}
