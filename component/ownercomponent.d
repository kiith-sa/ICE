
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Gives entity an owner entity (e.g. entity that fired a projectile is its owner).
module component.ownercomponent;


import util.yaml;

import component.entitysystem;


///Gives entity an owner entity (e.g. entity that fired a projectile is its owner).
struct OwnerComponent
{
    ///Owner of the entity.
    EntityID ownerID;

    ///Load from a YAML node. Throws YAMLException on error.
    this(ref YAMLNode yaml)
    {
        throw new YAMLException("Can't specify OwnerComponent in YAML - it's run-time only");
    }

    ///Construct from ID of the owner entity.
    this(const EntityID id) pure nothrow
    {
        ownerID = id;
    }
}

