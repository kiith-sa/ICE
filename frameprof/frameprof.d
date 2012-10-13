
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

/// Utility script extracting data from ICE frame profiler output.
module frameprof;


import std.algorithm;
import std.array;
import std.container;
import std.conv;
import std.exception;
import std.math;
import std.regex;
import std.stdio;
import std.stream;
import std.traits;
import std.typecons;

import dyaml.dumper;
import dyaml.exception;
import dyaml.loader;
import dyaml.node;
import dyaml.representer;
import dyaml.style;

import util.intervals;

/**
 * TODO:
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

/**
 * Main FrameProf object.
 *
 * Contains all profiling functionality.
 * Might be split into multiple classes/functions if needed.
 */
struct FrameProf
{
private:
    /// Frame profile loaded from YAML.
    YAMLNode frameProfile_;

public:
    /// Construct FrameProf loading profile data from specified file.
    this(string fileName)
    {
        frameProfile_ = Loader(fileName).load();
    }

    /// Construct FrameProf loading profile data from specified file object (e.g. stdin).
    this(ref std.stdio.File file)
    {
        char[] fileBuffer;
        char[] line;
        while(file.readln(line))
        {
            fileBuffer ~= line;
        }
        frameProfile_ = Loader(new MemoryStream(fileBuffer)).load();
    }

    /// Get the memory log loaded from YAML.
    @property ref YAMLNode frameProfile() {return frameProfile_;}
}

/**
 * Parse a string of ranges in format "a-b,c-d,e".
 *
 * Params:  raw = Raw string before parsing.
 * 
 * Returns: Parsed ranges.
 *
 * Throws: ConvException on a number parsing error.
 *         FrameProfCLIException on an invalid range.
 */
Tuple!(T, T)[] parseRanges(T)(string raw)
{
    // Must be specific per type to avoid a compiler (as of DMD 2.060) bug.
    static if(is(T == uint))
    {
        Tuple!(uint, uint)[] ranges = 
            raw.split(",")
               .map!((r) => r.canFind("-") ? r.split("-") : [r, r])()
               .map!((p) => tuple(to!uint(p[0]), to!uint(p[1])))()
               .array();
    }
    else static if(is(T == double))
    {
        Tuple!(double, double)[] ranges = 
            raw.split(",")
               .map!((r) => r.canFind("-") ? r.split("-") : [r, r])()
               .map!((p) => tuple(to!double(p[0]), to!double(p[1])))()
               .array();
    }
    else static assert(false, "Unsupported parseRanges type");

    if(ranges.canFind!("a[0] > a[1]")())
    {
        throw new FrameProfCLIException("Start of a range greater than its end");
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
 * Throws:  FrameProfCLIException if arg is not an option, and anything process() throws.
 */
void processOption(string arg, void delegate(string, string[]) process)
{
    enforce(arg.startsWith("--"), new FrameProfCLIException("Unknown argument: " ~ arg));
    auto argParts = arg[2 .. $].split("=");
    process(argParts[0], argParts[1 .. $]);
}

/// Print help information.
void help()
{
    string[] help = [
        "FrameProf",
        "ICE frame profile analyzer",
        "Copyright (C) 2012 Ferdinand Majerech",
        "",
        "Usage: frameprof [--help] [--log=<path>] <command> [local-options ...]",
        "",
        "Global options:",
        "  --help                     Print this help information.",
        "  --log=<path>               By default, FrameProf tries to load frame log from",
        "                             user_data/main/logs/frameProfilerDump.yaml .",
        "                             This option can override that to specify custom",
        "                             log file.",
        "  --stdin                    Load frame log from stdin instead of a file.",
        "",
        "",
        "Commands:",
        ];
    foreach(line; help) {writeln(line);}
}

/// Exception thrown at CLI errors.
class FrameProfCLIException : Exception 
{
    public this(string msg, string file = __FILE__, int line = __LINE__)
    {
        super(msg, file, line);
    }
}

/// Parses FrameProf CLI commands, composes them into an action to execute, and executes it.
struct FrameProfCLI
{
private:
    // Should we read from stdin instead of a log file?
    bool readFromStdin = false;
    // File name of the log file to load.
    string logFileName = "user_data/main/logs/frameProfilerDump.yaml";
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
    // Is the output of the program a sequence of frames?
    bool framesOutput_ = false;

public:
    /// Construct a FrameProfCLI with specified command-line arguments and parse them.
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
            auto frameprof = readFromStdin ? FrameProf(stdin) : FrameProf(logFileName);
            auto rawResult = action_(frameprof.frameProfile["frames"]);
            auto result    = framesOutput_ ? YAMLNode(["frames"], [rawResult])
                                           : rawResult;

            auto stream        = new MemoryStream();
            auto dumper        = Dumper(stream);
            auto representer   = new Representer();
            representer.defaultCollectionStyle = CollectionStyle.Block;
            dumper.representer = representer;
            dumper.dump(result);
            writeln(cast(string)stream.data());
        }
        catch(YAMLException e)      {writeln("YAML error: ", e.msg);}
        catch(FrameProfCLIException e){writeln(e.msg);}
    }
    

private:
    /// Parse a command. Sets up command state and switches to its option parser function.
    void command(string arg)
    {
        switch (arg)
        {
            default: 
                throw new FrameProfCLIException("Unknown command: " ~ arg);
        }
    }

    /// Parse a global option or command.
    void globalOrCommand(string arg)
    {
        // Command
        if(!arg.startsWith("--")) 
        {
            command(arg);
            return;
        }

        // Global option
        processOption(arg, (opt, args){
        switch(opt)
        {
            case "help":  help(); return;
            case "stdin": readFromStdin = true; return;
            case "log":
                enforce(!arg.empty,
                        new FrameProfCLIException("Option --log needs an argument (filename)"));
                logFileName = args[0];
                return;
            default:
                throw new FrameProfCLIException("Unrecognized global option: --" ~ opt);
        }
        });
    }
}

/// Program entry point.
void main(string[] args)
{
    try{FrameProfCLI(args).execute();}
    catch(ConvException e)
    {
        writeln("String conversion error. Maybe an argument is in incorrect format?\n" ~
                "ERROR: ", e.msg);
        return;
    }
    catch(FrameProfCLIException e)
    {
        writeln("ERROR: ", e.msg);
        return;
    }
}
