
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

import file.fileio;
import formats.cli;
import ice.exceptions;
import ice.ice;


///Program entry point.
void main(string[] args)
{
    //will add -h/--help and generate usage info by itself
    auto cli = new CLI();
    cli.description = "DPong 0.6.0\n"
                      "Pong game written in D.\n"
                      "Copyright (C) 2010-2011 Ferdinand Majerech";
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
        rootData(root);
        userData(user);

        auto rootFS = new FSDir("root_data", root, No.writable);
        auto userFS = new FSDir("user_data", user, Yes.writable);
        auto rootStack = new StackDir("root_data");
        rootStack.mount(rootFS.dir("main"));
        auto userStack = new StackDir("user_data");
        userStack.mount(userFS.dir("main"));
        auto gameDir = new StackDir("root");
        gameDir.mount(rootStack);
        gameDir.mount(userStack);

        auto ice = new Ice(gameDir);
        scope(exit){clear(ice);}
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
    catch(Exception e)
    {
        writeln("Game failed to start, with an unhandled exeption: ", e.toString(), " ", e.msg);
        exit(-1);
    }
}
