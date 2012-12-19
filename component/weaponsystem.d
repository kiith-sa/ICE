
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///System that handles weapon functionality.
module component.weaponsystem;


import std.algorithm;
import std.typecons;

import containers.fixedarray;
import containers.lazyarray;
import math.vector2;
import memory.memory;
import time.gametime;
import util.resourcemanager;
import util.yaml;

import component.controllercomponent;
import component.entitysystem;
import component.exceptions;
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
        /// Entity system whose data we're processing.
        EntitySystem entitySystem_;

        /// Game time subsystem.
        const GameTime gameTime_;

        /// Reference to the resource manager handling YAML loading.
        ResourceManager!YAMLNode yamlManager_;

        /// Lazily loads and stores weapon data.
        LazyArray!WeaponData weaponData_;

        /// WeaponData used when weapon data loading fails.
        WeaponData placeholderWeaponData_;

    public:
        /// Construct a WeaponSystem working on entities from specified EntitySystem
        /// and using specified game time subsystem to determine time.
        this(EntitySystem entitySystem, const GameTime gameTime)
        {
            entitySystem_ = entitySystem;
            gameTime_     = gameTime;
            weaponData_.loaderDelegate = &loadWeaponData;
        }

        /// Provide a reference to the YAML resource manager. 
        /// 
        /// Must be called at least once after construction.
        ///
        /// Throws:  SystemInitException on failure.
        @property void yamlManager(ResourceManager!YAMLNode rhs)
        {
            yamlManager_ = rhs;
            if(!loadWeaponData("placeholder/weapon.yaml", placeholderWeaponData_))
            {
                throw new SystemInitException("Failed to load placeholder weapon data");
            }
        }

        /// Fire weapons based on entities' controller components.
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
                    WeaponData* weapon = weaponInstance.placeholder
                        ? &placeholderWeaponData_ 
                        : weaponData_[weaponInstance.dataIndex];
                    if(weapon is null)
                    {
                        writeln("WARNING: Could not load weapon data ", weaponInstance.dataIndex);
                        writeln("Falling back to placeholder weapon data...");
                        weapon = &placeholderWeaponData_;
                        weaponInstance.placeholder = true;
                    }

                    if(!weaponInstance.spawnsAdded)
                    {
                        addSpawns(e, *weapon, cast(ubyte)idx, weaponInstance);
                    }

                    //Are we firing this weapon?
                    const firePressed  = control.firing[weaponSlot];

                    //At initialization, timeSinceLastBurst is infinite so assert that works.
                    static assert(double.infinity + 0.1 == double.infinity);
                    timeSinceLastBurst  += timeStep;
                    //Negative reloadTimeRemainingRatio is no problem - we can reload if <= 0;
                    reloadTimeRemainingRatio -= timeStep / weapon.reloadTime;

                    //Start a burst if the player is firing and the time is right.
                    if(firePressed &&
                       reloadTimeRemainingRatio <= 0.0f &&
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
         *          weaponIndex    = Index of the weapon in the WeaponComponent
         *                           (may be different from weapon slot).
         *          weaponInstance = Instance of the weapon belonging to the entity.
         */
        void addSpawns(ref Entity e, ref WeaponData weapon, 
                       const ubyte weaponIndex,
                       ref WeaponComponent.Weapon weaponInstance)
        {
            auto spawner = e.spawner;
            assert(spawner !is null, 
                   "Entity has a WeaponComponent but not SpawnerComponent. "
                   "Code that spawns the entity must ensure that if it has a "
                   "WeaponComponent, it has a SpawnerComponent as well.");

            spawner.preallocateExtraSpawns(weapon.spawns.length);
            //Not by reference - we need a copy so we can modify spawn condition
            foreach(spawn; weapon.spawns)
            {
                alias SpawnerComponent.SpawnCondition SpawnCondition;
                //Spawn condition to spawn when at weapon burst.
                SpawnCondition condition;
                condition.type = SpawnCondition.Type.WeaponBurst;
                condition.weaponIndex = weaponIndex;
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
                reloadTimeRemainingRatio = 1.0f;//weapon.reloadTime;
                ammoConsumed             = 0;
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
                assert(yamlManager_ !is null, 
                       "Trying to load a weapon but YAML resource manager has not been set");

                YAMLNode* yamlSource = yamlManager_.getResource(name);
                if(yamlSource is null)
                {
                    writeln(fail() ~ "Couldn't load YAML file " ~ name);
                    return false;
                }

                output.initialize(name, *yamlSource);
            }
            catch(YAMLException e)
            {
                writeln(fail() ~ e.msg); return false;
            }
            return true;
        }
}

private:

alias SpawnerComponent.Spawn Spawn;
