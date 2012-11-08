
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Memory allocators used in containers (but also usable directly).
module memory.allocator;


import core.stdc.string;
import std.algorithm;
import std.conv;
import std.traits;

import memory.memory;
import util.signal;


/// When called, any buffered memory
mixin Signal!() freeUnusedBuffers;

/// This is a dummy struct documenting allocator API, which is identical for every Allocator struct.
///
/// Note: Any memory allocated by one of the allocators must NOT be used 
/// after main() (in static destructors).
struct AllocatorAPI
{
    /// Allocate an array of specified type. 
    /// 
    /// Arrays allocated with alloc must NOT be resized.
    /// 
    /// Params:  elems = Number of objects to allocate space for.
    /// 
    /// Returns: Allocated array. Values in the array are default-initialized.
    static T[] allocArray(T, string file = __FILE__, uint line = __LINE__)
                         (const size_t elems){assert(false, "DUMMY STRUCT");};

    /// Reallocate an array allocated by alloc() .
    /// 
    /// Contents of the array are preserved but array itself might be moved in memory,
    /// invalidating any pointers pointing to it.
    /// 
    /// If the array is shrunk and of non-reference type (e.g. not a class), 
    /// any extra elements are cleared (if they have destructors, they're called).
    /// 
    /// Params:  array = Array to reallocate.
    ///          elems = Number of objects for the reallocated array to hold.
    /// 
    /// Returns: Reallocated array.
    static T[] realloc(T, string file = __FILE__, uint line = __LINE__)
                      (T[] array, const size_t elems){assert(false, "DUMMY STRUCT");};

    /// Free an array of objects allocated by allocArray(). 
    /// 
    /// If the array is of non-reference type (e.g. not a class), array elements 
    /// are cleared (if they have destructors, they're called).
    /// 
    /// Params: array = Array to free.
    static void free(T)(T[] array){assert(false, "DUMMY STRUCT");};

    /// Can the allocator allocate values of specified type?
    template canAllocate(U)
    {
        enum canAllocate = false;
    }
}

/// Allocates memory directly through memory.memory.
struct DirectAllocator
{
    static T[] allocArray(T, string file = __FILE__, uint line = __LINE__)(const size_t elems)
    {
        return memory.memory.allocArray!(T, file, line)(elems);
    }

    static T[] realloc(T, string file = __FILE__, uint line = __LINE__)(T[] array, const size_t elems)
    {
        return memory.memory.realloc!(T, file, line)(array, elems);
    }

    static void free(T)(T[] array){memory.memory.free(array);}

    template canAllocate(U)
    {
        enum canAllocate = !is(U == class);
    }
}

/// An allocator that preserves previously allocated buffers, reusing them later.
///
/// We have a fixed number of buffers. When allocating, we look for a free buffer 
/// large enough for our allocation. If found, we use it, otherwise we allocate a
/// new buffer and either replace a smaller unused buffer, or, if out of buffers,
/// we just return the new buffer without keeping track of it.
///
/// When freeing, if the buffer freed matches one of buffers in the allocator, we
/// mark that buffer as free. Otherwise we just delete it.
///
/// When reallocating a buffer matching a buffer in the allocator, we look if we 
/// have extra space in the buffer, and try to reuse it. Only if we can't we 
/// reallocate the buffer in the allocator and return it. (If not in the allocator,
/// we simply reallocate the buffer).
struct BufferSwappingAllocator(T, uint BufferCount)
    if(!is(T == class))
{
private:
    // Buffers in the allocator.
    //
    // The allocator tries to keep the allocations in one of these buffers.
    // If it runs out of buffers, it falls back to direct allocation.
    //
    // The first buffersUsed_ buffers are the allocated buffers; the others 
    // are currently free.
    static T[][BufferCount] buffers_;
    // Number of currently used buffers (the first buffersUsed_ buffers are used).
    static uint buffersUsed_ = 0;

    // Total number of manual allocations.
    static uint totalAllocations_ = 0;
    // Number of manual allocations that were avoided thanks to reusing buffers.
    static uint recycledAllocations_ = 0;
    // Total number of preallocations (made at first allocation to avoid the need to reallocate).
    static uint preAllocations_ = 0;

    // Has preAlloc() been called yet?
    static bool preAllocated_ = false;

    // Preallocate each buffer with some space to avoid unnecessary early allocations.
    //
    // Called at the first allocation.
    static void preAlloc()
    {
        preAllocated_ = true;
        foreach(ref buffer; buffers_)
        {
            // 32 is an arbitrary number, can be changed or made type-dependent
            buffer = memory.memory.allocArray!T(32);
            ++totalAllocations_;
            ++preAllocations_;
        }
        // Will deallocate unused buffers when main() ends to avoid 
        // leaking memory.
        freeUnusedBuffers.connect({
            foreach(ref buffer; buffers_[buffersUsed_ .. $]) if(null !is buffer)
            {
                memory.memory.free(buffer);
                buffer = null;
            }
        });
    }

    // Static destructor; prints debug information (buffer deallocation is handled elsewhere).
    static ~this()
    {
        import std.stdio;
        auto percent(uint allocs)
        {
            return " (" ~ to!string(allocs * 100 / totalAllocations_) ~ "%)";
        }
        writeln("BufferSwappingAllocator!(" ~ T.stringof ~ ", " ~
                to!string(BufferCount) ~ ") stats:");
        writeln("Total allocations: ", totalAllocations_);
        if(totalAllocations_ == 0){return;}
        writeln("Recycled allocations: ", recycledAllocations_, percent(recycledAllocations_));
        writeln("Preallocations: ", preAllocations_, percent(preAllocations_));
    }

public:
    static T[] allocArray(T, string file = __FILE__, uint line = __LINE__)(const size_t elems)
    out(result)
    {
        assert(result.ptr != null, "Allocated a null array");
    }
    body
    {
        // At the first call, preallocate the buffers.
        if(!preAllocated_)
        {
            // Must be done here, not in static ctor 
            // (static ctor might be called before initializing memory debug info)
            preAlloc();
        }
        ++totalAllocations_;
        const bytes = elems * T.sizeof;
        // Look for a free buffer large enough.
        foreach(ref buffer; buffers_[buffersUsed_ .. $]) if(buffer.length >= elems)
        {
            auto result = buffer[0 .. elems];
            swap(buffers_[buffersUsed_], buffer);
            // Default initialize the contents of the result buffer.
            enum zeroInit = __traits(hasMember, T, "CAN_INITIALIZE_WITH_ZEROES");
            static if(zeroInit)
            {
                memset(result.ptr, 0, bytes);
            }
            else foreach(ref item; result)
            {
                static init = T.init;
                memcpy(cast(void*)&item, cast(void*)&init, T.sizeof);
            }
            ++buffersUsed_;
            ++recycledAllocations_;
            return result;
        }

        // Couldn't find a free buffer large enough, allocate a new one.
        // If possible, insert the new buffer into buffers_.
        auto result = memory.memory.allocArray!(T, file, line)(elems);
        if(buffersUsed_ < BufferCount)
        {
            auto buffer = buffers_[buffersUsed_];
            // Unused buffer smaller than the new buffer; 
            // replace it with the new buffer.
            assert(buffer.length < elems, "Buffer longer than or as long as result; "
                   "but those should have been handled by the above foreach loop");
            if(buffer !is null)
            {
                memory.memory.free(buffer);
            }
            // Either a buffer we've just cleared in the above branch
            // or one that has not been allocated yet. Replace it.
            buffers_[buffersUsed_] = result;
            ++buffersUsed_;
        }
        return result;
    }

    static T[] realloc(T, string file = __FILE__, uint line = __LINE__)(T[] array, const size_t elems)
    {
        const oldLength = array.length;
        const bytes     = elems * T.sizeof;
        ++totalAllocations_;

        // Look for the array in buffers.
        foreach(ref buffer; buffers_[0 .. buffersUsed_]) if(array.ptr == buffer.ptr)
        {
            // Our buffer still has enough space, so continue using it.
            if(buffer.length >= elems)
            {
                // Expanding. Initialize new elements.
                if(elems > oldLength) foreach(ref item; buffer[oldLength .. elems])
                {
                    enum zeroInit = __traits(hasMember, T, "CAN_INITIALIZE_WITH_ZEROES");
                    static if(zeroInit)
                    {
                        memset(&item, 0, T.sizeof);
                    }
                    else
                    {
                        static init = T.init;
                        memcpy(cast(void*)&item, cast(void*)&init, T.sizeof);
                        item = T.init;
                    }
                }
                // Shortening. Deinitialize removed elements.
                else if(elems < oldLength) foreach(ref item; buffer[elems .. oldLength])
                {
                    static if(hasElaborateDestructor!T) 
                    {
                        clear(item);
                    }
                }
                ++recycledAllocations_;
                return buffer[0 .. elems];
            }
            // Too big, won't fit into the buffer.
            else
            {
                // Need to allocate as T[] to make sure GC ranges are updated.
                buffer = memory.memory.realloc(buffer, elems);
                return buffer;
            }
        }

        // Not buffered - was allocated separately, so reallocate separately.
        return memory.memory.realloc(array, elems);
    }

    static void free(T)(T[] array)
    {
        // Find if any of the buffers matches passed array.
        foreach(ref buffer; buffers_[0 .. buffersUsed_]) if(array.ptr == buffer.ptr)
        {
            static if (hasElaborateDestructor!T) foreach(ref T elem; array)
            {
                clear(elem);
            }
            --buffersUsed_;
            swap(buffer, buffers_[buffersUsed_]);
            return;
        }
        // Check for deleting an unused buffer (might detect some double-free bugs).
        debug foreach(ref buffer; buffers_[buffersUsed_ .. $])
        {
            assert(array.ptr != buffer.ptr, "Trying to free an unused buffer");
        }

        // Not buffered - was allocated separately, so delete it separately.
        memory.memory.free(array);
    }

    template canAllocate(U)
    {
        enum canAllocate = is(U == T);
    }
}
