
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Array that lazily loads items. Used for resource management.
module containers.lazyarray;


import std.algorithm;
import std.range;
import std.traits;
import std.typecons;

import containers.vector;
import memory.allocator;


/**
 * Index to a LazyArray. ID specifies type of resource identifier.
 *
 * Note: DO NOT change alignment here as it causes a gc bug
 *       that garbage collects the id_ string even if it's
 *       still used.
 */
struct LazyArrayIndex(T, ID = string)
{
    private:
        ///Identifier of the resource. This is cleared after the resource is loaded.
        ID id_;

        ///Index of the resource in the LazyArray once loaded (uint.max when not loaded).
        uint index_ = uint.max;

    public:
        ///Is the resource loaded?
        bool loaded(ref const LazyArray!(T, ID) array) const pure nothrow 
        {
            return index_ < array.storage_.length;
        }

        ///Construct a LazyArrayIndex_ pointing to resource with specified identifier.
        this(ID id) pure nothrow
        {
            id_ = id;
        }

        /// Get a string representation of the ID 
        ///
        /// (only works if the resource has not been loaded.)
        string toString() @safe const pure nothrow
        {
            static if(is(ID == string))
            {
                return id_ is null ? "Unknown ID (loaded)" : id_;
            }
            else
            {
                return id_.toString();
            }
        }

    private:
        ///Set the index once the resource is loaded.
        @property void index(const uint rhs) 
        {
            clear(id_);
            index_ = rhs;
        }

        ///Get the resource identitifer.
        const(ID) id(ref const LazyArray!(T, ID) array) const pure nothrow 
        in
        {
            assert(!loaded(array), 
                   "Accessing the ID of a LazyArrayIndex after its resource "
                   "has been loaded - the ID is now cleared, replaced by index.");
        }
        body
        {
            return id_;
        }

        ///Get the resource identitifer (non-const version).
        @property ID idNonConst(ref const LazyArray!(T, ID) array) pure nothrow 
        in
        {
            assert(!loaded(array), 
                   "Accessing the ID of a LazyArrayIndex after its resource "
                   "has been loaded - the ID is now cleared, replaced by index.");
        }
        body
        {
            return id_;
        }
}

pragma(msg, "LazyArrayIndex!(uint, string) size: ", LazyArrayIndex!(uint, string).sizeof);

/**
 * Array that lazily loads items. Used for resource management. 
 *
 * LazyArray uses special indices ($(D LazyArrayIndex_)), which contain resource
 * identifiers. When we ask for an element from LazyArray by indexing with
 * this index, it checks if the element is loaded.
 *
 * If it's loaded, it returns a pointer to it.
 *
 * If it's not loaded, it loads and stores it (using a user-provided
 * delegate), and returns a pointer to it. If the resource could not be loaded,
 * it returns null.
 *
 * The $(D LazyArrayIndex_) indices are always updated to point to the loaded
 * resource based on the resource ID.
 *
 * LazyArray cannot be copied for simplicity of implementation.
 */
struct LazyArray(T, ID = string)
{
    @disable this(this);
    @disable void opAssign(LazyArray);

    private:
        ///IDs of items in storage_. ids_[i] is the ID if storage_[i].
        Vector!(ID, BufferSwappingAllocator!(ID, 8)) ids_;
        ///Allocated storage. Not using Vector due to a DMD 2.061 error.
        T[] storage_;

        ///Delegate used to load data if it's requested and not loaded yet.
        bool delegate(ID, out T) loadData_ = null;

    public:
        ///Destroy the LazyArray.
        ~this()
        {
            foreach(ref elem; storage_)
            {
                destroy(elem);
            }
            destroy(storage_);
        }

        ///Get the item at specified index, loading it if needed. Returns null on failure.
        T* opIndex(ref LazyArrayIndex!(T, ID) index)
        in
        {
            assert(loadData_ !is null, 
                   "Trying to get an element from a lazy array, "
                   "but loader delegate was not specified");
        }
        body
        {
            if(!index.loaded(this))
            {
                //Resource id must be valid.
                static if(isArray!ID || is(ID == class))
                {
                    assert(index.idNonConst(this) !is null, 
                           "Indexing a lazy array with an index that has a null "
                           "resource identifier");
                }

                //Check if we've already loaded this resource.
                long storageIdx = -1;
                foreach(size_t idx, ref T item; storage_)
                {
                    if(ids_[idx] == index.idNonConst(this)) 
                    {
                        storageIdx = idx;
                        break;
                    }
                }

                if(storageIdx >= 0)
                {
                    index.index = cast(uint)storageIdx;
                }
                else
                {
                    storage_.length = storage_.length + 1;
                    storage_.assumeSafeAppend();
                    ids_.length     = ids_.length + 1;
                    ids_.back       = index.idNonConst(this);
                    //Add the new item, and clear it if we fail.
                    if(!loadData_(index.idNonConst(this), storage_.back))
                    {
                        clear(storage_.back);
                        clear(ids_.back);
                        storage_.length = storage_.length - 1;
                        ids_.length     = ids_.length - 1;
                        return null;
                    }
                    index.index = cast(uint)storage_.length - 1;
                }
            }

            return &(storage_[index.index_]);
        }

        /**
         * Used by foreach.
         *
         * Foreach will iterate over all elements of the array in linear order
         * from start to end.
         */
        int opApply(int delegate(ref T) dg)
        {
            int result = 0;
            foreach(ref item; storage_)
            {
                result = dg(item);
                if(result){break;}
            }
            return result;
        }

        /**
         * Set the delegate used to load elements.
         *
         * The delegate must take a resource ID and an output argument to write 
         * the loaded element to. It must return true if the element was loaded
         * successfully and false otherwise.
         *
         * The loader delegate should take the resource ID, load the resource
         * based on it and write it to output. It should never throw, although
         * it's not forced to be nothrow for practicality reasons.
         */
        @property void loaderDelegate(bool delegate(ID, out T) rhs) pure nothrow 
        {
            loadData_ = rhs;
        }
}
