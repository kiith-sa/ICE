
//          Copyright Ferdinand Majerech 2011 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


module dgamevfs.test;


import dgamevfs._;


import std.algorithm;
import std.file;
import std.stdio;
import std.traits;
import std.typecons;


//collectException has some kind of bug (probably lazy expressions),
//so using this instead:
bool fail(D)(D dg) if(isDelegate!D)
{
    try{dg();}
    catch(VFSException e){return true;}
    return false;
}

bool testVFSFileInfo(VFSDir parent, string name, 
                       Flag!"exists" exists, Flag!"writable" writable)
{
    auto file = parent.file(name);
    if(file.path != parent.path ~ "/" ~ name)             {return false;}
    if(file.exists != exists || file.writable != writable){return false;}

    if(!exists && (!fail(&file.bytes) || !fail(&file.input))){return false;}
    if(exists && (fail(&file.bytes) || fail(&file.input)))   {return false;}
    return true;
}

bool testVFSFileRead(VFSDir parent, string name, string expected)
{
    auto file = parent.file(name);

    VFSFileInput refcountTestIn(VFSFileInput i){return i;}
    //read what we've written before
    {
        auto i = refcountTestIn(file.input);
        auto buf = new char[expected.length * 2];
        auto slice = i.read(cast(void[])buf);
        if(slice.length != file.bytes || cast(string)slice != expected)
        {
            return false;
        }
    }
    //should be automatically closed
    if(file.open){return false;}

    return true;
}

bool testVFSFileIO(VFSDir parent, string name, string data)
{
    auto file = parent.file(name);

    VFSFileOutput refcountTestOut(VFSFileOutput o){return o;}
    //write, this should create the file if it doesn't exist yet
    {
        auto o = refcountTestOut(file.output);
        o.write(cast(const void[])data);
    }
    //should be automatically closed
    if(file.open){return false;}

    if(fail(&file.bytes) || file.bytes != data.length || fail(&file.input))
    {
        return false;
    }

    if(!testVFSFileRead(parent, name, data))
    {
        return false;
    }

    return true;
}

bool testVFSFileSeek(VFSDir parent, string name)
{
    auto file = parent.file(name);
    {
        auto output = file.output;
        output.write(cast(const void[])"Teh smdert iz");
        if(!fail({output.seek(-4, Seek.Set);}) || 
           !fail({output.seek(4, Seek.End);}))
        {
            return false;
        }

        output.seek(0, Seek.Set);
        output.write(cast(const void[])"The");
        output.write(cast(const void[])" answaa");
        output.seek(-2, Seek.Current);
        output.write(cast(const void[])"er");
        output.seek(-2, Seek.End);
        output.write(cast(const void[])"is 42.");
    }
    {
        auto input = file.input;
        if(!fail({input.seek(-4, Seek.Set);}) || 
           !fail({input.seek(4, Seek.End);}))
        {
            return false;
        }
        
        auto buffer = new char[3];
        input.read(cast(void[])buffer);
        if(buffer != "The"){return false;}

        input.seek(-3, Seek.End);
        input.read(cast(void[])buffer);
        if(buffer != "42."){return false;}

        input.seek(0, Seek.Set);
        buffer = new char[file.bytes];
        input.read(cast(void[])buffer);
        if(buffer != "The answer is 42."){return false;}
    }
    return true;
}

bool testVFSDirInfo(VFSDir parent, string name, Flag!"exists" exists,
                      Flag!"writable" writable, Flag!"create" create)
{
    auto dir = parent.dir(name);
    if(dir.path != parent.path ~ "/" ~ name)            {return false;}
    if(dir.exists != exists || dir.writable != writable){return false;}
    if(!create){return true;}
    dir.create();
    if(!dir.exists){return false;}
    return true;
}

bool testVFSDirFiles(VFSDir dir, Flag!"deep" deep)
{
    foreach(file; dir.files(deep))
    {
        auto sepsAdded = count(file.path, '/') - count(dir.path, '/');
        if(sepsAdded < 1){return false;} 
        if(!file.exists){return false;}
    }
    return true;
}

bool testVFSDirDirs(VFSDir dir, Flag!"deep" deep)
{
    foreach(sub; dir.dirs(deep))
    {
        auto sepsAdded = count(sub.path, '/') - count(dir.path, '/');
        if(sepsAdded < 1){return false;} 
        if(!sub.exists){return false;}
    }
    return true;
}

bool testVFSDirContents(VFSDir dir, string[] expectedFiles, string[] expectedDirs, string glob = null)
{
    alias std.algorithm.remove remove;
    foreach(file; dir.files(Yes.deep, glob))
    {
        if(!canFind(expectedFiles, file.path))
        {
            writeln("FAILED file iteration (unexpected file ", file.path, ")");
            //Unexpected file.
            return false;
        }
        expectedFiles = remove!((string a){return a == file.path;})(expectedFiles);
    }
    foreach(sub; dir.dirs(Yes.deep, glob))
    {
        if(!canFind(expectedDirs, sub.path))
        {
            writeln("FAILED directory iteration (unexpected directory ", sub.path, ")");
            //Unexpected directory.
            return false;
        }
        expectedDirs = remove!((string a){return a == sub.path;})(expectedDirs);
    }
    if(expectedFiles.length > 0 || expectedDirs.length > 0)
    {
        writeln("FAILED file/directory iteration (unexpected files, dirs: ", 
                 expectedFiles, expectedDirs, ")");
        //Missing file/directory.
        return false;
    }
    return true;
}

bool testVFSDirGlob(VFSDir root)
{
    assert(root.path == "root");
    auto dirsCreate = ["fonts",
                       "fonts/ttf",
                       "fonts/otf",
                       "fonts/extra",
                       "shaders",
                       "shaders/extra",
                       "txt"];
    auto filesCreate = ["fonts/config.txt",
                        "fonts/ttf/a.ttf",
                        "fonts/ttf/info.txt",
                        "fonts/ttf/b.ttf",
                        "fonts/otf/a.otf",
                        "fonts/otf/otf.txt",
                        "fonts/extra/bitmapfont.png",
                        "shaders/extra/info.txt",
                        "shaders/extra/effect.frag",
                        "shaders/extra/effect.vert"];
    with(root)
    {
        foreach(subdir; dirsCreate)
        {
            dir(subdir).create();
        }
        foreach(subfile; filesCreate)
        {
            file(subfile).output.write(cast(const void[])"42"); 
        }

        //Containing font:
        auto fontDirs   = ["root/fonts", 
                           "root/fonts/ttf", 
                           "root/fonts/otf", 
                           "root/fonts/extra"];
        auto fontFiles  = ["root/fonts/config.txt",
                           "root/fonts/ttf/a.ttf",
                           "root/fonts/ttf/info.txt",
                           "root/fonts/ttf/b.ttf",
                           "root/fonts/otf/a.otf",
                           "root/fonts/otf/otf.txt",
                           "root/fonts/extra/bitmapfont.png"];

        //Containing extra:
        auto extraDirs  = ["root/fonts/extra", "root/shaders/extra"];
        auto extraFiles = ["root/fonts/extra/bitmapfont.png",
                           "root/shaders/extra/info.txt",
                           "root/shaders/extra/effect.frag",
                           "root/shaders/extra/effect.vert"];

        //Ending with ttf:
        auto ttfDirs    = ["root/fonts/ttf"];
        auto ttfFiles   = ["root/fonts/ttf/a.ttf", "root/fonts/ttf/b.ttf"];

        //Ending with .txt:
        auto txtDirs    = cast(string[])[];
        auto txtFiles   = ["root/fonts/config.txt", 
                           "root/fonts/ttf/info.txt", 
                           "root/fonts/otf/otf.txt",
                           "root/shaders/extra/info.txt"];

        //Containing tf:
        auto tfDirs     = ["root/fonts/ttf", "root/fonts/otf"];
        auto tfFiles    = ["root/fonts/ttf/a.ttf",
                           "root/fonts/ttf/info.txt",
                           "root/fonts/ttf/b.ttf",
                           "root/fonts/otf/a.otf",
                           "root/fonts/otf/otf.txt"];

        if(!testVFSDirContents(root, fontFiles,  fontDirs,  "*font*") ||
           !testVFSDirContents(root, extraFiles, extraDirs, "*extra*") ||
           !testVFSDirContents(root, ttfFiles,   ttfDirs,   "*ttf") ||
           !testVFSDirContents(root, txtFiles,   txtDirs,   "*.txt") ||
           !testVFSDirContents(root, tfFiles,    tfDirs,    "*tf*"))
        {
            return false;
        }
    }

    return true;
}

bool testVFSStream(VFSFile file)
{
    {
        auto output = VFSStream(file.output);

        auto buf = "42\n"; 
        output.writeExact(cast(void*)buf.ptr, buf.length);
        output.writefln("%d * %d == %d", 6, 9, 42);
    }
    if(file.open){return false;}

    {
        auto input = VFSStream(file.input, file.bytes);

        if(input.getc() != '4' || input.getc() != '2' || input.getc() != '\n')
        {
            return false;
        }
        auto line = input.readLine();
        if(line != "6 * 9 == 42")     {return false;}
        if(input.stream.available > 0){return false;}
    }
    if(file.open){return false;}

    return true;
}

bool testVFSDirMain(VFSDir root)
{
    //We expect these to be true from the start.
    if(!root.exists || !root.writable || root.path != "root"){return false;}

    string answer = "The answer is 42.";

    //Nonexistent file:
    if(!testVFSFileInfo(root, "file1", No.exists, Yes.writable) || 
       !testVFSFileIO(root, "file1", answer))
    {
        writeln("FAILED nonexistent file");
        return false;
    }

    //Direct file access: (file1 exists now)
    if(!testVFSFileInfo(root, "file1", Yes.exists, Yes.writable) ||
       !testVFSFileRead(root, "file1", answer))
    {
        writeln("FAILED existing file");
        return false;
    }

    //Invalid file paths:
    if(!fail({root.file("a::c");}) || !fail({root.file("nonexistent_subdir/file");}))
    {
        writeln("FAILED invalid file paths");
        return false;
    }

    //Creating subdirectories:
    if(!testVFSDirInfo(root, "sub1", No.exists, Yes.writable, Yes.create) ||
       !testVFSDirInfo(root, "sub1/sub2", No.exists, Yes.writable, Yes.create))
    {
        writeln("FAILED creating subdirectories");
        return false;
    }
    foreach(char c; 'A' .. 'Z')
    {
        auto name = "sub1/sub2/sub" ~ c;
        if(!testVFSDirInfo(root, name, No.exists, Yes.writable, Yes.create))
        {
            writeln("FAILED creating many subdirectories");
            return false;
        }
        auto sub = root.dir(name);
        foreach(char f; '1' .. '9')
        {
            auto fname = "file" ~ f;
            if(!testVFSFileInfo(sub, fname, No.exists, Yes.writable) || 
               !testVFSFileIO(sub, fname, answer))
            {
                writeln("FAILED creating files in subdirectories");
                return false;
            }        
        }
    }

    //File in a subdirectory:
    if(!testVFSFileInfo(root, "sub1/sub2/subN/file5", Yes.exists, Yes.writable) ||
       !testVFSFileIO(root, "sub1/sub2/subN/file5", answer))
    {
        writeln("FAILED file in a subdirectory");
        return false;
    }

    //Seeking:
    if(!testVFSFileSeek(root, "seek_test"))
    {
        writeln("FAILED file seeking");
        return false;
    }

    //Subdirectory:
    {
        auto sub = root.dir("subdir");
        //sub doesn't exist yet:
        if(!fail({sub.file("file");}))
        {
            writeln("FAILED subdirectory file/dir access");
            return false;
        }
        sub.create();
        //Now it exists:
        if(fail({sub.file("file");}))
        {
            writeln("FAILED subdirectory file/dir access");
            return false;
        }
        //Looking for a file in a subdir of sub that doesn't exist:
        if(!fail({sub.file("subdir2/file");}))
        {
            writeln("FAILED subdirectory file/dir access");
            return false;
        }
    }

    //files()/dirs():
    if(!testVFSDirFiles(root, No.deep) || !testVFSDirFiles(root, Yes.deep) ||
       !testVFSDirDirs(root, No.deep)  || !testVFSDirDirs(root, Yes.deep))
    {
        writeln("FAILED file/directory iteration");
        return false;
    }

    //Globbing:
    if(!testVFSDirGlob(root))
    {
        writeln("FAILED globbing");
        return false;
    }
 
    //created before
    auto sub = root.dir("sub1");
    //files()/dirs() from a subdir:
    if(!testVFSDirFiles(sub, No.deep) || !testVFSDirFiles(sub, Yes.deep) ||
       !testVFSDirDirs(sub, No.deep)  || !testVFSDirDirs(sub, Yes.deep))
    {
        writeln("FAILED file/directory iteration in a subdirectory");
        return false;
    }

    //We added some files to subdirs, so files().length should be less that files(Yes.deep).length:
    if(root.files().length >= root.files(Yes.deep).length || 
       root.dirs().length >= root.dirs(Yes.deep).length)
    {
        writeln("FAILED file/directory iteration item count");
        return false;
    }

    //Nonexistent dir:
    {
        auto dir = root.dir("nonexistent");
        if(!fail({dir.file("file");}) ||
           !fail({dir.dir("dir");})   ||
           !fail({dir.files();})      ||
           !fail({dir.dirs();}))
        {
            writeln("FAILED nonexistent directory");
            return false;
        }
    }

    //VFSStream:
    if(!testVFSStream(root.file("stream")))
    {
        writeln("FAILED VFSStream");
        return false;
    }

    return true;
}

bool testMemoryDir()
{
    auto memoryDir = new MemoryDir("root");
    //basic info methods
    if(!memoryDir.writable || memoryDir.exists ||
       memoryDir.path != memoryDir.name || memoryDir.path != "root")
    {
        writeln("FAILED MemoryDir info");
        return false;
    }

    //create
    memoryDir.create();
    if(!memoryDir.exists)
    {
        writeln("FAILED MemoryDir create");
        return false;
    }

    if(!testVFSDirMain(memoryDir))
    {
        writeln("FAILED MemoryDir general");
        return false;
    }

    //remove
    memoryDir.dir("subdir").create();
    memoryDir.remove();
    if(memoryDir.exists)
    {
        writeln("FAILED memoryDir remove");
        return false;
    }
    return true;
}

bool testStackDirMount()
{
    auto cycle1 = new StackDir("cycle1");
    auto cycle2 = new StackDir("cycle2");
    cycle1.mount(cycle2);
    if(!fail({cycle2.mount(cycle1);}))
    {
        writeln("FAILED circular mounting");
        return false;
    }

    auto parent = new StackDir("parent");
    auto child  = new MemoryDir("child");
    auto main   = new StackDir("main");
    parent.mount(child);
    if(fail({main.mount(child);}))
    {
        writeln("FAILED mounting a dir with parent");
        return false;
    }

    auto child2 = new StackDir("child");
    if(!fail({parent.mount(child2);}))
    {
        writeln("FAILED mounting a dir with same name");
        return false;
    } 

    return true;
}

bool testStackDirStacking()
{
    //Initialize directory structure:
    auto mainPkg = new MemoryDir("main");
    with(mainPkg)
    {
        create();
        dir("fonts").create();
        dir("fonts/ttf").create();
        dir("fonts/otf").create();
        file("fonts/ttf/a.ttf").output.write(cast(const void[])"42");
        file("fonts/otf/b.otf").output.write(cast(const void[])"42");
        dir("logs").create();
        dir("shaders").create();
        file("shaders/font.vert").output.write(cast(const void[])"42");
        file("shaders/font.frag").output.write(cast(const void[])"42");
        writable = false;
    }

    auto userPkg = new MemoryDir("user");
    with(userPkg)
    {
        create();
        dir("fonts").create();
        dir("fonts/ttf").create();
        file("fonts/ttf/a.ttf").output.write(cast(const void[])"42");
        dir("logs").create();
        dir("shaders").create();
        dir("maps").create();
    }

    auto modPkg = new MemoryDir("mod");
    auto modLog = "mod/logs/memory.log";
    with(modPkg)
    {
        create();
        dir("logs").create();
        dir("shaders").create();
        file("shaders/font.vert").output.write(cast(const void[])"42");
        file("logs/memory.log").output.write(cast(const void[])modLog);
        writable = false;
    }

    auto stackDir = new StackDir("root");
    stackDir.mount(mainPkg);
    stackDir.mount(userPkg);
    stackDir.mount(modPkg);

    if(!stackDir.writable || !stackDir.exists)
    {
        writeln("FAILED stackdir info");
        return false;
    }

    //File/dir access:
    {
        //Should find the right file to get bytes() and read from:
        if(!testVFSFileRead(stackDir.dir("logs"), "memory.log", modLog))
        {
            writeln("FAILED stackdir read");
            return false;
        }
        //This should write to the "user" package.
        stackDir.dir("logs").file("memory.log").output.write(cast(const void[])"out");
        //This should read from the "mod" package
        if(!testVFSFileRead(stackDir.dir("logs"), "memory.log", modLog))
        {
            writeln("FAILED stackdir read shadowing written");
            return false;
        }
        if(!testVFSFileRead(stackDir.dir("user::logs"), "memory.log", "out"))
        {
            writeln("FAILED stackdir explicitly read written");
            return false;
        }
    }

    //File/dir iteration:
    auto expectedFiles = ["root/logs/memory.log",
                           "root/shaders/font.vert",
                           "root/shaders/font.frag",
                           "root/fonts/ttf/a.ttf",
                           "root/fonts/otf/b.otf"];
    auto expectedDirs  = ["root/logs",
                           "root/shaders",
                           "root/maps",
                           "root/fonts",
                           "root/fonts/ttf",
                           "root/fonts/otf"];
    if(!testVFSDirContents(stackDir, expectedFiles, expectedDirs))
    {
            writeln("FAILED file/directory iteration");
            return false;
    }

    expectedFiles = ["root/fonts/ttf/a.ttf",
                      "root/fonts/otf/b.otf"];
    expectedDirs =  ["root/fonts/ttf",
                      "root/fonts/otf"];
    if(!testVFSDirContents(stackDir.dir("fonts"), expectedFiles, expectedDirs))
    {
            writeln("FAILED file/directory iteration in a subdirectory");
            return false;
    }

    return true;
}

bool testStackDir()
{
    //General:
    {
        auto mainPkg = new MemoryDir("main");
        auto userPkg = new MemoryDir("user");
        auto stackDir = new StackDir("root");
        stackDir.mount(mainPkg);
        stackDir.mount(userPkg);

        //basic info methods
        if(!stackDir.writable || stackDir.exists ||
           stackDir.path != stackDir.name || stackDir.path != "root")
        {
            writeln("FAILED StackDir info");
            return false;
        }

        //create
        stackDir.create();
        if(!stackDir.exists)
        {
            writeln("FAILED StackDir create");
            return false;
        }

        if(!testVFSDirMain(stackDir))
        {
            writeln("FAILED StackDir general");
            return false;
        }

        //remove
        stackDir.dir("subdir").create();
        stackDir.remove();
        if(stackDir.exists)
        {
            writeln("FAILED stackDir remove");
            return false;
        }
    }

    //Mounting:
    if(!testStackDirMount())
    {
        writeln("FAILED StackDir mount");
        return false;
    }

    //Stacking:
    if(!testStackDirStacking())
    {
        writeln("FAILED StackDir stacking");
        return false;
    }

    return true;
}

bool testFSDir()
{
    auto path = "testFSDir";
    if(exists(path)){rmdirRecurse(path);}
    mkdir(path);
    scope(exit){rmdirRecurse(path);}

    auto fsDir = new FSDir("root", path ~ "/root", Yes.writable);
    //basic info methods
    if(!fsDir.writable || fsDir.exists ||
       fsDir.path != fsDir.name || fsDir.path != "root")
    {
        writeln(cast(bool)fsDir.writable, " ", fsDir.exists, " ", 
                fsDir.path, " ", fsDir.name);
        writeln("FAILED FSDir info");
        return false;
    }

    //create
    fsDir.create();
    if(!fsDir.exists)
    {
        writeln("FAILED FSDir create");
        return false;
    }

    if(!testVFSDirMain(fsDir))
    {
        writeln("FAILED FSDir general");
        return false;
    }

    //remove
    fsDir.dir("subdir").create();
    fsDir.remove();
    if(fsDir.exists)
    {
        writeln("FAILED FSDir remove");
        return false;
    }

    return true;
}

unittest
{
    writeln("---------- ",
            testMemoryDir() ? "SUCCESS" : "FAILURE",
            " MemoryDir unittest ", "----------");
    writeln("---------- ",
            testStackDir() ? "SUCCESS" : "FAILURE",
            " StackDir unittest ", "----------");
    writeln("---------- ",
            testFSDir() ? "SUCCESS" : "FAILURE",
            " FSDir unittest ", "----------");
}

void main()
{
    writeln("Done");
}
