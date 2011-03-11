
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module util.string;


/**
 * Does a string start with specified prefix?
 *
 * Params:  str    = String to check.
 *          prefix = Prefix to look for.
 *
 * Returns: True if the string starts with specified prefix, false otherwise.
 */
bool starts_with(string str, string prefix)
{
    return str.length >= prefix.length && str[0 .. prefix.length] == prefix;
}
