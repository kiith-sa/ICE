
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

/**
 * $(BIG ICE API documentation)
 *
 * Introduction:
 * 
 * This is the complete API documentation for ICE. It describes
 * all classes, structs, interfaces, functions and so on.
 * This API documentation is intended to serve developers who want to
 * improve the ICE engine, as well as those who want to modify it for
 * their own needs.
 */


///Program entry point.
module main.ice;


import core.stdc.stdlib: exit;     
import std.stdio: writeln;
import std.typecons;

import dgamevfs._;

import formats.cli;
import ice.exceptions;
import ice.ice;
import util.unittests;
import memory.allocator;
import memory.memory;


///Program entry point.
void main(string[] args)
{
    memory.memory.suspendMemoryDebugRecording = false;

    writeln("Started main()...");
    //will add -h/--help and generate usage info by itself
    auto cli = new CLI();
    cli.description = "ICE 0.1.0\n"
                      "Top-down scrolling shooter written in D.\n"
                      "Copyright (C) 2010-2012 Ferdinand Majerech, Libor Malis, David Horvath, Tomas Nguyen";
    cli.epilog = "Report errors at <kiithsacmp@gmail.com> (in English, Czech or Slovak).";

    string root = "./data";
    string user = "./user_data";

    //Root data and user data MUST be specified at startup
    cli.addOption(CLIOption("root_data").shortName('R').target(&root));
    cli.addOption(CLIOption("user_data").shortName('U').target(&user));

    if(!cli.parse(args)){return;}

    scope(exit) writeln("Main exit");
    try
    {
        auto rootFS    = new FSDir("root_data", root, No.writable);
        auto userFS    = new FSDir("user_data", user, Yes.writable);
        //Create userFS if it doesn't exist. rootFS not existing is an error.
        userFS.create();

        auto rootStack = new StackDir("root_data");
        auto userStack = new StackDir("user_data");
        auto gameDir   = new StackDir("root");

        rootStack.mount(rootFS.dir("main"));
        auto userMain = userFS.dir("main");
        userMain.create();
        userStack.mount(userMain);
        gameDir.mount(rootStack);
        gameDir.mount(userStack);

        writeln("Initialized VFS...");
        memory.memory.gameDir = gameDir;
        auto ice = new Ice(gameDir);
        // This is here due to an unknown std.regex 32bit bug.
        // It should be moved back to the start later.
        runUnitTests();
        writeln("Initialized ICE...");
        scope(exit){clear(ice);}
        writeln("Going to run ICE...");
        ice.run();
    }
    catch(GameStartupException e)
    {
        writeln("Game failed to start: ", e.msg);
        exit(-1);
    }
    catch(VFSException e)
    {
        writeln("Game failed due to a file system error "
                "(maybe data directory is missing?): ", e.msg);
        exit(-1);
    }

    memory.allocator.freeUnusedBuffers.emit();
}
