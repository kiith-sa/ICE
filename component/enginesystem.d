
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///System that uses engine components to determine entities' movement.
module component.enginesystem;


import std.algorithm;

import math.vector2;
import time.gametime;

import component.enginecomponent;
import component.entitysystem;
import component.physicscomponent;
import component.system;


///System that uses engine components to determine entities' movement.
class EngineSystem : System
{
    private:
        ///Entity system whose data we're processing.
        EntitySystem entitySystem_;
        
        ///Game time subsystem.
        const GameTime gameTime_;

    public:
        /**
         * Construct an EngineSystem working on entities from specified EntitySystem
         * and using specified game time subsystem to determine time.
         */
        this(EntitySystem entitySystem, const GameTime gameTime)
        {
            entitySystem_ = entitySystem;
            gameTime_     = gameTime;
        }

        ///Update entities' velocities based on their engines.
        void update()
        {
            foreach(Entity e, 
                    ref EngineComponent  engine,
                    ref PhysicsComponent physics;
                    entitySystem_)
            {
                auto velocity  = &physics.velocity;
                //Rotate accelerationDirection from entity space to world space.
                auto direction = engine.accelerationDirection;
                direction.rotate(physics.rotation);

                if(engine.instantAcceleration)
                {
                    //If accelerationDirection is zero, this is also zero, as expected.
                    *velocity = engine.maxSpeed * direction;
                    continue;
                }

                //Acceleration for current time step.
                const acceleration = engine.acceleration * gameTime_.timeStep;
                //If the engine is disabled, decelerate.
                if(direction.isZero)
                {
                    *velocity *= max(0.0f, 1.0f - acceleration / velocity.length);
                    continue;
                }

                //Accelerate, and if we go over max speed, decrease velocity to 
                //max speed. 
                //This has a nice side effect of decreasing velocity in our 
                //previous direction, emulating friction.
                //It's a hacky solution and definitely not realistic, but simple
                //and good enough for now.
                *velocity += direction * acceleration;
                if(velocity.length > engine.maxSpeed){velocity.length = engine.maxSpeed;}
            }
        }
}
