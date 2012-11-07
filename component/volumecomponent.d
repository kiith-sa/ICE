
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Component that provides a spatial volume to an entity.
module component.volumecomponent;


import std.conv;
import std.exception;

import dyaml.exception;

import math.rect;
import math.vector2;
import util.yaml;


///Component that provides a spatial volume to an entity.
struct VolumeComponent 
{
    private static bool DO_NOT_DESTROY_AT_ENTITY_DEATH;

    public:
        ///Volume types.
        enum Type : ubyte
        {
            Uninitialized,
            AABBox
        }

    private:
        union
        {
            ///Axis-aligned bounding box.
            Rectf aabbox_;
        }

        ///Type of the volume.
        Type type_ = Type.Uninitialized;

    public:
        ///Load from a YAML node. Throws YAMLException on error.
        this(ref YAMLNode yaml)
        {
            enforce(yaml.length == 1,
                    new YAMLException("volume YAML node with more than one entry"));
            if(yaml.containsKey("aabbox"))
            {
                auto box = yaml["aabbox"];
                aabbox_ = Rectf(fromYAML!Vector2f(box["min"], "min"),
                                fromYAML!Vector2f(box["max"], "max"));
                enforce(aabbox_.valid, 
                        new YAMLException("Invalid aabbox volume: " 
                                           ~ to!string(aabbox_)));
                type_ = Type.AABBox;
            }
            else
            {
                throw new YAMLException("Volume YAML node with no known volume"
                                        " type (known types: aabbox)");
            }
        }

        ///Construct an axis aligned bounding box from a rectangle.
        this(const Rectf aabbox)
        {
            type_ = Type.AABBox;
            aabbox_ = aabbox;
        }

        ///Get type of the volume.
        @property Type type() const pure nothrow {return type_;}

        ///Get the volume as an AABBox (type must be AABBox).
        @property ref const(Rectf) aabbox() const pure nothrow 
        in
        {
            assert(type_ == Type.AABBox, 
                   "Unexpected volume type (trying to read a volume as an aabbox)");
        }
        body
        {
            return aabbox_;
        }
}
