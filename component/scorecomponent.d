//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Makes an entity increase its killer's score when it dies.
module component.scorecomponent;


import util.yaml;


/// Makes an entity increase its killer's score when it dies.
struct ScoreComponent
{
    /// Experience value of this entity.
    uint exp;

    /// Load from a YAML node. Throws YAMLException on error.
    this(ref YAMLNode yaml)
    {
        exp = yaml["exp"].as!uint;
    }
}
