#!dmd -run
/**
 * License: Boost 1.0
 *
 * Copyright (c) 2009-2010 Eric Poggel, Changes 2011 Ferdinand Majerech
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * Description:
 *
 * This is a D programming language build script (and library) that can be used
 * to compile D (version 1) source code.  Unlike Bud, DSSS/Rebuild, Jake, and
 * similar tools, CDC is contained within a single file that can easily be
 * distributed with projects.  This simplifies the build process since no other
 * tools are required.  The main() function can be utilized to turn
 * CDC into a custom build script for your project.
 *
 * CDC's only requirement is a D compiler.  It is/will be supported on any 
 * operating system supported by the language.  It works with dmd, ldc (soon), 
 * and gdc.
 *
 * CDC can be used just like dmd, except for the following improvements.
 * <ul>
 *   <li>CDC can accept paths as as well as individual source files for compilation.
 *    Each path is recursively searched for source, library, object, and ddoc files.</li>
 *   <li>CDC automatically creates a modules.ddoc file for use with CandyDoc and
 *    similar documentation utilities.</li>
 *   <li>CDC defaults to use the compiler that was used to build itself.  Compiler
 *    flags are passed straight through to that compiler.</li>
 *   <li>The -op flag is always used, to prevent name conflicts in object and doc files.</li>
 *   <li>Documentation files are all placed in the same folder with their full package
 *    names.  This makes relative links between documents easier.</li>
 * </ul>

 * These DMD/LDC options are automatically translated to the correct GDC
 * options, or handled manually:
 * <dl>
 * <dt>-c</dt>         <dd>do not link</dd>
 * <dt>-D</dt>         <dd>generate documentation</dd>
 * <dt>-Dddocdir</dt>  <dd>write fully-qualified documentation files to docdir directory</dd>
 * <dt>-Dfdocfile</dt> <dd>write fully-qualified documentation files to docfile file</dd>
 * <dt>-lib</dt>       <dd>Generate library rather than object files</dd>
 * <dt>-run</dt>       <dd>run resulting program, passing args</dd>
 * <dt>-Ipath</dt>     <dd>where to look for imports</dd>
 * <dt>-o-</dt>        <dd>do not write object file.</dd>
 * <dt>-offilename</dt><dd>name output file to filename</dd>
 * <dt>-odobjdir</dt>  <dd>write object & library files to directory objdir</dd>
 * </dl>
 *
 * In addition, these optional flags have been added.
 * <dl>
 * <dt>--dmd</dt>       <dd>Use dmd to compile</dd>
 * <dt>--gdc</dt>       <dd>Use gdc to compile</dd>
 * <dt>--ldc</dt>       <dd>Use ldc to compile</dd>
 * <dt>--verbose</dt>   <dd>Print all commands as they're executed.</dd>
 * <dt>--root</dt>      <dd>Set the root directory of all source files.
 *                 This is useful if CDC is run from a path outside the source folder.</dd>
 * </dl>
 *
 * Bugs:
 * <ul>
 * <li>Doesn't yet work with LDC.  See dsource.org/projects/ldc/ticket/323</li>
 * <li>Dmd writes out object files as foo/bar.o, while gdc writes foo.bar.o</li>
 * <li>Dmd fails to write object files when -od is an absolute path.</li>
 * </ul>
 *
 * Test_Matrix:
 * <ul>
 * <li>pass - DMD/phobos/Win32</li>
 * <li>pass - GDC/phobos/Win32</li>
 * <li>pass - GDC/phobos/Linux32</li>
 * <li>pass - GDC/phobos/OSX</li>
 * <li>? - DMD/OSX</li>
 * <li>? - BSD</li>
 * <li>? - DMD2</li>
 * </ul>
 *
 * TODO:
 * <ul>
 * <li>Add support for a --script argument to accept another .d file that calls cdc's functions.</li>
 * <li>Print help or at least info on run.</li>
 * <li>-Df option</li>
 * <li>GDC - Remove dependancy on "ar" on windows? </li>
 * <li>LDC - Scanning a folder for files is broken. </li>
 * <li>Test with D2</li>
 * <li>Unittests</li>
 * <li>More testing on paths with spaces. </li>
 * </ul>
 *
 * API:
 * Use any of these functions in your own build script.
 */

module cdc;


import std.c.stdarg;

import std.string;


/**
 * Use to implement your own custom build script, or pass args on to defaultBuild() 
 * to use this file as a generic build script like bud or rebuild. */
int main(string[] args)
{
    // Operate cdc as a generic build script
    //return defaultBuild(args);

    /*
    // This is an example of a custom build script.
    if (!exists("bar.lib")
        CDC.compile(["foo"], ["-lib", "-offoo.lib"]);
    CDC.compile(["bar", "main.d", "foo.lib"], ["-D", "-ofbar"]);
    return 0;
    */

    string build = "debug";
    bool no_sse = false;

    string[] extra_args = ["-w", "-wi"];

    args = args[1 .. $];
    foreach(arg; args)
    {
        if(arg == "--no-sse"){no_sse = true;}
        else if(arg == "--help" || arg == "-h"){help(); return 0;}
        else if(arg[0] == '-'){extra_args ~= arg;}
    }
    if(args.length > 0 && args[$ - 1][0] != '-'){build = args[$ - 1];}

    string sse3 = " -version=sse3 -version=sse2 -version=sse1";
    if(!no_sse){extra_args ~= sse3;}
    

    string[] debug_args = ["-unittest", "-gc", "-ofpong-debug"];
    string[] no_contracts_args = ["-release", "-gc", "-ofpong-no-contracts"];
    string[] release_args = ["-O", "-inline", "-release", "-gc", "-ofpong-release"];

    void compile(string[] arguments, string[] extra_files = [])
    {
        CDC.compile(extra_files ~ [
                     "dependencies/", 
                     
                     "physics/", "scene/", "file/", "formats/", "gui/", "math/", 
                     "memory/", "monitor/", "platform/", "spatial/", 
                     "time/", "video/", "containers/", "util/",

                     "color.d", "graphdata.d", "image.d", "pong.d", "stringctfe.d"
                     ],
                     arguments ~ extra_args);
    }

    switch(build)
    {
        case "debug":
            compile(debug_args);
            break;
        case "no-contracts":
            compile(no_contracts_args);
            break;
        case "release":
            compile(release_args);
            break;
        case "all":
            compile(debug_args);
            compile(no_contracts_args);
            compile(release_args);
            break;
        default:
            writefln("unknown build target: ", build);
            writefln("available targets: 'debug', 'no-contracts', 'release', 'all'");
            break;
    }

    return 0;
}

///Print help information.
void help()
{
    string help =
        "Pong build script\n"
        "Changes Copyright (C) 2010-2011 Ferdinand Majerech\n"
        "Based on CDC script Copyright (C) 2009-2010 Eric Poggel\n"
        "Usage: cdc [OPTION ...] [EXTRA COMPILER OPTION ...] [TARGET]\n"
        "This script uses the compiler it was built with to compile the project.\n"
        "\n"
        "Any options starting with '-' not parsed by the script will be\n"
        "passed to the compiler used.\n"
        "\n"
        "Optionally, build target can be specified, 'debug' is default.\n"
        "Available build targets:\n"
        "    debug           Debug information, unittests, contracts built in.\n"
        "                    No optimizations. Target binary name: 'pong-debug'\n"
        "    no-contracts    Debug information, no unittests, contracts, optimizations.\n"
        "                    Target binary name: 'pong-no-contracts'\n"
        "    release         Debug information, no unittests, contracts.\n"
        "                    Optimizations, inlining enabled.\n"
        "                    Target binary name: 'pong-release'\n"
        "    all             All of the above.\n"
        "\n"
        "Available options:\n"
        " -h --help          Show this help information.\n"
        "    --no-sse        Don't use hand-coded SSE optimizations.\n"
        "                    By default, custom SSE code requiring SSE 3 is included.\n"
        "                    This is needed on old X86 or non-X86 platforms.\n"
        ;
    writefln(help);
}

/*
 * ----------------------------------------------------------------------------
 * CDC Code, modify with caution
 * ----------------------------------------------------------------------------
 */

// Imports
import std.string : join, find, replace, tolower;
import std.stdio : writefln;
import std.path : sep, getDirName, getName, addExt;
import std.file : chdir, copy, isdir, isfile, listdir, mkdir, exists, getcwd, remove, write;
import std.format;
import std.traits;
import std.c.process;
import std.c.time : usleep;


/// This is always set to the name of the default compiler, which is the compiler used to build cdc.
version (DigitalMars)
    string compiler = "dmd";
version (GNU)
    string compiler = "gdc"; /// ditto
version (LDC)
    string compiler = "ldmd";  /// ditto

version (Windows)
{    const string[] obj_ext = ["obj", "o"]; /// An array of valid object file extensions for the current.
    const string lib_ext = "lib"; /// Library extension for the current platform.
    const string bin_ext = "exe"; /// executable file extension for the current platform.
}
else
{    const string[] obj_ext = ["o"]; /// An array of valid object file extensions for the current.
    const string lib_ext = "a"; /// Library extension for the current platform.
    const string bin_ext = ""; /// Executable file extension for the current platform.
}

/**
 * Program entry point.  Parse args and run the compiler.*/
int defaultBuild(string[] args)
{    args = args[1..$];// remove self-name from args

    string root;
    string[] options;
    string[] paths;
    string[] run_args;

    // Populate options, paths, and run_args from args
    bool run;
    foreach (arg; args)
    {    switch (arg)
        {    case "--verbose": verbose = true; break;
            case "--dmd": compiler = "dmd"; break;
            case "--gdc": compiler = "gdc"; break;
            case "--ldc": compiler = "ldc"; break;
            case "-run": run = true; options~="-run";  break;
            default:
                if (starts_with(arg, "--root"))
                {    root = arg[6..$];
                    continue;
                }

                if (arg[0] == '-' && (!run || !paths.length))
                    options ~= arg;
                else if (!run || exists(arg))
                    paths ~= arg;
                else if (run && paths.length)
                    run_args ~= arg;
    }    }

    // Compile
    CDC.compile(paths, options, run_args, root);

    return 0; // success
}

/**
 * A library for compiling d code.
 * Example:
 * --------
 * // Compile all source files in src/core along with src/main.d, link with all library files in the libs folder,
 * // generate documentation in the docs folder, and then run the resulting executable.
 * CDC.compile(["src/core", "src/main.d", "libs"], ["-D", "-Dddocs", "-run"]);
 * --------
 */
struct CDC
{
    /**
     * Compile d code using the current compiler.
     * Params:
     *     paths = Array of source and library files and folders.  Directories are recursively searched.
     *     options = Compiler options.
     *     run_args = If -run is specified, pass these arguments to the generated executable.
     *     root = Use this folder as the root of all paths, instead of the current folder.  This can be relative or absolute.
     *     verbose = Print each command before it's executed.
     * Returns:
     *     Array of commands that were executed.
     * TODO: Add a dry run option to just return an array of commands to execute. */
    static string[] compile(string[] paths, string[] options=null, string[] run_args=null, string root=null)
    {    
        // Change to root directory and back again when done.
        string cwd = getcwd();
        if (root.length)
        {    if (!exists(root))
                throw new Exception(`Directory specified for --root "` ~ root ~ `" doesn't exist.`);
            chdir(root);
        }
        scope(exit)
            if (root.length)
                chdir(cwd);

        // Convert src and lib paths to files
        string[] sources;
        string[] libs;
        string[] ddocs;
        foreach (src; paths)
            if (src.length)
            {    if (!exists(src))
                    throw new Exception(`Source file/folder "` ~ src ~ `" does not exist.`);
                if (isdir(src)) // a directory of source or lib files
                {    sources ~= scan(src, [".d"]);
                    ddocs ~= scan(src, [".ddoc"]);
                    libs ~= scan(src, [lib_ext]);
                } else if (isfile(src)) // a single file
                {
                    scope ext = src[rfind(src, ".")..$];
                    if (".d" == ext)
                        sources ~= src;
                    else if (lib_ext == ext)
                        libs ~= src;
                }
            }

        // Add dl.a for dynamic linking on linux
        version (linux)
            libs ~= ["-L-ldl"];

        // Combine all options, sources, ddocs, and libs
        CompileOptions co = CompileOptions(options, sources);
        options = co.getOptions(compiler);
        if (compiler=="gdc")
            foreach (inout d; ddocs)
                d = "-fdoc-inc="~d;
        else foreach (inout l; libs)
            version (GNU) // or should this only be version(!Windows)
                l = `-L`~l; // TODO: Check in dmd and gdc

        // Create modules.ddoc and add it to array of ddoc's
        if (co.D)
        {    string modules = "MODULES = \r\n";
            sources.sort;
            foreach(string src; sources)
            {    src = split(src, "\\.")[0]; // get filename
                src = replace(replace(src, "/", "."), "\\", ".");
                modules ~= "\t$(MODULE "~src~")\r\n";
            }
            write("modules.ddoc", modules);
            ddocs ~= "modules.ddoc";
            scope(failure) remove("modules.ddoc");
        }
        
        string[] arguments = options ~ sources ~ ddocs ~ libs;

        // Compile
        if (compiler=="gdc")
        {
            // Add support for building libraries to gdc.
            if (co.lib || co.D || co.c) // GDC must build incrementally if creating documentation or a lib.
            {
                // Remove options that we don't want to pass to gcd when building files incrementally.
                string[] incremental_options;
                foreach (option; options)
                    if (option!="-lib" && !starts_with(option, "-o"))
                        incremental_options ~= option;

                // Compile files individually, outputting full path names
                string[] obj_files;
                foreach(source; sources)
                {    string obj = replace(source, "/", ".")[0..$-2]~".o";
                    string ddoc = obj[0..$-2];
                    if (co.od)
                        obj = co.od ~ file_separator ~ obj;
                    obj_files ~= obj;
                    string[] exec = incremental_options ~ ["-o"~obj, "-c"] ~ [source];
                    if (co.D) // ensure doc files are always fully qualified.
                        exec ~= ddocs ~ ["-fdoc-file="~ddoc~".html"];
                    execute(compiler, exec); // throws ProcessException on compile failure
                }

                // use ar to join the .o files into a lib and cleanup obj files (TODO: how to join on GDC windows?)
                if (co.lib)
                {    remove(co.of); // since ar refuses to overwrite it.
                    execute("ar", "cq "~ co.of ~ obj_files);
                }

                // Remove obj files if -c or -od not were supplied.
                if (!co.od && !co.c)
                    foreach (o; obj_files)
                        remove(o);
            }

            if (!co.lib && !co.c)
            {
                // Remove documentation arguments since they were handled above
                string[] nondoc_args;
                foreach (arg; arguments)
                    if (!starts_with(arg, "-fdoc") && !starts_with(arg, "-od"))
                        nondoc_args ~= arg;

                executeCompiler(compiler, nondoc_args);
            }
        }
        else // (compiler=="dmd" || compiler=="ldc")
        {    
            executeCompiler(compiler, arguments);        
            // Move all html files in doc_path to the doc output folder and rename with the "package.module" naming convention.
            if (co.D)
            {    foreach (string src; sources)
                {    
                    if (src[$-2..$] != ".d")
                        continue;

                    string html = src[0..$-2] ~ ".html";
                    string dest = replace(replace(html, "/", "."), "\\", ".");
                    if (co.Dd.length)
                    {    
                        dest = co.Dd ~ file_separator ~ dest;
                        html = co.Dd ~ file_separator ~ html;
                    }
                    if (html != dest) // TODO: Delete remaining folders where source files were placed.
                    {    copy(html, dest);
                        remove(html);
            }    }    }
        }

        // Remove extra files
        string basename = co.of[rfind(co.of, "/")+1..$];
        remove(addExt(basename, "map"));
        if (co.D)
            remove("modules.ddoc");
        if (co.of && !(co.c || co.od))
            foreach (ext; obj_ext)
                remove(addExt(co.of, ext)); // delete object files with same name as output file that dmd sometimes leaves.

        // If -run is set.
        if (co.run)
        {    execute("./" ~ co.of, run_args);
            version(Windows) // give dmd windows time to release the lock.
                if (compiler=="dmd")
                    usleep(100000);
            remove(co.of); // just like dmd
        }

    }

    // A wrapper around execute to write compile options to a file, to get around max arg lenghts on Windows.
    private static void executeCompiler(string compiler, string[] arguments)
    {    try {
            version (Windows)
            {    write("compile", join(arguments, " "));
                scope(exit)
                    remove("compile");
                execute(compiler~" ", ["@compile"]);
            } else
                execute(compiler, arguments);
        } catch (ProcessException e)
        {    throw new Exception("Compiler failed.");
        }
    }

    /*
     * Store compilation options that must be handled differently between compilers
     * This also implicitly enables -of and -op for easier handling. */
    private struct CompileOptions
    {
        bool c;                // do not link
        bool D;                // generate documentation
        string Dd;            // write documentation file to this directory
        string Df;            // write documentation file to this filename
        bool lib;            // generate library rather than object files
        bool o;                // do not write object file
        string od;            // write object & library files to this directory
        string of;            // name of output file.
        bool run;
        string[] run_args;    // run immediately afterward with these arguments.

        private string[] options; // stores modified options.

        /*
         * Constructor */
        static CompileOptions opCall(string[] options, string[] sources)
        {    CompileOptions result;
            foreach (i, option; options)
            {
                if (option == "-c")
                    result.c = true;
                else if (option == "-D" || option == "-fdoc")
                    result.D = true;
                else if (starts_with(option, "-Dd"))
                    result.Dd = option[3..$];
                else if (starts_with(option, "-fdoc-dir="))
                    result.Df = option[10..$];
                else if (starts_with(option, "-Df"))
                    result.Df = option[3..$];
                else if (starts_with(option, "-fdoc-file="))
                    result.Df = option[11..$];
                else if (option == "-lib")
                    result.lib = true;
                else if (option == "-o-" || option=="-fsyntax-only")
                    result.o = true;
                else if (starts_with(option, "-of"))
                    result.of = option[3..$];
                else if (starts_with(option, "-od"))
                    result.od = option[3..$];
                else if (starts_with(option, "-o") && option != "-op")
                    result.of = option[2..$];
                else if (option == "-run")
                    result.run = true;

                if (option != "-run") // run will be handled specially to allow for it to be used w/ multiple source files.
                    result.options ~= option;
            }

            // Set the -o (output filename) flag to the first source file, if not already set.
            string ext = result.lib ? lib_ext : bin_ext; // This matches the default behavior of dmd.
            if (!result.of.length && !result.c && !result.o && sources.length)
            {    result.of = split(split(sources[0], "/")[$-1], "\\.")[0] ~ ext;
                result.options ~= ("-of" ~ result.of);
            }
            version (Windows)
            {    if (find(result.of, ".") <= rfind(result.of, "/"))
                    result.of ~= bin_ext;

                //Stdout(find(result.of, ".")).newline;
            }
            // Exception for conflicting flags
            if (result.run && (result.c || result.o))
                throw new Exception("flags '-c', '-o-', and '-fsyntax-only' conflict with -run");

            return result;
        }

        /*
        * Translate DMD/LDC compiler options to GDC options.
        * This function is incomplete. (what about -L? )*/
        string[] getOptions(string compiler)
        {    string[] result = options.dup;

            if (compiler != "gdc")
            {
                version(Windows)
                    foreach (inout option; result)
                        if (starts_with(option, "-of")) // fix -of with / on Windows
                            option = replace(option, "/", "\\");

                if (!contains(result, "-op"))
                    return result ~ ["-op"]; // this ensures ddocs don't overwrite one another.
                return result;
            }

            // is gdc
            string[string] translate;
            translate["-Dd"] = "-fdoc-dir=";
            translate["-Df"] = "-fdoc-file=";
            translate["-debug="] = "-fdebug=";
            translate["-debug"] = "-fdebug"; // will this still get selected?
            translate["-inline"] = "-finline-functions";
            translate["-L"] = "-Wl";
            translate["-lib"] = "";
            translate["-O"] = "-O3";
            translate["-o-"] = "-fsyntax-only";
            translate["-of"] = "-o ";
            translate["-unittest"] = "-funittest";
            translate["-version"] = "-fversion=";
            translate["-w"] = "-wall";

            // Perform option translation
            foreach (inout option; result)
            {    if (starts_with(option, "-od")) // remove unsupported -od
                    option = "";
                if (option =="-D")
                    option = "-fdoc";
                else
                    foreach (before, after; translate) // Options with a direct translation
                        if (option.length >= before.length && option[0..before.length] == before)
                        {    option = after ~ option[before.length..$];
                            break;
                        }
            }
            return result;
        }
        unittest {
            string[] sources = [cast(string)"foo.d"];
            string[] options = [cast(string)"-D", "-inline", "-offoo"];
            scope result = CompileOptions(options, sources).getOptions("gdc");
            assert(result[0..3] == [cast(string)"-fdoc", "-finline-functions", "-o foo"]);
        }
    }
}

bool verbose = false;

/**
 * Execute a command-line program and print its output.
 *
 * Params: command = The command to execute, e.g. "dmd".
 *         args    = Arguments to pass to the command.
 *
 * Throws: ProcessException on failure or status code 1.
 */
void execute(string command, string[] args=null)
{    
    command ~= " " ~ join(args, " ");

    if(verbose){writefln("CDC:  " ~ command);}

    version(Windows)
    {
        if(starts_with(command, "./")){command = command[2 .. $];}
    }
            
    int status = !system((command ~ "\0").ptr);
    if(!status)
    {
        throw new ProcessException(format("Process '%s' exited with status %d", 
                                          command, status));
    }
}

///Path separator character for the current platform.
version(Windows){char file_separator ='\\';}
else{char file_separator ='/';}

///Directory scan mode. 
enum ScanMode
{    
    ///Scan files.
    Files = 1,
    ///Scan folders.
    Directories = 2,
}

/**
 * Recursively get all files with specified extensions in directory and subdirectories.
 *
 * Params:  directory  = Absolute or relative path to the current directory
 *          extensions = Array of extensions to match
 *          mode       = Scan mode. Files or directories.
 *
 * Returns: An array of paths (including filename) relative to directory.
 *
 * BUGS: LDC fails to return any results. 
 */
string[] scan(string folder, string[] extensions = [""], ScanMode mode = ScanMode.Files)
{    
    string[] result;
    foreach(string filename; listdir(folder))
    {    
        //file_separator breaks gdc windows.
        string name = folder ~ "/" ~ filename; 
        if(isdir(name)){result ~= scan(name, extensions, mode);}
        if((mode == ScanMode.Files && isfile(name)) || 
           (mode == ScanMode.Directories && isdir(name)))
        {    
            foreach(string ext; extensions)
            {
                //if filename ends with ext
                if(filename.length >= ext.length && filename[$ - ext.length .. length] == ext)
                {
                    result ~= name;
                }
            }
        }    
    }
    return result;
}

/**
 * Does a string start with specified prefix?
 *
 * Params:  str    = String to check.
 *          prefix = Prefix to look for.
 *
 * Returns: True if the string starts with specified prefix, false otherwise.
 */
bool starts_with(string str, string prefix)
{
    return str.length >= prefix.length && str[0 .. prefix.length] == prefix;
}

/**
 * Determine whether or not does an array contain an element.
 *
 * Params:  array = Array to check.
 *          elem  = Element to look for.
 */
bool contains(T)(T[] array, T element)
{
    foreach(array_element; array)
    {
        if(array_element == element){return true;}
    }
    return false;
}

// Define ProcessException in Phobos
class ProcessException : Exception {this(string message){super(message);}};
