
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Component that allows to tag an entity.
module component.tagscomponent;


import std.typecons;

import containers.vector;
import util.yaml;


/// Component that allows to tag an entity.
///
/// Tagged entities can be accessed by the engine allowing for special logic;
/// e.g. a player ship.
struct TagsComponent
{
private:
    // Length of all tags in bytes.
    enum TAG_LENGTH = 4;
public:
    /// Convenience alias (a tag is just a fixed-size char array).
    alias char[TAG_LENGTH] Tag;

private:
    // TODO This is a struct for DMD 2.058/Windows compatibility.
    //      This is needed to avoid a bogus compiler error.
    //      Once we move to something newer, turn this back to a union.
    struct
    {
        // Stores tag when there are at most 6 tags.
        Tag[6] tagsFew_;
        // Stores tags when there are more than 6 tags.
        Tag[] tagsMany_ = void;
        // Temporarily disabled and using a dynamic array instead 
        // because dtors/copyctors/etc of structs in a union get called,
        // causing bugs. When that is fixed in DMD, use a Vector instead 
        // and destroy it explicitly in dtor of this struct.
        //Vector!Tag tagsMany_ = void;
    }
    // When tagsFew_ is used, this is the number of tags in tagsFew_.
    //
    // When using tagsMany_, this is tagsFew_.length + 1.
    ubyte fewCount_ = 0;

public:
    /// Determine if this tagComponent contains specified tag.
    ///
    /// tagStr = String form of the tag. Must have at most 4 characters.
    ///          If it has less than 4 characters, the others are assumed 
    ///          to be '\0'.
    bool hasTag(string tagStr)
    {
        assert(tagStr.length <= TAG_LENGTH, 
               "hasTag() called with too large tag string: " ~ tagStr);
        foreach(ref tag; tags)
        {
            if(tagStr == tag[0 .. tagStr.length] && 
               tag[tagStr.length .. TAG_LENGTH] == "\0\0\0\0"[tagStr.length .. TAG_LENGTH])
            {
                return true;
            }
        }
        return false;
    }
    import util.unittests;
    private static void unittestHasTag()
    {
        TagsComponent component;
        Tag tag1 = "ABCD";
        Tag tag2 = "ABD\0";
        Tag tag3 = "ABC\0";
        Tag tag4 = "\0\0\0\0";
        component.addTag(tag1);
        component.addTag(tag2);
        component.addTag(tag3);
        component.addTag(tag4);
        assert(component.hasTag(""));
        assert(component.hasTag("ABC"));
        assert(component.hasTag("ABCD"));
        assert(component.hasTag("ABC\0"));
        assert(!component.hasTag("ABDD"));
    }
    mixin registerTest!(unittestHasTag, "TagsComponent.hasTag");

    /// Add a new tag to the component.
    void addTag(const Tag tag)
    {
        if(fewCount_ < tagsFew_.length)
        {
            tagsFew_[fewCount_++] = tag;
        }
        // Too many to fit in tagsFew_; start using tagsMany_.
        else if(fewCount_ == tagsFew_.length)
        {
            auto temp = tagsFew_;
            // Need to re-initialize (same data was used by tagsFew_).
            tagsMany_ = typeof(tagsMany_).init;
            tagsMany_ ~= temp;
            tagsMany_ ~= tag;
            // Only need to reach tagsFew_.length + 1.
            ++fewCount_;
        }
        else
        {
            tagsMany_ ~= tag;
        }
    }
    import util.unittests;
    private static void unittestAddTag()
    {
        Tag[] tags;
        tags ~= "ABCD";
        tags ~= "ABCE";
        tags ~= "ABCF";
        tags ~= "ABCG";
        tags ~= "ABCH";
        tags ~= "ABCJ";
        tags ~= "ABCK";
        tags ~= "ABCL";
        tags ~= "ABCM";
        tags ~= "ABCN";

        TagsComponent component;

        uint i = 0;
        foreach(tag; tags[0 .. component.tagsFew_.length])
        {
            component.addTag(tag);
            assert(tags[0 .. ++i] == component.tags);
        }
        component.addTag(tags[component.tagsFew_.length]);
        assert(tags[0 .. ++i] == component.tags);
        foreach(tag; tags[component.tagsFew_.length + 1 .. $])
        {
            component.addTag(tag);
            assert(tags[0 .. ++i] == component.tags);
        }
    }
    mixin registerTest!(unittestAddTag, "TagsComponent.addTag");

    /// Load from a YAML node. Throws YAMLException on error.
    this(ref YAMLNode yaml)
    {
        // Should be a sequence of strings.
        foreach(string tagStr; yaml)
        {
            if(tagStr.length <= TAG_LENGTH)
            {
                Tag tag;
                tag[0 .. tagStr.length] = tagStr;
                tag[tagStr.length .. TAG_LENGTH] = '\0';
                addTag(tag);
            }
            else
            {
                throw new YAMLException("Tags can only have 4 characters: \"" 
                                        ~ tagStr ~ "\"");
            }
        }
    }

private:
    /// Return all tags. Abstracts away tagsFew_ and tagsMany_.
    @property immutable(Tag)[] tags() pure nothrow
    {
        return cast(immutable(Tag)[])
               ((fewCount_ <= tagsFew_.length) ? tagsFew_[0 .. fewCount_]
                                               : tagsMany_[]);
    }
}

