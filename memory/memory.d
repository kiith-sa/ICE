
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module memory.memory;


import std.c.stdlib;
import std.c.string;

import std.stdio;
import std.string;

import file.fileio;
import containers.array;


public:
    ///Allocate an object of a basic type, or a struct/class with default values.
    T* alloc(T)(){return allocate!(T)();}

    template alloc_struct(T)
    {
        /**
         * Allocate a struct with specified parameters to structs' initializer.
         *
         * Params:  args = Arguments to structs' initializer.
         *
         * Returns: Pointer to allocated memory.
         */
        T* alloc_struct(Args...)(Args args){return allocate_struct!(T, Args)(args);}
    }

    ///Free an object allocated by alloc(). Will call die() method if defined.
    void free(T)(T* ptr){deallocate(ptr);}
    ///Unittest for alloc_struct() and die().
    unittest
    {
        struct Test
        {
            static bool dead = false;
            int a, b;

            static Test opCall(int a, int b)
            {
                Test t;
                t.a = a;
                t.b = b;
                return t;
            }

            void die(){dead = true;}
        }

        Test* test = alloc_struct!(Test)(12, 13);
        assert(*test == Test(12,13));
        free(test);
        assert(Test.dead == true);
    }

    /**
     * Allocate an array of objects. 
     *
     * Arrays allocated with alloc must NOT be resized.
     *
     * Params:  elems = Number of objects to allocate space for.
     *
     * Returns: Allocated array.
     */
    T[] alloc(T)(ulong elems){return allocate!(T)(elems);}

    /**
     * Reallocate an array allocated by alloc() .
     *
     * Contents of the array are preserved but array itself might be moved in memory,
     * invalidating any pointers pointing to it.
     *
     * If the array is shrunk, any extra elements defining a die() method that
     * are not pointers or reference types (classes) will have that method called.
     *
     * Params:  array = Array to reallocate.
     *          elems = Number of objects for the reallocated array to hold.
     *
     * Returns: Reallocated array.
     */
    T[] realloc(T)(T[] array, ulong elems){return reallocate!(T)(array, elems);}

    /**
     * Free an array of objects allocated by alloc(). 
     *
     * If the type defines a die() method and is not a pointer or reference type
     * (e.g. class), that method will be called for all elements of the array.
     *
     * Params: array = Array to free.
     */
    void free(T)(T[] array){deallocate(array);}
    ///Unittest for alloc(), realloc() and free().
    unittest
    {
        uint[] test = alloc!(uint)(5);
        assert(test.length == 5 && test[3] == 0);
        test[3] = 5;
        test = realloc(test, 4);
        assert(test.length == 4 && test[3] == 5);
        test = realloc(test, 8);
        assert(test.length == 8 && test[3] == 5 && test[7] == 0);
        free(test);
    }

package:
    ///Get currently allocated memory in bytes.
    ulong currently_allocated(){return currently_allocated_;}

private:
    ///Total memory manually allocated over the whole run of the program, in bytes.
    ulong total_allocated_ = 0;
    ///Total memory manually freed over the whole run of the program, in bytes.
    ulong total_freed_ = 0;
    ///Currently allocated memory, in bytes.
    ulong currently_allocated_ = 0;

    ///Struct holding allocation data for one object type.
    struct Stats
    {
        ///Total bytes allocated or freed.
        ulong bytes;
        ///Total allocations or deallocations.
        uint allocations;
        ///Total objects allocated.
        ulong objects;

        ///Get allocation data in string format.
        string statistics()
        {
            alias std.string.toString to_string;
            return to_string(bytes) ~ " bytes, " ~ to_string(allocations) ~
                   " allocations, " ~ to_string(objects) ~ " objects";                     
        }                
    }                    
    
    ///Statistics about allocations of types.
    Stats[string] alloc_stats_;
    ///Statistics about deallocations of types.
    Stats[string] dealloc_stats_;
    ///Pointers to currently allocated buffers.
    void*[] alloc_pointers_;


    ///Allocate one object and default-initialize it.
    T* allocate(T)()
    {
        uint bytes = T.sizeof;
        T* ptr = cast(T*)malloc(bytes);
        total_allocated_ += bytes;
        currently_allocated_ += bytes;

        debug_allocate(ptr, 1);

        //default-initialize the object.
        static if (is(typeof(T.init))){*ptr = T.init;}
        return ptr;
    }

    /**
     * Allocate a struct with specified parameters for the structs' initializer.
     *
     * Params:  args = Parameters for the structs' initializer.
     *
     * Returns: Pointer to the allocated struct.
     */
    T* allocate_struct(T, CtorArgs...)(CtorArgs args)
    {
        uint bytes = T.sizeof;
        T* ptr = cast(T*)malloc(bytes);
        total_allocated_ += bytes;
        currently_allocated_ += bytes;

        debug_allocate(ptr, 1); 

        //initialize the object.
        *ptr = T(args);

        return ptr;
    }

    /**
     * Allocate an array with given number of elements.
     *
     * Arrays returned by allocate() must NOT be resized.
     *
     * Params:  elems = Number of objects for the array to hold.
     * 
     * Returns: Allocated array.
     */
    T[] allocate(T)(ulong elems)
    out(result)
    {
        assert(result.length == elems, "Failed to allocate space for "
                                       "specified number of elements");
        assert(T.sizeof * elems <= uint.max && elems <= uint.max,
               "Memory allocation over 4 GiB or for over 2^32 objects not supported yet");
    }
    body
    {
        ulong bytes = T.sizeof * elems;
        //only 4G elems supported for now
        T[] array = (cast(T*)malloc(cast(uint)bytes))[0 .. cast(uint)elems];
        total_allocated_ += bytes;
        currently_allocated_ += bytes;

        debug_allocate(array.ptr, elems); 

        //default-initialize the array.
        //using memset for ubytes as it's faster and ubytes are often used for large arrays.
        static if (is(T == ubyte)){memset(array.ptr, 0, cast(uint)bytes);}
        else if (is(typeof(T.init))) 
        {
            array[] = T.init;
        }
        return array;
    }

    /**
     * Reallocate an array allocated with allocate().
     *
     * Array data might move around the memory, invalidating any pointers to it.
     *
     * Params:  array = Array to reallocate.
     *          elems = Number of elements for the reallocated array to hold.
     *
     * Returns: Reallocated array.
     */
    T[] reallocate(T)(T[] array, ulong elems)
    in
    {
        assert(alloc_pointers_.contains(cast(void*)array.ptr), 
               "Trying to reallocate a pointer that isn't allocated (or was freed)");
    }
    body
    {
        long old_bytes = T.sizeof * array.length;
        long new_bytes = T.sizeof * elems;
        T* old_ptr = array.ptr;
        ulong old_length = array.length;

        //if we're shrinking, destroy extra elements unless this is 
        //an array of pointers or reference types.
        static if (is(typeof(T.die)) && !is(typeof(cast(T*)T))) 
        {
            if(old_length > elems)
            {
                foreach(ref T elem; array[elems .. $]){elem.die();}
            }
        }

        array = (cast(T*)std.c.stdlib.realloc(array.ptr, new_bytes))[0 .. elems];

        long diff = new_bytes - old_bytes;
        total_allocated_ += diff;
        currently_allocated_ += diff;

        debug_reallocate(array.ptr, array.length, old_ptr, old_length); 

        //default-initialize new elements, if any
        if(array.length > old_length)
        {
            //using memset for ubytes as it's faster and ubytes are often used for large arrays.
            static if (is(T == ubyte))
            {
                memset(array.ptr + old_length, 0, cast(uint)(new_bytes - old_bytes));
            }
            else if (is(typeof(T.init))) 
            {
                if(array.length > old_length)
                {
                    array[old_length .. $] = T.init;
                }
            }
        }
        return array;
    }

    ///Free an object allocated by allocate(). If a die() method is defined, it will be called.
    void deallocate(T)(ref T* ptr)
    in
    {
        assert(alloc_pointers_.contains(cast(void*)ptr), 
               "Trying to free a pointer that isn't allocated (or is already freed?)");
    }
    body
    {
        total_freed_ += T.sizeof;
        currently_allocated_ -= T.sizeof;

        static if (is(typeof(T.die))){ptr.die();}

        debug_free(ptr, 1); 

        std.c.stdlib.free(ptr);
    }

    /**
     * Free an array allocated by allocate().
     *
     * If a die() method is defined for the array's type and the array doesn't hold
     * pointers or reference types, die() will be called for every object in the array.
     *
     * Params:  array = Array to deallocate.
     */
    void deallocate(T)(ref T[] array)
    in
    {
        assert(alloc_pointers_.contains(cast(void*)array.ptr), 
               "Trying to free a pointer that isn't allocated (or is already freed)");
    }
    body
    {
        ulong bytes = T.sizeof * array.length;
        total_freed_ += bytes;
        currently_allocated_ -= bytes;

        //destroy the elements unless this is an array of pointers or reference types.
        static if (is(typeof(T.die)) && !is(typeof(cast(T*)(T))))
        {
            foreach(ref T elem; array){elem.die();}
        }

        debug_free(array.ptr, array.length); 

        std.c.stdlib.free(array.ptr);
    }

    ///Return a string containing statistics about allocated memory.
    string statistics()
    {
        alias std.string.toString to_string;
        string stats = "Memory allocator statistics:";
        stats ~= "\nTotal allocated (bytes): " ~ to_string(total_allocated_);
        stats ~= "\nTotal freed (bytes): " ~ to_string(total_freed_);
        
        stats ~= "\nAllocated pointers that were not freed: " ~
                 to_string(alloc_pointers_.length);

        stats ~= "\n\nAllocation statistics:\n";
        foreach(type_name, stat; alloc_stats_)
        {
            stats ~= type_name ~ " - " ~ stat.statistics ~ "\n";
        }
        stats ~= "\nDeallocation statistics:\n";
        foreach(type_name, stat; dealloc_stats_)
        {
            stats ~= type_name ~ " - " ~ stat.statistics ~ "\n";
        }

        return stats;
    }

    ///Write out allocator statistics at program exit.
    static ~this()
    {
        scope(failure){writefln("Error logging memory usage");}
        ensure_directory_user("main::logs");
        string stats = statistics();
        File file = open_file("main::logs/memory.log", FileMode.Write);
        file.write(stats);
        close_file(file);
        if(alloc_pointers_.length > 0)
        {
            writefln("WARNING: MEMORY LEAK DETECTED, FOR MORE INFO SEE:\n"
                     "userdata::main::logs/memory.log");
        }
    }

    /**
     * Record data about an allocation.
     * 
     * Params:  ptr     = Pointer to the allocated memory.
     *          objects = Number of objects allocated.
     */
    void debug_allocate(T)(T* ptr, ulong objects)
    {
        string type = typeid(T).toString;
        Stats* stats = type in alloc_stats_;
        //If this type was not yet allocated, add an entry
        if(stats is null){alloc_stats_[type] = Stats(objects * T.sizeof, 1, objects);}
        else
        {
            stats.bytes += objects * T.sizeof;
            stats.allocations += 1;
            stats.objects += objects;
        }
        //add the pointer to array of allocated pointers
        alloc_pointers_ ~= cast(void*)ptr;
    }

    //not the best way to go about recording reallocs, but sufficient for now
    /**
     * Record data about a reallocation.
     * 
     * Params:  new_ptr     = Pointer to the reallocated memory.
     *          new_objects = Number of objects in reallocated memory.
     *          old_ptr     = Pointer to original memory.
     *          old_objects = Number of objects in original memory.
     */
    void debug_reallocate(T)(T* new_ptr, ulong new_objects,
                             T* old_ptr, ulong old_objects)
    {
        string type = typeid(T).toString;
        Stats* stats = type in alloc_stats_;

        assert(stats !is null, "Allocation stats for a reallocated type are empty");

        stats.bytes += (new_objects - old_objects) * T.sizeof;
        stats.allocations += 1;
        stats.objects += new_objects - old_objects;

        if(new_ptr != old_ptr)
        {
            //remove the old pointer from array of allocated pointers
            alias containers.array.remove remove;
            alloc_pointers_.remove(cast(void*)old_ptr);
            //add the new pointer to array of allocated pointers
            alloc_pointers_ ~= cast(void*)new_ptr;
        }
    }

    /**
     * Record data about a deallocation.
     * 
     * Params:  ptr     = Pointer to deallocated memory.
     *          objects = Number of objects deallocated.
     */
    void debug_free(T)(T* ptr, ulong objects)
    {
        string type = typeid(T).toString;
        Stats* stats = type in dealloc_stats_;
        //If this type was not yet deallocated, add an entry
        if(stats is null){dealloc_stats_[type] = Stats(objects * T.sizeof, 1, objects);}
        else
        {
            stats.bytes += objects * T.sizeof;
            stats.allocations += 1;
            stats.objects += objects;
        }
        //remove the pointer from array of allocated pointers
        alias containers.array.remove remove;
        alloc_pointers_.remove(cast(void*)ptr);
    }
