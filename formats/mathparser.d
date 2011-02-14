
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module formats.mathparser;


import std.string;
import std.conv;

import containers.array;


/**
 * Parse a string as a math expression.
 *
 * An associative array of substitutions can be passed
 * to substitute strings in the expression for numbers.
 * Substitutions are not checked for operators or spaces, so it
 * is possible to e.g. substitute "abc * d" for 42 .
 *
 * Params:  expression    = Math expression to parse.
 *          substitutions = Substitutions to use.
 *
 * Returns: Result of the expression.
 *
 * Throws:  Exception if the expression is invalid 
 *          (e.g. parentheses mismatch or redundant operator)
 */
T parse_math(T)(string expression, T[string] substitutions = null)
{
    if(expression.length == 0)
    {
        throw new Exception("Can't parse an empty string as a math expression");
    }
    if(substitutions !is null){expression = substitute(expression, substitutions);}
    return parse_postfix!(T)(to_postfix(expression));
}
///Unittest for parse_math
unittest
{
    int[string] substitutions;
    substitutions["width"] = 320;
    substitutions["height"] = 240;
    string str = "width + 12 0 * 2 + 2 * height";
    assert(parse_math(str, substitutions) == 1040);
    str = "3 + 4 * 8 / 1 - 5";
    assert(parse_math!(int)(str) == 30);
}


private:
    ///Formatting operators (parentheses).
    dchar[] formatting = ['(', ')'];
    ///Associative operators.
    dchar[] associative = ['*', '+'];
    ///Left-associative operators.
    dchar[] associative_left = ['-', '/'];
    ///All arithmetic operators.
    dchar[] arithmetic;
    ///All operators.
    dchar[] operators;
    ///Operator precedences indexed by the operators (higher number - higher precedence)
    uint[dchar] precedence;

    ///Static constructor. Set up operator arrays.
    static this()
    {
        arithmetic = associative ~ associative_left;
        operators = formatting ~ arithmetic;
        precedence = ['+':1, '-':1, '*':2, '/':2, '(':3, ')':3];
    }

    /**
     * Substitute strings for numbers based on a dictionary.
     *
     * Params:  input         = String to apply substitutions to.
     *          substitutions = Dictionary of substitutions to apply.
     *
     * Returns: Input string with substitutions applied.
     */
    string substitute(T)(string input, T[string] substitutions)
    {
        alias std.string.toString to_string;
        foreach(from, to; substitutions){input = replace(input, from, to_string(to));}
        return input;
    }

    /**
     * Convert an infix math expression to postfix (reverse polish) notation. 
     *
     * Params:  expression = Infix expression to convert.
     *
     * Returns: Input expression converted to postfix notation.
     *
     * Throws:  Exception if the expression is invalid 
     *          (e.g. parentheses mismatch or redundant operator)
     */
    string to_postfix(string expression)
    {
        alias containers.array.contains contains;
        dchar[] stack;

        string output = "";
        bool last_was_space = false;
        dchar prev_c = 0;

        dchar pop(){
            if(stack.length > 0){
                dchar c = stack[$ - 1];
                stack = stack[0 .. $ - 1];
                return c;}
            return 0;}

        foreach(dchar c; expression)
        {
            //ignore spaces
            if(iswhite(c)){continue;}
            //not an operator
            if(!operators.contains(c)){output ~= c;}
            //operator
            else
            {
                //if there are two operators in a row, we have an error.
                if(arithmetic.contains(prev_c) && arithmetic.contains(c))
                {
                    throw new Exception("Redundant operator in math expression " ~ expression);
                }
                //parentheses
                if(c == '('){stack ~= c;}//push to stack
                else if(c == ')')
                {
                    dchar tok = pop();
                    while(tok != '(')
                    {
                        if(tok == 0)
                        {
                            throw new Exception("Parenthesis mismatch in math "
                                                "expression " ~ expression);
                        }
                        output ~= " ";
                        output ~= tok;
                        tok = pop();
                    }
                }
                //arithmetic operator
                else
                {
                    //peek 
                    dchar tok = stack.length ? stack[$ - 1] : 0;

                    while(tok != 0 && tok != '(')
                    {
                        if(arithmetic.contains(c) && precedence[c] <= precedence[tok])
                        {
                            tok = pop();
                            output ~= " ";
                            output ~= tok;
                        }
                        else{break;}
                        //peek
                        tok = stack.length ? stack[$ - 1] : 0;
                    }

                    //push
                    stack ~= c;
                    output ~= " ";
                }
            }
            prev_c = c;
        }
        //peek
        dchar tok = stack.length ? stack[$ - 1] : 0;
                                            
        while(tok != 0)
        {
            if(tok == '(')
            {
                throw new Exception("Parenthesis mismatch in math expression " ~ expression);
            }
            tok = pop();

            output ~= " ";
            output ~= tok;

            //peek
            tok = stack.length ? stack[$ - 1] : 0;
        }
        return output;
    }

    /**
     * Parse a postfix math expression and return its result.
     *
     * Params:  postfix = Postfix expression to parse.
     *
     * Returns: Result of the expression.
     *
     * Throws:  Exception if an invalid token is detected in the expression.
     */
    T parse_postfix(T)(string postfix)
    {
        T[] stack;
        string[] tokens = split(postfix);

        void bin_operator(T function(T, T) operator){
            T x = stack[$ - 1]; T y = stack[$ - 2];
            stack[$ - 2] = operator(x, y);
            stack = stack[0 .. $ - 1];}

        foreach(string token; tokens)
        {
            switch(token[0])
            {
                case '+': bin_operator(function(T x, T y){return y + x;}); break; 
                case '-': bin_operator(function(T x, T y){return y - x;}); break; 
                case '*': bin_operator(function(T x, T y){return y * x;}); break; 
                case '/': bin_operator(function(T x, T y){return y / x;}); break; 
                default:
                    if(isNumeric(token)){stack ~= cast(T) toReal(token);}
                    else{throw new Exception("Invalid token in an expression: " ~ token);}
                    break;
            }
        }
        assert(stack.length == 1, "Postfix notation parser stack contains too many "
                                  "values at exit");
        return stack[$ - 1];
    }
