module actor.actor;


import std.string;
import std.stdio;

import actor.actormanager;
import physics.physicsbody;
import math.vector2;
import math.rectangle;


/** 
 * Base class for all game objects.
 *
 * Actor with geometry that can collide with other actors and move.
 */
abstract class Actor
{
    protected:
        PhysicsBody physics_body_;

    public:
        ///Return position of this actor.
        final Vector2f position()
        in
        {
            assert(physics_body_ !is null, 
                   "Trying to get position of an actor with no physics body");
        }
        body
        {
            return physics_body_.position;
        }

        ///Return velocity of this actor.
        final Vector2f velocity()
        in
        {
            assert(physics_body_ !is null, 
                   "Trying to get velocity of an actor with no physics body");
        }
        body{return physics_body_.velocity;}

        ///Return a reference to physics body of this actor. Will return const after D2 move.
        final PhysicsBody physics_body(){return physics_body_;}

        /**
         * Update this Actor.
         *
         * Params:  time_step = Time step in seconds.
         *          game_time = Current game time.
         */
        void update(real time_step, real game_time);

        ///Draw this actor.
        void draw();

        ///Destroy this actor.
        void die()
        {
            if(physics_body_ !is null){physics_body_.die();}
            ActorManager.get.remove_actor(this);
        }

        ~this()
        {
            assert(!ActorManager.get.has_actor(this), 
                   "Actor must be removed from the ActorManager before destruction");
        }

    protected:
        //Construct Actor with specified properties.
        this(PhysicsBody physics_body) 
        {
            physics_body_ = physics_body;
            ActorManager.get.add_actor(this);
        };
}
