
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Allows entities to spawn other entities at certain conditions.
module component.spawnercomponent;


import std.algorithm;
import std.conv;
import std.exception;
import std.stdio;
import std.string;
import std.typecons;

import containers.lazyarray;
import containers.vector;
import math.vector2;
import memory.allocator;
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
            ///Spawn when (or after) an entity dies.
            Death,
            ///Spawn when (or after) an entity is spawned.
            Spawn,
            ///Spawn when (or after) a weapon burst is fired.
            WeaponBurst,
            ///Spawn in periodic intervals.
            Periodic
        }

        ///Type of condition.
        Type type = Type.Spawn;

        union 
        {
            ///If type is WeaponBurst, this specifies which weapon has to be fired.
            ubyte weaponIndex;

            struct
            {
                ///If type is Periodic, this is the period in seconds.
                float period;
                /**
                 * If type is Periodic, this is the time since last spawn in seconds.
                 *
                 * It is initialized by infinity so the first spawn always 
                 * gets triggered right after the spawner is created.
                 */
                float timeSinceLastSpawn = float.infinity;
            }
        }

        ///Load a SpawnCondition from YAML.
        this(ref YAMLNode yaml)
        {
            auto str = yaml.as!string;
            if(str == "death"){type = Type.Death;}
            if(str == "spawn"){type = Type.Spawn;}
            else if(str.startsWith("weaponBurst"))
            {
                type = Type.WeaponBurst;
                auto parts = str.split();
                string weaponError()
                {
                    return "Invalid weaponBurst spawn condition: \"" ~ str ~ "\""
                           "weaponBurst spawn condition must be in format "
                           "\"weaponBurst x\" where x specifies the weapon.";
                }

                enforce(parts.length == 2, new YAMLException(weaponError()));
                try{weaponIndex = to!ubyte(parts[1]);}
                catch(ConvException e)
                {
                    throw new YAMLException(weaponError());
                }
            }
            else if(str.startsWith("periodic"))
            {
                type = Type.Periodic;
                auto parts = str.split();
                string periodError()
                {
                    return "Invalid periodic spawn condition: \"" ~ str ~ "\""
                           "periodic spawn condition must be in format "
                           "\"periodic t\" where x specifies the period in seconds.";
                }

                enforce(parts.length == 2, new YAMLException(periodError()));
                try
                {
                    period = to!float(parts[1]);
                    enforce(period > 0.0f, 
                            new YAMLException("Negative or zero spawning period"));
                }
                catch(ConvException e)
                {
                    throw new YAMLException(periodError());
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

        ///Is the spawner spawnee's owner?
        bool spawnerIsOwner;

        /**
         * Should the spawnee's engine (if any) accelerationDirection 
         * be set to (0, 1) after spawn?
         *
         * (Used by projectiles)
         */
        bool accelerateForward = false;

        /**
         * Load a Spawn from YAML.
         *
         * Params:  yaml = YAML node to load from 
         */
        this(ref YAMLNode yaml)
        {
            spawnee = LazyArrayIndex(yaml["entity"].as!string);

            //By default, spawn condition is "spawn" .
            if(yaml.containsKey("condition"))
            {
                condition = SpawnCondition(yaml["condition"]);
            }

            spawnerIsOwner = yaml.containsKey("spawnerIsOwner")
                           ? yaml["spawnerIsOwner"].as!bool 
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
    Vector!(Spawn, BufferSwappingAllocator!(Spawn, 80)) spawns;

    ///Load a SpawnerComponent from YAML.
    this(ref YAMLNode yaml)
    {
        spawns.reserve(yaml.length);
        foreach(ref YAMLNode spawn; yaml)
        {
            spawns ~= Spawn(spawn);
        }
    }

    ///Preallocate space for extra more spawns.
    void preallocateExtraSpawns(const size_t extra)
    {
        spawns.reserve(spawns.length + extra);
    }

    ///Add a spawn (used by WeaponSystem to add projectile spawns).
    void addSpawn(ref Spawn spawn)
    {
        spawns ~= spawn;
    }
}
