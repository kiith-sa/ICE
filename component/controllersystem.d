
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///System that handles player/script control of entities.
module component.controllersystem;


import std.algorithm;
import std.math;

import ice.player;
import containers.lazyarray;
import math.vector2;
import time.gametime;
import util.resourcemanager;
import util.yaml;

import component.controllercomponent;
import component.dumbscriptcomponent;
import component.enginecomponent;
import component.entitysystem;
import component.playercomponent;
import component.physicscomponent;
import component.system;


///System that handles player/script control of entities.
class ControllerSystem : System
{
    private:
        ///Entity system whose data we're processing.
        EntitySystem entitySystem_;

        ///Game time subsystem.
        const GameTime gameTime_;

        ///Reference to the resource manager handling YAML loading.
        ResourceManager!YAMLNode yamlManager_;

        ///Loaded dumb scripts.
        LazyArray!DumbScript dumbScripts_;

    public:
        /**
         * Construct a ControllerSystem working on entities from specified EntitySystem
         * and using specified game time subsystem to determine time.
         */
        this(EntitySystem entitySystem, const GameTime gameTime)
        {
            entitySystem_ = entitySystem;
            gameTime_     = gameTime;
            dumbScripts_.loaderDelegate(&loadDumbScript);
        }

        ///Provide a reference to the YAML resource manager. 
        ///
        ///Must be called at least once after construction.
        @property void yamlManager(ResourceManager!YAMLNode rhs) @safe pure nothrow
        {
            yamlManager_ = rhs;
        }

        /**
         * Update the ControllerSystem, processing entities with ControllerComponents.
         *
         * Player controls the ControllerComponent, which in turn is used to
         * control the EngineComponent of the entity.
         */
        void update()
        {
            //Could be moved to a DumbScriptSystem.

            //Allow dumb scripts to control their entities.
            foreach(ref Entity e,
                    ref ControllerComponent control,
                    ref DumbScriptComponent scriptComponent; 
                    entitySystem_)
            {
                DumbScript* script = dumbScripts_[scriptComponent.scriptIndex];
                if(script is null)
                {
                    import std.stdio;
                    writeln("WARNING: Could not load dumb scipt ", 
                            scriptComponent.scriptIndex);
                    writeln("Falling back to a placeholder (idle) dumb script");
                    assert(false, "TODO - Placeholder dumb script not implemented");
                }

                script.control(control, scriptComponent, gameTime_.timeStep);
            }

            //Could be moved to a PlayerControlSystem.

            //Allow players to control their entities' ControllerComponents.
            foreach(ref Entity e, 
                    ref ControllerComponent control,
                    ref PlayerComponent     playerComponent;
                    entitySystem_)
            {
                if(playerComponent.player is null) {continue;}
                playerComponent.player.control(e.id, control);
            }

            //Set engines' acceleration directions based on controller data.
            foreach(ref Entity e, 
                    ref ControllerComponent control,
                    ref EngineComponent     engine;
                    entitySystem_)
            {
                engine.accelerationDirection = control.movementDirection;
            }

            //Kill entities if specified by their controller.
            foreach(ref Entity e, ref ControllerComponent control; entitySystem_)
            {
                if(control.die){e.kill();}
            }
        }

    private:
        /**
         * Load a dumb script from specified source file.
         *
         * Params:  sourceName = Name of the script source file in the game directory.
         *          output     = Loaded script will be written here.
         *
         * Returns: true on success, false on failure.
         */
        bool loadDumbScript(string sourceName, out DumbScript output)
        {
            import std.stdio;
            string fail(){return "Failed to load dumb script " ~ sourceName ~ ": ";}
            try
            {
                assert(yamlManager_ !is null, 
                       "Trying to load a dumb script but YAML resource manager has not been set");

                YAMLNode* yamlSource = yamlManager_.getResource(sourceName);
                if(yamlSource is null)
                {
                    writeln(fail() ~ "Couldn't load YAML file " ~ sourceName);
                    return false;
                }
                output = DumbScript(*yamlSource);
            }
            catch(YAMLException e){writeln(fail(), e.msg); return false;}
            return true;
        }
}

