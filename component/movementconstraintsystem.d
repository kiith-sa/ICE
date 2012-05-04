
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///System that handles movement constraints.
module component.movementconstraintsystem;


import component.entitysystem;
import component.movementconstraintcomponent;
import component.ownercomponent;
import component.physicscomponent;
import component.volumecomponent;
import component.system;

import math.vector2;


///System that handles movement constraints.
class MovementConstraintSystem : System
{
    private:
        ///Entity system whose data we're processing.
        EntitySystem entitySystem_;

    public:
        /**
         * Construct a MovementConstraintSystem working on entities from specified EntitySystem.
         */
        this(EntitySystem entitySystem)
        {
            entitySystem_ = entitySystem;
        }

        ///Update physics state of all entities with PhysicsComponents.
        void update()
        {
            foreach(ref Entity e, 
                    ref MovementConstraintComponent constraint, 
                    ref PhysicsComponent physics; 
                    entitySystem_)
            {
                //Update constraint position if it's e.g. constrained to an owner.
                constraint.position = constraintPosition(e, constraint);
                final switch(constraint.type)
                {
                    case MovementConstraintComponent.Type.AABBox:
                        applyConstraintAABBox(e, constraint, physics);
                        break;
                    case MovementConstraintComponent.Type.Uninitialized:
                        assert(false, "Uninitialized MovementConstraintComponent");
                }
            }
        }
    private:
        /**
         * Get the position the entity is constrained to.
         *
         * If the entity is constrained to an owner, it is constrained 
         * to its position. Otherwise, it's constrained to position specified 
         * in world space by MovementConstraintComponent.position.
         *
         * Params:  e          = Entity that is constrianed.
         *          constraint = Constraint component of the entity.
         */
        Vector2f constraintPosition(ref Entity e, 
                                    ref const MovementConstraintComponent constraint)
        {
            import std.stdio;
            if(constraint.constrainedToOwner)
            {
                auto owner = e.owner;
                //No owner
                if(owner is null)
                {
                    writeln("An entity's movement is constrained to an owner, "
                            "but it has no owner. Constraining to coords 0,0");
                    return constraint.position;
                }

                auto ownerEntity = entitySystem_.entityWithID(owner.ownerID);
                //Owner is dead but we're still alive
                if(ownerEntity is null)
                {
                    return constraint.position;
                }

                auto ownerPhysics = ownerEntity.physics;
                //Owner has no PhysicsComponent.
                if(ownerPhysics is null)
                {
                    writeln("An entity's movement is constrained to an owner, "
                            "but its owner has no physics component. "
                            "Constraining to coords 0,0");
                    return constraint.position;
                }

                //Constraint to owners' position.
                return ownerPhysics.position;
            }

            return constraint.position;
        }

        /**
         * Apply an AABBox constraint to an entity,
         *
         * This limits the center of the entity to be within the AABBox 
         * specified by the constraint. The volume, if any, of the entity 
         * might still stick out of the area it's constrained to.
         */
        void applyConstraintAABBox(ref Entity e, 
                                   ref const MovementConstraintComponent constraint,
                                   ref PhysicsComponent physics)
        {
            //Clamp position to constraint.

            physics.position = (constraint.aabbox + constraint.position)
                               .clamp(physics.position);
        }
}




