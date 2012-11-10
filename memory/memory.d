
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Manual memory management functions.
module memory.memory;


import core.stdc.stdlib;
import core.stdc.string;

import core.memory;

import std.algorithm;
import std.conv;
import std.stdio;
import std.string;
import std.traits;

import dgamevfs._;

import time.time;
import util.unittests;


public:
    /**
     * Allocate space for and optionally initialize a primitive value or struct.
     *
     * For now, if allocating a struct, that struct must not have its empty 
     * constructor disabled.
     *
     * Note: 
     * 
     * Some types, such as unions, can't be initialized since their default 
     * initializer (T.init) is ambiguous. Data of such types can still be 
     * initialized to zero bytes by adding an "annotation" static variable to 
     * the type, like in this example:
     *
     * Example:
     * --------------------
     * struct ZeroInitialized
     * {
     *     static bool CAN_INITIALIZE_WITH_ZEROES;
     *     union 
     *     {
     *         int i;
     *         float f;
     *     }
     * }
     * --------------------
     *
     * Params:  args = Arguments to value's initializer/constructor.
     *                 If no arguments are specified, the value is default-initialized.
     *
     * Returns: Pointer to allocated struct.
     */
    T* alloc(T, string file = __FILE__, uint line = __LINE__, Args ...)(Args args) 
        if(!is(T == class)) 
    {
        return allocateSingle!(T, file, line, Args)(args);
    }

    ///Free an object (struct) allocated by alloc(). Will clear the object.
    void free(T)(T* ptr)
        if(!is(T == class))
    {
        deallocate(ptr);
    }
    ///Unittest for alloc() and free calling dtor.
    void unittestSingle()
    {
        writeln("memory.memory struct alloc()/free() unittest");
        scope(success){writeln("test passed");}
        scope(failure){writeln("test FAILED");}
        static struct Test
        {
            static bool dead = false;
            int a, b;

            this(int a, int b)
            {
                this.a = a;
                this.b = b;
            }

            ~this(){dead = true;}
        }
        int* integer = alloc!int;
        int* integer2 = alloc!int(8);
        free(integer);
        free(integer2);
        Test* test = alloc!Test(12, 13);
        Test* test2 = alloc!Test;
        assert(*test == Test(12,13) && *test2 == Test(0, 0));
        free(test);
        assert(Test.dead == true);
        Test.dead = false;
        free(test2);
        assert(Test.dead == true);
    }
    mixin registerTest!(unittestSingle, "Single object allocation");
    /**
     * Allocate an array of specified type. 
     *
     * Arrays allocated with alloc must NOT be resized.
     *
     * Params:  elems = Number of objects to allocate space for.
     *
     * Returns: Allocated array. Values in the array are default-initialized.
     */
    T[] allocArray(T, string file = __FILE__, uint line = __LINE__)(const size_t elems)
    {
        return allocate!(T, file, line)(elems);
    }

    /**
     * Reallocate an array allocated by alloc() .
     *
     * Contents of the array are preserved but array itself might be moved in memory,
     * invalidating any pointers pointing to it.
     *
     * If the array is shrunk and of non-reference type (e.g. not a class), 
     * any extra elements are cleared (if they have destructors, they're called).
     *
     * Params:  array = Array to reallocate.
     *          elems = Number of objects for the reallocated array to hold.
     *
     * Returns: Reallocated array.
     */
    T[] realloc(T, string file = __FILE__, uint line = __LINE__)(T[] array, const size_t elems)
    {
        return reallocate!(T, file, line)(array, elems);
    }

    /**
     * Free an array of objects allocated by alloc(). 
     *
     * If the array is of non-reference type (e.g. not a class), array elements 
     * are cleared (if they have destructors, they're called).
     *
     * Params: array = Array to free.
     */
    void free(T)(T[] array){deallocate(array);}
    ///Unittest for allocArray(), realloc() and free().
    void unittestArray()
    {
        writeln("memory.memory allocArray()/realloc()/free() unittest");
        scope(success){writeln("test passed");}
        scope(failure){writeln("test FAILED");}
        uint[] test = allocArray!uint(5);
        assert(test.length == 5 && test[3] == 0);
        test[3] = 5;
        test = realloc(test, 4);
        assert(test.length == 4 && test[3] == 5);
        test = realloc(test, 8);
        assert(test.length == 8 && test[3] == 5 && test[7] == 0);
        free(test);
    }
    mixin registerTest!(unittestArray, "Array allocation");

    ///VFSDir to output memory log to.
    VFSDir gameDir;

    ///Debug info is only recorded after main() is entered.
    ///
    ///There seems to be a bug with dynamic array appending
    ///before main() (e.g. in unittests).
    /// 
    ///TODO revisit this when a new DMD (currently 2.060) is released
    bool suspendMemoryDebugRecording = true;

package:
    ///Get currently allocated memory in bytes.
    ulong currentlyAllocated(){return currentlyAllocated_;}

private:
    ///Total memory manually allocated over the whole run of the program, in bytes.
    ulong totalAllocated_ = 0;
    ///Total memory manually freed over the whole run of the program, in bytes.
    ulong totalFreed_ = 0;
    ///Currently allocated memory, in bytes.
    ulong currentlyAllocated_ = 0;

    /**
     * Struct holding information about a memory allocation.
     *
     * Holds detailed information about the allocation
     * and takes 80 bytes on 64-bit, 76 bytes on 32-bit.
     */
    struct Allocation
    {
        static assert(Allocation.sizeof <= 80, 
                      "Unexpected size of the Allocation struct");
        private:
            ///Number of objects allocated.
            uint objects_;
            ///Line number where the allocation happened.
            ushort line_;
            ///Time, in hectomicroseconds since start, when the allocation happened.
            uint time_;
            ///Bytes per object.
            ushort objectBytes_;
            ///Last characters of the object type name.
            char[28] type_ = "                            ";
            ///Last characters of the file name where the allocation happened.
            char[24] file_ = "                        ";
       
            ///Time when the program started.
            static real startTime_;

        public:
            ///Pointer to the allocated memory.
            void* ptr;

        public:
            /**
             * Construct an Allocation info object.
             *
             * Template parameters specify data type allocated,
             * file and line where the allocation happened.
             *
             * Params:
             *      ptr     = Pointer to allocated memory.
             *      objects = Number of objects allocated.
             *
             * Returns: Constructed Allocation.
             */
            static Allocation construct(T, string file, uint line) 
                                       (const T* ptr, const size_t objects)
            {
                Allocation a;

                static if(file.length > 24){a.file_[0 .. 24] = file[$ - 24 .. $];}
                else{a.file_[0 .. file.length] = file[];}
                a.line_ = line;
                a.objectBytes_ = T.sizeof;

                enum type = T.stringof;
                static if(type.length > 28){a.type_[0 .. 28] = type[$ - 28 .. $];}
                else{a.type_[0 .. type.length] = type[];}

                a.objects_ = objects > uint.max ? uint.max : cast(uint)objects;
                a.time_ = cast(uint)(10000.0 * (getTime() - startTime_));

                a.ptr = cast(void*)ptr;

                return a;
            }

            ///Get information string about the allocation (encoded in YAML).
            string info(const ubyte indentWidth)
            {
                static char[256] spaces;
                spaces[] = ' ';
                string indent = cast(string)spaces[0 .. indentWidth];
                string meta = "";

                meta ~= indent ~ "- __FILE__: '" ~ strip(cast(char[])file_)           ~ "'\n";

                meta ~= indent ~ "  __LINE__: "  ~ to!string(line_)                   ~ "\n";
                meta ~= indent ~ "  type    : '" ~ strip(cast(char[])type_)           ~ "'\n";
                meta ~= indent ~ "  objects : "  ~ to!string(objects_)                ~ "\n";
                meta ~= indent ~ "  bytes   : "  ~ to!string(objects_ * objectBytes_) ~ "\n";
                meta ~= indent ~ "  time    : "  ~ to!string(time_ * 0.0001)          ~ "\n";
                meta ~= indent ~ "  ptr     : ";

                return meta ~ to!string(ptr);
            }

        private:
            ///Static constructor - set start time.
            static this(){startTime_ = getTime();}
    }

    ///Information about allocations that have been freed.
    Allocation[] pastAllocations_;

    //set (RB tree) might work better if there are performance problems
    ///Information about current allocations.
    Allocation[] allocations_;

    /**
     * Allocate and initialize a primitive value or struct.
     *
     * Params:  args = Parameters for the values' constructor/initializer.
     *                 If not specified, the value is default-initialized.
     *
     * Returns: Pointer to the allocated struct.
     */
    T* allocateSingle(T, string file, uint line, Args ...)(Args args)
    {
        const bytes = T.sizeof;

        T* ptr;

        scope(failure)
        {
            writeln("allocate_single!" ~ typeid(T).toString ~ " at " ~ file ~
                    " : " ~ to!string(line) ~ " failed");
            deallocate(ptr);
        }

        ptr = cast(T*)malloc(bytes);
        debugAllocate!(T, file, line)(ptr, 1); 

        enum zeroInit = __traits(hasMember, T, "CAN_INITIALIZE_WITH_ZEROES");
        static if(args.length == 0)
        {
            static init = T.init;
            memcpy(cast(void*)ptr, cast(void*)&init, T.sizeof);
        }
        else static if(zeroInit)
        {
            memset(cast(void*)ptr, 0, T.sizeof);
        }
        else                       
        {
            emplace(ptr, args);
        }

        static if(hasIndirections!T){GC.addRange(cast(void*)ptr, T.sizeof);}

        return ptr;
    }

    /**
     * Allocate and default-initialize an array with given number of elements.
     *
     * Arrays returned by allocate() must NOT be resized.
     *
     * Params:  elems = Number of objects for the array to hold.
     * 
     * Returns: Allocated array.
     */
    T[] allocate(T, string file, uint line)(const size_t elems)
    out(result)
    {
        assert(result.length == elems, "Failed to allocate space for "
                                       "specified number of elements");
    }
    body
    {
        const bytes = T.sizeof * elems;

        T[] array;

        scope(failure)
        {
            writeln("allocate!" ~ typeid(T).toString ~ " at " ~ file ~
                    " : " ~ to!string(line) ~ " failed");
            deallocate(array);
        }

        array = (cast(T*)malloc(bytes))[0 .. elems];

        debugAllocate!(T, file, line)(array.ptr, elems); 
        static if(hasIndirections!T)
        {
            GC.addRange(cast(void*)array.ptr, T.sizeof * array.length);
        }

        enum zeroInit = __traits(hasMember, T, "CAN_INITIALIZE_WITH_ZEROES");

        //default-initialize the array.
        //using memset for ubytes as it's faster and ubytes are often used for large arrays.
        static if (is(T == ubyte) || zeroInit)
        {
            memset(array.ptr, 0, bytes);
        }
        else foreach(ref item; array)
        {
            static init = T.init;
            memcpy(cast(void*)&item, cast(void*)&init, T.sizeof);
        }

        return array;
    }

    /**
     * Reallocate an array allocated with allocate().
     *
     * Array data might move around the memory, invalidating any pointers to it.
     * Any added elements are default-initialized. Any removed elements are cleared.
     *
     * Params:  array = Array to reallocate.
     *          elems = Number of elements for the reallocated array to hold.
     *
     * Returns: Reallocated array.
     */
    T[] reallocate(T, string file, uint line)(T[] array, const size_t elems)
    in
    {
        debug
        {
        if(!suspendMemoryDebugRecording)
        {
        //must be in a separate function due to a compiler bug
        bool match(ref Allocation a){return a.ptr == cast(void*)array.ptr;}
        assert(canFind!match(allocations_),
               "Trying to free a pointer that isn't allocated (or has been freed)");
        }
        }
    }
    body
    {
        const oldBytes = T.sizeof * array.length;
        const newBytes = T.sizeof * elems;
        T* oldPtr = array.ptr;
        const oldLength = array.length;
                  
        //if we're shrinking, destroy extra elements unless this is 
        //an array of pointers or reference types.
        static if(hasElaborateDestructor!T) 
        {
            if(oldLength > elems) foreach(ref T elem; array[elems .. $])
            {
                clear(elem);
            }
        }

        static if(hasIndirections!T)
        {
            GC.removeRange(cast(void*)array.ptr);
        }
        array = (cast(T*)core.stdc.stdlib.realloc(cast(void*)array.ptr, newBytes))[0 .. elems];
        static if(hasIndirections!T)
        {
            GC.addRange(cast(void*)array.ptr, T.sizeof * array.length);
        }

        debugReallocate!(T, file, line)(array.ptr, array.length, oldPtr, oldLength); 

        //default-initialize new elements, if any
        if(array.length > oldLength)
        {
            enum zeroInit = __traits(hasMember, T, "CAN_INITIALIZE_WITH_ZEROES");
            //using memset for ubytes as it's faster and ubytes are often used for large arrays.
            static if (is(T == ubyte) || zeroInit)
            {
                memset(array.ptr + oldLength, 0, newBytes - oldBytes);
            }
            else if(array.length > oldLength) 
            {
                foreach(ref item; array[oldLength .. $])
                {
                    static init = T.init;
                    memcpy(cast(void*)&item, cast(void*)&init, T.sizeof);
                }
            }
        }
        return array;
    }

    ///Free an object allocated by allocate(). If a destructor is defined, it will be called.
    void deallocate(T)(ref T* ptr)
    in
    {
        debug
        {
        if(!suspendMemoryDebugRecording)
        {
        //must be in a separate function due to a compiler bug
        bool match(ref Allocation a){return a.ptr == cast(void*)ptr;}
        assert(canFind!match(allocations_),
               "Trying to free a pointer that isn't allocated (or has been freed): " ~
               to!string(ptr));
        }
        }
    }
    body
    {
        //call dtor for structs
        clear(*ptr);

        debugFree(ptr, 1); 

        static if(hasIndirections!T){GC.removeRange(cast(void*)ptr);}

        core.stdc.stdlib.free(ptr);
    }

    /**
     * Free an array allocated by allocate().
     *
     * If a destructor is defined for the array's type and the array doesn't hold
     * pointers or reference types, the destructor will be called for every object in the array.
     *
     * Params:  array = Array to deallocate.
     */
    void deallocate(T)(ref T[] array)
    in
    {
        //must be in a separate function due to a compiler bug
        debug
        {
        if(!suspendMemoryDebugRecording)
        {
        bool match(ref Allocation a){return a.ptr == cast(void*)array.ptr;}
        assert(canFind!match(allocations_),
               "Trying to free a pointer that isn't allocated (or has been freed): " ~
               to!string(array.ptr));
        }
        }
    }
    body
    {
        const bytes = T.sizeof * array.length;

        //destroy the elements unless this is an array of pointers or reference types.
        static if (hasElaborateDestructor!T) foreach(ref T elem; array)
        {
            clear(elem);
        }

        debugFree(array.ptr, array.length); 

        static if(hasIndirections!T)
        {
            GC.removeRange(cast(void*)array.ptr);
        }

        core.stdc.stdlib.free(array.ptr);
    }

    ///Return a string containing statistics about allocated memory.
    string statistics()
    {
        string stats = "#Memory allocator statistics:";
        stats ~= "\nTotal allocated bytes: " ~ to!string(totalAllocated_);
        stats ~= "\nTotal freed bytes    : " ~ to!string(totalFreed_);
        stats ~= "\nMemory debug bytes   : " ~ 
                 to!string(Allocation.sizeof *
                           (allocations_.length + pastAllocations_.length));

        const nonFreed = allocations_.length;
        stats ~= nonFreed ? "\n#LEAK: " ~ to!string(nonFreed) ~ " pointers were not freed."
                          : "\n#All pointers have been freed, no memory leaks detected.";
        stats ~= "\n\n\n";

        stats ~= "Allocations:";
        foreach(ref allocation; allocations_)
        {
            stats ~= "\n\n" ~ allocation.info(2) ~ "\n    freed   : false";
        }
        foreach(ref allocation; pastAllocations_)
        {
            stats ~= "\n\n" ~ allocation.info(2) ~ "\n    freed   : true";
        }

        return stats;
    }

    ///Write out allocator statistics at program exit.
    static ~this()
    {
        scope(failure){writeln("Error logging memory usage");}

        writeln("Collecting memory usage profile...");
        string stats = statistics();
        writeln("Writing memory usage profile...");

        auto logs = gameDir.dir("main::logs");
        logs.create();
        logs.file("memoryLog.yaml").output.write(cast(void[]) stats);

        if(allocations_.length > 0)
        {
            writeln("WARNING: MEMORY LEAK DETECTED, FOR MORE INFO SEE:\n"
                     "user_data::main::logs/memory.log");
        }
    }

    /**
     * Record data about an allocation.
     * 
     * Params:  ptr     = Pointer to the allocated memory.
     *          objects = Number of objects allocated.
     */
    void debugAllocate(T, string file, uint line)(const T* ptr, const size_t objects)
    {
        if(suspendMemoryDebugRecording){return;}
        auto allocation = Allocation.construct!(T, file, line)(ptr, objects);
        allocations_.assumeSafeAppend();
        allocations_ ~= allocation;

        const bytes = objects * T.sizeof;
        totalAllocated_ += bytes;
        currentlyAllocated_ += bytes;
    }

    //not the best way to go about recording reallocs, but sufficient for now
    /**
     * Record data about a reallocation.
     * 
     * Params:  newPtr     = Pointer to the reallocated memory.
     *          newObjects = Number of objects in reallocated memory.
     *          oldPtr     = Pointer to original memory.
     *          oldObjects = Number of objects in original memory.
     */
    void debugReallocate(T, string file, uint line)
                         (const T* newPtr, const size_t newObjects,
                          const T* oldPtr, const size_t oldObjects)
    {
        if(suspendMemoryDebugRecording){return;}
        //find and replace allocation info corresponding to reallocated data
        bool found = false;
        foreach(ref allocation; allocations_) if(allocation.ptr == oldPtr)
        {
            pastAllocations_.assumeSafeAppend();
            pastAllocations_ ~= allocation;
            //replace allocation info
            allocation = Allocation.construct!(T, file, line)(newPtr, newObjects);
            found = true;
            break;
        }
        assert(found, "No match found for a pointer to reallocate");

        const oldBytes = oldObjects * T.sizeof;
        const newBytes = newObjects * T.sizeof;
        const diff = newBytes - oldBytes;
        totalAllocated_ += diff;
        currentlyAllocated_ += diff;
    }

    /**
     * Record data about a deallocation.
     * 
     * Params:  ptr     = Pointer to deallocated memory.
     *          objects = Number of objects deallocated.
     */
    void debugFree(T)(const T* ptr, const size_t objects)
    {
        if(suspendMemoryDebugRecording){return;}
        //remove allocation info
        bool found = false;
        foreach(ref allocation; allocations_) if(allocation.ptr == ptr)
        {
            pastAllocations_.assumeSafeAppend();
            pastAllocations_ ~= allocation;
            //remove by rewriting by the last allocation
            allocation = allocations_[$ - 1];
            found = true;
            break;
        }
        assert(found, "No match found for pointer to free");
        allocations_ = allocations_[0 .. $ - 1];

        const bytes = objects * T.sizeof;
        totalFreed_ += bytes;
        currentlyAllocated_ -= bytes;
    }
