
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


module component.spawnersystem;


import std.algorithm;
import std.typecons;

import dgamevfs.exceptions;
import dgamevfs.vfs;

import component.controllercomponent;
import component.entitysystem;
import component.ownercomponent;
import component.spawnercomponent;
import component.system;

import containers.lazyarray;
import containers.vector;
import math.vector2;
import memory.memory;
import time.gametime;
import util.frameprofiler;
import util.yaml;


/**
 * System that handles spawning of entities (e.g. projectiles fired from weapons).
 *
 * Must run after any system that might kill an entity, and after WeaponSystem.
 */
class SpawnerSystem : System 
{
    private:
        ///Entity system whose data we're processing.
        EntitySystem entitySystem_;

        ///Game time subsystem.
        const GameTime gameTime_;

        ///Prototypes of entities loaded from files.
        LazyArray!(EntityPrototype*) entityPrototypes_;

        ///Prototype to be spawned associated with in-game time when it should be spawned.
        alias Tuple!(real, "time", EntityPrototype*, "spawn") Spawn;

        /**
         * Stores prototypes of entities whose spawn conditions have been met.
         *
         * spawnStorage_[0 .. spawnsUsed_] are prototypes to be spawned. Other 
         * entries are preallocated and ready to be reused.
         *
         * TODO Possible optimizations:
         *
         * 1) Binary heap, sorted array, or sorted array of indices to this array.
         *
         * 2) Do not save spawns with delay 0 into spawnStorage_ - have a special 
         *    code path that spawns them directly from stack.
         */
        Vector!Spawn spawnStorage_;

        ///Number of used items in spawnStorage_.
        size_t spawnsUsed_;

        ///Game data directory.
        VFSDir gameDir_;

    public:
        /**
         * Construct a SpawnerSystem.
         *
         * Params:  entitySystem = EntitySystem whose entities we're processing.
         *          gameTime     = Game time subsystem.
         */
        this(EntitySystem entitySystem, const GameTime gameTime)
        {
            spawnStorage_.reserve(1024);
            const preallocLength = 384;
            spawnStorage_.length = preallocLength;
            foreach(s; 0 .. preallocLength)
            {
                spawnStorage_[s].spawn = alloc!EntityPrototype;
            }
            entitySystem_ = entitySystem;
            gameTime_     = gameTime;
            entityPrototypes_.loaderDelegate = &loadEntityFromFile;
        }

        ///Destroy a SpawnerSystem, freeing all used resources.
        ~this()
        {
            //Free any spawns that didn't haven't reached the time to be spawned yet.
            foreach(ref spawn; spawnStorage_)
            {
                free(spawn.spawn);
            }
            //Free entity prototypes loaded from files.
            foreach(ref prototype; entityPrototypes_)
            {
                free(prototype);
            }
        }

        ///Set game directory to load entities from.
        @property void gameDir(VFSDir rhs) pure nothrow
        {
            gameDir_ = rhs;
        }

        void update()
        {
            //Check if any spawn has met its condition and if so, add it to spawnStorage_.
            foreach(ref Entity e, ref SpawnerComponent spawner; entitySystem_)
            {
                foreach(ref spawn; spawner.spawns)
                {
                    processSpawn(e, spawn);
                }
            }

            const time = gameTime_.gameTime;

            //Spawn any spawns that have reached their spawn time.
            for(size_t s = 0; s < spawnsUsed_; ++s)
            {
                if(spawnStorage_[s].time > time){continue;}

                //Spawn.
                entitySystem_.newEntity(*(spawnStorage_[s].spawn));
                //Remove from spawnStorage_ (it's unsorted, so removing can be fast).
                --spawnsUsed_;
                swap(spawnStorage_[s], spawnStorage_[spawnsUsed_]);
            }
        }

    private:
        ///Determine if a spawn condition is met and if so, add a spawn to spawnStorage_.
        void processSpawn(ref Entity spawner, ref SpawnerComponent.Spawn spawn)
        {
            if(spawnConditionMet(spawner, spawn.condition))
            {
                this.prepareSpawn(spawner, spawn);
            }
        }

        ///Shortcut for readability.
        alias SpawnerComponent.SpawnCondition Condition;

        ///Has a spawn condition been met?
        bool spawnConditionMet(ref Entity spawner, 
                               ref Condition condition) const pure nothrow
        {
            with(Condition.Type) final switch(condition.type) 
            {
                case Death:         return spawner.killed;
                case Spawn:         return spawner.spawned;
                case WeaponBurst:   return burstConditionMet(spawner, condition);
                case Periodic:      return periodicConditionMet(spawner, condition);
            }
        }

        ///Has a weapon burst spawn condition been met?
        bool burstConditionMet(ref Entity spawner, 
                               ref Condition condition) const pure nothrow
        {
            auto weapons = spawner.weapon;
            return weapons is null ? false  
                                   : weapons.burstStarted[condition.weaponIndex];
        }

        ///Has a periodic spawn condition been met?
        bool periodicConditionMet(ref Entity spawner, 
                                  ref Condition condition) const pure nothrow
        {
            condition.timeSinceLastSpawn += gameTime_.timeStep;

            if(condition.timeSinceLastSpawn >= condition.period)
            {
                condition.timeSinceLastSpawn = 0.0f;
                return true;
            }

            return false;
        }

        ///Prepare a spawn, adding it to spawnStorage_ but not spawning (it might have a delay).
        void prepareSpawn(ref Entity spawner, ref SpawnerComponent.Spawn spawn)
        {
            //Get the prototype of the entity to spawn.
            EntityPrototype** prototypePtr = entityPrototypes_[spawn.spawnee];
            if(prototypePtr is null)
            {
                import std.stdio;
                writeln("WARNING: Could not load entity data ", spawn.spawnee.id);
                writeln("Falling back to placeholder entity data...");
                assert(false, "TODO - Placeholder entity data not implemented");
            }

            //Allocate a new spawn or return unused one.
            Spawn* timedSpawn = getFreeSpawn();
            timedSpawn.time = gameTime_.gameTime + spawn.delay;

            //Set the spawn to the prototype and optionally 
            //override its components based on componentOverrides.
            timedSpawn.spawn.clone(**prototypePtr);
            try if(spawn.hasComponentOverrides) 
            {
                timedSpawn.spawn.overrideComponents(spawn.componentOverrides);
            }
            catch(YAMLException e)
            {
                import std.stdio;
                writeln("WARNING: Could not load component overrides when "
                        "spawning an entity: ", e.msg);
                writeln("Ignoring (overriding nothing) ...");
            }

            //Position/rotate/etc the spawnee relative to the spawner
            //(unless the spawnee's physics component says it 
            //should be positioned absolutely).
            auto ePhysics = spawner.physics;
            auto sPhysics = &(timedSpawn.spawn.physics);
            if(ePhysics !is null && !sPhysics.isNull)
            {
                sPhysics.setRelativeTo(*ePhysics);
            }

            if(spawn.spawnerIsOwner)
            {
                timedSpawn.spawn.owner = OwnerComponent(spawner.id);
            }

            if(spawn.accelerateForward && !timedSpawn.spawn.engine.isNull)
            {
                timedSpawn.spawn.engine.accelerationDirection = Vector2f(0.0f, 1.0f);
            }

            //WeaponComponent requires (extends) SpawnerComponent.
            if(!timedSpawn.spawn.weapon.isNull && 
               timedSpawn.spawn.spawner.isNull)
            {
                timedSpawn.spawn.spawner = SpawnerComponent();
            }
            //DumbScriptComponent requires (extends) ControllerComponent.
            if(!timedSpawn.spawn.dumbScript.isNull &&
               timedSpawn.spawn.controller.isNull)
            {
                timedSpawn.spawn.controller = ControllerComponent();
            }
        }

        ///Get unused spawn in spawnStorage_, allocating new one if needed.
        Spawn* getFreeSpawn()
        in
        {
            assert(spawnsUsed_ <= spawnStorage_.length, 
                   "more spawns used than spawnStorage_ holds");
        }
        body
        {
            if(spawnsUsed_ == spawnStorage_.length)
            {
                spawnStorage_.length = spawnStorage_.length + 1;
                spawnStorage_.back.spawn = alloc!EntityPrototype;
            }

            return &spawnStorage_[spawnsUsed_++];
        }

        ///Load entity prototype from file with specified name to output.
        bool loadEntityFromFile(string name, out EntityPrototype* output)
        {
            try 
            {
                assert(gameDir_ !is null, 
                       "Trying to load an entity but game directory has not been set");
                YAMLNode yamlSource;
                {
                    auto zone  = Zone("SpawnerSystem EntityPrototype file reading & YAML parsing");
                    yamlSource = loadYAML(gameDir_.file(name));
                }

                {
                    auto zone = Zone("SpawnerSystem EntityPrototype allocation " ~ 
                                     "(after loading from file)");
                    output = alloc!EntityPrototype(name, yamlSource);
                }
            }
            catch(YAMLException e){return false;}
            catch(VFSException e){return false;}

            return true;
        }
}
