
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Base class for actors in the scene.
module scene.actor;


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
        PhysicsBody physicsBody_;

        ///Index of update when the actor is dead (to be removed).
        size_t deadAtUpdate_ = size_t.max;

    public:
        ///Get position of this actor.
        @property final Vector2f position() const pure {return physicsBody_.position;}

        ///Get velocity of this actor.
        @property final Vector2f velocity() const pure {return physicsBody_.velocity;}

        ///Get a reference to physics body of this actor.
        @property final PhysicsBody physicsBody() {return physicsBody_;}

        /**
         * Destroy the actor at the end of specified update.
         *
         * This can be used to destroy the actor at the current update by passing
         * current updateIndex from the SceneManager.
         * 
         * Note that the actor will not be destroyed immediately -
         * At the end of update, all dead actors' onDie() methods are called 
         * first, and then the actors are destroyed.
         *
         * Params: updateIndex  = Update to destroy the actor at.
         */
        final void die(const size_t updateIndex)
        {
            physicsBody_.die(updateIndex);
            deadAtUpdate_ = updateIndex;
        }

    protected:
        /**
         * Construct an Actor.
         *
         * Params:  physicsBody = Physics body of the actor.
         */
        this(PhysicsBody physicsBody) 
        in
        {
            assert(physicsBody !is null, "Can't construct an actor without a physics body");
        }
        body
        {
            physicsBody_ = physicsBody;
        };

        /**
         * Called at the end of the update after the actors' die() method is called.
         *
         * This is used to handle any game logic that needs to happen when an 
         * actor dies, for instance detaching particle systems from an actor or
         * spawning new actors.
         *
         * The physics body of the actor is not yet destroyed at onDie().
         *
         * Params:  manager = SceneManager to get time information and add new actors.
         */
        void onDie(SceneManager manager){};

        /**
         * Update this Actor.
         *
         * Params:  manager   = SceneManager to get time information from and/or add new actors.
         */
        void update(SceneManager manager);

        ///Draw this actor.
        void draw(VideoDriver driver);

    package:
        ///Is the actor dead at specified update?
        @property final bool dead (in size_t updateIndex) const pure
        {
            return updateIndex >= deadAtUpdate_;
        }

        /**
         * Used by SceneManager to update the actor.
         *
         * Params:  manager   = SceneManager to get time information from and/or add new actors.
         */
        final void updatePackage(SceneManager manager){update(manager);}

        /**
         * Used by SceneManager to call onDie() of the actor.
         *
         * Params:  manager   = SceneManager to get time information from and/or add new actors.
         */
        final void onDiePackage(SceneManager manager){onDie(manager);}


        ///Interface used by SceneManager to draw the actor.
        final void drawActor(VideoDriver driver){draw(driver);}
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
    mixin(generateFactory("Vector2f $ position $ Vector2f(0.0f, 0.0f)", 
                          "Vector2f $ velocity $ Vector2f(0.0f, 0.0f)"));

    /**
     * Do any work required on the new actor to be produced and return it.
     *
     * This is used as a shortcut to add a produced actor to the scene manager
     * and do any other work that needs to be done on all new actors.
     */
    protected final T newActor(SceneManager manager, T actor)
    {
        manager.addActor(actor);
        return actor;
    }

    /**
     * Return a new instance of the actor type produced with factory parameters.
     *
     * Params:  manager = Scene manager to manage the actor and any actors it creates. 
     */
    public T produce(SceneManager manager);
}
