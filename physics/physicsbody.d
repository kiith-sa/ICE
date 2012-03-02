
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Base class for physics bodies.
module physics.physicsbody;


import std.algorithm;

import spatial.volume;
import physics.contact;
import physics.physicsengine;
import spatial.spatialmanager;
import math.vector2;
import math.math;


///Body in physics simulation. Currently a (very) simple rigid body.
class PhysicsBody
{
    protected:
        ///Collision volume of this body. If null, this body can't collide.
        const Volume volume_;

        ///Position during previous update in world space, used for spatial management.
        Vector2f positionOld_;
        ///Position in world space.
        Vector2f position_;
        ///Velocity in world space.
        Vector2f velocity_;

        ///Inverse mass of this body. (0 means infinite mass)
        real inverseMass_;

        //we could use a set here, if this is too slow
        ///Bodies we've collided with this frame.
        PhysicsBody[] colliders_;

        ///Index of update when the body is dead (to be removed).
        size_t deadAtUpdate_ = size_t.max;

    public:
        /**
         * Construct a PhysicsBody with specified parameters.
         *
         * Params:    volume   = Collision volume to use for collision detection.
         *                       If null, this body cannot collide with anything.
         *            position = Position in world space.
         *            velocity = Velocity in world space.
         *            mass     = Mass of the body. Can be infinite (immovable object).
         *                       Can't be zero or negative.
         */
        this(const Volume volume, const Vector2f position, const Vector2f velocity, const real mass)
        {
            volume_       = volume;
            positionOld_ = position_ = position;
            velocity_     = velocity;
            this.mass     = mass;
        }

        /**
         * Destroy the body at the end of specified update.
         *
         * This can be used to destroy the body at the current update by passing
         * current updateIndex from the SceneManager.
         * 
         * Note that the body will not be destroyed immediately -
         * At the end of update, all dead bodies' onDie() methods are called 
         * first, and then the bodies are destroyed.
         *
         * Params: updateIndex  = Update to destroy the body at.
         */
        final void die(const size_t updateIndex) pure
        {
            deadAtUpdate_ = updateIndex;
        }

        ///Get position of the body, in world space.
        @property final Vector2f position() const pure {return position_;}

        ///Set position of the body, in world space.
        @property final void position(const Vector2f p)pure {position_ = p;}

        ///Get velocity of the body, in world space.
        @property final Vector2f velocity() const pure {return velocity_;}

        ///Set velocity of the body, in world space.
        @property final void velocity(const Vector2f v) pure {velocity_ = v;}

        ///Set mass of the body. Mass must be positive and can be infinite.
        @property final void mass(const real mass) pure
        in{assert(mass >= 0.0, "Can't set physics body mass to zero or negative.");}
        body
        {
            inverseMass_ = (mass == real.infinity) ? 0.0 : 1.0 / mass;
        }

        ///Get inverse mass of the body.
        @property final real inverseMass() const pure {return inverseMass_;}

        ///Get a reference to collision volume of this body.
        @property final const(Volume) volume() const pure {return volume_;}

        ///Return an array of bodies this body has collided with during last update.
        @property PhysicsBody[] colliders() pure {return colliders_;} 

        ///Has the body collided with anything during the last update?
        @property bool collided() const pure {return colliders_.length > 0;}

    protected:
        /**
         * Update physics state of the body.
         *
         * Params:  timeStep = Time length of the update in seconds.
         *          spatial   = Spatial manager managing the body.
         */
        void update(const real timeStep, SpatialManager!PhysicsBody spatial)
        {
            assert(timeStep >= 0.0, "Can't update a physics body with negative time step");

            position_ += velocity_ * timeStep;
            colliders_.length = 0; 
            //spatial manager does not manage bodies without volumes.
            if(position_ != positionOld_ && volume_ !is null)
            {
                spatial.updateObject(this, positionOld_);
            }
            positionOld_ = position_;
        }

        /**
         * Resolve collision response to a contact.
         *
         * Params:  contact = Contact to respond to. Must involve this body.
         */
        void collisionResponse(ref Contact contact)
        {
            if(equals(inverseMass_, 0.0L)){return;}
            if(equals(contact.inverseMassTotal, 0.0L)){return;}
            Vector2f scaledNormal = contact.contactNormal * contact.desiredDeltaVelocity;
            Vector2f change = scaledNormal * (inverseMass_ / contact.inverseMassTotal);
            if(change.length < 0.00001){change.zero();}
            if(this is contact.bodyA){velocity_ -= change;}
            else{velocity_ += change;}
        }

        /**
         * Called at the end of the update after the bodies' die() method is called.
         *
         * This is used to handle any game logic that needs to happen when a 
         * body dies.
         */
        void onDie(){};

    package:
        ///Is the actor dead at specified update?
        @property final bool dead (const size_t updateIndex) const pure
        {
            return updateIndex >= deadAtUpdate_;
        }

        /**
         * Used by PhysicsEngine to update the body.
         *
         * Params:  timeStep = Time length of the update in seconds.
         *          spatial   = Spatial manager managing the body.
         */
        final void updatePackage(const real timeStep, SpatialManager!PhysicsBody spatial)
        {
            update(timeStep, spatial);
        }

        ///Used by PhysicsEngine to call onDie() of the body.
        final void onDiePackage(){onDie();}

        /**
         * Enforces contract on all (even inherited) implementations of collisionResponse
         * and registers bodies this body has collided with.
         */
        final void collisionResponseContract(ref Contact contact)
        in
        {
            assert(contact.bodyA is this || contact.bodyB is this,
                   "Trying to resolve collision with a contact that doesn't involve this body");
        }
        body
        {
            auto other = this is contact.bodyA ? contact.bodyB : contact.bodyA;
            //add this collider if we don't have it yet
            if(!canFind!"a is b"(colliders_, other)){colliders_ ~= other;}
            collisionResponse(contact);
        }

        /**
         * Add the body to a spatial manager (and save old position).
         *
         * Params:  spatial = Spatial manager to add to.
         */
        void addToSpatial(SpatialManager!PhysicsBody spatial)
        {
            positionOld_ = position_;
            spatial.addObject(this);
        }

        /**
         * Remove the body from a spatial manager.
         *
         * Params:  spatial = Spatial manager to remove from.
         */
        void removeFromSpatial(SpatialManager!PhysicsBody spatial)
        {
            spatial.removeObject(this);
        }
}
