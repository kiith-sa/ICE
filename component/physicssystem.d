
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///System that handles entity movement and physics interactions.
module component.physicssystem;


import time.gametime;

import component.entitysystem;
import component.physicscomponent;
import component.system;


///System that handles entity movement and physics interactions.
class PhysicsSystem : System
{
    private:
        ///Entity system whose data we're processing.
        EntitySystem entitySystem_;

        ///Game time subsystem.
        const GameTime gameTime_;

    public:
        /**
         * Construct a PhysicsSystem working on entities from specified EntitySystem
         * and using specified game time subsystem to determine time.
         */
        this(EntitySystem entitySystem, const GameTime gameTime)
        {
            entitySystem_ = entitySystem;
            gameTime_     = gameTime;
        }

        ///Update physics state of all entities with PhysicsComponents.
        void update()
        {
            //Move the entities.
            foreach(ref Entity e, ref PhysicsComponent phys; entitySystem_)
            {
                phys.position += gameTime_.timeStep * phys.velocity;
            }
        }
}


