
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Memory pool for efficient object allocation.
module memory.pool;


import core.memory;

import std.algorithm;
import std.conv;
import std.exception;
import std.traits;
import std.typecons;

import math.math;
import memory.memory;
import util.typeinfo;
import util.unittests;

/**
 * Memory pool for efficient object allocation.
 *
 *
 * Stores objects of registered types in linear fashion.
 *
 *
 * Structs, classes and primitive types are stored directly in the memory pool 
 * instead of using the garbage collector. Any structs or classes with 
 * indirections (such as pointers or references) are automatically added to the
 * garbage collector for scanning. This can be disabled by adding the following
 * member to the struct/class: $(D static bool MEMORYPOOL_DISABLE_GC_SCAN) .
 *
 *
 * For dynamic arrays or closures, only the array/delegate structure is be 
 * stored in the pool, not array storage/closure context which are still handled                      
 * by the garbage collectors.
 *
 *
 * Allocation and deallocation is done through an opague
 * handle: $(D MemoryPoolObject). 
 *
 *
 * The MemoryPool can dereference this handle and return
 * a pointer directly to the object. Allocated objects are
 * never moved in memory, so these pointers are safe. 
 *
 *
 * Of course, after the object is freed, any such direct
 * pointers are invalid (and will most likely point to a 
 * different object of same type, as the MemoryPool reuses memory).
 *
 *
 * Note that while MemoryPool stores objects efficiently and reuses freed
 * memory when allocating new objects, it never shrinks allocated space.
 *
 *
 * When the MemoryPool is destroyed (using the destroy()) method, any 
 * non-freed objects are destroyed with it.
 */
class MemoryPool
{
    private:
        ///Pools for registered types.
        ObjectPool[TypeInfo] pools_;

    public:
        /**
         * Destroys the memory pool, freeing all used memory.
         *
         * This invalidates any references or MemoryPoolObjects pointing to
         * data allocated by the MemoryPool.
         *
         * This must be called to free the memory used by the MemoryPool.
         *
         * After destroy() is called, the MemoryPool is left in a blank state,
         * as if it was just constructed.
         */
        void destroy()
        {
            foreach(TypeInfo type, ref ObjectPool pool; pools_)
            {
                pool.destroy();
            }

            clear(pools_);
        }

        /**
         * Register a type for allocation.
         *
         * This must be called before objects of specified type may be
         * allocated.
         */
        void registerType(T)() 
            if(!is(T == interface))
        {
            assert((typeid(T) in pools_) is null, 
                   "Registering type " ~ T.stringof ~ " twice");

            pools_[typeid(T)] = ObjectPool.init;
            pools_[typeid(T)].initialize!T();
        }

        /**
         * Get access to iterate all objects of type T.
         *
         * If T is a class type, this also iterates over objects of types 
         * deriving T. Similarly, if T is an interface, this iterates over 
         * types implementing T.
         *
         * At least one type matching, deriving or implementing T must be 
         * registered.
         *
         * Examples:
         * --------------------
         * class Foo{}
         *
         * MemoryPool pool;
         *
         * //initialize pool, register Foo
         *
         * foreach(Foo foo; pool.objectsOfType!Foo))
         * {
         *     //do stuff
         * }
         * --------------------
         */
        @property ObjectIterable!T objectsOfType(T)() 
        {
            assert(hasPoolOfType!T, 
                   "Trying to access objects of type " ~ T.stringof ~ " but "
                   "there is no such registered (or derived) type in the MemoryPool.");

            return ObjectIterable!T(this);
        }

        /**
         * Get a reference to specified object.
         *
         * For classes and interfaces, returns a reference to the 
         * object as T, even it T is a parent class or an interface
         * implemented by the stored object.
         *
         * For other types, returns a pointer to the object as T* .
         *
         * T must be the actual type of the object, a parent class or 
         * interface implemented by the stored type.
         */
        auto getObject(T)(MemoryPoolObject object)
        {
            assert((object.type in pools_) !is null, 
                   "Trying get an object of unregistered type " ~ T.stringof);

            return pools_[object.type].getObject!T(object);
        }

        /**
         * Allocate an object of type T.
         *
         * Args are arguments to pass to the object's constructor,
         * or to initialize the object with.
         *
         * If there are no arguments, a struct, primitive type or a class
         * with a zero-argument constructor can be allocated.
         */
        MemoryPoolObject allocate(T, Args ...)(Args args)
        {
            assert((typeid(T) in pools_) !is null, 
                   "Trying to allocate an object of unregistered type " 
                   ~ T.stringof);

            return pools_[typeid(T)].allocate!T(args);
        }

        /**
         * Free an allocated object.
         *
         * If the object has a destructor, it will be called, regardless of
         * whether it is a struct or a class.
         * 
         * After calling this, any references to the object will be invalid and 
         * might, in fact, point to different objects allocated later.
         */
        void free(MemoryPoolObject object)
        {
            assert((object.type in pools_) !is null, 
                   "Trying free an object of unregistered type " 
                   ~ object.type.toString());

            pools_[object.type].free(object);
        }

        ///Get size of memory used by allocated objects in bytes.
        @property size_t allocatedBytes()
        {
            size_t result = 0;
            foreach(TypeInfo type, ref ObjectPool pool; pools_)
            {
                result += pool.allocatedBytes;
            }
            return result;
        }

    private:
        ///Do we have any pool of type T, type deriving T or type implementing T?
        bool hasPoolOfType(T)() 
        {
            if((typeid(T) in pools_) !is null){return true;}

            static if(is(T == class) || is(T == interface))
            {
                foreach(TypeInfo type, ref ObjectPool pool; pools_) 
                {
                    if(isDerivedFrom!T(type)){return true;}
                }
            }

            return false;
        }
}
void unittestMemoryPool()
{
    class C{}
    class D : C {}
    class E : D {uint u; this(uint uu){u = uu;}}
    struct S{}

    bool testRegisterDestroyHasPoolOfType()
    {
        auto pool = new MemoryPool();
        pool.registerType!uint();
        pool.registerType!D();
        pool.registerType!S();
        if(pool.pools_.length != 3  || 
           pool.allocatedBytes != 0 ||
           !pool.hasPoolOfType!uint ||
           !pool.hasPoolOfType!C    ||
           !pool.hasPoolOfType!D    ||
           !pool.hasPoolOfType!S    ||
           pool.hasPoolOfType!int)
        {
            return false;
        }

        pool.destroy();
        if(pool.pools_.length != 0  || 
           pool.allocatedBytes != 0 ||
           pool.hasPoolOfType!uint ||
           pool.hasPoolOfType!C    ||
           pool.hasPoolOfType!D    ||
           pool.hasPoolOfType!S)
        {
            return false;
        }

        return true;
    }

    bool testAllocFree()
    {
        auto pool = new MemoryPool();
        scope(exit){pool.destroy();}
        pool.registerType!uint();
        pool.registerType!D();
        pool.registerType!C();
        pool.registerType!S();

        auto obj = pool.allocate!uint(4);
        if(pool.allocatedBytes != 4 || *pool.getObject!uint(obj) != 4)
        {
            return false;
        }
        pool.free(obj);
        if(pool.allocatedBytes != 0){return false;}
        return true;
    }

    bool testGetObject()
    {
        auto pool = new MemoryPool();
        scope(exit){pool.destroy();}
        pool.registerType!uint();
        pool.registerType!E();
        pool.registerType!C();
        pool.registerType!S();

        auto obj = pool.allocate!uint(42);
        auto obj2 = pool.allocate!E(42);

        if(*pool.getObject!uint(obj)         != 42 ||
           pool.getObject!E(obj2).u          != 42 ||
           (cast(E)pool.getObject!D(obj2)).u != 42 ||
           (cast(E)pool.getObject!C(obj2)).u != 42)
        {
            return false;
        }

        return true;
    }

    bool testIteration()
    {
        auto pool = new MemoryPool();
        scope(exit){pool.destroy();}
        pool.registerType!uint();
        pool.registerType!D();
        pool.registerType!C();
        pool.registerType!S();

        foreach(uint i; 0 .. 1024)
        {
            pool.allocate!uint(i);
        }
        pool.allocate!S;
        pool.allocate!S;

        pool.allocate!D;
        pool.allocate!D;
        pool.allocate!C;

        uint i = 0;
        foreach(u; pool.objectsOfType!uint)
        {
            if(u != i){return false;}
            ++i;
        }
        if(i != 1024){return false;}

        i = 0;
        foreach(ref S s; pool.objectsOfType!S)
        {
            ++i;
        }
        if(i != 2){return false;}

        i = 0;
        foreach(c; pool.objectsOfType!C)
        {
            ++i;
        }
        if(i != 3){return false;}

        i = 0;
        foreach(c; pool.objectsOfType!C)
        {
            ++i;
            if(i == 2){break;}
        }
        if(i != 2)
        {
            return false;
        }

        i = 0;
        foreach(c; pool.objectsOfType!C)
        {
            if(i == 1){continue;}
            ++i;
        }
        if(i != 1)
        {
            return false;
        }

        i = 0;
        foreach(d; pool.objectsOfType!D)
        {
            ++i;
        }
        if(i != 2){return false;}

        return true;
    }

    assert(testRegisterDestroyHasPoolOfType());
    assert(testAllocFree());
    assert(testGetObject());
    assert(testIteration());
}
mixin registerTest!(unittestMemoryPool, "MemoryPool general");


/**
 * Handle to an object allocated by a memory pool.
 *
 * Returned by MemoryPool.allocate() and needed for MemoryPool.free().
 *
 * MemoryPool.getObject() can be used to obtain direct access to the object
 * pointed to by this handle.
 *
 * 12 bytes on 64bit, 8 bytes on 32bit.
 */
align(4) struct MemoryPoolObject
{
    private:
        ///Actual type of the object.
        TypeInfo type_;

        ///Index of the object in its ObjectPool.
        uint poolIndex_;

    public:
        ///Get type information about the object.
        @property TypeInfo type() pure nothrow {return type_;}
}

///Allows iteration over objects in a MemoryPool, seamlessly handling derived classes.
struct ObjectIterable(T)
{
    private:
        ///Memory pool we iterate over.
        MemoryPool pool_;

    public:
        /**
         * Foreach over the memory pool.
         *
         * This iterates over any objects in the memory pool that are 
         * of type T, derive it (if T is a class type) or implement it
         * (if T is an interface).
         */
        int opApply(int delegate(ref T) dg)
        { 
            //Loop over a particular ObjectPool.
            //If this returns nonzero, break.
            static int loop(ObjectPool* objectPool, int delegate(ref T) dg)
            {
                int result = 0;
                foreach(uint idx; objectPool.roster_[0 .. objectPool.rosterUsed_])
                {
                    void* ptr = objectPool.objectAtIndex(idx);

                    static if(is(T == class))
                    {
                        T classRef = cast(T)ptr;
                        result = dg(classRef);
                    }
                    else static if(is(T == interface))
                    {
                        //Interfaces don't start exactly where the object starts 
                        //so we need to cast to Object and let D cast figure it out
                        T interfaceRef = cast(T)(cast(Object)ptr);
                        result = dg(interfaceRef);
                    }
                    else{result = dg(*(cast(T*)ptr));}

                    if(result){break;}
                } 
                return result;
            }

            static if(is(T == class) || is(T == interface))
            {
                //Loop over each type in the loop that matches or is derived from T.
                foreach(TypeInfo type, ref ObjectPool objectPool; pool_.pools_)
                {
                    if(type is typeid(T) || isDerivedFrom!T(type))
                    {
                        const result = loop(&objectPool, dg);
                        //if the loop was broken out from
                        if(result){return result;}
                    }
                }
                return 0;
            }
            else
            {
                assert((typeid(T) in pool_.pools_) !is null,
                       "Iterating over unregistered type in a MemoryPool "
                       "(MemoryPool should assert false when asked for an "
                       "iterator over unregistered type)");
                auto objectPool = &(pool_.pools_[typeid(T)]);
                return loop(objectPool, dg);
            }
        }

    private:
        ///Construct an ObjectIterable to iterate over specified memory pool.
        this(MemoryPool pool) pure nothrow
        {
            pool_ = pool;
        }
}

private:

/**
 * A pool storing objects of a particular type.
 *
 * The objects are stored in a linear fashion in large (currently 4kiB)
 * buffers. They are aligned according to alignment size of their type.
 * Allocated objects are never moved, so pointers/references to them are
 * stable. ObjectPool always reuses memory of previously freed objects
 * when allocating, but never shrinks.
 *
 * ObjectPool instances should never be copied and never be accessible
 * from code outside MemoryPool.
 */
struct ObjectPool
{
    private:
        ///Information about the type allocated by this pool.
        TypeInfo type_;
        /**
         * Number of bytes taken by single instance of allocated type.
         *
         * This might be greater than the actual instance size to ensure
         * consecutive instances in the pool are all aligned according
         * to alignment_.
         */
        size_t alignedInstanceSize_;
        //Alignment of the type allocated by this pool.
        size_t alignment_;

        /**
         * Each buffer has the allocated storage and pointer to the first element.
         *
         * The first element might start at storage[0] due to alignment.
         */
        alias Tuple!(ubyte[], "storage", ubyte*, "startPtr") Buffer;

        ///Size of a single buffer in the pool in bytes.
        enum bufferSize_ = 4096;
        ///Buffers in the pool.
        Buffer[] buffers_ = null;
        ///Number of instances of the type allocated each buffer can hold.
        size_t instancesPerBuffer_;

        /** 
         * Roster: Indices into the pool. 
         *
         * Elements in roster_[0 .. rosterUsed_] are indices to allocated
         * instances, while indices in roster_[rosterUsed_ .. $] point to free 
         * instances. rosterLocations_ is used to keep track of where each
         * instance is in roster_. rosterLocations_[i] is the index of roster item
         * that points to instance i.
         *
         * When an object is freed, roster item that points to it is swapped
         * with roster item pointing to the last allocated object, and rosterUsed_ is
         * decremented. 
         *
         * MemoryPoolObject stores index to the pool, which is used both
         * to get the instance and to get the roster item that points to 
         * it when free() is called (through rosterLocations_).
         *
         * Indices to the pool are divided by instancesPerBuffer_ to get the buffer
         * the instance is in, and moduloed also by instancesPerBuffer_ to get the
         * index of the instance in the buffer.
         *
         * Roster allows us to allocate/free in constant time, easily 
         * keep track of allocated/free memory, and to access allocated 
         * instances in bulk.
         */

        ///Instance indices.
        uint[] roster_ = null;
        ///Where in the roster is the index of i-th instance?
        uint[] rosterLocations_ = null;
        ///Number of roster indices used by allocated instances (i.e. also number of allocated instances).
        size_t rosterUsed_ = 0;
        ///Does this type have indirections that might lead to garbage collected memory?
        bool hasIndirections_;

    public:
        @disable this(this);
        
        /**
         * Initialize the object pool for specified type.
         *
         * Used to initialize an ObjectPool after being created.
         */
        void initialize(T)() pure
            if(!is(T == interface))
        {
            static assert(T.sizeof <= bufferSize_ / 2, 
                          "Trying to create an ObjectPool for an object that is too large: " ~ T.stringof);

            type_         = typeid(T);
            alignment_    = T.alignof;
            alignedInstanceSize_ = alignToUpperMultipleOf(alignment_, memorySize!T);
            //Each buffer contains (bufferSize_ / alignedInstanceSize_) - 1 objects 
            //to account for alignment of the first object

            instancesPerBuffer_ = (bufferSize_ / alignedInstanceSize_) - 1;
            hasIndirections_    = hasIndirections!T && 
                                  !__traits(hasMember, T, "MEMORYPOOL_DISABLE_GC_SCAN"); 

            debug{invariant_();}
        }

        ///Destroy the object pool, releasing all allocated memory.
        void destroy()
        {
            debug{invariant_();}

            //Free remaining objects
            while(rosterUsed_ > 0)
            {
                //Free the object pointed to by first roster element
                free(MemoryPoolObject(type_, roster_[0]));
            }

            type_ = null;
            alignedInstanceSize_ = alignment_ = instancesPerBuffer_ = 0;
            hasIndirections_ = false;

            static void clean(T)(ref T[] array)
            {
                if(array is null){return;}
                .free(array);
                array = null;
            }

            if(buffers_ !is null) foreach(buffer; buffers_)
            {
                .free(buffer.storage);
            }
            clean(buffers_);
            clean(roster_);
            clean(rosterLocations_);
        }

        /**
         * Allocate an object of type T.
         *
         * Args are arguments to pass to the object's constructor,
         * or to initialize the object with.
         *
         * If there are no arguments, a struct, primitive type or a class
         * with a zero-argument constructor can be allocated.
         */
        MemoryPoolObject allocate(T, Args ...)(Args args)
        in
        {
            assert(typeid(T) == type_, 
                   "Allocating with an ObjectPool with wrong type");
        }
        out(result)
        {
            assert(isAllocated(result.poolIndex_), 
                   "Object returned from allocate() is not allocated");
        }
        body
        {
            debug{invariant_(); scope(exit){invariant_();}}

            if(rosterUsed_ == roster_.length){reallocatePool();}

            //roster_[rosterUsed] points to the first free item
            const poolIndex = roster_[rosterUsed_];

            void[] objectChunk = objectAtIndex(poolIndex)[0 .. alignedInstanceSize_];
            emplace!(T, Args)(objectChunk, args);
            if(hasIndirections_){GC.addRange(objectChunk.ptr, alignedInstanceSize_);}

            ++rosterUsed_;

            return MemoryPoolObject(typeid(T), cast(uint)poolIndex);
        }

        ///Free an object previously allocated by this ObjectPool.
        void free(MemoryPoolObject object)
        in
        {
            assert(null !is object.type, 
                   "Freeing an uninitialized MemoryPoolObject");
            assert(type_ is object.type, 
                   "Freeing from an ObjectPool with wrong type");
            assert(isAllocated(object.poolIndex_), 
                   "Trying to free an object that is not allocated");
        }
        body
        {
            debug{invariant_(); scope(exit){invariant_();}}

            //Index to object to pool
            const poolIndex    = object.poolIndex_;
            //Roster item that points to the object
            const rosterIndex_ = rosterLocations_[poolIndex];
            auto objectPtr     = objectAtIndex(poolIndex);

            //Destroy object in poolIndex
            if(isClass(type_)){clear(cast(Object)objectPtr);}
            else              {object.type.destroy(objectPtr);}

            if(hasIndirections_){GC.removeRange(objectPtr);}

            const swappedPoolIndex             = roster_[rosterUsed_ - 1];
            //Change (index to destroyed object) to (index to last allocated object)
            roster_[rosterIndex_]              = swappedPoolIndex;
            //Change now unused index in roster to point to our destroyed object.
            roster_[rosterUsed_ - 1]           = poolIndex;
            //Our destroyed object can now be found in roster at rosterUsed_ - 1
            rosterLocations_[poolIndex]        = cast(uint)(rosterUsed_ - 1);
            //Object that was at rosterUsed_ - 1 can now be found at rosterIndex_ 
            rosterLocations_[swappedPoolIndex] = rosterIndex_;
            
            --rosterUsed_;
        }

        /**
         * Get a reference to specified object.
         *
         * For classes and interfaces, returns a reference to the 
         * object as T, even it T is a parent class or an interface
         * implemented by the stored object.
         *
         * For other types, returns a pointer to the object as T* .
         *
         * T must be the stored type, a parent class or interface
         * implemented by the stored type.
         */
        auto getObject(T, string file = __FILE__, uint line = __LINE__)
                      (MemoryPoolObject object) nothrow
        in
        {
            assert(typeid(T) is type_ || isDerivedFrom!T(type_), 
                   "Getting object from an ObjectPool with wrong type: " ~
                   file ~ " " ~ to!string(line));
            assert(isAllocated(object.poolIndex_), 
                   "Trying to access an object that is not allocated: " ~ 
                   file ~ " " ~ to!string(line));
        }
        body
        {
            debug{invariant_(); scope(exit){invariant_();}}

            auto objectPtr = objectAtIndex(object.poolIndex_);

            static if(is(T == class))         {return cast(T)objectPtr;}
            //Interfaces don't start exactly where the object starts 
            //so we need to cast to Object and let D cast figure it out
            else static if(is(T == interface)){return cast(T)(cast(Object)objectPtr);}
            else                              {return cast(T*)objectPtr;}
        }

        ///Get size of memory used by allocated objects in bytes.
        @property size_t allocatedBytes() const pure nothrow
        {
            return rosterUsed_ * alignedInstanceSize_;
        }

    private:
        /**
         * Get a pointer to the object starting at specified index in the pool.
         *
         * Params:  poolIndex = Index the object is at. This is divided by
         *                      instancesPerBuffer_ to get the buffer index
         *                      and moduloed also by instancesPerBuffer_ to
         *                      get the index in that buffer.
         *
         * Returns: Untyped ointer to the start of the object.
         */
        void* objectAtIndex(const uint poolIndex) pure nothrow
        in
        {
            assert(poolIndex < roster_.length, "Indexing outside of the object pool");
        }
        body
        {
            debug{invariant_(); scope(exit){invariant_();}}

            const bufferIndex   = poolIndex / instancesPerBuffer_;
            const instanceIndex = poolIndex % instancesPerBuffer_;
            return cast(void*)(buffers_[bufferIndex].startPtr + 
                               (instanceIndex * alignedInstanceSize_));
        }

        ///Is instance at specified index allocated?
        bool isAllocated(const uint poolIndex) const pure nothrow
        in
        {
            assert(roster_.length > poolIndex, 
                   "Checking if a slot outside of the object pool is allocated");
        }
        body
        {
            debug{invariant_(); scope(exit){invariant_();}}
            return rosterLocations_[poolIndex] < rosterUsed_;
        }

        ///Reallocate the pool (add a buffer) to increase the capacity.
        void reallocatePool()
        {
            debug{invariant_(); scope(exit){invariant_();}}

            auto newBuffer = allocArray!ubyte(bufferSize_);
            const ptrInt   = cast(size_t)(cast(void*)newBuffer.ptr);
            //Aligning to alignment__
            const aligned     = alignToUpperMultipleOf(alignment_, ptrInt);
            auto newBufferPtr = cast(ubyte*)(cast(void*)aligned);

            buffers_        = buffers_ is null 
                              ? allocArray!Buffer(1)
                              : realloc(buffers_, buffers_.length + 1);
            buffers_[$ - 1] = Buffer(newBuffer, newBufferPtr);

            //Determining added capacity for instances
            const newBufferEndPtr      = newBuffer.ptr + newBuffer.length;
            const newBufferUsableBytes = newBufferEndPtr - newBufferPtr;
            const addedCapacity        = newBufferUsableBytes / alignedInstanceSize_;
            assert(addedCapacity >= instancesPerBuffer_, 
                   "Reallocation didn't result in expected capacity");

            roster_ = roster_ is null 
                      ? allocArray!uint(instancesPerBuffer_) 
                      : realloc(roster_, roster_.length + instancesPerBuffer_);
            rosterLocations_ = rosterLocations_ is null 
                               ? allocArray!uint(instancesPerBuffer_) 
                               : realloc(rosterLocations_,
                                         rosterLocations_.length + instancesPerBuffer_);

            foreach(uint i; cast(uint)rosterUsed_ .. cast(uint)roster_.length)
            {
                //i-th roster element points to (free) i-th object in the pool
                roster_[i] = i;
                //i-th slot can be found at i-th index in the roster.
                rosterLocations_[i] = i;
            }
        }

        ///Invariant method, used because builtin D invariant is bugged.
        void invariant_() const pure nothrow
        {
            assert(rosterUsed_ <= roster_.length,
                   "More than roster.length slots used in roster");
            assert(roster_.length == rosterLocations_.length,
                   "roster_ and rosterLocations_ lengths do not match");
            assert(alignedInstanceSize_ > 0 && alignment_ > 0,
                   "Zero object instance size or alignment");
        }
}

//Testing code

struct S{byte b;}
align(1)  struct S1  {real r; byte b; byte[128] bs;}
align(4)  struct S4  {real r; byte b; byte[128] bs;}
align(8)  struct S8  {real r; byte b; byte[128] bs;}
align(16) struct S16 {real r; byte b; byte[128] bs;}
class C     {real r; byte b; byte[128] bs;}
class D : C {float f;}
interface I{uint get();}
static bool eDestroyed = false;
class E : D, I 
{
    uint u; 
    this(uint uu){u = uu;} 
    ~this(){eDestroyed = true;}
    uint get(){return u;}
    bool opEquals(uint uu){return u == uu;}
}

void unittestObjectPool()
{
    import std.stdio;
    bool testDestroy(T)()
    {
        ObjectPool pool;
        pool.initialize!T();
        pool.destroy();
        return (pool.type_                   is null &&
                pool.alignedInstanceSize_    == 0    &&
                pool.alignment_              == 0    &&
                pool.bufferSize_             == 4096 &&
                pool.instancesPerBuffer_     == 0    &&
                !pool.hasIndirections_               &&
                pool.rosterUsed_             == 0    &&
                pool.roster_.length          == 0    &&
                pool.rosterLocations_.length == 0    &&
                pool.buffers_.length         == 0);
    }

    bool testInit(T)()
    {
        ObjectPool pool;
        pool.initialize!T();
        scope(exit){pool.destroy();}

        return (pool.type_                   is typeid(T)                            &&
                pool.alignment_              == T.alignof                            &&
                pool.alignedInstanceSize_    ==                                      
                alignToUpperMultipleOf(T.alignof, memorySize!T)                      &&
                pool.bufferSize_             == 4096                                 &&
                pool.instancesPerBuffer_     == 4096 / pool.alignedInstanceSize_ - 1 &&
                pool.hasIndirections_        == hasIndirections!T                    &&
                pool.rosterUsed_             == 0                                    &&
                pool.roster_.length          == 0                                    &&
                pool.rosterLocations_.length == 0                                    &&
                pool.buffers_.length         == 0);
    }

    bool testInitDestroy(T)()
    {
        if(!testDestroy!T())
        {
            writeln("ObjectPool of ", T.stringof, " destroy() test failed");
            return false;
        }
        if(!testInit!T())
        {
            writeln("ObjectPool of ", T.stringof, " initialize() test failed");
            return false;
        }
        return true;
    }

    bool testAllocFree(T)()
    {
        ObjectPool pool;
        pool.initialize!T();
        scope(exit){pool.destroy();}

        //Test allocating/freeing 1 object
        auto obj = pool.allocate!T();
        if(pool.rosterUsed_         !=  1         ||
           pool.buffers_.length     !=  1         ||
           pool.rosterLocations_[0] !=  0         ||
           pool.roster_[0]          !=  0         ||
           obj.type                 !is typeid(T) ||
           obj.poolIndex_           !=  0)
        {
            writeln("Failed allocating 1 ", T.stringof);
            return false;
        }
        pool.free(obj);
        if(pool.rosterUsed_         != 0 ||
           pool.buffers_.length     != 1 ||
           pool.rosterLocations_[0] != 0 ||
           pool.roster_[0]          != 0)
        {
            writeln("Failed freeing 1 ", T.stringof);
            return false;
        }

        //Test allocating 2k objects and then freeing every other one
        MemoryPoolObject[2000] objects;
        foreach(ref object; objects)
        {
            object = pool.allocate!T();
        }
        if(pool.rosterUsed_ != 2000)
        {
            writeln("Failed allocating 2000 of ", T.stringof);
            return false;
        }
        foreach(o; 0 .. objects.length / 2)
        {
            pool.free(objects[(o + 1) * 2 - 1]);
        }
        if(pool.rosterUsed_ != 1000)
        {
            writeln("Failed freeing every other ", T.stringof);
            return false;
        }

        //Test allocating 500 objects - those should be allocated
        //from the free slots left by previous freeing
        MemoryPoolObject[500] objects2;
        foreach(ref object; objects2)
        {
            object = pool.allocate!T();
        }
        if(pool.rosterUsed_         !=  1500      ||
           objects2[0].poolIndex_   !=  1999)
        {
            writeln("Failed allocating 500 more of ", T.stringof);
            return false;
        }

        //Free everything that's left
        foreach(ref object; objects2)
        {
            pool.free(object);
        }
        foreach(o; 0 .. objects.length / 2)
        {
            pool.free(objects[o * 2]);
        }
        if(pool.rosterUsed_ !=  0)
        {
            writeln("Failed freing all remaining of ", T.stringof);
            return false;
        }
        return true;
    }

    //Tested object needs to have a this() and opEquals() with 1 uint
    bool testGetObject(T)()
    {
        ObjectPool pool;
        pool.initialize!T();
        scope(exit){pool.destroy();}

        //unifies pointers with references
        auto get(T)(T val)
        {
            static if(isPointer!T){return *val;}
            else                  {return val;}
        }

        //Allocate/free 1 object
        auto obj = pool.allocate!T(42);
        if(get(pool.getObject!T(obj)) != 42){return false;}
        pool.free(obj);

        //Allocate and access 2000 objects
        MemoryPoolObject[2000] objects;
        foreach(i, ref object; objects)
        {
            object = pool.allocate!T(cast(uint)i);
        }
        foreach(i, object; objects)
        {
            if(get(pool.getObject!T(object)) != cast(uint)i){return false;}
        }

        //Free overy other object, and ensure access still works
        foreach(o; 0 .. objects.length / 2)
        {
            pool.free(objects[(o + 1) * 2 - 1]);
        }
        foreach(o; 0 .. objects.length / 2)
        {
            const idx = o * 2;
            if(get(pool.getObject!T(objects[idx])) != cast(uint)idx){return false;}
        }

        //Allocate and access 500 more objects, ensure both old and new objects are OK
        MemoryPoolObject[500] objects2;
        foreach(i, ref object; objects2)
        {
            object = pool.allocate!T(cast(uint)(i + 10000));
        }
        foreach(o; 0 .. objects.length / 2)
        {
            const idx = o * 2;
            if(get(pool.getObject!T(objects[idx])) != cast(uint)idx){return false;}
        }
        foreach(i, object; objects2)
        {
            if(get(pool.getObject!T(object)) != cast(uint)(i + 10000)){return false;}
        }

        return true;
    }

    assert(testInitDestroy!float());
    assert(testInitDestroy!long());
    assert(testInitDestroy!(typeof((bool a) => a))());
    assert(testInitDestroy!S());
    assert(testInitDestroy!S1());
    assert(testInitDestroy!S4());
    assert(testInitDestroy!S8());
    assert(testInitDestroy!S16());
    assert(testInitDestroy!C());
    assert(testInitDestroy!D());

    assert(testAllocFree!float());
    assert(testAllocFree!long());
    assert(testAllocFree!(typeof((bool a) => a))());
    assert(testAllocFree!S());
    assert(testAllocFree!S1());
    assert(testAllocFree!S4());
    assert(testAllocFree!S8());
    assert(testAllocFree!S16());
    assert(testAllocFree!C());
    assert(testAllocFree!D());

    assert(testGetObject!uint);
    assert(testGetObject!ulong);
    assert(testGetObject!E);
    {
        ObjectPool pool;
        pool.initialize!E();
        scope(exit){pool.destroy();}

        auto obj = pool.allocate!E(42);

        E e = pool.getObject!E(obj);
        assert(e.u == 42);
        D d = pool.getObject!D(obj);
        assert((cast(E)d).u == 42);
        C c = pool.getObject!C(obj);
        assert((cast(E)c).u == 42);
        I i = pool.getObject!I(obj);
        assert(i.get() == 42);

        //Ensure dtor gets called
        pool.free(obj);
        assert(eDestroyed);
    }

    {
        ObjectPool pool;
        pool.initialize!uint();
        scope(exit){pool.destroy();}

        auto obj = pool.allocate!uint(42);
        assert(pool.isAllocated(0));
        pool.free(obj);
        assert(!pool.isAllocated(0));
    }
}
mixin registerTest!(unittestObjectPool, "ObjectPool general");


