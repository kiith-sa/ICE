
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
import std.typecons;

import dyaml.dumper;
import dyaml.exception;
import dyaml.node;
import dyaml.loader;

import util.intervals;

/**
 * TODO:
 * Time distribution of allocs.
 * Aggregate results.
 * Get sequence of files, lines, types
 * Aggregate per file, line, type, file-line, type-line, file-type
 * AWESOME: FrameProfiler could output arguments for 
 *     memprof filter --time 
 *     based on zones. So we could get an exact list of allocations happening within 
 *     a frame. We could even use this to drill down to deeper zones
 *     once we get a general idea to find out precise causes of allocations.
 *     Maybe even in a Perf-style CLI app.
 *
 *     One XXX ASAP good way to use this would be to filter the 
 *     worst frames, and get allocations for those.
 */

alias dyaml.node.Node YAMLNode;

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
     * Get a YAML mapping containing size distribution of allocations.
     *
     * This categorizes allocations based on allocation size and gets
     * the number of allocations in each category.
     *
     * Params: allocations = YAML sequence of allocations to process.
     *         baseSize    = Used if logarithmic is false. Splits the distribution into
     *                       equal sized categories sized baseSize bytes.
     *         logarithmic = If true, the distribution is split into categories
     *                       based on powers of two.
     */
    static YAMLNode allocationSizeDistribution
        (ref YAMLNode allocations, const size_t baseSize, const bool logarithmic)
    {
        const maxAllocation = 
            max(allocations, (ref YAMLNode node){return node["bytes"].as!size_t;});
        string[] categories;
        size_t[] allocationCounts;

        // Collect allocation counts for each interval.
        void allocCounts(T)(T intervals)
        {
            foreach(i; intervals)
            {
                const count = 
                    filterAllocations(allocations, 
                                      (ref n) => i.contains(n["bytes"].as!size_t)).length;
                if(count == 0){continue;}

                categories ~= to!string(i.min) ~ " - " ~ to!string(i.max - 1);
                allocationCounts ~= count;
            }
        }

        if(logarithmic) {allocCounts(IntervalsPowerOfTwo!size_t(maxAllocation + 1));}
        else            {allocCounts(IntervalsLinear!size_t(baseSize, 0, maxAllocation + 1));}
        return YAMLNode(categories, allocationCounts, "tag:yaml.org,2002:pairs");
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
        (ref YAMLNode allocations, bool delegate(ref YAMLNode) predicate)
    {
        YAMLNode[] nodes;
        foreach(ref YAMLNode a; allocations) if(predicate(a))
        {
            nodes ~= a;
        }
        return nodes;
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
    static @property size_t max(T)
        (ref YAMLNode allocations, T delegate(ref YAMLNode) evaluate)
    {
        return map!((a) => evaluate(a))(allocations.as!(YAMLNode[]))
               .reduce!((a, b) => std.algorithm.max(a, b))();
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
        "  --help                Print this help information.",
        "  --log=<path>          By default, MemProf tries to load memory log from",
        "                        user_data/main/logs/memoryLog.yaml . This option ",
        "                        can override that to specify custom log file.",
        "  --stdin               Load memory log from stdin instead of a file.",
        "",
        "Commands:",
        "  sizedist              Categorize allocations in the memory log by",
        "                        allocation size and output the number of allocations",
        "                        in each category as a YAML mapping.",
        "    Local options:",
        "      --linear[=<step>] By default, allocation categories are based on",
        "                        powers of two, e.g. 16-31 bytes, 32-63, and so on.",
        "                        When --linear is specified, the categories are",
        "                        equal sized instead, separated by step bytes.",
        "                        If not specified, step is 1024.",
        "  filter                Filter the memory log to only those allocations",
        "                        that meet specified conditions.",
        "    Local options:",
        "      --line=<lines>    Filter to those allocations that happen on ",
        "                        specified lines, regardless of file, type or time.",
        "                        lines is a comma-separated sequence of line ",
        "                        numbers or line number ranges in format A-B.",
        "                        For example: memprof filter --lines=42,13-37",
        "      --file=<files>    Filter to those allocations that happen in ",
        "                        specified files. files is a perl-style regular ",
        "                        expression.",
        "                        For example: memprof filter --files='aa.d|bb.d'",
        "      --type=<types>    Filter to those allocations that allocate ",
        "                        specified types. types is a perl-style regular ",
        "                        expression.",
        "                        For example: memprof filter --types='int|string",
        "      --time=<times>    Filter to those allocations that happen during ",
        "                        specified time periods. times is a comma-separated ",
        "                        sequence of time ranges (in seconds) in format A-B.",
        "                        For example: memprof filter --time=1.1-3.0,5-6.3",
        "      --bytes=<bytes>   Filter to those allocations that allocate specified ",
        "                        number of bytes. bytes is a comma-separated ",
        "                        sequence of size ranges (in bytes) in format A-B.",
        "                        For example: memprof filter --bytes=2-4,256-384",
        "      --objects=<objs>  Filter to those allocations that allocate specified ",
        "                        number of objects. objs is a comma-separated ",
        "                        sequence of object count ranges in format A-B.",
        "                        For example: memprof filter --objects=2-4,6-8"
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
    // If not null, called after options are parsed.
    void delegate() postProcess_;
    // Action to execute (determined by command line arguments)
    YAMLNode delegate(ref YAMLNode allocations) action_;

    // Condition functions for the filter command.
    bool delegate(ref YAMLNode)[] filterConditions_;

public:
    /// Construct a MemProfCLI with specified command-line arguments and parse them.
    this(string[] cliArgs)
    {
        // We start parsing global options/commands.
        processArg_ = &globalOrCommand;
        foreach(arg; cliArgs[1 .. $]) {processArg_(arg);}
        if(postProcess_ !is null)     {postProcess_();}
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
    /// Parses local options of the "sizedist" command.
    void localSizeDist(string arg)
    {
        processOption(arg, (opt, args){
        switch(opt)
        {
            // Overrides the default (power-of-two distribution) action.
            case "linear":
                uint linearCategorySize = args.empty ? 1024 : to!uint(args[0]);
                action_ = (ref YAMLNode allocations)
                {
                    return MemProf.allocationSizeDistribution
                               (allocations, linearCategorySize, false);
                };
                return;
            default:
                throw new MemProfCLIException("Unrecognized sizedist option: --" ~ opt);
        }
        });
    }

    /// Parses local options for the "filter" command.
    void localFilter(string arg)
    {
        processOption(arg, (opt, args){
        enforce(!args.empty,
                new MemProfCLIException("Option " ~ opt ~ " needs an argument"));

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
            case "sizedist": 
                processArg_ = &localSizeDist;
                action_ = (ref YAMLNode allocations)
                {
                    return MemProf.allocationSizeDistribution(allocations, 1, true);
                };
                return;
            case "filter":
                processArg_ = &localFilter;
                postProcess_ = ()
                {
                    enforce(filterConditions_.length > 0,
                            new MemProfCLIException
                                ("No options specified for the \'filter\' argument"));
                    action_ = (ref YAMLNode allocations)
                    {
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
