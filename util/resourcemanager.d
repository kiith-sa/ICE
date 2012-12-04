
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Loads and provides access to resources of various types.
module util.resourcemanager;


import std.algorithm;
import std.stdio;
import std.typecons;
import dgamevfs._;

import containers.lazyarray;


/// Common interface for resource managers. 
///
/// Must be downcasted to get the resource manager itself 
/// (due to the template/virtual incompatibility).
interface GenericResourceManager
{
    /// Does this resource manager manage specified type?
    ///
    /// If true, the manager can be downcasted to ResourceManager!T.
    @property bool managesType(T)() @safe const pure nothrow
    {
        return managesType_(typeid(T));
    }

protected:
    /// Implementation of managesType().
    bool managesType_(TypeInfo typeInfo) @safe const pure nothrow;
}

/// Governs how the manager loads its resources.
enum LoadStrategy
{
    /// Preload any found resources as early as possible.
    AggressivePreload,
    /// Load a resource only when it's about to be used.
    OnDemand
}


/// ID for fast repeated access to a resource.
struct ResourceID(T)
{
private:
    // Underlying lazy array index.
    LazyArrayIndex!T index_;

public:
    /// Construct a ResourceIndex for a resource with specified virtual filesystem path.
    this(string path)
    {
        if(path.startsWith("root/"))
        {
            path = path["root/".length .. $];
        }
        index_ = LazyArrayIndex!T(path);
    }
}

/// Concrete resource manager managing resources of type T.
class ResourceManager(T) : GenericResourceManager
{
public:
    /// Accepts a files range and returns files of this resource type.
    alias VFSFile[] delegate(VFSFiles) ResourceFilter;
    /// Loads a resource from file. Returns true on successm false on failure.
    alias bool delegate(VFSFile, out T) ResourceLoader;

private:
    // Resource filter used, if any (if null, only fileGlob_ is used).
    //
    // Determines which files will be considered for preloading.
    ResourceFilter resourceFilter_;

    /// Resource loader used.
    ResourceLoader resourceLoader_;

    // Only files matching this glob pattern will be considered for preloading.
    //
    // Can be null - in which case all files will be considered. If resourceFilter_
    // is not null, it is used to narrow down the files further.
    string fileGlob_;

    // Game data directory to load resources from.
    VFSDir gameDir_;

    // Determines whether and how to preload resources.
    LoadStrategy loadStrategy_ = LoadStrategy.OnDemand;

    // Stores loaded resources 
    //
    // LazyArray lazily loads resources; ResourceManager just determines
    // the loading strategy.
    LazyArray!T storage_;

public:
    /// Construct a ResourceLoader using a glob pattern to filter resources.
    ///
    /// Params:  gameDir        = Game data directory to load resources from.
    ///          resourceLoader = Delegate that loads a resource from file,
    ///                           and returns true on success, false on failure.
    ///                           The passed file might be NULL if the file was 
    ///                           not found. This allows the delegate to load the 
    ///                           backup resource (or just fail by returning false).
    ///          fileGlob       = Glob pattern determining which files to load.
    this(VFSDir gameDir, ResourceLoader resourceLoader, string fileGlob)
    {
        gameDir_        = gameDir;
        resourceFilter_ = null;
        resourceLoader_ = resourceLoader;
        fileGlob_       = fileGlob;
        storage_.loaderDelegate = &loaderWrapper;
    }

    /// Construct a ResourceLoader using a delegate to filter resources.
    ///
    /// Params:  gameDir        = Game data directory to load resources from.
    ///          resourceLoader = Delegate that loads a resource from file,
    ///                           and returns true on success, false on failure.
    ///                           The passed file might be NULL if the file was 
    ///                           not found. This allows the delegate to load the 
    ///                           backup resource (or just fail by returning false).
    ///          fileGlob       = Delegate taking a VFSFiles range and returning
    ///                           an array of files to load.
    this(VFSDir gameDir, ResourceLoader resourceLoader, ResourceFilter resourceFilter)
    {
        gameDir_        = gameDir;
        resourceFilter_ = resourceFilter;
        resourceLoader_ = resourceLoader;
        fileGlob_       = null;
        storage_.loaderDelegate = &loaderWrapper;
    }

    /// Set the loading strategy to control resource loading.
    @property void loadStrategy(const LoadStrategy rhs)
    {
        loadStrategy_ = rhs;
        if(loadStrategy_ == LoadStrategy.AggressivePreload)
        {
            preloadAll();
        }
    }

    /// Get a resource which is in file with specified path.
    ///
    /// Params:  path = Path of the resource file.
    ///
    /// Returns: Pointer to the resource if found, null otherwise.
    T* getResource(string path)
    {
        if(path.startsWith("root/"))
        {
            path = path["root/".length .. $];
        }
        auto index = LazyArrayIndex!(T)(path);
        //Loads from file if not yet loaded.
        T* value = storage_[index];
        if(value is null)
        {
            writeln("WARNING: Failed to load or preload file ", path);
            writeln("Ignoring...");
        }
        return value;
    }

    /// Get a resource with specified resource ID.
    /// This is faster when accessing a resource more than once.
    ///
    /// Params:  id = ID to use.
    ///
    /// Returns: Pointer to the resource if found, null otherwise.
    T* getResource(ref ResourceID!T id)
    {
        //Loads from file if not yet loaded.
        T* value = storage_[id.index_];
        if(value is null)
        {
            writeln("WARNING: Failed to load or preload file ", id);
            writeln("Ignoring...");
        }
        return value;
    }

    /// Delete all loaded resources.
    void clear()
    {
        .clear(storage_);
        storage_.loaderDelegate = &loaderWrapper;
    }

protected:
    override bool managesType_(TypeInfo typeInfo) @safe const pure nothrow
    {
        return typeid(T) is typeInfo;
    }

private:
    /// Preload all resources of this type found in the gameDir_.
    void preloadAll()
    {
        auto files = gameDir_.files(Yes.deep, fileGlob_);
        if(resourceFilter_ !is null) foreach(file; resourceFilter_(files))
        {
            getResource(file.path);
        }
        else foreach(file; files)
        {
            getResource(file.path);
        }
    }

    /// Wraps the loader delegate in a function usable by LazyArray.
    bool loaderWrapper(string name, out T result)
    {
        VFSFile file;
        // Handle the case when the file does not exist.
        try                   {file = gameDir_.file(name);}
        catch(VFSException e) {file = null;}

        // The loader can decide to load a placeholder on failure.
        return resourceLoader_(file, result);
    }
}
