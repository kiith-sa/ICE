
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Math expression parser.
module formats.mathparser;
@trusted


import std.algorithm;
import std.array;
import std.conv;                  
import std.exception;
import std.functional;
import std.stdio;
import std.string;
import std.traits;
alias std.algorithm.find find;


///Exception thrown at math parsing errors.
class MathParserException : Exception{this(string msg){super(msg);}} 

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
 * Throws:  MathParserException if the expression is invalid 
 *          (e.g. parentheses mismatch or redundant operator)
 */
T parse_math(T)(in string expression, T[string] substitutions = null)
    if(isNumeric!T)
{
    enforceEx!MathParserException(expression.length > 0, 
                                  "Can't parse an empty string as a math expression");

    scope(failure){writefln("Parsing math expression failed: " ~ expression);}
    const substituted = substitutions is null ? expression 
                                              : substitute(expression, substitutions);
    return parse_postfix!T(to_postfix(substituted));
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
    string substitute(T)(in string input, T[string] substitutions)
    {
        //ugly hack, could use rewriting
        char[] mutable = input.dup;
        foreach(from, to_; substitutions)
        {
            auto replacement = to_ >= cast(T)0 ? to!string(to_) 
                                               : "(0 " ~ to!string(to_) ~ ")";
            mutable = replace(mutable, from, replacement);
        }
        return cast(string)mutable;
    }

    /**
     * Convert an infix math expression to postfix (reverse polish) notation. 
     *
     * Params:  expression = Infix expression to convert.
     *
     * Returns: Input expression converted to postfix notation.
     *
     * Throws:  MathParserException if the expression is invalid 
     *          (e.g. parentheses mismatch or redundant operator)
     */
    string to_postfix(in string expression)
    {
        dchar[] stack;

        string output = "";
        bool last_was_space = false;
        dchar prev_c = 0;

        dchar pop()
        {
            if(stack.length > 0)
            {
                dchar c = stack[$ - 1];
                stack = stack[0 .. $ - 1];
                return c;
            }
            return 0;
        }

        foreach(dchar c; expression)
        {
            //ignore spaces
            if(iswhite(c)){continue;}
            //not an operator
            if(!operators.canFind(c)){output ~= c;}
            //operator
            else
            {
                //if there are two operators in a row, we have an error.
                if(arithmetic.canFind(prev_c) && arithmetic.canFind(c))
                {
                    throw new MathParserException("Redundant operator in math expression " 
                                                  ~ expression);
                }

                //parentheses
                if(c == '('){stack ~= c;}//push to stack
                else if(c == ')')
                {
                    dchar tok = pop();
                    while(tok != '(')
                    {
                        enforceEx!MathParserException
                                  (tok != 0, "Parenthesis mismatch in math expression " 
                                              ~ expression);
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
                        if(arithmetic.canFind(c) && precedence[c] <= precedence[tok])
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
            enforceEx!MathParserException
                      (tok != '(', "Parenthesis mismatch in math expression " ~ expression);

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
     * Throws:  MathParsetException if an invalid token is detected in the expression.
     */
    T parse_postfix(T)(in string postfix)
    {
        scope(failure){writefln("Parsing postfix notation failed: " ~ postfix);}

        T[] stack;
        const string[] tokens = split(postfix);

        void bin_operator(string op)()
        {
            T x = stack[$ - 1]; T y = stack[$ - 2];
            stack[$ - 2] = binaryFun!op(y, x);
            stack = stack[0 .. $ - 1];
        }

        foreach(token; tokens) switch(token[0])
        {
            case '+': bin_operator!"a + b"; break; 
            case '-': bin_operator!"a - b"; break; 
            case '*': bin_operator!"a * b"; break; 
            case '/': bin_operator!"a / b"; break; 
            default:
                enforceEx!MathParserException
                          (std.string.isNumeric(token), 
                           "Invalid token a in math expression: " ~ token);
                stack ~= cast(T) to!real(token);
                break;
        }
        assert(stack.length == 1, "Postfix notation parser stack contains too many "
                                  "values at exit");
        return stack[$ - 1];
    }
