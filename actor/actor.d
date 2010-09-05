module actor.actor;


import std.string;
import std.stdio;

import actor.actormanager;
import math.vector2;


/** 
 * Base class for all game objects.
 *
 * Actor with geometry that can collide with other actors and move.
 */
abstract class Actor
{
    invariant
    {
        //At speeds like this, collision and precision errors start to appear.
        assert(velocity_.length <= 1600.0, "Actor speed can't be greater than 1600");
    }

    protected:
        //Position of this actor this frame.
        Vector2f position_;

        //Position of this actor at the beginning of the next frame.
        Vector2f next_position_;
        
        //Velocity of this actor.
        Vector2f velocity_;

    public:
        ///Return velocity of this actor.
        final Vector2f velocity(){return velocity_;}

        ///Return position of this actor.
        final Vector2f position(){return position_;}

        ///Update physics state of this Actor.
        void update_physics()
        {
            next_position_ = position_ + velocity_ * ActorManager.get.frame_length();
        }

        ///Update this Actor.
        void update(){position_ = next_position_;}

        ///Draw this actor.
        void draw();

        /**
         * Collision test with an actor. 
         * 
         * Params:    actor  = Actor to test collision with. 
         *            point  = Vector to write intersection point to.
         *            velocity = Vector to write new velocity of colliding actor to.
         * 
         * Returns: true if there is a collision, false otherwise.
         */
        bool collision(Actor actor, out Vector2f position, out Vector2f velocity)
        {
            return false;
        }

        ///Destroy this actor.
        void die(){ActorManager.get.remove_actor(this);}

        ~this()
        {
            assert(!ActorManager.get.has_actor(this), 
                   "Actor must be removed from the ActorManager before destruction");
        }

    package:
        //Return position this actor will have next frame. 
        //Should only be called from Actor::Update().
        final Vector2f next_position(){return next_position_;}

    protected:
        //Construct Actor with specified properties.
        this(Vector2f position, Vector2f velocity = Vector2f(0.0, 0.0)) 
        {
            position_ = next_position_ = position;
            velocity_ = velocity;
            ActorManager.get.add_actor(this);
        };
}
