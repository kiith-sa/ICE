module actor.actor;


import std.string;
import std.stdio;

import actor.actorcontainer;
import physics.physicsbody;
import video.videodriver;
import math.vector2;
import math.rectangle;
import factory;


/** 
 * Base class for all game objects.
 *
 * Actor with geometry that can collide with other actors and move.
 */
abstract class Actor
{
    protected:
        /*
         * Container owning this actor, with ability to add more actors.
         *
         * (most likely ActorManager)
         */
        ActorContainer container_;

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

        ///Destroy this actor.
        void die()
        {
            physics_body_.die();
            container_.remove_actor(this);
            container_ = null;
        }

    protected:
        /*
         * Construct Actor with specified properties.
         *
         * Params:  container    = Container to manage the actor and any actors it creates.
         *          physics_body = Physics body of the actor.
         */
        this(ActorContainer container, PhysicsBody physics_body) 
        in
        {
            assert(container !is null, "Actor must have a non-null container");
            assert(physics_body !is null, 
                   "Can't construct an actor without a physics body");
        }
        body
        {
            physics_body_ = physics_body;
            container.add_actor(this);
            container_ = container;
        };

        /*
         * Update this Actor.
         *
         * Params:  time_step = Time step in seconds.
         *          game_time = Current game time.
         */
        void update(real time_step, real game_time);

        //Draw this actor.
        void draw(VideoDriver driver);

    package:
        /*
         * Interface to update the actor by ActorManager.
         *
         * Params:  time_step = Time step in seconds.
         *          game_time = Current game time.
         */
        final void update_actor(real game_time, real time_step)
        {
            update(game_time, time_step);
        }

        //Interface to draw the actor by ActorManager.
        final void draw_actor(VideoDriver driver){draw(driver);}
}
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
            override void update(real time_step, real game_time){}
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

    assert(container.ok, "Error in actor registration with ActorManager");
}

/**
 * Base class for all actor factories, template input specifies actor
 * type the factory constructs.
 *
 * Params:  position = Starting position of the actor.
 *          velocity = Starting velocity of the actor.
 */
abstract class ActorFactory(T)
{
    mixin(generate_factory("Vector2f $ position $ Vector2f(0.0f, 0.0f)", 
                           "Vector2f $ velocity $ Vector2f(0.0f, 0.0f)"));
    /**
     * Return a new instance of the actor type produced by the factory with specified parameters.
     *
     * Params:  container = Container to manage the actor and any actors it creates. 
     *                      Should probably be the ActorManager.
     */
    public T produce(ActorContainer container);
}
