
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///String functions used in CTFE.
module util.stringctfe;
@safe


/**
 * Replacement for std.string.split, which can't be evaluated at compile time.
 *
 * Splits the string to an array of substrings, delimited by specified character.
 *
 * Params: str       = String to split.
 *         delimiter = Delimiter used to split the string.
 *
 * Returns: Resulting array of substrings.
 */
string[] split_ctfe(in string str, in char delimiter)
{
    string current;
    string[] result;
    foreach(c; str)
    {
        if(c == delimiter)
        {
            if(current.length > 0)
            {
                result ~= current;
                current = "";
            }
            continue;
        }
        current ~= c;
    }
    if(current.length > 0){result ~= current;}
    return result;
}

/**
 * Replacement for std.string.join, which can't be evaluated at compile time.
 *
 * Joins all given strings into one string with specified separator.
 *
 * Params:  words = Strings to join.
 *          sep   = Separator to use.
 *
 * Returns: Joined string.
 */
string join_ctfe(in string[] words, in string sep)
{
    if(words.length == 0){return "";}
    string result = words[0];
    foreach(word; words[1 .. $]){result ~= sep ~ word;}
    return result;
}

/**
 * Replacement for std.string.strip, which can't be evaluated at compile time.
 *
 * Removes all leading and trailing spaces and returns resulting string.
 *
 * Params:  str = String to strip.
 *
 * Returns: Stripped string.
 */
string strip_ctfe(string str)
{
    while(str.length && str[0] == ' ')
    {
        str = str[1 .. $];
    }
    while(str.length && str[$ - 1] == ' ')
    {
        str = str[0 .. $ - 1];
    }
    return str;
}
