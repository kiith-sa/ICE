module physics.physicsbody;


import spatial.volume;
import physics.contact;
import physics.physicsengine;
import spatial.spatialmanager;
import math.vector2;
import math.math;
import arrayutil;


///Object in physics simulation. Currently a (very) simple rigid body.
class PhysicsBody
{
    protected:
        //Should be immutable or const in D2:
        //Collision volume of this body. If null, this body can't collide.
        Volume volume_;
        //Position this body had last frame, in world space, used for spatial management.
        Vector2f position_old_;
        //Position of this body in world space.
        Vector2f position_;
        //Velocity of this body in world space.
        Vector2f velocity_;
        //Inverse of mass of this body. (0 means infinite mass)
        real inverse_mass_;
        //Bodies we've collided with this frame.
        PhysicsBody[] colliders_;

    public:
        /**
         * Construct a PhysicsBody with specified parameters.
         *
         * Params:    volume   = Collision volume to use for collision detection.
         *                       If null, this body cannot collide with anything.
         *            position = Position of the body in world space.
         *            velocity = Velocity of the body.
         *            mass     = Mass of the body. Can be infinite (immovable objects)
         *                       Can't be zero or negative.
         */
        this(Volume volume, Vector2f position, Vector2f velocity, real mass)
        {
            this.volume_ = volume;
            position_old_ = position_ = position;
            velocity_ = velocity;
            this.mass = mass;
        }

        ///Destroy this physics object.
        void die(){}
        

        /**
         * Perform collision response to the given contact.
         *
         * Should only be called by the physics code, not by the user.
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

        ///Return position of the body.
        final Vector2f position(){return position_;}

        ///Set position of this body.
        final void position(Vector2f p){position_ = p;}

        ///Return velocity of the body.
        final Vector2f velocity(){return velocity_;}

        ///Set velocity of the body.
        final void velocity(Vector2f v){velocity_ = v;}

        ///Set mass of the body. Mass must be positive and can be infinite.
        final void mass(real mass)
        in{assert(mass >= 0.0, "Can't set physics body mass to zero or negative.");}
        body
        {
            if(mass == real.infinity){inverse_mass_ = 0.0;}
            else{inverse_mass_ = 1.0 / mass;}
        }

        ///Return inverse mass of the body.
        final real inverse_mass(){return inverse_mass_;}

        ///Return collision volume of this body.
        final Volume volume(){return volume_;}

        ///Return an array of bodies this body has collided with during last physics update.
        PhysicsBody[] colliders(){return colliders_;} 

        ///Has this body collided with anything during the last physics update?
        bool collided(){return colliders_.length > 0;}

        /**
         * Update physics state of this body to the next frame.
         *
         * Params:  time_step = Time length of the frame in seconds.
         *          manager   = Spatial manager managing the body.
         */
        void update(real time_step, SpatialManager!(PhysicsBody) manager)
        {
            position_ += velocity_ * time_step;
            colliders_.length = 0; 
            //spatial manager does not manage bodies without volumes.
            if(position_ != position_old_ && volume_ !is null)
            {
                manager.update_object(this, position_old_);
            }
            position_old_ = position_;
        }

    package:
        /*
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
            PhysicsBody other = this is contact.body_a ? contact.body_b : contact.body_a;
            if(!colliders_.contains(other, true)){colliders_ ~= other;}
            collision_response(contact);
        }

        /*
         * Add this body to a spatial manager (and save old position).
         *
         * Params:  manager = Spatial manager to add to.
         */
        void add_to_spatial(SpatialManager!(PhysicsBody) manager)
        {
            position_old_ = position_;
            manager.add_object(this);
        }

        /*
         * Add this body from a spatial manager.
         *
         * Params:  manager = Spatial manager to remove from.
         */
        void remove_from_spatial(SpatialManager!(PhysicsBody) manager)
        {
            manager.remove_object(this);
        }
}
