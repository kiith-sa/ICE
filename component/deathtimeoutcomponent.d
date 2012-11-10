
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Component that limits the lifetime of an entity.
module component.deathtimeoutcomponent;


import std.math;

import util.yaml;


///Component that limits the lifetime of an entity.
struct DeathTimeoutComponent
{
    private static bool DO_NOT_DESTROY_AT_ENTITY_DEATH;
    
    ///Time left for the entity to live, in (game time) seconds.
    double timeLeft;

    ///Load from a YAML node. Throws YAMLException on error.
    this(ref YAMLNode yaml) 
    {
        timeLeft = fromYAML!(double, "a >= 0")(yaml, "deathTimeout");
    }

    ///Construct manually.
    this(const double timeLeft) pure nothrow
    {
        this.timeLeft = timeLeft;
    }
}

