
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

/**
 * $(BIG DPong API documentation)
 *
 * Introduction:
 * 
 * This is the complete API documentation for DPong. It describes
 * all classes, structs, interfaces, functions and so on.
 * This API documentation is intended to serve developers who want to
 * improve the Pong engine, as well as those who want to modify it for
 * their own needs.
 */

module main.pong;


import std.stdio: writeln;
import std.c.stdlib: exit;     

import file.fileio;
import formats.cli;
import pong.pong;


///Program entry point.
void main(string[] args)
{
    //will add -h/--help and generate usage info by itself
    auto cli = new CLI();
    cli.description = "DPong 0.1.0\n"
                      "Pong game written in D.\n"
                      "Copyright (C) 2010-2011 Ferdinand Majerech";
    cli.epilog = "Report errors at <kiithsacmp@gmail.com> (in English, Czech or Slovak).";

    string root = "./data";
    string user = "./user_data";

    //Root data and user data MUST be specified at startup
    cli.add_option(CLIOption("root_data").short_name('R').target(&root));
    cli.add_option(CLIOption("user_data").short_name('U').target(&user));

    if(!cli.parse(args)){return;}

    try
    {
        root_data(root);
        user_data(user);

        Pong pong = new Pong();
        scope(exit){pong.die();}
        pong.run();
    }
    catch(Exception e)
    {
        writeln("Unhandled exeption: ", e.toString(), " ", e.msg);
        exit(-1);
    }
}                                     
