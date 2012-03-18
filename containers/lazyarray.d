
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Array that lazily loads items. Used for resource management.
module containers.lazyarray;


import std.algorithm;
import std.traits;
import std.typecons;

import containers.fixedarray;


///Index to a LazyArray. ID specifies type of resource identifier.
align(4) struct LazyArrayIndex_(ID = string)
{
    private:
        ///Identifier of the resource.
        ID id_;

        ///Index of the resource in the LazyArray.
        uint index_ = uint.max;

    public:
        ///Get the resource identitifer.
        @property ID id() const pure nothrow {return id_;}

        ///Is the resource loaded?
        @property bool loaded() const pure nothrow {return index_ != uint.max;}

        ///Construct a LazyArrayIndex_ pointing to resource with specified identifier.
        this(const ID id) pure nothrow
        {
            id_ = id;
        }
}

///Default LazyArrayIndex_ uses string as resource identifier.
alias LazyArrayIndex_!string LazyArrayIndex;

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
        ///Item with a resource ID.
        struct Item
        {
            ID id;
            T value;
        }

        ///Allocated storage.
        FixedArray!Item storage_;

        ///Used storage (number of items in the aray).
        uint used_;

        ///Delegate used to load data if it's requested and not loaded yet.
        bool delegate(ID, out T) loadData_ = null;

    public:
        ///Get the item at specified index, loading it if needed. Returns null on failure.
        T* opIndex(ref LazyArrayIndex_!ID index)
        in
        {
            assert(loadData_ !is null, 
                   "Trying to get an element from a lazy array, "
                   "but loader delegate was not specified");
        }
        body
        {
            if(!index.loaded)
            {
                //Resource id must be valid.
                static if(isArray!ID || is(ID == class))
                {
                    assert(index.id_ !is null, 
                           "Indexing a lazy array with an index that has a null "
                           "resource identifier");
                }

                //Check if we've already loaded this resource.
                long storageIdx = -1;
                foreach(size_t idx, ref Item item; storage_[0 .. used_])
                {
                    if(item.id == index.id) 
                    {
                        storageIdx = idx;
                        break;
                    }
                }

                if(storageIdx >= 0)
                {
                    index.index_ = cast(uint)storageIdx;
                }
                else
                {
                    assert(storage_.length <= used_, 
                           "Storage length lower than number of used items");

                    //Reallocate if needed.
                    if(storage_.length == used_)
                    {
                        reallocate();
                    }

                    //Add the new item, and clear it if we fail.
                    storage_[used_].id = index.id;
                    if(!loadData_(index.id, storage_[used_].value))
                    {
                        clear(storage_[used_]);
                        return null;
                    }
                    index.index_ = used_;

                    //Successfully added the new item.
                    ++used_;
                }
            }

            assert(index.index_ < used_, "LazyArray index out of bounds");
            return &(storage_[index.index_].value);
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
            foreach(ref item; storage_[0 .. used_])
            {
                result = dg(item.value);
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

    private:
        ///Reallocate the array to add more capacity.
        void reallocate()
        {
            auto newStorage = FixedArray!Item(storage_.length * 2 + 1);

            //Using move();
            //Postblit constructors don't always get called as of DMD 2.058
            //which can result to two instances of a FixedArray
            //pointing to same data that both get destroyed, causing a double free.
            //
            //move() just moves the data without calling dtor,
            //so it's destroyed only once in the function it was moved to.
            //
            //This might need to be rewritten if any problems appear once the bug 
            //has been fixed.

            static if(hasElaborateDestructor!T)
            {
                foreach(size_t i, ref Item item; storage_[0 .. used_])
                {
                    newStorage[i] = move(item);
                }
            }
            else
            {
                newStorage[0 .. used_] = storage_[0 .. used_];
            }
            storage_ = move(newStorage);
        }
}
