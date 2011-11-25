
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

    public:
        ///Get position of this actor.
        @property final Vector2f position() const {return physics_body_.position;}

        ///Get velocity of this actor.
        @property final Vector2f velocity() const {return physics_body_.velocity;}

        ///Get a reference to physics body of this actor.
        @property final PhysicsBody physics_body() {return physics_body_;}

        ///Destroy this actor.
        void die()
        {
            clear(physics_body_);
            container_.remove_actor(this);
            //can't set this here due to a compiler bug (stuff gets reordered)
            //container_ = null;
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

        /**
         * Update this Actor.
         *
         * Params:  time_step = Update time step in seconds.
         *          game_time = Current game time.
         */
        void update(in real time_step, in real game_time);

        ///Draw this actor.
        void draw(VideoDriver driver);

    package:
        /**
         * Interface used by SceneManager to update the actor.
         *
         * Params:  time_step = Time step in seconds.
         *          game_time = Current game time.
         */
        final void update_actor(in real time_step, in real game_time)
        {
            update(time_step, game_time);
        }

        ///Interface used by SceneManager to draw the actor.
        final void draw_actor(VideoDriver driver){draw(driver);}
}
///Unittest for Actor.
unittest
{
    class ActorContainerTest : ActorContainer
    {
        private:
            uint add_counter;
            uint remove_counter;
        public:
            override void add_actor(Actor actor){add_counter++;}
            override void remove_actor(Actor actor){remove_counter++;}
            bool ok(){return add_counter == 1 && remove_counter == 1;}
    }

    class ActorTest : Actor
    {    
        public:
            override void update(in real time_step, in real game_time){}
            override void draw(VideoDriver driver){}
            this(ActorContainer container)
            {
                auto zero = Vector2f(0.0f, 0.0f);
                super(container, new PhysicsBody(null, zero, zero, 10.0));
            }
    }

    auto container = new ActorContainerTest;
    auto test = new ActorTest(container);
    test.die();

    assert(container.ok, "Error in actor registration with ActorContainer");
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
