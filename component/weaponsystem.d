
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///System that handles weapon functionality.
module component.weaponsystem;


import std.algorithm;

import dgamevfs._;

import containers.fixedarray;
import containers.lazyarray;
import math.vector2;
import time.gametime;
import util.yaml;

import component.controllercomponent;
import component.entitysystem;
import component.deathtimeoutcomponent;
import component.enginecomponent;
import component.physicscomponent;
import component.visualcomponent;
import component.weaponcomponent;
import component.system;


///System that handles weapon functionality.
class WeaponSystem : System
{
    private:
        ///Weapon "class", containing data shared by all instances of a weapon.
        struct WeaponData
        {
            ///Time period between bursts.
            double burstPeriod;
            ///Number of bursts before we need to reload. 0 means no ammo limit.
            uint ammo        = 0;
            ///Time it takes to reload after running out of ammo.
            double reloadTime = 1.0f;

            /** 
             * Specification of a shot in the burst. 
             *
             * Each burst comprises multiple shots, which can shoot different
             * projectiles in different directions, etc.
             */
            struct Shot
            {
                ///Index pointing to the shot's projectile in the WeaponSystem.
                LazyArrayIndex projectileIndex;
                ///Position of the shot in entity space.
                Vector2f position = Vector2f(0.0f, 0.0f);
                ///Delay relative to start of the burst. Must be >= 0 and <= burstPeriod.
                double delay      = 0.0f;
                ///Direction to shoot in in entity space.
                float direction   = 0.0f;
                ///Speed to shoot the projectile with. Negative means maximum projectile speed.
                float speed       = -1.0f; //maxSpeed
            }

            ///Shots in one burst, sorted by delay from earliest to latest.
            FixedArray!Shot shots;

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
                shots = FixedArray!Shot(burst.length);
                uint i = 0;
                foreach(ref YAMLNode shot; burst)
                {
                    Shot s;
                    s.projectileIndex = LazyArrayIndex(shot["projectile"].as!string);
                    s.position = shot.containsKey("position") 
                               ? fromYAML!Vector2f(shot["position"], "position")
                               : Vector2f(0.0f, 0.0f);
                    s.direction = shot.containsKey("direction") 
                                ? fromYAML!float(shot["direction"], "direction")
                                : 0.0f;
                    //Negative means fire at max projectile speed.
                    s.speed = shot.containsKey("speed") 
                            ? fromYAML!float(shot["speed"], "speed")
                            : -1.0f;

                    s.delay = shot.containsKey("delay") 
                            ? fromYAML!double(shot["delay"], "delay")
                            : 0.0;
                    if(s.delay > burstPeriod)
                    {
                        import std.stdio;
                        writeln("WARNING: Shot delay in weapon \"" ~ name ~ 
                                "\" longer than burstPeriod. Setting to burstPeriod.");
                        s.delay = burstPeriod;
                    }

                    shots[i] = s;
                    ++i;
                }

                //Sort so we can process shots in chronological order.
                sort!((a, b){return a.delay < b.delay;})(shots[]);
                assert(shots[0].delay <= shots[shots.length - 1].delay,
                       "Weapon shots incorrectly sorted by delay");
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

        ///Lazily loads and stores projectile entity prototypes.
        LazyArray!EntityPrototype projectilePrototypes_;

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
            projectilePrototypes_.loaderDelegate = &loadProjectileData;
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
                import std.stdio;
                foreach(ref weaponInstance; weapons.weapons) with(weaponInstance)
                {
                    ///Loads weapon data if needed.
                    WeaponData* weapon = weaponData_[weaponInstance.dataIndex];
                    if(weapon is null)
                    {
                        writeln("WARNING: Could not load weapon data ", weaponInstance.dataIndex.id);
                        writeln("Falling back to placeholder weapon data...");
                        assert(false, "TODO - Placeholder weapon data not implemented");
                    }

                    //Are we firing this weapon?
                    const firePressed  = control.firing[weaponSlot];

                    //OK: IF weapon.ammo >= 0, we need to check if we're reloading

                    //THEN we need to increase timeSinceLastBurst 

                    //At initialization, timeSinceLastBurst is infinite so assert that works.
                    static assert(double.infinity + 0.1 == double.infinity);
                    timeSinceLastBurst  += timeStep;
                    //Negative reloadTimeRemaining is no problem - we can reload if <= 0;
                    reloadTimeRemaining -= timeStep;

                    //Handle a burst 
                    if(burstInProgress)
                    {
                        assert(shotsSoFarThisBurst < weapon.shots.length, 
                               "We seem to have shot more shots this burst than we have");
                        //If we're out of time, force-shoot all remaining shots.
                        bool flush = timeSinceLastBurst >= weapon.burstPeriod;
                        //Fire anything with delay < timeSinceLastBurst .
                        foreach(ref shot; weapon.shots[shotsSoFarThisBurst .. weapon.shots.length])
                        {
                            //Weapon[shots] is sorted by delay so we can break.
                            if(!flush && shot.delay > timeSinceLastBurst)
                            {
                                break;
                            }

                            fire(physics, shot);

                            ++shotsSoFarThisBurst;
                        }

                        //Done shooting.
                        if(shotsSoFarThisBurst == weapon.shots.length)
                        {
                            finishBurst();
                        }
                    }

                    //Start a burst if the player is firing and the time is right.
                    if(firePressed && 
                       reloadTimeRemaining <= 0.0f &&
                       timeSinceLastBurst >= weapon.burstPeriod)
                    {
                        //If weapon has limited ammo (0 means infinite), use up one unit.
                        if(weapon.ammo > 0)
                        {
                            assert(ammoConsumed < weapon.ammo, 
                                   "Firing but we've consumed all our ammo");
                            ++ammoConsumed;

                            //We've used up all ammo, start reloading.
                            if(ammoConsumed == weapon.ammo)
                            {
                                reloadTimeRemaining = weapon.reloadTime;
                                ammoConsumed        = 0;
                            }
                        }

                        //We can only start a new burst after shooting out all
                        //projectiles from the previous one.
                        assert(!burstInProgress, 
                               "Starting a burst but previous burst is still in "
                               "progress");
                        startBurst();
                    }
                }
            }
        }

    private:
        /**
         * Fire a shot.
         *
         * In practice, firing means spawning a new, projectile, entity.
         *
         * Params:  physics = Physics component of the entity that fired the shot
         *          shot    = Shot to fire.
         */
        void fire(ref PhysicsComponent physics, ref WeaponData.Shot shot) 
        {
            EntityPrototype* prototype = projectilePrototypes_[shot.projectileIndex];
            if(prototype is null)
            {
                import std.stdio;
                writeln("WARNING: Could not load projectile data ", shot.projectileIndex.id);
                writeln("Falling back to placeholder projectile data...");
                assert(false, "TODO - Placeholder projectile data not implemented");
            }

            const direction = physics.rotation + shot.direction;

            //Negative shot speed means shooting the projectile at its maximum speed.
            auto shotSpeed = shot.speed;
            if(shotSpeed < 0)
            {
                shotSpeed = prototype.engine.isNull 
                          ? 0.0f 
                          : prototype.engine.get.maxSpeed;
            }        
            prototype.physics = PhysicsComponent(physics.position + shot.position, 
                                                 direction, 
                                                 angleToVector(direction) * shotSpeed);  
            entitySystem_.newEntity(*prototype);
        }

        ///Load projectile data from file with specified name to output.
        bool loadProjectileData(string name, out EntityPrototype output)
        {
            try 
            {
                assert(gameDir_ !is null, 
                       "Trying to load a projectile but game directory has not been set");
                auto yaml = loadYAML(gameDir_.file(name));
                output = EntityPrototype(name, yaml);                                                
                with(output) if(!engine.isNull)
                {
                    engine.get.accelerationDirection = Vector2f(0.0f, 1.0f);
                }
            }
            catch(YAMLException e){return false;}
            catch(VFSException e){return false;}

            return true;
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
                auto  yaml = loadYAML(gameDir_.file(name));
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