#!/usr/bin/python3
 
#          Copyright Ferdinand Majerech 2010 - 2011.
# Distributed under the Boost Software License, Version 1.0.
#    (See accompanying file LICENSE_1_0.txt or copy at
#          http://www.boost.org/LICENSE_1_0.txt)


import os
import shutil


def zip_directory(directory):
    import zipfile
    zip_file = zipfile.ZipFile(directory + ".zip", "w", 
                               compression=zipfile.ZIP_DEFLATED)
    root_len = len(os.path.abspath(directory))
    for root, directories, files in os.walk(directory):
        archive_root = os.path.abspath(root)[root_len:]
        for f in files:
            fullpath = os.path.join(root, f)
            archive_name = os.path.join(archive_root, f)
            zip_file.write(fullpath, archive_name, zipfile.ZIP_DEFLATED)
    zip_file.close()

def tgz_directory(directory):
    import tarfile
    tar_file = tarfile.open(directory + ".tgz", "w:gz")
    tar_file.add(directory)
    tar_file.close()

def which(program):
    def is_exe(fpath):
        return os.path.exists(fpath) and os.access(fpath, os.X_OK)

    fpath, fname = os.path.split(program)
    if fpath:
        if is_exe(program):
            return program
    else:
        for path in os.environ["PATH"].split(os.pathsep):
            exe_file = os.path.join(path, program)
            if is_exe(exe_file):
                return exe_file
    return None

#run a command and return its return value
def run_cmd(cmd):
    import subprocess
    print (cmd)
    return subprocess.call(cmd, shell=True)


class InputError(Exception):
    pass

class CompileError(Exception):
    pass


class CDCManager:
    __supported_architectures = ["x86", "x64"]
    __architecture_switch = {"x86" : "-m32", "x64" : "-m64"}

    __compiler = None;
    __architectures = set();

    def __init__(self, compiler, architectures):
        if not compiler:
            if which("gdc"):
                compiler = "gdc"
            elif which("dmd"):
                compiler = "dmd"
            else:
                raise InputError("No compiler found or specified")
        else:
            if not which(compiler):
                raise InputError("Can't find compiler: ", compiler)
        self.__compiler = compiler

        if not len(architectures):
            architectures.add("x86")
            if self.__compiler == "gdc":
                architectures.add("x64")
        else:
            for arch in architectures:
                if not arch in self.__supported_architectures:
                    raise InputError("Unknown architecture: ", arch)
        self.__architectures = architectures

    def compile(self):
        binaries = []

        cdc_compile = self.__compiler + " cdc.d" +\
                      (" -o cdc" if self.__compiler == "gdc" else "")
        if run_cmd(cdc_compile):
            raise CompileError("Error compiling the CDC build script")

        for arch in self.__architectures:
            pong_compile = "./cdc " + self.__architecture_switch[arch]
            if run_cmd(pong_compile + " debug"):
                raise CompileError("Error compiling debug build for architecture: ", arch)
            if run_cmd(pong_compile + " release"):
                raise CompileError("Error compiling debug build for architecture: ", arch)
            binaries.append("pong-debug." + arch)
            shutil.move("pong-debug", binaries[-1])
            binaries.append("pong-release." + arch)
            shutil.move("pong-release", binaries[-1])

        return binaries


class Packager:
    __supported_formats = ["zip", "tgz"]
    __format_switch = {"zip" : zip_directory, "tgz" : tgz_directory}

    #CDCManager
    __manager = None

    __formats = set()

    def __init__(self, manager, formats):
        self.__manager = manager
        if not len(formats):
            formats.add("tgz")
        else:
            for f in formats:
                if not f in self.__supported_formats:
                    raise InputError("Unknown archive format: ", f)
        self.__formats = formats

    def package(self, name):
        binaries = self.__manager.compile()
        try:
            os.mkdir(name)
            for binary in binaries:
                shutil.move(binary, name)
            ignore = shutil.ignore_patterns("*~", "*.sw*")
            shutil.copytree("doc", os.path.join(name, "doc"), ignore=ignore)
            shutil.copytree("data", os.path.join(name, "data"), ignore=ignore)
            shutil.copytree("user_data", os.path.join(name, "user_data"), 
                            ignore=shutil.ignore_patterns("*~", "*.sw*", 
                                                          "screenshots", "logs"))
            shutil.copy("README.txt", name)
            shutil.copy("README.html", name)
            shutil.copy("style.css", name)
            shutil.copy("dpong_logo64.png", name)

            for f in self.__formats:
                self.__format_switch[f](name)

        except Exception as error:
            raise error
        finally:
            shutil.rmtree(name)


def help():
    print ("DPong Linux packaging script.\n"
           "Copyright (C) 2011 Ferdinand Majerech\n\n"
           "Creates a binary package that can be launched standalone\n"
           "from the current directory.\n"
           "Usage: package-linux.py [OPTIONS] PACKAGE_NAME\n"
           " -h --help          Display this help and exit.\n"
           " -c --compiler val  Compiler name to use, e.g. dmd.\n"
           "                    If not specified, the script will try to\n"
           "                    detect an installed compiler, gdc or dmd,\n"
           "                    with gdc taking priority if both are found.\n"
           " -a --arch     val  Specify architecture to compile for.\n"
           "                    At the moment, only 'x86' and 'x64' can be\n"
           "                    used. Can be specified multiple times to\n"
           "                    specify multiple architectures.\n"
           "                    Default is x86.\n"
           " -f --format   val  Specify archive format of the package.\n"
           "                    At the moment, only 'tgz' and 'zip' can be\n"
           "                    used. Can be specified more than once\n"
           "                    to specify multiple formats. Default is tgz.\n"
           "\n"
           "Example:\n"
           "    ./package-linux -c gdc -a x86 -a x64 -f zip -f tgz dpong-pkg\n"
           "\n"
           "This will compile an x86 and x64 builds of DPong using GDC, \n"
           "and will package them in dpong-pkg.zip and dpong-pkg.tgz .\n")


def main():
    import getopt
    import sys

    try:
        opts, args = getopt.getopt(sys.argv[1:],"hc:a:f:",
                                   ["help", "compiler=", "arch=", "format="])
    except getopt.GetoptError as error:
        print(error)
        help()
        sys.exit(1)


    compiler = None
    architectures = set()
    formats = set()

    for opt, arg in opts:
        if opt in ("-h", "--help"):
            help()
            sys.exit(0)
        elif(opt in ("-c", "--compiler")):
            compiler = arg;
        elif(opt in ("-a", "--arch")):
            architectures.add(arg)
        elif(opt in ("-f", "--format")):
            formats.add(arg)

    packager = None
    try:
        packager = Packager(CDCManager(compiler, architectures), formats)
    except InputError as error:
        print(error)
        help()
        sys.exit(1)

    if not len(args):
        help()
        sys.exit(1)

    try:
        packager.package(args[0])
    except CompileError as error:
        print(error)
        help()
        sys.exit(1)
    except OSError as error:
        print(error)
        help()
        sys.exit(1)
    except IOError as error:
        print(error)
        help()
        sys.exit(1)


if __name__ == '__main__':
    main()
