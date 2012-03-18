
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///System that handles player control of entities.
module component.controllersystem;


import std.conv;
import std.math;

import ice.player;
import math.vector2;

import component.controllercomponent;
import component.enginecomponent;
import component.entitysystem;
import component.physicscomponent;
import component.system;


///System that handles player control of entities.
class ControllerSystem : System
{
    private:
        ///Entity system whose data we're processing.
        EntitySystem entitySystem_;

        ///Maps entities to players that control them.
        Player[EntityID] entityToController_;

    public:
        ///Construct a ControllerSystem working on entities from specified EntitySystem.
        this(EntitySystem entitySystem)
        {
            entitySystem_ = entitySystem;
        }

        ///Destroy the ControllerSystem.
        ~this()
        {
            clear(entityToController_);
        }

        /**
         * Set controller player of entity with specified ID.
         *
         * Note that each entity with a ControllerComponent must have a 
         * controller player set.
         *
         * Params:  id     = ID of the controlled entity.
         *          player = Player to control the entity.
         */
        void setEntityController(EntityID id, Player controller)
        {
            entityToController_[id] = controller;
        }

        /**
         * Update the ControllerSystem, processing entities with ControllerComponents.
         *
         * Player controls the ControllerComponent, which in turn is used to
         * control the EngineComponent of the entity.
         */
        void update()
        {
            foreach(Entity e, 
                    ref ControllerComponent control, 
                    ref EngineComponent     engine;
                    entitySystem_)
            {
                assert(null !is (e.id in entityToController_),
                       "Entity with a ControllerComponent but no controlling "
                       "player: " ~ to!string(e.id));

                //Allow player to control the ControllerComponent.
                auto controller = entityToController_[e.id];
                controller.control(e.id, control);

                //Set engine acceleration direction based on controller data.
                auto direction = &engine.accelerationDirection;
                *direction = Vector2f(0.0f, 0.0f);
                if(control.up)   {*direction += Vector2f(0.0f, 1.0f);}
                if(control.down) {*direction += Vector2f(0.0f, -1.0f);}
                if(control.left) {*direction += Vector2f(1.0f, 0.0f);}
                if(control.right){*direction += Vector2f(-1.0f, 0.0f);}
            }
        }
}

