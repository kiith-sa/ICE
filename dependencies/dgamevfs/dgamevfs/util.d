//          Copyright Ferdinand Majeatabase/D/rech 2011 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


//Utility functions used by D:GameVFS.
module dgamevfs.util;


import std.algorithm;
import std.array;
import std.path;

import dgamevfs.exceptions;


//Is a file/directory name valid (i.e. no directory or package separators)?
bool noSeparators(string name) pure @trusted nothrow
{
    return !name.canFind("/") && !name.canFind("::");
}

//Are there no package separators in the path?
bool noPackageSeparators(string path) pure @trusted nothrow
{
    return !path.canFind("::");
}

//Clean any leading "./" and trailing "/" from a filesystem path, and replace "\" by "/".
string cleanFSPath(string path)
{
    while(path.startsWith("./")){path = path[2 .. $];}
    while(path.endsWith("/")){path = path[0 .. $ - 1];}
    return path.replace("\\", "/");
}

/*
 * If a path starts by a package, return it.
 *
 * Params:  path = Path to parse.
 *          rest = Rest of the path (beyond the package separator)
 *                 will be written here if the path starts by a package.
 *                 Otherwise this will be empty.
 *
 * Returns: Package the path starts with, if any. null otherwise.
 */
string expectPackage(string path, out string rest) pure @trusted nothrow
{
    auto parts = path.findSplit("::");
    //No package separator.
    if(parts[2].length == 0){return null;}
    //Package separator, but in a subdir.
    if(parts[0].canFind("/")){return null;}

    rest = parts[2];
    return parts[0];
}

/*
 * If a path starts by a subdirectory, return it.
 *
 * Params:  path = Path to parse.
 *          rest = Rest of the path (beyond the directory separator)
 *                 will be written here if the path starts by a subdirectory.
 *                 Otherwise this will be empty.
 *
 * Returns: Subdirectory the path starts with, if any. null otherwise.
 *
 * Throws:  VFSInvalidPathException if a package separator is found in the directory name.
 */
string expectSubdir(string path, out string rest) @trusted
{
    auto parts = path.findSplit("/");
    //No directory separator.
    if(parts[2].length == 0){return null;}
    //Package separator in a directory name.
    if(parts[0].canFind("::"))
    {
        throw invalidPath("Unexpected package separator found in path: ", path);
    }

    rest = parts[2];
    return parts[0];
}

/**
 * Match path of a directory or a file relative to a parent directory with
 * a glob pattern.
 *
 * Params:  path       = Path of the file/directory.
 *          parentPath = Path of the parent directory.
 *          glob       = Glob pattern to match with. If null, a match is assumed.
 *
 * Returns: True on match or if glob is null; false otherwise.
 */
bool subPathMatch(string path, string parentPath, string glob) pure @safe
{
    if(glob is null){return true;}
    auto relative = path;
    relative.skipOver(parentPath);
    relative.skipOver("/");
    return globMatch(relative, glob);
}
