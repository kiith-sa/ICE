
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Base class for physics bodies.
module physics.physicsbody;
@safe


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
        Vector2f position_old_;
        ///Position in world space.
        Vector2f position_;
        ///Velocity in world space.
        Vector2f velocity_;

        ///Inverse mass of this body. (0 means infinite mass)
        real inverse_mass_;

        //we could use a set here, if this is too slow
        ///Bodies we've collided with this frame.
        PhysicsBody[] colliders_;

        ///Index of update when the body is dead (to be removed).
        size_t dead_at_update_ = size_t.max;

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
        this(in Volume volume, in Vector2f position, in Vector2f velocity, in real mass)
        {
            volume_       = volume;
            position_old_ = position_ = position;
            velocity_     = velocity;
            this.mass     = mass;
        }

        /**
         * Destroy the body at the end of specified update.
         *
         * This can be used to destroy the body at the current update by passing
         * current update_index from the SceneManager.
         * 
         * Note that the body will not be destroyed immediately -
         * At the end of update, all dead bodies' on_die() methods are called 
         * first, and then the bodies are destroyed.
         *
         * Params: update_index  = Update to destroy the body at.
         */
        final void die(size_t update_index)
        {
            dead_at_update_ = update_index;
        }

        ///Get position of the body, in world space.
        @property final Vector2f position() const {return position_;}

        ///Set position of the body, in world space.
        @property final void position(in Vector2f p){position_ = p;}

        ///Get velocity of the body, in world space.
        @property final Vector2f velocity() const {return velocity_;}

        ///Set velocity of the body, in world space.
        @property final void velocity(in Vector2f v){velocity_ = v;}

        ///Set mass of the body. Mass must be positive and can be infinite.
        @property final void mass(in real mass)
        in{assert(mass >= 0.0, "Can't set physics body mass to zero or negative.");}
        body
        {
            inverse_mass_ = (mass == real.infinity) ? 0.0 : 1.0 / mass;
        }

        ///Get inverse mass of the body.
        @property final real inverse_mass() const {return inverse_mass_;}

        ///Get a reference to collision volume of this body.
        @property final const(Volume) volume() const {return volume_;}

        ///Return an array of bodies this body has collided with during last update.
        @property PhysicsBody[] colliders(){return colliders_;} 

        ///Has the body collided with anything during the last update?
        @property bool collided() const {return colliders_.length > 0;}

    protected:
        /**
         * Update physics state of the body.
         *
         * Params:  time_step = Time length of the update in seconds.
         *          spatial   = Spatial manager managing the body.
         */
        void update(in real time_step, SpatialManager!PhysicsBody spatial)
        {
            assert(time_step >= 0.0, "Can't update a physics body with negative time step");

            position_ += velocity_ * time_step;
            colliders_.length = 0; 
            //spatial manager does not manage bodies without volumes.
            if(position_ != position_old_ && volume_ !is null)
            {
                spatial.update_object(this, position_old_);
            }
            position_old_ = position_;
        }

        /**
         * Resolve collision response to a contact.
         *
         * Params:  contact = Contact to respond to. Must involve this body.
         */
        void collision_response(ref Contact contact)
        {
            if(equals(inverse_mass_, 0.0L)){return;}
            if(equals(contact.inverse_mass_total, 0.0L)){return;}
            Vector2f scaled_normal = contact.contact_normal * contact.desired_delta_velocity;
            Vector2f change = scaled_normal * (inverse_mass_ / contact.inverse_mass_total);
            if(change.length < 0.00001){change.zero();}
            if(this is contact.body_a){velocity_ -= change;}
            else{velocity_ += change;}
        }

        /**
         * Called at the end of the update after the bodies' die() method is called.
         *
         * This is used to handle any game logic that needs to happen when a 
         * body dies.
         */
        void on_die(){};

    package:
        ///Is the actor dead at specified update?
        @property final bool dead (in size_t update_index) const
        {
            return update_index >= dead_at_update_;
        }

        /**
         * Used by PhysicsEngine to update the body.
         *
         * Params:  time_step = Time length of the update in seconds.
         *          spatial   = Spatial manager managing the body.
         */
        final void update_package(in real time_step, SpatialManager!PhysicsBody spatial)
        {
            update(time_step, spatial);
        }

        ///Used by PhysicsEngine to call on_die() of the body.
        final void on_die_package(){on_die();}

        /**
         * Enforces contract on all (even inherited) implementations of collision_response
         * and registers bodies this body has collided with.
         */
        final void collision_response_contract(ref Contact contact)
        in
        {
            assert(contact.body_a is this || contact.body_b is this,
                   "Trying to resolve collision with a contact that doesn't involve this body");
        }
        body
        {
            auto other = this is contact.body_a ? contact.body_b : contact.body_a;
            //add this collider if we don't have it yet
            if(!canFind!"a is b"(colliders_, other)){colliders_ ~= other;}
            collision_response(contact);
        }

        /**
         * Add the body to a spatial manager (and save old position).
         *
         * Params:  spatial = Spatial manager to add to.
         */
        void add_to_spatial(SpatialManager!PhysicsBody spatial)
        {
            position_old_ = position_;
            spatial.add_object(this);
        }

        /**
         * Remove the body from a spatial manager.
         *
         * Params:  spatial = Spatial manager to remove from.
         */
        void remove_from_spatial(SpatialManager!PhysicsBody spatial)
        {
            spatial.remove_object(this);
        }
}
