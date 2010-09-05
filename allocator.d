module allocator;


import std.c.stdlib;

import std.stdio;
import std.string;

import arrayutil;


public:
    ///Allocate an object.
    T* alloc(T)(){return allocate!(T)();}

    ///Allocate an array of objects.
    T[] alloc(T)(uint elems){return allocate!(T)(elems);}

    ///Free an object allocated by alloc(). Will call die() method if defined.
    void free(T)(T* ptr){deallocate(ptr);}

    ///Free an array of objects allocated by alloc(). Will call die() methods if defined.
    void free(T)(T[] array){deallocate(array);}

private:
    //Total memory manually allocated over run of the program, in bytes.
    ulong total_allocated_ = 0;
    //Total memory manually freed over run of the program, in bytes.
    ulong total_freed_ = 0;

    //Debug
    //Struct holding allocation data for one object type.
    struct Stats
    {
        //Total bytes allocated/freed.
        ulong bytes;
        //Total allocations.
        uint allocations;
        //Total objects allocated.
        uint objects;

        //Return a string with allocation data stored.
        string statistics()
        {
            alias std.string.toString to_string;
            return to_string(bytes) ~ " bytes, " ~ to_string(allocations) ~
                   " allocations, " ~ to_string(objects) ~ " objects";                     
        }                
    }                    
    
    //Statistics about allocations of types.
    Stats[string] alloc_stats_;
    //Statistics about deallocations of types.
    Stats[string] dealloc_stats_;
    //Pointers to currently allocated buffers.
    void*[] alloc_pointers_;
    //\Debug



    ///Allocate one object.
    T* allocate(T)()
    {
        ulong bytes = T.sizeof;
        T* ptr = cast(T*)malloc(bytes);
        total_allocated_ += bytes;

        debug_allocate(ptr, 1); //Debug

        //default-initialize the object.
        static if (is(typeof(T.init))) 
        {
            *ptr = T.init;
        }
        return ptr;
    }

    ///Allocate an array of objects with given number of elements.
    /**
     * @note arrays returned by allocate() must NOT be resized.
     */
    T[] allocate(T)(uint elems)
    out(result)
    {
        assert(result.length == elems, "Failed to allocate space for "
                                       "specified number of elements");
    }
    body
    {
        ulong bytes = T.sizeof * elems;
        T[] array = cast(T[])malloc(bytes)[0 .. elems];
        total_allocated_ += bytes;

        debug_allocate(array.ptr, elems); //Debug

        //default-initialize the array.
        static if (is(typeof(T.init))) 
        {
            array[] = T.init;
        }
        return array;
    }

    ///Free one object allocated by allocate().
    void deallocate(T)(ref T* ptr)
    in
    {
        //Debug
        assert(alloc_pointers_.contains(cast(void*)ptr), 
               "Trying to free a pointer that isn't allocated (or is already freed?)");
    }
    body
    {
        total_freed_ += T.sizeof;

        debug_free(ptr, 1); //Debug

        std.c.stdlib.free(ptr);
    }

    ///Free an array allocated by allocate().
    void deallocate(T)(ref T[] array)
    in
    {
        //Debug
        assert(alloc_pointers_.contains(cast(void*)array.ptr), 
               "Trying to free a pointer that isn't allocated (or is already freed)");
    }
    body
    {
        total_freed_ += T.sizeof * array.length;

        debug_free(array.ptr, array.length); //Debug

        std.c.stdlib.free(array.ptr);
    }

    ///Return a string containing statistics about allocated memory.
    string statistics()
    {
        alias std.string.toString to_string;
        string stats = "Memory allocator statistics:";
        stats ~= "\nTotal allocated (bytes): " ~ to_string(total_allocated_);
        stats ~= "\nTotal freed (bytes): " ~ to_string(total_freed_);
        
        //Debug
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
        //\Debug

        return stats;
    }

    ///Write out allocator statistics at program exit.
    static ~this(){writefln(statistics());}

    //Debug
    //Record data about an allocation.
    void debug_allocate(T)(T* ptr, ulong objects)
    {
        string type = typeid(T).toString;
        Stats* stats = type in alloc_stats_;
        //If this type was not yet allocated, add an entry
        if(stats is null)
        {
            alloc_stats_[type] = Stats(objects * T.sizeof, 1, objects);
        }
        else
        {
            stats.bytes += objects * T.sizeof;
            stats.allocations += 1;
            stats.objects += objects;
        }
        //add the pointer to array of allocated pointers
        alloc_pointers_ ~= cast(void*)ptr;
    }

    //Record data about a deallocation.
    void debug_free(T)(T* ptr, ulong objects)
    {
        string type = typeid(T).toString;
        Stats* stats = type in dealloc_stats_;
        //If this type was not yet deallocated, add an entry
        if(stats is null)
        {
            dealloc_stats_[type] = Stats(objects * T.sizeof, 1, objects);
        }
        else
        {
            stats.bytes += objects * T.sizeof;
            stats.allocations += 1;
            stats.objects += objects;
        }
        //remove the pointer from array of allocated pointers
        alias arrayutil.remove remove;
        alloc_pointers_.remove(cast(void*)ptr);
    }
    //\Debug
