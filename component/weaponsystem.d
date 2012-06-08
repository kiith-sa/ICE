
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///System that handles weapon functionality.
module component.weaponsystem;


import std.algorithm;
import std.typecons;

import dgamevfs._;

import containers.fixedarray;
import containers.lazyarray;
import math.vector2;
import memory.memory;
import time.gametime;
import util.yaml;

import component.controllercomponent;
import component.entitysystem;
import component.deathtimeoutcomponent;
import component.enginecomponent;
import component.ownercomponent;
import component.physicscomponent;
import component.spawnercomponent;
import component.spawnersystem;
import component.statisticscomponent;
import component.visualcomponent;
import component.weaponcomponent;
import component.system;


///System that handles weapon functionality.
class WeaponSystem : System
{
    private:
        alias SpawnerComponent.Spawn Spawn;

        ///Weapon "class", containing data shared by all instances of a weapon.
        struct WeaponData
        {
            ///Time period between bursts.
            double burstPeriod;
            ///Number of bursts before we need to reload. 0 means no ammo limit.
            uint ammo         = 0;
            ///Time it takes to reload after running out of ammo.
            double reloadTime = 1.0f;

            ///Spawns to spawn weapon's projectiles, once added to a SpawnerComponent of an Entity.
            FixedArray!Spawn spawns;

            /**
             * Initialize from YAML.
             *
             * Params:  name = Name of the weapon, for debugging.
             *          yaml = YAML node to load from.
             *
             * Returns: true on success, false on failure.
             *
             * Throws:  YAMLException if the weapon could not be loaded (e.g. not enough data).
             */
            void initialize(string name, ref YAMLNode yaml)
            {
                burstPeriod = fromYAML!(double, "a > 0.0")(yaml["burstPeriod"], "burstPeriod");

                //0 means unlimited ammo.
                ammo = yaml.containsKey("ammo") ? yaml["ammo"].as!uint : 0;
                reloadTime = yaml.containsKey("reloadTime")
                           ? fromYAML!(double, "a > 0.0")(yaml["reloadTime"], "reloadTime") 
                           : 0;

                auto burst = yaml["burst"];

                spawns = FixedArray!Spawn(burst.length);
                uint i = 0;
                foreach(ref YAMLNode shot; burst)
                {
                    spawns[i] = loadProjectileSpawn(shot);
                    ++i;
                }
            }
        }

        ///Entity system whose data we're processing.
        EntitySystem entitySystem_;

        ///Game time subsystem.
        const GameTime gameTime_;

        ///Game directory to load weapons and projectiles from.
        VFSDir gameDir_;

        ///Lazily loads and stores weapon data.
        LazyArray!WeaponData weaponData_;

    public:
        /**
         * Construct a WeaponSystem working on entities from specified EntitySystem
         * and using specified game time subsystem to determine time.
         */
        this(EntitySystem entitySystem, const GameTime gameTime)
        {
            entitySystem_ = entitySystem;
            gameTime_     = gameTime;
            weaponData_.loaderDelegate = &loadWeaponData;
        }


        ///Set game directory to load weapons and projectiles from.
        @property void gameDir(VFSDir rhs) pure nothrow
        {
            gameDir_ = rhs;
        }

        ///Fire weapons based on entities' controller components.
        void update()
        {
            const timeStep = gameTime_.timeStep;
            foreach(ref Entity e, 
                    ref WeaponComponent weapons,
                    ref ControllerComponent control,
                    ref PhysicsComponent physics; 
                    entitySystem_)
            {
                weapons.burstStarted.zeroOut();
                import std.stdio;
                foreach(idx, ref weaponInstance; weapons.weapons) with(weaponInstance)
                {
                    ///Loads weapon data if needed.
                    WeaponData* weapon = weaponData_[weaponInstance.dataIndex];
                    if(weapon is null)
                    {
                        writeln("WARNING: Could not load weapon data ", weaponInstance.dataIndex.id);
                        writeln("Falling back to placeholder weapon data...");
                        assert(false, "TODO - Placeholder weapon data not implemented");
                    }

                    if(!weaponInstance.spawnsAdded)
                    {
                        addSpawns(e, *weapon, weaponInstance);
                    }

                    //Are we firing this weapon?
                    const firePressed  = control.firing[weaponSlot];

                    //At initialization, timeSinceLastBurst is infinite so assert that works.
                    static assert(double.infinity + 0.1 == double.infinity);
                    timeSinceLastBurst  += timeStep;
                    //Negative reloadTimeRemaining is no problem - we can reload if <= 0;
                    reloadTimeRemaining -= timeStep;

                    //Start a burst if the player is firing and the time is right.
                    if(firePressed &&
                       reloadTimeRemaining <= 0.0f &&
                       timeSinceLastBurst >= weapon.burstPeriod)
                    {
                        initiateBurst(weaponInstance, *weapon, e.statistics);
                        weapons.burstStarted[idx] = true;
                    }
                }
            }
        }

    private:
        /**
         * Add spawns a weapon to the SpawnerComponent of the entity.
         *
         * Weapon component/system logic only decides when bursts occur.
         * Projectiles are actually spawned by Spawner component/system.
         * When a WeaponComponent of a particular Entity is first encountered,
         * its projectiles are added to SpawnerComponent of that Entity.
         * In order for this to work, every Entity with a WeaponComponent must
         * also have a SpawnerComponent.
         *
         * Params:  e              = Entity the weapon instance belongs to.
         *          weapon         = "Class" of the weapon.
         *          weaponInstance = Instance of the weapon belonging to the entity.
         */
        void addSpawns(ref Entity e, ref WeaponData weapon, 
                       ref WeaponComponent.Weapon weaponInstance)
        {
            auto spawner = e.spawner;
            assert(spawner !is null, 
                   "Entity has a WeaponComponent but not SpawnerComponent. "
                   "Code that spawns the entity must ensure that if it has a "
                   "WeaponComponent, it has a SpawnerComponent as well.");

            //Not by reference - we need a copy so we can modify spawn condition
            foreach(spawn; weapon.spawns)
            {
                alias SpawnerComponent.SpawnCondition SpawnCondition;
                //Spawn condition to spawn when at weapon burst.
                SpawnCondition condition;
                condition.type = SpawnCondition.Type.WeaponBurst;
                condition.weaponIndex = weaponInstance.weaponSlot;
                spawn.condition = condition;
                spawner.addSpawn(spawn);
            }

            weaponInstance.spawnsAdded = true;
        }

        /**
         * Limited ammo logic called from weapon handling code when starting a burst.
         *
         * Params:  weaponInstance = Instance of the weapon we're processing.
         *          weapon         = "Class" of the weapon.
         */
        static void processAmmo(ref WeaponComponent.Weapon weaponInstance,
                                ref const WeaponData weapon) pure nothrow
        {
            assert(weapon.ammo != 0, "Calling processAmmo on a weapon with infinite ammo");

            //Use up one unit if ammo and start reloading if we used all of it.
            with(weaponInstance)
            {
                assert(ammoConsumed < weapon.ammo, 
                       "Firing but we've consumed all our ammo");
                ++ammoConsumed;

                if(ammoConsumed < weapon.ammo){return;}

                //We've used up all ammo, start reloading.
                reloadTimeRemaining = weapon.reloadTime;
                ammoConsumed        = 0;
            }
        }

        /**
         * Start a burst, using up ammo and handling statistics if needed. 
         *
         * Params:  weaponInstance = Instance of the weapon we're processing.
         *          weapon         = "Class" of the weapon.
         *          statistics     = StatisticsComponent of the firing entity.
         *                           null if there is no such component.
         */
        static void initiateBurst(ref WeaponComponent.Weapon weaponInstance,
                                  ref const WeaponData weapon, 
                                  StatisticsComponent* statistics)
        {
            with(weaponInstance)
            {
                //If the ammo is not infinite (0), use up ammo.
                if(weapon.ammo != 0)
                {
                    processAmmo(weaponInstance, weapon);
                }

                timeSinceLastBurst = 0.0f;

                if(null !is statistics)
                {
                    ++statistics.burstsFired;
                }
            }
        }

        ///Load weapon data from file with specified name to output.
        bool loadWeaponData(string name, out WeaponData output)
        {
            import std.stdio;
            string fail(){return "Failed to load weapon data " ~ name ~ ": ";}
            try
            {
                assert(gameDir_ !is null, 
                       "Trying to load a weapon but game directory has not been set");
                auto yaml = loadYAML(gameDir_.file(name));
                output.initialize(name, yaml);
            }
            catch(YAMLException e)
            {
                writeln(fail() ~ e.msg); return false;
            }
            catch(VFSException e) 
            {
                writeln(fail() ~ e.msg); return false;
            }
            return true;
        }
}

/**
 * Specialized function to load a projectile spawn from YAML.
 *
 * The major difference is that accelerateForward is set to true.
 *
 * There is also code to support legacy projectile syntax. This will be removed.
 *
 * Params:  yaml = YAML node to load fromYAML
 */
Spawn loadProjectileSpawn(ref YAMLNode yaml)
{
    auto result = Spawn(yaml, No.entityRequired);
    with(result)
    {
        loadProjectileLegacy(result, yaml);
        accelerateForward = true;
    }

    return result;
}

private:

alias SpawnerComponent.Spawn Spawn;

import std.stdio;

///Backwards compatibility - load old projectile spawning YAML tags. Will be removed.
void loadProjectileLegacy(ref Spawn spawn, ref YAMLNode yaml)
{
    enum warning = 
        "WARNING: projectile, position, direction and speed tags in "    ~ 
        "weapon bursts are deprecated and will be removed.\nCode using " ~
        "them must be rewritten by overriding components.\n\n\n"         ~
        "Example:\n"                                                     ~
        "\nold:\n"                                                       ~
        " - projectile: projectiles/shieldbullet.yaml\n"                 ~
        "   delay: 0.0\n"                                                ~
        "   position: [0.0, 35.0]\n"                                     ~
        "   direction: 0.8\n"                                            ~
        "   speed: 50.0\n"                                               ~
        "\nnew:\n"                                                       ~
        " - entity: projectiles/shieldbullet.yaml\n"                     ~
        "   delay: 0.0\n"                                                ~
        "   components:\n"                                               ~
        "     physics:\n"                                                ~
        "       position: [0.0, 35.0]\n"                                 ~
        "       rotation: 0.8\n"                                         ~
        "       speed:    50.0\n";

    const hasPosition   = yaml.containsKey("position");
    const hasDirection  = yaml.containsKey("direction");
    const hasSpeed      = yaml.containsKey("speed");
    const hasProjectile = yaml.containsKey("projectile");

    if(!hasPosition && !hasDirection && !hasSpeed && !hasProjectile){return;}

    if(hasProjectile)
    {
        spawn.spawnee = LazyArrayIndex(yaml["projectile"].as!string);
        writeln(warning);
    }

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

    writeln(warning);

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
string loadProjectileEntity(ref YAMLNode yaml)
{
    if(yaml.containsKey("entity")){return yaml["entity"].as!string;}
    writeln("WARNING: Weapon projectile name should now be specified "
            "under the \"entity\" key, not \"projectile\"");
    return yaml["projectile"].as!string;
}
