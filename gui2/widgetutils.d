
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

/// Parse a (non-optional) widget property from YAML and return its value.
T parseProperty(T, string name, WidgetT)(ref YAMLNode yaml)
{
    try
    {
        return yaml[name].as!T;
    }
    catch(YAMLException e)
    {
        auto msg = "Failed to parse widget property " ~ name ~ ": " ~ e.msg;
        throw new WidgetInitException(msg);
    }
}
