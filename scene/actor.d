
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Base class for actors in the scene.
module scene.actor;
@safe


import std.string;
import std.stdio;

import scene.scenemanager;
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

        //TODO DOC
        ///Destroy this actor.
        final void die(size_t frame)
        {
            physics_body_.die();
            dead_at_frame_ = frame + 1;
        }

    protected:
        /**
         * Construct an Actor.
         *
         * Params:  physics_body = Physics body of the actor.
         */
        this(PhysicsBody physics_body) 
        in
        {
            assert(physics_body !is null, "Can't construct an actor without a physics body");
        }
        body
        {
            physics_body_ = physics_body;
        };

        //TODO DOC
        /**
         * Update this Actor.
         *
         * Params:  time_step = Update time step in seconds.
         *          game_time = Current game time.
         */
        void update(SceneManager manager);

        ///Draw this actor.
        void draw(VideoDriver driver);

    package:
        //TODO DOC
        @property final bool dead (in size_t frame) const
        {
            return frame >= dead_at_frame_;
        }

        //TODO DOC
        /**
         * Interface used by SceneManager to update the actor.
         *
         * Params:  time_step = Time step in seconds.
         *          game_time = Current game time.
         */
        final void update_actor(SceneManager manager)
        {
            update(manager);
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

    //TODO DOC
    protected final T new_actor(SceneManager manager, T actor)
    {
        manager.add_actor(actor);
        return actor;
    }

    //TODO DOC
    /**
     * Return a new instance of the actor type produced with factory parameters.
     *
     * Params:  manager = Scene manager to manage the actor and any actors it creates. 
     */
    public T produce(SceneManager manager);
}
