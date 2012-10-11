
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

/// Memory profiler using ICE logging of manual memory allocations.
module memprof;


import std.algorithm;
import std.array;
import std.conv;
import std.exception;
import std.regex;
import std.stdio;
import std.stream;
import std.traits;
import std.typecons;

import dyaml.dumper;
import dyaml.exception;
import dyaml.node;
import dyaml.loader;

import util.intervals;

/**
 * TODO:
 *
 * We currently "aggregate" alloc counts, using distribution.
 * TODO: Also aggregate bytes, object counts, average alloc, alloc median.
 * Do this: ./memprof-debug distribution --aggregate=bytes
 * Also: If distribution has no conditions, aggregate total 
 * (e.g. total allocs, etc)
 *
 * Since "distribution" is not necessarily descriptive in this sense,
 * "./memprof-debug aggregate --bytes" should translate into 
 * "./memprof-debug distribution --aggregate=bytes"
 *
 * TODO List command (using listValues).
 *
 * No --file --line combinations and the like 
 * (nontrivial and not very useful - and we can just pipe through filter anyway)
 *
 * AWESOME: FrameProfiler could output arguments for 
 *     memprof filter --time 
 *     based on zones. So we could get an exact list of allocations happening within 
 *     a frame. We could even use this to drill down to deeper zones
 *     once we get a general idea to find out precise causes of allocations.
 *     Maybe even in a Perf-style CLI app.
 *
 *     One (ASAP) good way to use this would be to filter the 
 *     worst frames, and get allocations for those.
 */

/// Readability aliases
alias dyaml.node.Node YAMLNode;
alias Tuple!(string, YAMLNode) NamedNode;
alias NamedNode[] delegate(ref YAMLNode) Distribution;
alias bool delegate(ref YAMLNode) Filter;

/**
 * Main MemProf object.
 *
 * Contains all profiling functionality.
 * Might be split into multiple classes/functions if needed.
 */
struct MemProf
{
private:
    /// Memory log loaded from YAML.
    YAMLNode memoryLog_;

public:
    /// Construct MemProf loading memory log from specified file.
    this(string fileName)
    {
        memoryLog_ = Loader(fileName).load();
    }

    /// Construct MemProf loading memory log from specified file object (e.g. stdin).
    this(ref std.stdio.File file)
    {
        char[] fileBuffer;
        char[] line;
        while(file.readln(line))
        {
            fileBuffer ~= line;
        }
        memoryLog_ = Loader(new MemoryStream(fileBuffer)).load();
    }

    /// Get the memory log loaded from YAML.
    @property ref YAMLNode memoryLog() {return memoryLog_;}

    /**
     * Allocation distribution in intervals, useful for e.g. allocation sizes.
     *
     * Categorizes allocations based on specified property; returns an array 
     * of named nodes where name is composed of name of the property and the 
     * interval containing its value, and node is a sequence of all allocations 
     * where the value is in the interval.
     *
     * Only makes sense for numeric properties.
     *
     * Params:  allocations        = Allocations to distribute.
     *          property           = Property to distribute according to.
     *          linearCategorySize = When logarithmic is false, this is the size 
     *                               of the intervals used.
     *          logarithmic        = Should the intervals be based on powers 
     *                               of two? (0-1, 1-2, 2-4, 4-8 ... 256-512 ...)
     *                               Useful for allocation sizes.
     *
     * Returns: Categories (allocation sequences) with names corresponding to 
     *          intervals containing their values of specified property.
     */
    static NamedNode[] allocationDistribution(T, bool logarithmic = false)
        (ref YAMLNode allocations, string property, T linearCategorySize)
        if(isNumeric!T)
    {
        const maxValue = 
            max!T(allocations, (ref YAMLNode node){return node[property].as!T;});

        alias IntervalsPowerOfTwo IPowerOfTwo;
        alias IntervalsLinear ILinear;
        static if(logarithmic)
        {
            auto intervals = IPowerOfTwo!T(maxValue + cast(T)1);
        }
        else
        {
            // +1 for the max value is needed as the intervals are open 
            // from right.
            auto intervals = ILinear!T(linearCategorySize, 0, maxValue + cast(T)1);
        }

        // Name-category pairs (category is a sequence of allocations)
        NamedNode[] result;
        foreach(i; intervals)
        {
            auto allocs = 
                filterAllocations(allocations, 
                                  (ref n) => i.contains(n[property].as!T));
            if(allocs.empty) {continue;}

            auto name = property ~ "_" ~ to!string(i.min) ~ " - " ~ to!string(i.max);
            result ~= tuple(name, YAMLNode(allocs));
        }
        return result;
    }

    /**
     * Non-interval allocation distribution, useful for e.g. files and types.
     *
     * Categorizes allocations based on specified property; returns an array 
     * of named nodes where name is composed of name of the property and its 
     * value, and node is a sequence of all allocations with that value of 
     * specified property.
     *
     * Params:  allocations = Allocations to distribute.
     *          property    = Property to distribute according to.
     *
     * Returns: Categories (allocation sequences) with names corresponding to 
     *          values of specified property.
     */
    static NamedNode[] allocationDistribution(T)
        (ref YAMLNode allocations, string property)
    {
        NamedNode[] result;
        foreach(value; listValues!T(allocations, property))
        {
            auto allocs = 
                filterAllocations(allocations, (ref n) => value == n[property].as!T);
            auto name = property ~ "_" ~ to!string(value);
            result ~= tuple(name, YAMLNode(allocs));
        }
        return result;
    }

    /**
     * Filter a sequence of YAML allocations to only those which satisfy predicate.
     *
     * Params:  allocations = YAML sequence of allocations to process.
     *          predicate   = Allocations for which this function returns true
     *                        are kept; those for which it returns false are 
     *                        removed.
     *
     * Returns: Filtered YAML sequence containing only allocations that satisfy predicate.
     */
    static YAMLNode[] filterAllocations
        (ref YAMLNode allocations, Filter predicate)
    {
        YAMLNode[] nodes;
        foreach(ref YAMLNode a; allocations) if(predicate(a))
        {
            nodes ~= a;
        }
        return nodes;
    }

    /**
     * Lists all existing values of specified allocation property.
     *
     * E.g. all files, all byte sizes, etc. .
     *
     * Params:  allocations = A sequence of allocations to list values for.
     *          property    = Allocation property to list values of.
     *
     * Returns: Array of all values of specified property.
     */
    static T[] listValues(T)(ref YAMLNode allocations, string property)
    {
        ubyte[T] set;

        foreach(ref YAMLNode alloc; allocations)
        {
            set[alloc[property].as!T] = 1;
        }

        return set.keys;
    }

private:
    /**
     * Get the maximum value returned by evaluate() for an allocation.
     *
     * This computes evaluate(allocation) for each allocation and returns the maximum.
     *
     * Params:  allocations = YAML sequence of allocations to process.
     *          evaluate    = Function to evaluate each allocation with.
     *
     * Returns: Maximum value of evaluate(allocation) from given sequence of allocations.
     */
    static @property T max(T)
        (ref YAMLNode allocations, T delegate(ref YAMLNode) evaluate)
    {
        auto result = cast(T)0;
        foreach(YAMLNode alloc; allocations)
        {
            result = std.algorithm.max(result, evaluate(alloc));
        }
        return result;
    }
}

/**
 * Parse a string of ranges in format "a-b,c-d,e".
 *
 * Params:  raw = Raw string before parsing.
 * 
 * Returns: Parsed ranges.
 *
 * Throws: ConvException on a number parsing error.
 *         MemProfCLIException on an invalid range.
 */
Tuple!(T, T)[] parseRanges(T)(string raw)
{
    // Must be specific per type to avoid a compiler (as of DMD 2.060) bug.
    static if(is(T == uint))
    {
        Tuple!(uint, uint)[] ranges = 
            raw.split(",").map!((r) => r.canFind("-") ? r.split("-") : [r, r])()
               .map!((p) => tuple(to!uint(p[0]), to!uint(p[1])))().array();
    }
    else static if(is(T == double))
    {
        Tuple!(double, double)[] ranges = 
            raw.split(",").map!((r) => r.canFind("-") ? r.split("-") : [r, r])()
               .map!((p) => tuple(to!double(p[0]), to!double(p[1])))().array();
    }
    else static assert(false, "Unsupported parseRanges type");

    if(ranges.canFind!("a[0] > a[1]")())
    {
        throw new MemProfCLIException("Start of a range greater than its end");
    }
    return ranges;
}

/**
 * Process a command line option (argument starting with --).
 *
 * Params:  arg     = Argument to process.
 *          process = Function to process the option. Takes
 *                    the option and its arguments.
 *
 * Throws:  MemProfCLIException if arg is not an option, and anything process() throws.
 */
void processOption(string arg, void delegate(string, string[]) process)
{
    enforce(arg.startsWith("--"), new MemProfCLIException("Unknown argument: " ~ arg));
    auto argParts = arg[2 .. $].split("=");
    process(argParts[0], argParts[1 .. $]);
}

/// Print help information.
void help()
{
    string[] help = [
        "MemProf",
        "ICE memory profiler",
        "Copyright (C) 2012 Ferdinand Majerech",
        "",
        "Usage: memprof [--help] [--log=<path>] <command> [local-options ...]",
        "",
        "Global options:",
        "  --help                     Print this help information.",
        "  --log=<path>               By default, MemProf tries to load memory log from",
        "                             user_data/main/logs/memoryLog.yaml . This option ",
        "                             can override that to specify custom log file.",
        "  --stdin                    Load memory log from stdin instead of a file.",
        "",
        "Commands:",
        "  distribution               Categorize allocations according to specified",
        "                             criteria and get allocation counts for each",
        "                             category. Criteria can be combined (e.g. ",
        "                             --file --line). Some criteria (time, bytes, etc.)",
        "                             are categorized in intervals.",
        "                             Intervals are always closed(inclusive) from the",
        "                             left, and open(exclusive) from the right.",
        "    Local options:",
        "      --line                 Show allocation counts per line (regardless ",
        "                             of file)",
        "      --file                 Show allocation counts per line",
        "      --type                 Show allocation counts per type",
        "      --time[=<step>]        Show allocation counts by time in linear",
        "                             in linear intervals of specified size",
        "                             (6.0 by default). E.g. 0-5.9.., 18.0-23.9.. etc. .",
        "                             Must not be combined with --bytes",
        "      --bytes                Show allocation counts by allocation size in",
        "                             intervals based on powers of two. E.g. 16-31,",
        "                             256-511, etc. . Must not be combined with",
        "                             --bytesLinear",
        "      --bytesLinear[=<step>] Show allocation counts by allocation size",
        "                             in linear intervals of specified size",
        "                             (1024 by default). E.g. 0-1023, 2048-3071 etc. .",
        "                             Must not be combined with --bytes",
        "      --objects[=<step>]     Show allocation counts by object count in linear",
        "                             intervals of specified size (128 by default). ",
        "                             E.g. 0-127, 384-511 etc. .",
        "                             Must not be combined with --bytes",
        "  filter                     Filter the memory log to only those allocations",
        "                             that meet specified conditions.", 
        "    Local options:",
        "      --line=<lines>         Filter to allocations that happen on ",
        "                             specified lines, regardless of file, type or time.",
        "                             lines is a comma-separated sequence of line ",
        "                             numbers or line number ranges in format A-B.",
        "                             For example: memprof filter --lines=42,13-37",
        "      --file=<files>         Filter to allocations that happen in ",
        "                             specified files. files is a perl-style regular ",
        "                             expression.",
        "                             For example: memprof filter --files='aa.d|bb.d'",
        "      --type=<types>         Filter to allocations that allocate ",
        "                             specified types. types is a perl-style regular ",
        "                             expression.",
        "                             For example: memprof filter --types='int|string",
        "      --time=<times>         Filter to allocations that happen during ",
        "                             specified time periods. times is a comma-separated ",
        "                             sequence of time ranges (in seconds) in format A-B.",
        "                             For example: memprof filter --time=1.1-3.0,5-6.3",
        "      --bytes=<bytes>        Filter to allocations that allocate specified ",
        "                             number of bytes. bytes is a comma-separated ",
        "                             sequence of size ranges (in bytes) in format A-B.",
        "                             For example: memprof filter --bytes=2-4,256-384",
        "      --objects=<objs>       Filter to allocations that allocate specified ",
        "                             number of objects. objs is a comma-separated ",
        "                             sequence of object count ranges in format A-B.",
        "                             For example: memprof filter --objects=2-4,6-8"
        ];
    foreach(line; help) {writeln(line);}
}

/// Exception thrown at CLI errors.
class MemProfCLIException : Exception 
{
    public this(string msg, string file = __FILE__, int line = __LINE__)
    {
        super(msg, file, line);
    }
}

/// Parses MemProf CLI commands, composes them into an action to execute, and executes it.
struct MemProfCLI
{
private:
    // Should we read from stdin instead of a log file?
    bool readFromStdin = false;
    // File name of the log file to load.
    string logFileName = "user_data/main/logs/memoryLog.yaml";
    /*
     * Current command line argument processing function.
     *
     * In the beginning, this is the function to process global arguments.
     * When a command is encountered, it is set to that command's 
     * local arguments parser function.
     */
    void delegate(string) processArg_;
    // Action to execute (determined by command line arguments)
    YAMLNode delegate(ref YAMLNode allocations) action_;

    // Condition functions for the filter command.
    Filter[] filterConditions_;
    // Distribution functions for the distribution command.
    Distribution[] distributionFunctions_;

public:
    /// Construct a MemProfCLI with specified command-line arguments and parse them.
    this(string[] cliArgs)
    {
        // We start parsing global options/commands.
        processArg_ = &globalOrCommand;
        foreach(arg; cliArgs[1 .. $]) {processArg_(arg);}
    }

    /// Execute the action specified by command line arguments.
    void execute()
    {
        if(action_ is null)
        {
            writeln("No command given");
            help();
            return;
        }

        // Execute the command.
        try
        {
            auto memprof = readFromStdin ? MemProf(stdin) : MemProf(logFileName);
            auto result  =
                YAMLNode(["Allocations"], [action_(memprof.memoryLog["Allocations"])]);

            auto stream  = new MemoryStream();
            Dumper(stream).dump(result);
            writeln(cast(string)stream.data());
        }
        catch(YAMLException e)      {writeln("YAML error: ", e.msg);}
        catch(MemProfCLIException e){writeln(e.msg);}
    }
    

private:
    /// Parses local options for the "distribution" command.
    void localDistribution(string arg)
    {
        processOption(arg, (opt, args){
        auto intervalDistribution(T)(string property, const T defaultCategorySize)
        {
            const categorySize = args.empty ? defaultCategorySize : to!T(args[0]);
            return (ref YAMLNode allocs) =>
                   MemProf.allocationDistribution!T(allocs, property, categorySize);
        }
        auto listDistribution(T)(string property)
        {
            return (ref YAMLNode allocs) =>
                   MemProf.allocationDistribution!T(allocs, property);
        }
        void addDistribution(Distribution fun){distributionFunctions_ ~= fun;}

        switch(opt)
        {
            case "line":        addDistribution(listDistribution!uint("__LINE__"));     break;
            case "file":        addDistribution(listDistribution!string("__FILE__"));   break;
            case "type":        addDistribution(listDistribution!string("type"));       break;
            case "time":        addDistribution(intervalDistribution("time", 6.0));     break;
            case "bytesLinear": addDistribution(intervalDistribution("bytes", 1024u));  break;
            case "objects":     addDistribution(intervalDistribution("objects", 128u)); break;
            case "bytes":
                addDistribution((ref YAMLNode allocs)
                {
                    return MemProf.allocationDistribution!(uint, true)(allocs, "bytes", 0);
                });
                break;
            default:
                throw new MemProfCLIException("Unrecognized distribution option: --" ~ arg);
        }
        });
    }

    /// Parses local options for the "filter" command.
    void localFilter(string arg)
    {
        processOption(arg, (opt, args){
        enforce(!args.empty, new MemProfCLIException("--" ~ opt ~ " needs an argument"));

        // Returns a function that checks if specified string property of an allocation
        // matches regex given as the option argument.
        auto matchString(string property)
        {
            return (ref YAMLNode alloc){
                const value = alloc[property].as!string;
                // The entire value must match the regex.
                auto match = value.match(args[0]);
                return !match.empty && match.front.hit == value;
            };
        }

        // Returns a function that checks if specified numeric property is on one of
        // ranges specified by the option argument.
        auto inRanges(T)(string property)
        {
            auto ranges = parseRanges!T(args[0]);
            return (ref YAMLNode alloc){
                const value = alloc[property].as!T;
                foreach(range; ranges) if(value >= range[0] && value <= range[1])
                {
                    return true;
                }
                return false;
            };
        }

        switch(opt)
        {
            case "line":    filterConditions_ ~= inRanges!uint("__LINE__"); break;
            case "file":    filterConditions_ ~= matchString("__FILE__");   break;
            case "type":    filterConditions_ ~= matchString("type");       break;
            case "time":    filterConditions_ ~= inRanges!double("time");   break;
            case "bytes":   filterConditions_ ~= inRanges!uint("bytes");    break;
            case "objects": filterConditions_ ~= inRanges!uint("objects");  break;
            default:
                throw new MemProfCLIException("Unrecognized filter option: --" ~ arg);
        }
        });
    }

    /// Parse a global option or command.
    void globalOrCommand(string arg)
    {
        // Command
        if(!arg.startsWith("--")) switch (arg)
        {
            case "distribution":
                processArg_ = &localDistribution;
                action_ = (ref YAMLNode allocations)
                {
                    enforce(!distributionFunctions_.empty,
                            new MemProfCLIException
                                ("No options specified for the \'distribution\' command"));

                    NamedNode[] categories = [tuple("", allocations)];
                    // Apply each distribution function 
                    // (getting a cross product of distributions)
                    foreach(f; distributionFunctions_)
                    {
                        NamedNode[] newCategories;
                        foreach(ref namedCategory; categories)
                        {
                            // Splitting a category to subcategories based on current
                            // distribution function. This function builds subcategory
                            // names.
                            auto name(ref NamedNode cat)
                            {
                                return tuple(namedCategory[0] ~ " " ~ cat[0], cat[1]);
                            }
                            newCategories ~= f(namedCategory[1]).map!name().array;
                        }
                        categories = newCategories;
                    }

                    string[] names  = categories.map!((ref c) => c[0])().array;
                    ulong[] lengths = categories.map!((ref c) => c[1].length)().array;
                    return YAMLNode(names, lengths);
                };
                return;
            case "filter":
                processArg_ = &localFilter;
                action_ = (ref YAMLNode allocations)
                {
                    enforce(!filterConditions_.empty,
                            new MemProfCLIException
                                ("No options specified for the \'filter\' command"));
                    return YAMLNode(MemProf.filterAllocations(allocations, 
                    (ref YAMLNode alloc)
                    {
                        foreach(c; filterConditions_) if(!c(alloc))
                        {
                            return false;
                        }
                        return true;
                    }));
                };
                return;
            default: 
                throw new MemProfCLIException("Unknown command: " ~ arg);
        }

        processOption(arg, (opt, args){
        switch(opt)
        {
            case "help":  help(); return;
            case "stdin": readFromStdin = true; return;
            case "log":
                enforce(!arg.empty,
                        new MemProfCLIException("Option --log needs an argument (filename)"));
                logFileName = args[0];
                return;
            default:
                throw new MemProfCLIException("Unrecognized global option: --" ~ opt);
        }
        });
    }
}

/// Program entry point.
void main(string[] args)
{
    try{MemProfCLI(args).execute();}
    catch(ConvException e)
    {
        writeln("String conversion error. Maybe an argument is in incorrect format?\n" ~
                "ERROR: ", e.msg);
        return;
    }
    catch(MemProfCLIException e)
    {
        writeln("ERROR: ", e.msg);
        return;
    }
}
