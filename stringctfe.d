
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module stringctfe;


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
string[] split(string str, char delimiter)
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
 * Replacement for std.string.strip, which can't be evaluated at compile time.
 *
 * Returns a copy of string without leading and trailing whitespace.
 *
 * Params: str = String to strip.
 *
 * Returns: Stripped string.
 */
string strip(string str)
{
    uint left = 0;
    while(str[left] == ' '){left++;}
    if(left == str.length){return "";}
    uint right = str.length - 1;
    while(str[right] == ' '){right--;}
    return str[left .. right + 1];
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
string join(string[] words, string sep)
{
    if(words.length == 0){return "";}
    string result = words[0];
    foreach(word; words[1 .. $]){result ~= sep ~ word;}
    return result;
}
