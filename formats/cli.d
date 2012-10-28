
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Command line parser.
module formats.cli;


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
 * The option is then added to a CLI using its addOption() method.
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
        string[] defaultArgs_ = null;

        ///Argument name to write in help text.
        string argName_;
                                                
    public:
        /**
         * Construct a CLIOption with specified name.
         *
         * Params:  name = Long name of the option. (Will automatically be prefixed with "--" .)
         *                 Must not be parsable as a number.
         */
        this(const string name)
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
        @property ref CLIOption shortName(const char name) pure
        in
        {
            assert((name >= 'a' && name <= 'z') || (name >= 'A' && name <= 'Z'), 
                   "CLI: Unsupported short option name:" ~ name);
        }
        body{short_ = name; return this;}

        ///Set help string of the option.
        @property ref CLIOption help(const string help) pure {help_ = help; return this;}

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
            if(isPrimitive!T)
        {
            assert(action_ is null, "Target of a CLIOption specified more than once");
            action_ = (string[] args){return storeAction(args, (T t){*target = t;});};
            argName_ = "arg";
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
               isPrimitive!(ParameterTypeTuple!T[0]) &&
               (functionAttributes!T & FunctionAttribute.nothrow_) &&
               is(ReturnType!T == void))
        {
            assert(action_ is null, "Target of a CLIOption specified more than once");
            alias ParameterTypeTuple!T[0] A;
            action_ = (string[] args){return storeAction(args, (A t){target(t);});};
            argName_ = "arg";
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
            if(isPrimitive!T)
        {
            assert(action_ is null, "Target of a CLIOption specified more than once");
            action_ = (string[] args){return arrayStoreAction(args, target);};
            argName_ = "arg...";
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
        ref CLIOption target(T)(T target, const int argCount = -1)
            if(is(T == void delegate(string[]) nothrow))
        {
            assert(action_ is null, "Target of a CLIOption specified more than once");
            action_ = (string[] args){return delegateAction(args, target, argCount);};
            if(argCount == -1){argName_ = "arg...";}
            else if(argCount > 0)
            {
                argName_ = "arg1";
                foreach(a; 1 .. argCount){argName_ ~= " arg" ~ to!string(a);}
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
        ref CLIOption defaultArgs(string[] args ...)
        {
            defaultArgs_ = args; 
            return this;
        }
    
    private:
        ///Determine whether or not this option is valid.
        @property bool valid() const pure {return action_ !is null;}

        ///Get left part of the help string for this option. (used by CLI.help())
        @property string helpLeft() const pure
        {
            string result = short_ == '\0' ? "     " : " -" ~ short_ ~ ", ";
            result ~= "--" ~ long_ ~ (argName_.length == 0 ? "" : "=" ~ argName_);
            return result;
        }
}

/**
 * Command line parser.
 *
 * Options are specified using the Option struct and added using the addOption() method.
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
 *     cli.addOption(CLIOption("flag").target(&flag).shortName('f'));
 *     //value, with defaults
 *     cli.addOption(CLIOption("value").target(&flag).shortName('v').defaultArgs("1"));
 *     //setter
 *     cli.addOption(CLIOption("setter").target(&setter).shortName('s');
 *     //array
 *     cli.addOption(CLIOption("array").target(array).shortName('a');
 *     //custom function
 *     cli.addOption(CLIOption("custom")
 *                        .target((string[] args){foreach(arg; args){writeln(arg);}})
 *                        .shortName('c');
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
        private struct OptionData
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
        uint lineWidth_ = 80;
        ///Description of the program (on the beginning of help).
        string description_;
        ///End of the help text.
        string epilog_;
        ///Command line options used.
        CLIOption[] options_;

        ///Name of the program (taken from the first command line argument).
        string programName_;
        ///Preprocessed option data.
        OptionData[] optionData_;
        ///Positional arguments.
        string[] positional_;
        ///Was help message requested?
        bool help_;
    
    public:
        ///Construct a CLI.
        this()
        {
            addOption(CLIOption("help").shortName('h').target(&help_)
                                        .help("Display this help and exit."));
        }

        ///Set program description (start of the help text).
        @property void description(const string text) pure {description_ = text;}

        ///Set epilog of the help text.
        @property void epilog(const string text) pure {epilog_ = text;}

        /**
         * Add a command line option.
         *
         * Every option must have an unique long (and short, if any) name.
         *
         * Params:  option = Option to add.
         */
        void addOption(CLIOption option) pure
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
            programName_ = args[0];

            //clean up in case parse() is called more than once
            clear(optionData_);
            clear(positional_);
            help_ = false;

            scope(failure){help();}

            preprocessArgs(args[1 .. $]);

            string[] longOpts_;
            foreach(ref option; options_){longOpts_ ~= option.long_;}

            //abbreviations (associative array - abbrev -> word)
            auto abbrev = abbrev(longOpts_);

            //search for all known options in optionData_
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
                    auto data = partition!match(optionData_);

                    if(data.length == 0)
                    {
                        //execute action with default args, if any
                        if(option.defaultArgs_ != null)
                        {
                            option.action_(option.defaultArgs_);
                        }
                        continue;
                    }

                    //execute options' actions and add unprocessed args to positional
                    foreach(optData; data)
                    {
                        positional_ ~= option.action_(optData.arguments);
                    }

                    //remove the processed data (partition divided the array into two parts)
                    optionData_ = optionData_[0 .. $ - data.length];
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
            if(optionData_.length > 0)
            {
                auto msg = "Unrecognized option/s: " ~ optionData_[0].name;
                foreach(o; optionData_[1 .. $]){msg ~= ", " ~ o.name;}
                throw new CLIException(msg);
            }

            return true;
        }

        /**
         * Preprocesses command line arguments into optionData_ and positional_ arrays.
         *
         * Params:  args = Arguments to preprocess (without program name).
         *
         * Throws:  CLIException when an invalid argument is detected.
         */
        void preprocessArgs(string[] args) 
        {               
            void addArg(const string arg) pure
            {
                //no options yet, so add to positional args
                if(optionData_.length == 0){positional_ ~= arg;}
                else{optionData_[$ - 1].arguments ~= arg;}
            }

            foreach(arg; args)
            {
                auto number = regex(r"^-?\d*\.?\d*$");
                //does not start with '-' or is a number
                if(indexOf(arg, '-') == -1 || !arg.match(number).empty)
                {
                    //ignore '=' between whitespaces
                    if(arg == "="){continue;}
                    addArg(arg);
                    continue;
                }

                string[] parts = std.string.split(arg, "=");
                enforceEx!CLIException(parts.length <= 2, 
                                       "CLI: Invalid argument (too many '='): " ~ arg);
                //starts with "--"
                if(indexOf(arg, "--") == 0)
                {
                    //without the --
                    optionData_ ~= OptionData(parts[0][2 .. $], parts[1 .. $]);
                }
                //starts with '-'
                else
                {
                    arg = parts[0][1 .. $];
                    foreach(i, c; arg)
                    {
                        static bool short_match(ref CLIOption option, const char sh) pure
                        {
                            return option.short_ == sh;
                        }

                        //if this is not an option
                        if(!canFind!short_match(options_, c))
                        {
                            addArg(arg[i .. $]);
                            break;
                        }
                        optionData_ ~= OptionData([c]);
                    }
                    if(parts.length == 2){addArg(parts[1]);}
                }
            }
        }
                                    
        ///Display help information.
        void help() 
        {
            writeln(description_);
            //might change once positional args are implemented
            writeln("Usage: " ~ programName_ ~ " [OPTION]...\n");
                            
            //space between right and left sides
            uint sep = 2;

            static CLIOption max(ref CLIOption a, ref CLIOption b)
            {
                return a.helpLeft.length > b.helpLeft.length ? a : b;
            }

            //option with widest left side
            auto widest = reduce!max(options_);

            //left side width
            uint leftWidth = clamp(cast(uint)widest.helpLeft.length + sep, 
                                    lineWidth_ / 4, lineWidth_ / 2);
            //right side width
            uint rightWidth = lineWidth_ - leftWidth;

            foreach(option; options_)
            {
                string left = option.helpLeft;
                string indent = replicate(" ", leftWidth);

                //if option left side too wide, print it on a separate line
                if(left.length + sep > leftWidth )
                {
                    writeln(left);
                    write(wrap(option.help_, lineWidth_, indent, indent));
                }
                else
                {
                    write(leftJustify(left, leftWidth));
                    write(wrap!string(option.help_, lineWidth_, null, indent));
                }
                if(option.defaultArgs_.length > 0)
                {
                    //default args
                    writeln(wrap("Default: " ~ join(option.defaultArgs_, ", "), 
                                 rightWidth, indent, indent));
                }
            }

            writeln("\n" ~ epilog_);
        }
}


private:
//used in unittest
int testGlobal;
import util.unittests;
void unittestCLI()
{
    auto cli = new CLI();
    bool flag = false;
    cli.addOption(CLIOption("flag").shortName('f').target(&flag).defaultArgs("true"));
    //defaults
    cli.parse(["programName"]);
    assert(flag == true);
    //bool flag - explicit, long
    cli.parse(["programName", "--flag=0"]);
    assert(flag == false);
    //bool flag - implicit, short
    cli.parse(["programName", "-f"]);
    assert(flag == true);
    //bool flag - explicit, short
    cli.parse(["programName", "-f0"]);
    assert(flag == false);
                           
    real r;
    int i;
    uint u;
    string s;
    cli.addOption(CLIOption("real").target(&r));
    cli.addOption(CLIOption("int").target(&i));
    cli.addOption(CLIOption("uint").target(&u));
    cli.addOption(CLIOption("string").target(&s));
    cli.parse(["programName", "--real", "4.2", "--int=-42", "--uint", "42", "--string", "42"]);
    if(!math.math.equals(r, cast(real)4.2L) || i != -42 || u != 42 || s != "42")
    {
        writeln("CLI unittest failed: r: ", r, ", i: ", i, ", u: ", u, ", s: ", s);
        writeln("math.math.equals(r, cast(real)4.2L): ", math.math.equals(r, cast(real)4.2L));
        writeln("i == -42: ", i == -42);
        writeln("u == 42: ", u == 42);
        writeln("s == \"42\": ", s == "42");
        assert(false);
    }

    //setters
    void setter(uint u_) nothrow {u = u_;}
    static void globalSetter(uint g) nothrow {testGlobal = g;}
    cli.addOption(CLIOption("setter").target(&setter));
    cli.addOption(CLIOption("globalSetter").target(&globalSetter));
    cli.parse(["programName", "--setter", "24", "--globalSetter", "42"]);
    assert(u == 24);
    assert(testGlobal == 42);

    //arrays
    uint[] array;
    cli.addOption(CLIOption("array").target(array));
    cli.parse(["programName", "--array", "1", "2", "--flag", "--array", "3,4"]);
    assert(array == [1u, 2u, 3u, 4u]);

    //custom functions
    string[] arrayStr;
    void deleg(string[] args) nothrow {arrayStr = args;}
    cli.addOption(CLIOption("deleg").target(&deleg));
    cli.parse(["programName", "--deleg", "4", "5", "6"]);
    assert(arrayStr == ["4", "5", "6"]);
}
mixin registerTest!(unittestCLI, "CLI general");

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
class CLIException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__) @trusted nothrow 
    {
        super(msg, file, line);
    }
}


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
string[] storeAction(T)(string[] args, void delegate(T) target)
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
string[] arrayStoreAction(T)(string[] args, ref T[] target)
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
 *          argCount = Number of arguments to pass.
 *                      If argCount is -1 , all, if any, arguments will be passed. 
 *
 * Returns: Arguments that were not passed.
 */
string[] delegateAction(string[] args, void delegate(string[]) nothrow target, int argCount)
{
    enforceEx!CLIException(cast(int)args.length >= argCount, 
              "Not enough option arguments: need " ~ to!string(argCount));

    // -1 means all, if any, args
    if(argCount == -1)     
    {
        target(args);
        return [];
    }
    target(args[0 .. argCount]); 
    return args[argCount .. $];
}
