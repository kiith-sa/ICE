
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module formats.cli;


import std.string;
import std.regexp : find;
import std.stdio : writefln, writef;
import std.conv;

import math.math : equals, clamp;
import containers.array;
import util.string;
import util.exception;
import util.traits;


//We copy this around. A lot.
//Doesn't matter, not performance critical, and we don't pollute the GC.
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
        ///Action to perform at this option.
        Action action_ = null;
        ///Help string.
        string help_ = "";
        ///Default arguments to pass to action if the option is not specified.
        string[] default_args_ = null;
                                                
    public:
        /**
         * Construct a CLIOption with specified name.
         *
         * Params:  name = Long name of the option. (Will automatically be prefixed with "--" .)
         *                 Must not be parsable as a number.
         *
         * Returns: Constructed option.
         */
        static CLIOption opCall(string name)
        in
        {
            assert(!isNumeric(name), "CLI: Long option name parsable as a number:" ~ name);
        }
        body
        {
            CLIOption option;                            
            option.long_ = name;
            return option;
        }

        /**
         * Set short name of the option. (Will be prefixed by "-" .)
         *
         * Params:  name = Short name (one character). Must be from the alphabet.
         */
        CLIOption short_name(char name)
        in{assert(letters.contains(name), "CLI: Unsupported short option name:" ~ name);}
        body{short_ = name; return *this;}

        ///Set help string of the option.
        CLIOption help(string help){help_ = help; return *this;}

        /**
         * Set value target.                       
         * 
         * Parse single argument of the option as target type and write it to the target.
         * 
         * Target must be specified (by any of the target() methods).
         *
         * Params:  target = Target variable to write option argument to.
         */
        CLIOption target(T)(T* target) 
        {
            assert(action_ is null, "Target of a CLIOption specified more than once");
            ///Since global function pointers are just that, pointers, we must handle them here.
            static if(is_global_function!(T*)){target_global_functon(target);}
            else{action_ = new StoreAction!(T)(target);}
            return *this;
        }              

        /**
         * Set setter target.                       
         * 
         * Parse single argument of the option as target type and pass it to specified setter.
         * 
         * Target must be specified (by any of the target() methods).
         *
         * Params:  target = Target setter to pass option argument to.
         */
        CLIOption target(T)(void delegate(T) target)
        {
            assert(action_ is null, "Target of a CLIOption specified more than once");
            action_ = new SetterStoreAction!(T)(target); 
            return *this;
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
         * Params:  target = Target array to write option arguments to.
         */
        CLIOption target(T)(ref T[] target)
        {
            assert(action_ is null, "Target of a CLIOption specified more than once");
            action_ = new ArrayStoreAction!(T)(target); 
            return *this;
        }

        /**
         * Set function target.                       
         * 
         * Pass arguments of the option to specified function without any parsing.
         * Optionally, required number of arguments can be specified.
         * 
         * Target must be specified (by any of the target() methods).
         *
         * Params:  target = Target function to pass option arguments to.
         */
        CLIOption target(T : void delegate(string[]))(T target, int arg_count = -1)
        {
            assert(action_ is null, "Target of a CLIOption specified more than once");
            action_ = new DelegateAction(target, arg_count);
            return *this;
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
        CLIOption default_args(string[] args ...){default_args_ = args; return *this;}
    
    private:
        ///Ugly hack to make global functions targetable.
        void target_global_functon(T : void function(U), U)(T target)
        {
            class Targeter
            {
                T target_;
                this(T t){target_ = t;}
                void target(U t){target_(t);}
            }

            Targeter t = new Targeter(target);
            action_ = new SetterStoreAction!(U)(&t.target);
        }

        ///Determine whether or not this option is valid.
        bool valid(){return action_ !is null;}

        ///Get left part of the help string for this option. (used by CLI.help())
        string help_left()
        {
            string result = short_ == '\0' ? "     " : " -" ~ short_ ~ ", ";
            string arg_name = action_.arg_name;
            result ~= "--" ~ long_ ~ (arg_name.length == 0 ? "" : "=" ~ arg_name);
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
 *                        .target((string[] args){foreach(arg; args){writefln(arg);}})
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
        alias std.string.find strfind;
        alias std.regexp.find refind;
        alias containers.array.find find;

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
        void description(string text){description_ = text;}

        ///Set epilog of the help text.
        void epilog(string text){epilog_ = text;}

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
            alias containers.array.find find;
            assert(option.valid, "CLI: Trying to add invalid option: " ~ option.long_);
            bool conflict(ref CLIOption o)
            {
                return (o.long_ == option.long_) || 
                       (o.short_ != '\0' && (o.short_ == option.short_));
            }
            assert(options_.find(&conflict) == -1, 
                   "CLI: Adding option " ~ option.long_ ~ " twice.");
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
                writefln(e.msg); 
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
            option_data_ = [];
            positional_ = [];
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
                        return o.name == [option.short_] || 
                               (abbrev.keys.contains(o.name) && abbrev[o.name] == option.long_);
                    }

                    //get all option data matching this option
                    auto data = option_data_.get_all(&match);

                    //if no option data found
                    if(data.length == 0)
                    {
                        //if we have default args
                        if(option.default_args_ != null){option.action_(option.default_args_);}
                        continue;
                    }

                    //execute options' actions and add unprocessed args to positional
                    foreach(opt_data; data)
                    {
                        positional_ ~= option.action_(opt_data.arguments);
                        option_data_.remove(opt_data);
                    }
                }
                catch(ConvError e)
                {
                    throw new CLIException("CLI: Incorrect input format: --" ~ option.long_);
                }
                catch(CLIException e){throw new CLIException(e.msg ~ " : --" ~ option.long_);}
            }

            //unknown options left
            if(option_data_.length > 0)
            {
                string msg = "Unrecognized option/s: " ~ option_data_[0].name;
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
                //does not start with '-' or is a number
                if(arg.strfind("-") < 0 || arg.refind("^-?\\d*\\.?\\d*$") >= 0)
                {
                    //ignore '=' between whitespaces
                    if(arg == "="){continue;}
                    add_arg(arg);
                    continue;
                }

                string[] parts = arg.split("=");
                enforceEx!(CLIException)(parts.length <= 2, 
                                         "CLI: Invalid argument (too many '='): " ~ arg);
                //starts with "--"
                if(arg.strfind("--") == 0)
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
                        //if this is not an option
                        if(options_.find((ref CLIOption o){return o.short_ == c;}) < 0)
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
            writefln(description_);
            //might change once positional args are implemented
            writefln("Usage: " ~ program_name_ ~ " [OPTION]...\n");
                            
            //space between right and left sides
            uint sep = 2;

            //option with widest left side
            auto widest = options_.max((ref CLIOption a, ref CLIOption b)
                                       {return a.help_left.length > b.help_left.length;});

            //left side width
            uint left_width = clamp(cast(uint)widest.help_left.length + sep, 
                                    line_width_ / 4, line_width_ / 2);
            //right side width
            uint right_width = line_width_ - left_width;

            foreach(option; options_)
            {
                string left = option.help_left;
                string indent = repeat(" ", left_width);

                //if option left side too wide, print it on a separate line
                if(left.length + sep > left_width )
                {
                    writefln(left);
                    writef(wrap(option.help_, line_width_, indent, indent));
                }
                else
                {
                    writef(ljustify(left, left_width));
                    writef(wrap(option.help_, line_width_, null, indent));
                }
                //default args
                writefln(wrap("Default: " ~ join(option.default_args_, ", "), 
                              right_width, indent, indent));
            }

            writefln("\n" ~ epilog_);
        }
}

unittest
{
    auto cli = new CLI();
    bool flag = false;
    cli.add_option(CLIOption("flag").short_name('f').target(&flag).default_args("1"));
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
    void setter(uint u_){u = u_;}
    cli.add_option(CLIOption("setter").target(&setter));
    cli.parse(["program_name", "--setter", "24"]);
    assert(u == 24);

    //arrays
    uint[] array;
    cli.add_option(CLIOption("array").target(array));
    cli.parse(["program_name", "--array", "1", "2", "--flag", "--array", "3,4"]);
    assert(array == [1u, 2u, 3u, 4u]);

    //custom functions
    string[] array_str;
    void deleg(string[] args){array_str = args;}
    cli.add_option(CLIOption("deleg").target(&deleg));
    cli.parse(["program_name", "--deleg", "4", "5", "6"]);
    assert(array_str == ["4", "5", "6"]);
}

private:

///Exception thrown at CLI errors.
class CLIException : Exception{this(string msg){super(msg);}}

///Action to be executed when an option is specified.
private abstract class Action
{
    /**
     * Execute the action.
     *
     * Params:  args = Command line arguments to process.
     *
     * Returns: Arguments that weren't processed.
     *
     * Throws:  ConvError on parsing error.
     */
    string[] opCall(string[] args);

    ///Get argument name for this action.
    string arg_name();
}

///Action that passes raw, unparsed option arguments to a delegate.
class DelegateAction : Action
{
    private:
        ///Delegate to pass option arguments to.
        void delegate(string[]) action_;
        ///Number of arguments of the command line option. -1 means any number.
        int arg_count_;

    public:
        /**
         * Construct a DelegateAction.
         *
         * Params:  action    = Delegate to pass option arguments to.
         *          arg_count = Number of arguments of the option. -1 means any number.
         */
        this(void delegate(string[]) action, int arg_count)
        {
            action_ = action;
            arg_count_ = arg_count;
        }

        override string[] opCall(string[] args)
        {
            enforceEx!(CLIException)(cast(int)args.length >= arg_count_, 
                       "Not enough option arguments: need " ~ to_string(arg_count_));
            if(arg_count_ == -1)     
            {
                action_(args);
                return [];
            }
            action_(args[0 .. arg_count_]); 
            return args[arg_count_ .. $];
        }

        override string arg_name()
        {
            if(arg_count_ == -1){return "args";}
            string result;
            if(arg_count_ >= 1){result ~= "arg0";}
            for(uint a = 1;a < arg_count_; a++)
            {
                result ~= ",arg" ~ to_string(a);
            }
            return result;
        }
}

///Action that parses a single option argument and stores it in a variable.
class StoreAction(T) : Action
{
    private:
        ///Variable to store the option argument in.
        T* target_;
    public:
        ///Construct a StoreAction with specified target.
        this(T* target){target_ = target;}

        override string[] opCall(string[] args)
        {
            static if(is(T == bool))
            {
                if(args.length == 0){*target_ = true; return [];}
            }
            enforceEx!(CLIException)(args.length >= 1, "Not enough option arguments: need 1");
            *target_ = to!(T)(args[0]); return args[1 .. $];
        }

        override string arg_name()
        {
            static if(is(T == bool)){return "";}
            else{return "arg";}
        }
}

///Action that parses a single option argument and passes it to a setter.
class SetterStoreAction(T) : Action
{
    private:
        ///Setter to pass the option argument to.
        void delegate(T) target_;

    public:
        ///Construct a SetterStoreAction with specified target.
        this(void delegate(T) target){target_ = target;}

        override string[] opCall(string[] args)
        {
            static if(is(T == bool))
            {
                if(args.length == 0){target_(true); return [];}
            }
            enforceEx!(CLIException)(args.length >= 1, "Not enough option arguments: need 1");
            target_(to!(T)(args[0])); return args[1 .. $];
        }

        override string arg_name()
        {
            static if(is(T == bool)){return "";}
            else{return "arg";}
        }
}
                
///Action that parses all option arguments and stores them in an array.
class ArrayStoreAction(T) : Action
{
    private:
        ///Array to store option arguments in
        T[]* target_;

    public:
        ///Construct an ArrayStoreAction with specified target.
        this(ref T[] target){target_ = &target;}

        override string[] opCall(string[] args)
        {
            foreach(arg; args)
            {
                //allow comma separated args
                foreach(sub; arg.split(",")){*target_ ~= to!(T)(sub);}
            }
            return [];
        }

        override string arg_name(){return "args";}
}
