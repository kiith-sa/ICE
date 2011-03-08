
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module util.exception;


import std.string;


template enforceEx(E)
{
    /**
     * Enforce a condition.
     * Throws exception of specified type if value is zero, otherwise returns it.
     *
     * Params:  value   = Condition (value) to enforce.
     *          message = Message to use if the exception is thrown.
     *
     * Returns: Value passed.
     *
     * Throws:  Exception of template type E, if the condition is not true.
     */
    T enforceEx(T, string file = __FILE__, int line = __LINE__)
               (T value, lazy string message)
    {
        alias std.string.toString to_string;
        if(value != cast(T)0){return value;}
        throw new E("file " ~ file ~ "\nline " ~ to_string(line) ~ "\n" ~ message);
    }
}
