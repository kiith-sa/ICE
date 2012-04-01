
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
import component.playercomponent;
import component.physicscomponent;
import component.system;


///System that handles player control of entities.
class ControllerSystem : System
{
    private:
        ///Entity system whose data we're processing.
        EntitySystem entitySystem_;

    public:
        ///Construct a ControllerSystem working on entities from specified EntitySystem.
        this(EntitySystem entitySystem)
        {
            entitySystem_ = entitySystem;
        }

        /**
         * Update the ControllerSystem, processing entities with ControllerComponents.
         *
         * Player controls the ControllerComponent, which in turn is used to
         * control the EngineComponent of the entity.
         */
        void update()
        {
            foreach(ref Entity e, 
                    ref ControllerComponent control,
                    ref EngineComponent     engine,
                    ref PlayerComponent     playerComponent;
                    entitySystem_)
            {
                //Allow player to control the ControllerComponent.
                auto player = playerComponent.player;
                player.control(e.id, control);

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

