
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Allows an entity to damage other entities at collision.
module component.warheadcomponent;


import util.yaml;


///Allows an entity to damage other entities at collision.
struct WarheadComponent
{
    private static bool DO_NOT_DESTROY_AT_ENTITY_DEATH;

    ///Damage caused (negative for a healing effect).
    int damage;

    ///Does this warhead kill its entity when activated?
    bool killsEntity = true;

    ///Load from a YAML node. Throws YAMLException on error.
    this(ref YAMLNode yaml)
    {
        damage = yaml["damage"].as!int;
        if(yaml.containsKey("killsEntity")){killsEntity = yaml["killsEntity"].as!bool;}
    }
}

