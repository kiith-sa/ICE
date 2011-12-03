
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Command line parser.
module formats.cli;
@safe


import std.algorithm;
import std.array;
import std.conv;
import std.exception;
import std.regex;
import std.stdio;
import std.string;
import std.traits;

import math.math;
import util.traits;


/**
 * Command line option.
 *
 * Methods of this struct are used to specify parameters of the option.
 * The option is then added to a CLI using its add_option() method.
 */
struct CLIOption
{
    private:
        ///Short version of the option. '\0' means no short version.
        char short_ = '\0';
        ///Long version of the option.
        string long_;

        ///Action to execute at this option.
        string[] delegate(string[]) action_ = null;
        ///Help string.
        string help_ = "";
        ///Default arguments to pass to action if the option is not specified.
        string[] default_args_ = null;

        ///Argument name to write in help text.
        string arg_name_;
                                                
    public:
        /**
         * Construct a CLIOption with specified name.
         *
         * Params:  name = Long name of the option. (Will automatically be prefixed with "--" .)
         *                 Must not be parsable as a number.
         */
        this(in string name)
        in
        {
            assert(!std.string.isNumeric(name), 
                   "CLI: Long option name parsable as a number:" ~ name);
        }
        body
        {
            long_ = name;
        }

        /**
         * Set short name of the option. (Will be prefixed by "-" .)
         *
         * Params:  name = Short name (one character). Must be from the alphabet.
         */
        @property ref CLIOption short_name(in char name)
        in
        {
            assert((name >= 'a' && name <= 'z') || (name >= 'A' && name <= 'Z'), 
                   "CLI: Unsupported short option name:" ~ name);
        }
        body{short_ = name; return this;}

        ///Set help string of the option.
        @property ref CLIOption help(in string help){help_ = help; return this;}

        /**
         * Set value target.                       
         * 
         * Parse single argument of the option as target type and write it to the target.
         * 
         * Target must be specified (by any of the target() methods) 
         * 
         * Target type must be a bool, number or a string.
         *
         * Params:  target = Target variable to write option argument to.
         */
        @property ref CLIOption target(T)(T* target)
            if(is_primitive!T)
        {
            assert(action_ is null, "Target of a CLIOption specified more than once");
            action_ = (string[] args){return store_action(args, (T t){*target = t;});};
            arg_name_ = "arg";
            return this;
        }              

        /**
         * Set setter function target.                       
         * 
         * Parse single argument of the option as target type and pass it to specified function.
         * 
         * Target must be specified (by any of the target() methods).
         * 
         * Target type must be function taking single bool, number or a string.
         *
         * Params:  target = Target setter to pass option argument to.
         */
        @property ref CLIOption target(T)(T target)
            if(isSomeFunction!T && 
               ParameterTypeTuple!T.length == 1 &&
               is_primitive!(ParameterTypeTuple!T[0]) &&
               (functionAttributes!T & FunctionAttribute.nothrow_) &&
               is(ReturnType!T == void))
        {
            assert(action_ is null, "Target of a CLIOption specified more than once");
            alias ParameterTypeTuple!T[0] A;
            action_ = (string[] args){return store_action(args, (A t){target(t);});};
            arg_name_ = "arg";
            return this;
        }

        /**
         * Set array target.                       
         * 
         * Parse arguments of the option as target type and write them to specified array.
         * If the option is specified more than once, arguments from all instances
         * of the option are written to the array.
         * 
         * Target must be specified (by any of the target() methods).
         * 
         * Target type must an arrao of bools, numbers, strings.
         *
         * Params:  target = Target array to write option arguments to.
         */
        @property ref CLIOption target(T)(ref T[] target)
            if(is_primitive!T)
        {
            assert(action_ is null, "Target of a CLIOption specified more than once");
            action_ = (string[] args){return array_store_action(args, target);};
            arg_name_ = "arg...";
            return this;
        }

        /**
         * Set function target.                       
         * 
         * Pass arguments of the option to specified function without any parsing.
         * Optionally, required number of arguments can be specified.
         * 
         * Target must be specified (by any of the target() methods).
         *
         * Target must be a void function taking an array of strings as its parameter.
         *
         * Params:  target = Target function to pass option arguments to.
         */
        ref CLIOption target(T)(T target, in int arg_count = -1)
            if(is(T == void delegate(string[]) nothrow))
        {
            assert(action_ is null, "Target of a CLIOption specified more than once");
            action_ = (string[] args){return delegate_action(args, target, arg_count);};
            if(arg_count == -1){arg_name_ = "arg...";}
            else if(arg_count > 0)
            {
                arg_name_ = "arg1";
                foreach(a; 1 .. arg_count){arg_name_ ~= " arg" ~ to!string(a);}
            }
            return this;
        }

        /**
         * Specify default arguments for this option.
         *
         * Option's action will be executed with specified arguments
         * if the option is not present.
         * If default arguments are not specified, and the option is not present,
         * option's action will not be executed.
         *
         * Params:  args = Default arguments for the option. 
         *
         * Returns: Resulting CLIOption.
         */
        ref CLIOption default_args(string[] args ...)
        {
            default_args_ = args; 
            return this;
        }
    
    private:
        ///Determine whether or not this option is valid.
        @property bool valid() const {return action_ !is null;}

        ///Get left part of the help string for this option. (used by CLI.help())
        @property string help_left() const
        {
            string result = short_ == '\0' ? "     " : " -" ~ short_ ~ ", ";
            result ~= "--" ~ long_ ~ (arg_name_.length == 0 ? "" : "=" ~ arg_name_);
            return result;
        }
}

/**
 * Command line parser.
 *
 * Options are specified using the Option struct and added using the add_option() method.
 *                 
 * Each option has a long, GNU-style name automatically prefixed by "--" and
 * optionally a short, one character name automatically prefixed by "-".
 * Long option names can be abbreviated as long as the abbreviation uniquely
 * identifies an option.
 *
 * Short options can be chained; Option arguments can be separated from options by spaces
 * or '='; Array options accept comma separated arguments; Boolean flags can have
 * optional argument, e.g. "-f0" will set flag -f to false.
 *
 * A help option (-h, --help) is automatically generated from help info specified
 * for each option.
 *
 * Examples:
 * --------------------
 * void main(string[] args)
 * {
 *     CLI cli = new CLI();
 *     cli.description = "Example 1.0\n Written in D by E. Xample";
 *     cli.epilog = "Find more info at www.example.com";
 *    
 *     bool flag;
 *     int val;
 *     int setter_val;
 *     void setter(int i){setter_val = i;}
 *     int[] array;
 *
 *     //bool flag
 *     cli.add_option(CLIOption("flag").target(&flag).short_name('f'));
 *     //value, with defaults
 *     cli.add_option(CLIOption("value").target(&flag).short_name('v').default_args("1"));
 *     //setter
 *     cli.add_option(CLIOption("setter").target(&setter).short_name('s');
 *     //array
 *     cli.add_option(CLIOption("array").target(array).short_name('a');
 *     //custom function
 *     cli.add_option(CLIOption("custom")
 *                        .target((string[] args){foreach(arg; args){writeln(arg);}})
 *                        .short_name('c');
 *     
 *     //parse arguments
 *     if(!cli.parse(args)){return;}
 *
 *     ...
 *
 * }
 * --------------------
 */
class CLI
{
    private:
        alias std.string.indexOf indexOf;

        ///Struct holding preprocessed (not yet parsed) option data.
        private static struct OptionData
        {                  
            ///Option name.
            string name;
            /**
             * Option arguments (unparsed). 
             *
             * Arguments that won't ba parsed will be added to positional arguments.
             */
            string[] arguments;
        }

        ///Line width of help text.
        uint line_width_ = 80;
        ///Description of the program (on the beginning of help).
        string description_;
        ///End of the help text.
        string epilog_;
        ///Command line options used.
        CLIOption[] options_;

        ///Name of the program (taken from the first command line argument).
        string program_name_;
        ///Preprocessed option data.
        OptionData[] option_data_;
        ///Positional arguments.
        string[] positional_;
        ///Was help message requested?
        bool help_;
    
    public:
        ///Construct a CLI.
        this()
        {
            add_option(CLIOption("help").short_name('h').target(&help_)
                                        .help("Display this help and exit."));
        }

        ///Set program description (start of the help text).
        @property void description(in string text){description_ = text;}

        ///Set epilog of the help text.
        @property void epilog(in string text){epilog_ = text;}

        /**
         * Add a command line option.
         *
         * Every option must have an unique long (and short, if any) name.
         *
         * Params:  option = Option to add.
         */
        void add_option(CLIOption option)
        in
        {
            debug
            {
            assert(option.valid, "CLI: Trying to add invalid option: " ~ option.long_);
            static bool conflict(ref CLIOption a, ref CLIOption b)
            {
                return (a.long_ == b.long_) || 
                       (a.short_ != '\0' && (a.short_ == b.short_));
            }
            assert(!canFind!conflict(options_, option), 
                   "CLI: Adding option " ~ option.long_ ~ " twice.");
            }
        }
        body
        {
            options_ ~= option;
        }

        /**
         * Parse command line arguments.
         *
         * Command line options' targets are written to/executed as the options are parsed.
         * If an error occurs, parsing is aborted and false is returned.
         * 
         * Params:  args = Command line arguments to parse. Must be at least one (program name).
         *
         * Returns: False in case of error or if help was requested. False otherwise.
         */
        bool parse(string[] args)
        {
            bool success;
            try{success = parse_(args);}
            catch(CLIException e)
            {
                writeln(e.msg); 
                return false;
            }
            return success;
        }

    private:
        /**
         * Parse command line arguments (internal method).
         * 
         * Params:  args = Command line arguments to parse. Must be at least one (program name).
         *
         * Returns: False if help was requested, true otherwise.
         * 
         * Throws:  CLIException on parsing error.
         */
        bool parse_(string[] args)
        in{assert(args.length > 0, "No command line arguments to parse. Need at least one");}
        body
        {
            //first arg is the program name
            program_name_ = args[0];

            //clean up in case parse() is called more than once
            clear(option_data_);
            clear(positional_);
            help_ = false;

            scope(failure){help();}

            preprocess_args(args[1 .. $]);

            string[] long_opts_;
            foreach(ref option; options_){long_opts_ ~= option.long_;}

            //abbreviations (associative array - abbrev -> word)
            auto abbrev = abbrev(long_opts_);

            //search for all known options in option_data_
            foreach(ref option; options_)
            {
                if(help_){help(); return false;}
                try
                {
                    bool match(ref OptionData o)
                    {
                        return o.name != [option.short_] &&
                               (!canFind(abbrev.keys, o.name) || abbrev[o.name] != option.long_);
                    }

                    //get option data that match this option
                    auto data = partition!match(option_data_);

                    if(data.length == 0)
                    {
                        //execute action with default args, if any
                        if(option.default_args_ != null)
                        {
                            option.action_(option.default_args_);
                        }
                        continue;
                    }

                    //execute options' actions and add unprocessed args to positional
                    foreach(opt_data; data)
                    {
                        positional_ ~= option.action_(opt_data.arguments);
                    }

                    //remove the processed data (partition divided the array into two parts)
                    option_data_ = option_data_[0 .. $ - data.length];
                }
                catch(ConvOverflowException e)
                {
                    throw new CLIException("CLI: Option argument out of range: --" ~ option.long_);
                }
                catch(ConvException e)
                {
                    throw new CLIException("CLI: Incorrect input format: --" ~ option.long_);
                }
                catch(CLIException e){throw new CLIException(e.msg ~ " : --" ~ option.long_);}
            }
            if(help_){help(); return false;}

            //unknown options left
            if(option_data_.length > 0)
            {
                auto msg = "Unrecognized option/s: " ~ option_data_[0].name;
                foreach(o; option_data_[1 .. $]){msg ~= ", " ~ o.name;}
                throw new CLIException(msg);
            }

            return true;
        }

        /**
         * Preprocesses command line arguments into option_data_ and positional_ arrays.
         *
         * Params:  args = Arguments to preprocess (without program name).
         *
         * Throws:  CLIException when an invalid argument is detected.
         */
        void preprocess_args(string[] args)
        {               
            void add_arg(string arg)
            {
                //no options yet, so add to positional args
                if(option_data_.length == 0){positional_ ~= arg;}
                else{option_data_[$ - 1].arguments ~= arg;}
            }

            foreach(arg; args)
            {
                auto number = regex(r"^-?\d*\.?\d*$");
                //does not start with '-' or is a number
                if(indexOf(arg, '-') == -1 || !arg.match(number).empty)
                {
                    //ignore '=' between whitespaces
                    if(arg == "="){continue;}
                    add_arg(arg);
                    continue;
                }

                string[] parts = std.string.split(arg, "=");
                enforceEx!CLIException(parts.length <= 2, 
                                       "CLI: Invalid argument (too many '='): " ~ arg);
                //starts with "--"
                if(indexOf(arg, "--") == 0)
                {
                    //without the --
                    option_data_ ~= OptionData(parts[0][2 .. $], parts[1 .. $]);
                }
                //starts with '-'
                else
                {
                    arg = parts[0][1 .. $];
                    foreach(i, c; arg)
                    {
                        static bool short_match(ref CLIOption option, char sh)
                        {
                            return option.short_ == sh;
                        }

                        //if this is not an option
                        if(!canFind!short_match(options_, c))
                        {
                            add_arg(arg[i .. $]);
                            break;
                        }
                        option_data_ ~= OptionData([c]);
                    }
                    if(parts.length == 2){add_arg(parts[1]);}
                }
            }
        }
                                    
        ///Display help information.
        void help()
        {
            writeln(description_);
            //might change once positional args are implemented
            writeln("Usage: " ~ program_name_ ~ " [OPTION]...\n");
                            
            //space between right and left sides
            uint sep = 2;

            static CLIOption max(ref CLIOption a, ref CLIOption b)
            {
                return a.help_left.length > b.help_left.length ? a : b;
            }

            //option with widest left side
            auto widest = reduce!max(options_);

            //left side width
            uint left_width = clamp(cast(uint)widest.help_left.length + sep, 
                                    line_width_ / 4, line_width_ / 2);
            //right side width
            uint right_width = line_width_ - left_width;

            foreach(option; options_)
            {
                string left = option.help_left;
                string indent = replicate(" ", left_width);

                //if option left side too wide, print it on a separate line
                if(left.length + sep > left_width )
                {
                    writeln(left);
                    write(wrap(option.help_, line_width_, indent, indent));
                }
                else
                {
                    write(ljustify(left, left_width));
                    write(wrap!string(option.help_, line_width_, null, indent));
                }
                if(option.default_args_.length > 0)
                {
                    //default args
                    writeln(wrap("Default: " ~ join(option.default_args_, ", "), 
                                 right_width, indent, indent));
                }
            }

            writeln("\n" ~ epilog_);
        }
}


private:
//used in unittest
int test_global;

unittest
{
    auto cli = new CLI();
    bool flag = false;
    cli.add_option(CLIOption("flag").short_name('f').target(&flag).default_args("true"));
    //defaults
    cli.parse(["program_name"]);
    assert(flag == true);
    //bool flag - explicit, long
    cli.parse(["program_name", "--flag=0"]);
    assert(flag == false);
    //bool flag - implicit, short
    cli.parse(["program_name", "-f"]);
    assert(flag == true);
    //bool flag - explicit, short
    cli.parse(["program_name", "-f0"]);
    assert(flag == false);
                           
    real r;
    int i;
    uint u;
    string s;
    cli.add_option(CLIOption("real").target(&r));
    cli.add_option(CLIOption("int").target(&i));
    cli.add_option(CLIOption("uint").target(&u));
    cli.add_option(CLIOption("string").target(&s));
    cli.parse(["program_name", "--real", "4.2", "--int=-42", "--uint", "42", "--string", "42"]);
    assert(equals(r, 4.2L) && i == -42 && u == 42 && s == "42");

    //setters
    void setter(uint u_) nothrow {u = u_;}
    static void global_setter(uint g) nothrow {test_global = g;}
    cli.add_option(CLIOption("setter").target(&setter));
    cli.add_option(CLIOption("global_setter").target(&global_setter));
    cli.parse(["program_name", "--setter", "24", "--global_setter", "42"]);
    assert(u == 24);
    assert(test_global == 42);

    //arrays
    uint[] array;
    cli.add_option(CLIOption("array").target(array));
    cli.parse(["program_name", "--array", "1", "2", "--flag", "--array", "3,4"]);
    assert(array == [1u, 2u, 3u, 4u]);

    //custom functions
    string[] array_str;
    void deleg(string[] args) nothrow {array_str = args;}
    cli.add_option(CLIOption("deleg").target(&deleg));
    cli.parse(["program_name", "--deleg", "4", "5", "6"]);
    assert(array_str == ["4", "5", "6"]);
}

///Convert a string to a bool lexically.
bool lexical_bool(string str)
{
    if(canFind(["Yes", "yes", "YES", "On", "on", "ON", "True", "true", "TRUE", 
                "Y", "y", "T", "t", "1"], str))
    {
        return true;
    }
    else if(canFind(["No", "no", "NO", "Off", "off", "OFF", "False", "false", "FALSE", 
                     "N", "n", "F", "f", "0"], str))
    {
        return false;
    }

    throw new ConvException("Could not parse string as bool: " ~ str);
}

///Exception thrown at CLI errors.
class CLIException : Exception{this(string msg){super(msg);}}


/**
 * Action that parses the first argument and passes it to a delegate.
 *
 * Params:  args   = Option arguments.
 *          target = Target delegate to pass parsed argument to.
 *
 * Returns: Arguments that were not parsed.
 *
 * Throws:  CLIException if there weren't enough arguments.
 *          ConvOverflowException on a parsing overflow error (e.g. to large int).
 *          ConvException on a parsing error.
 */
string[] store_action(T)(string[] args, void delegate(T) target)
{
    static if(is(T == bool))
    {
        if(args.length == 0)
        {
            target(true); 
            return [];
        }
        target(lexical_bool(args[0])); 
        return args[1 .. $];
    }
    else
    {
        enforceEx!(CLIException)(args.length >= 1, "Not enough option arguments: need 1");
        target(to!(T)(args[0])); return args[1 .. $];
    }
}

/**
 * Action that parses any number of arguments and saves them in an array.
 *
 * Params:  args   = Option arguments.
 *          target = Target array to add parsed arguments to.
 *
 * Returns: Empty array.
 *
 * Throws:  ConvOverflowException on a parsing overflow error (e.g. to large int).
 *          ConvException on a parsing error.
 */
string[] array_store_action(T)(string[] args, ref T[] target)
{
    //allow comma separated args
    foreach(arg; args) foreach(sub; std.string.split(arg, ","))
    {
        static if(is(T == bool)){target_ ~= lexical_bool(sub);}
        else{target ~= to!T(sub);}
    }
    return [];
}

/**
 * Action that passes a specified number of arguments to a delegate.
 *                 
 * Params:  args      = Option arguments.
 *          target    = Target delegate to pass arguments to.
 *          arg_count = Number of arguments to pass.
 *                      If arg_count is -1 , all, if any, arguments will be passed. 
 *
 * Returns: Arguments that were not passed.
 */
string[] delegate_action(string[] args, void delegate(string[]) nothrow target, int arg_count)
{
    enforceEx!CLIException(cast(int)args.length >= arg_count, 
              "Not enough option arguments: need " ~ to!string(arg_count));

    // -1 means all, if any, args
    if(arg_count == -1)     
    {
        target(args);
        return [];
    }
    target(args[0 .. arg_count]); 
    return args[arg_count .. $];
}
