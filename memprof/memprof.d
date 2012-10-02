
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

/// Memory profiler using ICE logging of manual memory allocations.
module memprof;


import std.algorithm;
import std.array;
import std.conv;
import std.stdio;
import std.stream;

import dyaml.dumper;
import dyaml.exception;
import dyaml.node;
import dyaml.loader;

import util.intervals;

alias dyaml.node.Node YAMLNode;

/// Main MemProf object.
///
/// Contains all profiling functionality.
/// Might be split into multiple classes/functions if needed.
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
        char[] lineBuffer;
        while (file.readln(lineBuffer))
        {
            fileBuffer ~= lineBuffer;
            fileBuffer ~= '\n';
        }
        
        auto stream = new MemoryStream(fileBuffer);
        memoryLog_ = Loader(stream).load();
    }

    /// Get the memory log loaded from YAML.
    @property ref YAMLNode memoryLog()
    {
        return memoryLog_;
    }

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
            foreach(interval; intervals)
            {
                bool inInterval(ref YAMLNode node)
                {
                    return interval.contains(node["bytes"].as!size_t);
                }
                const count = narrowAllocations(allocations, &inInterval).length;
                if(count == 0){continue;}

                categories ~= to!string(interval.min) ~ " - " ~ to!string(interval.max - 1);
                allocationCounts ~= count;
            }
        }

        if(logarithmic) {allocCounts(IntervalsPowerOfTwo!size_t(maxAllocation + 1));}
        else            {allocCounts(IntervalsLinear!size_t(baseSize, 0, maxAllocation + 1));}
        return YAMLNode(categories, allocationCounts, "tag:yaml.org,2002:pairs");
    }

    /**
     * Narrow a sequence of YAML allocations to only those which satisfy predicate.
     *
     * Params:  allocations = YAML sequence of allocations to process.
     *          predicate   = Allocations for which this function returns true
     *                        are kept; those for which it returns false are 
     *                        removed.
     *
     * Returns: Narrowed YAML sequence containing only allocations that satisfy predicate.
     */
    static YAMLNode[] narrowAllocations
        (ref YAMLNode allocations, bool delegate(ref YAMLNode) predicate)
    {
        YAMLNode[] nodes;
        foreach(ref YAMLNode record; allocations) if(predicate(record))
        {
            nodes ~= record;
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
        size_t maxValue = 0;
        foreach(ref YAMLNode record; allocations)
        {
            maxValue = std.algorithm.max(maxValue, evaluate(record));
        }
        return maxValue;
    }
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
        "                        If not specified, step is 1024."
        ];
    foreach(line; help) {writeln(line);}
}

/// Program entry point.
void main(string[] args)
{
    /// Should we read from stdin instead of a log file?
    bool readFromStdin = false;
    string logFileName = "user_data/main/logs/memoryLog.yaml";
    /**
     * Current command line argument processing function.
     *
     * At first, this is the function to process global arguments.
     * When a command is encountered, this is set to that command's 
     * local arguments parser function.
     */
    bool delegate(string) processArg;
    /// Action to execute (determined by command line arguments)
    YAMLNode delegate(ref YAMLNode) action;

    /// Parses local options of the "sizedist" command.
    bool localSizeDist(string arg)
    {
        if(!arg.startsWith("--"))
        {
            writeln("Unknown argument: ", arg);
            return false;
        }

        uint linearCategorySize = 1024;

        // Option
        auto argParts = arg[2 .. $].split("=");
        arg = argParts[0];
        switch(arg)
        {
            case "linear":
                if(argParts.length > 1)
                {
                    linearCategorySize = to!uint(argParts[1]);
                }
                action = (ref YAMLNode allocations)
                {
                    return MemProf.allocationSizeDistribution
                               (allocations, linearCategorySize, false);
                };
                return true;
            default:
                writeln("Unrecognized local option: --", arg);
                return false;
        }

        assert(false, "This code should never be reached");
    }

    bool globalOrCommand(string arg)
    {
        // Command
        if(!arg.startsWith("--")) switch (arg)
        {
            case "sizedist": 
                processArg = &localSizeDist;
                action = (ref YAMLNode allocations)
                {
                    return MemProf.allocationSizeDistribution(allocations, 1, true);
                };
                return true;
            default: writeln("Unknown command: ", arg); return false;
        }

        // Option
        auto argParts = arg[2 .. $].split("=");
        arg = argParts[0];
        switch(arg)
        {
            case "help":  return false;
            case "stdin": readFromStdin = true; return true;
            case "log":
                if(argParts.length == 1)
                {
                    writeln("Option --log needs an argument (filename)");
                    return false;
                }
                logFileName = argParts[1];
                return true;
            default:
                writeln("Unrecognized global option: --", arg);
                return false;
        }

        assert(false, "This code should never be reached");
    }

    processArg = &globalOrCommand;
    try foreach(arg; args[1 .. $])
    {
        if(!processArg(arg))
        {
            help();
            return;
        }
    }
    catch(ConvException e)
    {
        writeln("String conversion error. Maybe an argument is in wrong format?\n" ~
                "Error: ", e.msg);
        help();
        return;
    }

    if(action is null)
    {
        writeln("No command given");
        help();
        return;
    }

    try
    {
        auto memprof = readFromStdin ? MemProf(stdin) : MemProf(logFileName);
        auto result  = action(memprof.memoryLog["Allocations"]);

        auto stream  = new MemoryStream();
        Dumper(stream).dump(result);
        writeln(cast(string)stream.data());
    }
    catch(YAMLException e)
    {
        writeln("YAML error: ", e.msg);
        return;
    }
}
