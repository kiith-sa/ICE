
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Allows entities to spawn other entities at certain conditions.
module component.spawnercomponent;


import std.conv;
import std.exception;
import std.string;
import std.typecons;

import containers.lazyarray;
import containers.vector;

import util.yaml;


/**
 * Allows entities to spawn other entities at certain conditions.
 *
 * A SpawnerComponent is a collection of Spawns.
 *
 * A Spawn specifies an entity to spawn (loaded from file),
 * a condition determining when to spawn it, and optionally,
 * it can override any components of the entity.
 */
struct SpawnerComponent
{
    ///Condition that determines whether or not to spawn an entity.
    struct SpawnCondition
    {
        ///Condition type.
        enum Type : ubyte
        {
            /**
             * Uninitialized condition. 
             *
             * When a Spawn is initialized at a weapon, its condition is 
             * uninitialized, and only gets initialized when it's added 
             * to the entity.
             */
            Uninitialized,
            ///Spawn when (or after) an entity dies.
            Death,
            ///Spawn when (or after) a weapon burst is fired.
            WeaponBurst
        }

        ///Type of condition.
        Type type = Type.Uninitialized;

        union 
        {
            ///If type is WeaponBurst, this specifies which weapon has to be fired.
            ubyte weaponIndex;
        }

        ///Load a SpawnCondition from YAML.
        this(ref YAMLNode yaml)
        {
            auto str = yaml.as!string;
            if(str == "death"){type = Type.Death;}
            else if(str.startsWith("weaponBurst"))
            {
                type = Type.WeaponBurst;
                auto parts = str.split();
                string errmsg()
                {
                    return "Invalid weaponBurst spawn condition: \"" ~ str ~ "\""
                           "weaponBurst spawn condition must be in format "
                           "\"weaponBurst x\" where x specifies the weapon.";
                }

                enforce(parts.length == 2, new YAMLException(errmsg()));
                try{weaponIndex = to!ubyte(parts[2]);}
                catch(ConvException e)
                {
                    throw new YAMLException(errmsg());
                }
            }
        }
    }

    ///Specifies entity to spawn, condition to spawn it at and optionally overrides components.
    struct Spawn 
    {
        static bool CAN_INITIALIZE_WITH_ZEROES;

        //Might be slow, but try this first. Maybe a good benchmark for D:YAML.
        ///YAML node that overrides components of the spawnee.
        YAMLNode componentOverrides;

        ///Points to the EntityPrototype of the spawnee.
        LazyArrayIndex spawnee;

        ///How many seconds to spawn after the condition is fired.
        float delay = 0.0f;

        ///Condition that determines when to spawn.
        SpawnCondition condition;

        ///Are any components of the spawnee overridden by componentOverrides?
        bool hasComponentOverrides;

        ///Should PhysicsComponent (e.g. position) of the spawnee be relative to the spawner?
        bool relativePhysics;

        /**
         * Load a Spawn from YAML.
         *
         * Params:  yaml          = YAML node to load fromYAML
         *          loadCondition = Should the spawn condition be loaded?
         *                          (false for projectile spawns in weapons as the
         *                          WeaponSystem decides their spawn conditions)
         */
        this(ref YAMLNode yaml, Flag!"LoadCondition" loadCondition)
        {
            spawnee = LazyArrayIndex(yaml["entity"].as!string);
            if(loadCondition) 
            {
                condition = SpawnCondition(yaml["condition"]);
            }
            relativePhysics = yaml.containsKey("relativePhysics")
                            ? yaml["relativePhysics"].as!bool 
                            : true;
            delay = yaml.containsKey("delay")
                  ? fromYAML!(float, "a >= 0.0f")(yaml["delay"], "spawn constructor")
                  : 0.0f;
            if(yaml.containsKey("components"))
            {
                hasComponentOverrides = true;
                componentOverrides = yaml["components"];
            }
        }
    }
    
    ///Spawns that might be spawned by this SpawnerComponent.
    Vector!Spawn spawns;

    ///Load a SpawnerComponent from YAML.
    this(ref YAMLNode yaml)
    {
        spawns.reserve(yaml.length);
        foreach(ref YAMLNode spawn; yaml)
        {
            spawns ~= Spawn(spawn, Yes.LoadCondition);
        }
    }

    ///Add a spawn (used by WeaponSystem to add projectile spawns).
    void addSpawn(ref Spawn spawn)
    {
        spawns ~= spawn;
    }
}
