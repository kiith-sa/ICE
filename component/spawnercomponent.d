
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Allows entities to spawn other entities at certain conditions.
module component.spawnercomponent;


import std.conv;
import std.exception;
import std.stdio;
import std.string;

import containers.lazyarray;
import containers.vector;
import math.vector2;
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
         * Params:  yaml = YAML node to load fromYAML
         */
        this(ref YAMLNode yaml)
        {
            spawnee = LazyArrayIndex(yaml["entity"].as!string);
            condition = SpawnCondition(yaml["condition"]);

            relativePhysics = yaml.containsKey("relativePhysics")
                            ? yaml["relativePhysics"].as!bool 
                            : true;
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

        /**
         * Specialized function to load a projectile spawn from YAML.
         *
         * The major differences are that spawn condition is not loaded 
         * (WeaponBurst depending on which weapon is used will be the 
         * spawn condition), and that accelerateForward is set to true.
         *
         * Params:  yaml = YAML node to load fromYAML
         */
        static Spawn loadProjectileSpawn(ref YAMLNode yaml)
        {
            Spawn result;
            with(result)
            {
                spawnee = LazyArrayIndex(loadProjectileEntity(yaml));
                relativePhysics = yaml.containsKey("relativePhysics")
                                ? yaml["relativePhysics"].as!bool 
                                : true;
                spawnerIsOwner = yaml.containsKey("spawnerIsOwner")
                               ? yaml["spawnerIsOwner"].as!bool 
                               : true;
                delay = yaml.containsKey("delay")
                      ? fromYAML!(float, "a >= 0.0f")(yaml["delay"], "loadProjectileSpawn")
                      : 0.0f;

                if(yaml.containsKey("components"))
                {
                    hasComponentOverrides = true;
                    componentOverrides = yaml["components"];
                }

                loadProjectileLegacy(result, yaml);
                accelerateForward = true;
            }

            return result;

        }

        ///Backwards compatibility - load old projectile spawning YAML tags.
        static void loadProjectileLegacy(ref Spawn spawn, ref YAMLNode yaml)
        {
            const hasPosition  = yaml.containsKey("position");
            const hasDirection = yaml.containsKey("direction");
            const hasSpeed     = yaml.containsKey("speed");

            if(!hasPosition && !hasDirection && !hasSpeed){return;}

            if(spawn.hasComponentOverrides && 
               spawn.componentOverrides.containsKey("physics"))
            {
                return;
            }

            if(!spawn.hasComponentOverrides)
            {
                spawn.hasComponentOverrides = 1;
                //rotation/0.0f is a placeholder so we can call YAMLNode ctor.
                spawn.componentOverrides = YAMLNode([YAMLNode("physics")],
                                                    [YAMLNode(["rotation"], [0.0f])]);
            }
            else 
            {
                //rotation/0.0f is a placeholder so we can call YAMLNode ctor.
                spawn.componentOverrides["physics"] = YAMLNode(["rotation"], [0.0f]);
            }

            writeln("WARNING: position, direction and speed tags in weapon "  ~ 
                    "bursts are deprecated and will be removed.\nCode using " ~
                    "them must be rewritten by overriding components.\n\n\n"  ~
                    "Example:\n"                                              ~
                    "\nold:\n"                                                ~
                    " - projectile: projectiles/shieldbullet.yaml\n"          ~
                    "   delay: 0.0\n"                                         ~
                    "   position: [0.0, 35.0]\n"                              ~
                    "   direction: 0.8\n"                                     ~
                    "   speed: 50.0\n"                                        ~
                    "\nnew:\n"                                                ~
                    " - projectile: projectiles/shieldbullet.yaml\n"          ~
                    "   delay: 0.0\n"                                         ~
                    "   components:\n"                                        ~
                    "     physics:\n"                                         ~
                    "       position: [0.0, 35.0]\n"                          ~
                    "       rotation: 0.8\n"                                  ~
                    "       speed:    50.0\n");
            stdout.flush();

            auto physics = &(spawn.componentOverrides["physics"]);

            if(hasPosition)
            {
                (*physics)["position"] = yaml["position"];
            }

            if(hasDirection)
            {
                (*physics)["rotation"] = yaml["direction"];
            }

            if(hasSpeed)
            {
                const rotation = hasDirection ? (*physics)["rotation"].as!float : 0.0f;
                const velocity = angleToVector(rotation) * yaml["speed"].as!float;
                (*physics)["velocity"] = YAMLNode([velocity.x, velocity.y]);
            }
        }

        ///Backward compatibility - use "projectile" as synonym for "entity".
        static string loadProjectileEntity(ref YAMLNode yaml)
        {
            if(yaml.containsKey("entity")){return yaml["entity"].as!string;}
            writeln("WARNING: Weapon projectile name should now be specified "
                    "under the \"entity\" key, not \"projectile\"");
            return yaml["projectile"].as!string;
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
            spawns ~= Spawn(spawn);
        }
    }

    ///Add a spawn (used by WeaponSystem to add projectile spawns).
    void addSpawn(ref Spawn spawn)
    {
        spawns ~= spawn;
    }
}
