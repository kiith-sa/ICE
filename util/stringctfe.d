
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///String functions used in CTFE.
module util.stringctfe;


import std.array;


/**
 * Replacement for std.string.strip, which can't be evaluated at compile time.
 *
 * Removes all leading and trailing spaces and returns resulting string.
 *
 * Params:  str = String to strip.
 *
 * Returns: Stripped string.
 */
string stripCtfe(string str)
{
    while(str.length && str.front == ' '){str.popFront();}
    while(str.length && str.back == ' ') {str.popBack();}
    return str;
}

///Convert a character to lowercase (if not lowercase already).
char toLowerCtfe(const char c) pure nothrow
{
    return (c >= 'A' && c <= 'Z') ? cast(char)('a' + (c - 'A')) : c;
}
