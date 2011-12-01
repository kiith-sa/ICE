
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Base class for actors in the scene.
module scene.actor;
@safe


import std.string;
import std.stdio;

import scene.actorcontainer;
import physics.physicsbody;
import video.videodriver;
import math.vector2;
import math.rectangle;
import util.factory;


/** 
 * Base class for all game objects.
 *
 * Actor with a physics body.
 */
abstract class Actor
{
    protected:
        ///Container owning this actor, with ability to add more actors. (most likely SceneManager)
        ActorContainer container_;

        ///Physics body of this actor.
        PhysicsBody physics_body_;

        //TODO DOC
        size_t dead_at_frame_ = size_t.max;

    public:
        ///Get position of this actor.
        @property final Vector2f position() const {return physics_body_.position;}

        ///Get velocity of this actor.
        @property final Vector2f velocity() const {return physics_body_.velocity;}

        ///Get a reference to physics body of this actor.
        @property final PhysicsBody physics_body() {return physics_body_;}

        //TODO DOC, AND dead_at_frame_ MEMBER
        ///Destroy this actor.
        void die(size_t frame)
        {
            physics_body_.die();
            dead_at_frame_ = frame + 1;
        }

    protected:
        /**
         * Construct an Actor.
         *
         * Params:  container    = Container to manage the actor and any actors it creates.
         *          physics_body = Physics body of the actor.
         */
        this(ActorContainer container, PhysicsBody physics_body) 
        in
        {
            assert(container !is null, "Actor must have a non-null container");
            assert(physics_body !is null, "Can't construct an actor without a physics body");
        }
        body
        {
            physics_body_ = physics_body;
            container.add_actor(this);
            container_ = container;
        };

        //TODO DOC
        /**
         * Update this Actor.
         *
         * Params:  time_step = Update time step in seconds.
         *          game_time = Current game time.
         */
        void update(in real time_step, in real game_time, in size_t frame);

        ///Draw this actor.
        void draw(VideoDriver driver);

    package:
        //TODO DOC
        @property final bool dead (in size_t frame) const
        {
            return frame >= dead_at_frame_;
        }

        /**
         * Interface used by SceneManager to update the actor.
         *
         * Params:  time_step = Time step in seconds.
         *          game_time = Current game time.
         */
        final void update_actor(in real time_step, in real game_time, in size_t frame)
        {
            update(time_step, game_time, frame);
        }

        ///Interface used by SceneManager to draw the actor.
        final void draw_actor(VideoDriver driver){draw(driver);}
}

/**
 * Base class for actor factories, template type T specifies type the factory constructs.
 *
 * Params:  position = Starting position of the actor. 
 *                     Default; zero vector
 *          velocity = Starting velocity of the actor.
 *                     Default; zero vector
 */
abstract class ActorFactory(T)
{
    mixin(generate_factory("Vector2f $ position $ Vector2f(0.0f, 0.0f)", 
                           "Vector2f $ velocity $ Vector2f(0.0f, 0.0f)"));

    /**
     * Return a new instance of the actor type produced with factory parameters.
     *
     * Params:  container = Container to manage the actor and any actors it creates. 
     *                      Should probably be the SceneManager.
     */
    public T produce(ActorContainer container);
}
