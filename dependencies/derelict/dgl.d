module dgl;

version(Windows)
{
    pragma(lib, "lib\\DerelictGL.lib");
    pragma(lib, "lib\\DerelictGLU.lib");
    pragma(lib, "lib\\DerelictSDL.lib");
    pragma(lib, "lib\\DerelictUtil.lib");
}
else
{
    pragma(lib, "dl");
    pragma(lib, "lib/libDerelictGL.a");
    pragma(lib, "lib/libDerelictGLU.a");
    pragma(lib, "lib/libDerelictSDL.a");
    pragma(lib, "lib/libDerelictUtil.a");
}

import derelict.sdl.sdl;
//import derelict.sdl.image;
//import derelict.sdl.mixer;
//import derelict.sdl.net;
//import derelict.sdl.ttf;
import derelict.opengl.gl;
import derelict.opengl.glu;
import derelict.util.compat;
version (Tango) {}
else
import std.stdio;

version(D_Version2) {}
else version (Tango)
{
    import tango.io.Stdout;
}
else
{
    alias writefln writeln;
}

void println (A...)(A args)
{
    version (Tango)
    {
        static const string fmt = "{}{}{}{}{}{}{}{}"
                                  "{}{}{}{}{}{}{}{}"
                                  "{}{}{}{}{}{}{}{}";

        static assert (A.length <= fmt.length / 2, "too many arguments");

        Stdout.formatln(fmt[0 .. args.length * 2], args);
    }

    else
        writeln(args);
}

void dumpver(string sdlLib, CSDLVERPTR ver)
{
    println(sdlLib, " version: ", ver.major, '.', ver.minor, '.', ver.patch);
}

void main()
{
    DerelictSDL.load();
    DerelictGL.load();
    DerelictGLU.load();
//  DerelictSDLImage.load();
//  DerelictSDLMixer.load();
//  DerelictSDLNet.load();
//  DerelictSDLttf.load();

    if(SDL_Init(SDL_INIT_VIDEO) < 0)
    {
        throw new Exception("Couldn't init SDL: " ~ toDString(SDL_GetError()));
    }
    scope(exit)
    {
        if(SDL_Quit !is null)
            SDL_Quit();
    }

    SDL_GL_SetAttribute(SDL_GL_BUFFER_SIZE, 32);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 16);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

    if(SDL_SetVideoMode(1024, 768, 0, SDL_OPENGL) == null)
    {
        throw new Exception("Failed to set video mode: " ~ toDString(SDL_GetError()));
    }

    CSDLVERPTR sdlver = SDL_Linked_Version();
    dumpver("SDL", sdlver);
/*
    sdlver = IMG_Linked_Version();
    dumpver("SDL_image", sdlver);

    sdlver = Mix_Linked_Version();
    dumpver("SDL_mixer", sdlver);

    sdlver = SDLNet_Linked_Version();
    dumpver("SDL_net", sdlver);

    sdlver = TTF_Linked_Version();
    dumpver("SDL_ttf", sdlver);
*/
    GLVersion ver = DerelictGL.loadClassicVersions(GLVersion.GL21);
    ver = DerelictGL.loadModernVersions(GLVersion.GL30);
    println("Max GL version = ", DerelictGL.versionToString(ver));

    string glver = toDString(glGetString(GL_VERSION));
    println("GL version string = ", glver);

    string gluver = toDString(gluGetString(GLU_VERSION));
    println("GLU version string = ", gluver);

    DerelictGL.loadExtensions();

    println("Loaded OpenGL Extensions:");
    string[] extlist = DerelictGL.loadedExtensionNames;
    foreach(s; extlist)
        println("\t", s);

    println("Not Loaded OpenGL Extensions:");
    extlist = DerelictGL.notLoadedExtensionNames;
    foreach(s; extlist)
        println("\t", s);

    println("GL Extension String: ", toDString(glGetString(GL_EXTENSIONS)), "]");

    glClearColor(0.0, 0.0, 1.0, 1.0);

    bool running = true;

    while(running)
    {
        SDL_Event event;
        while(SDL_PollEvent(&event))
        {
            switch(event.type)
            {
                case SDL_KEYDOWN:
                    if(SDLK_ESCAPE == event.key.keysym.sym)
                    {
                        running = false;
                    }
                    break;
                case SDL_QUIT:
                    running = false;
                    break;
                default:
                    break;

            }
        }
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        SDL_GL_SwapBuffers();
        SDL_Delay(1);
    }
}