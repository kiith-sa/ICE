module actormanager;


import std.string;
import std.stdio;

import singleton;
import time;
import timer;
import eventcounter;
import videodriver;
import vector2;
import line2;
import rectangle;
import util;

///Stores and manages all Actors.
class ActorManager : Singleton
{
    mixin SingletonMixin;

    invariant
    {
        assert(FrameLength >= 0.0, "Frame length can't be negative");
        assert(FrameTime >= 0.0, "Frame time can't be negative");
        assert(TimeSpeed >= 0.0, "Time speed can't be negative");
    }

    private:
        Actor[] Actors;

        //Actors to be added at the beginning of the next frame
        Actor[] ActorsToAdd;

        //Actors to be removed at the beginning of the next frame
        Actor[] ActorsToRemove;

        //time between two last updates
        real FrameLength = 0.0;

        //time this update started 
        real FrameTime;
        
        //used to time actor updates
        Timer UpdateTimer;

        //collects statistics about actor updates
        EventCounter UpdateCounter;

        //Time speed multiplier
        real TimeSpeed = 1.0;

    public:

        ///Get frame length in seconds, i.e. update "frame" length, not graphics.
        real frame_length()
        {
            return FrameLength;
        }

        ///Get time when the current update started.
        real frame_time()
        {
            return FrameTime;
        }

        ///Set time speed multiplier (0 for pause, 1 for normal speed).
        void time_speed(real speed)
        {
            TimeSpeed = speed;
        }

        ///Get time speed multiplier.
        real time_speed()
        {
            return TimeSpeed;
        }
        
        /** 
         * Test for collision between given actor and any other actor/s.
         *
         * If there is more than one collision, resulting point and normal
         * are averaged.
         *
         * Params:    actor    = Actor to test collision with.
         *            point    = Vector to write collision _point to.
         *            velocity = Vector to write new _velocity of colliding _actor to.
         */
        bool collision(Actor actor, out Vector2f position, out Vector2f velocity)
        {
            foreach(a; Actors)
            {
                if(a.collision(actor, position, velocity))
                {
                    return true;
                }
            }
            return false;
        }
        
        ///Update the actor manager.
        void update()
        {
            //Explicitly passing time to UpdateTimer for synchronization.
            real time = Time.get_time();
            if(UpdateTimer.expired(time))
            {
                FrameLength = UpdateTimer.age(time) * TimeSpeed;
                //FrameTime = time;
                FrameTime += FrameLength;
                UpdateTimer.reset(time);
                update_actors();
            }
        }

        ///Draw all actors.
        void draw()
        {
            foreach(actor; Actors)
            {
                actor.draw();
            }
        }

        ///Remove all actors.
        void clear()
        {
            foreach(actor; Actors)
            {
                actor.die();
            }
            Actors = [];
            ActorsToAdd = [];
            ActorsToRemove = [];
        }

        ///Return a string with statistics about ActorManager run.
        string statistics()
        {
            return "UPS statistics:\n" ~ UpdateCounter.statistics();
        }

        ~this()
        {
            UpdateCounter.update.disconnect(&ups_update);
        }

    private:
        ///Add a new actor. Will be added at the beginning of next frame.
        void add_actor(Actor actor)
        {
            ActorsToAdd ~= actor;
        }

        ///Remove an actor. Will be removed at the beginning of next frame.
        void remove_actor(Actor actor)
        in
        {
            assert(Actors.contains(actor, true), 
                   "Can't remove an actor that is not in the ActorManager");
        }
        body
        {
            ActorsToRemove ~= actor;
        }

        //Update all actors
        void update_actors()
        {
            UpdateCounter.event();

            //Add or remove any actors requested
            foreach(actor; ActorsToRemove)
            {
                alias util.remove remove;
                Actors.remove(actor, true);
            }

            Actors ~= ActorsToAdd;
            ActorsToAdd = [];
            ActorsToRemove = [];

            //Update actors' states
            foreach(actor; Actors)
            {
                actor.update_physics();
            } 
            foreach(actor; Actors)
            {
                actor.update();
            } 
        }
        
        //Update updates per second output
        void ups_update(real ups)
        {
            writefln("UPS: ", ups);
        }

        this()
        {
            //at most 120 updates per second
            UpdateTimer(1.0 / 120.0);
            UpdateCounter = new EventCounter(1.0);
            UpdateCounter.update.connect(&ups_update);
            FrameTime = Time.get_time();
        }

        //Determines if given actor is in this ActorManager
        bool has_actor(Actor actor)
        {
            return Actors.contains(actor, true);
        }
}

/** 
 * Base class for all game objects.
 *
 * Actor with geometry that can collide with other actors and move.
 */
class Actor
{
    invariant
    {
        //At speeds like this, collision and precision errors start to appear.
        assert(Velocity.length <= 1600.0);
    }

    protected:
        //Position of this actor this frame.
        Vector2f Position;

        //Position of this actor at the beginning of the next frame.
        Vector2f NextPosition;
        
        //Velocity of this actor.
        Vector2f Velocity;

    public:
        ///Return velocity of this actor.
        Vector2f velocity()
        {
            return Velocity;
        }

        ///Return position of this actor.
        Vector2f position()
        {
            return Position;
        }

        ///Update physics state of this Actor.
        void update_physics()
        {
            NextPosition = Position + Velocity * ActorManager.get.frame_length();
        }

        ///Update this Actor.
        void update()
        {
            Position = NextPosition;
        }

        ///Draw this actor.
        void draw()
        {
        }

        /**
         * Collision test with an actor. 
         * 
         * Params:    actor  = Actor to test collision with. 
         *            point  = Vector to write intersection point to.
         *            velocity = Vector to write new velocity of colliding actor to.
         * 
         * Returns: true if there is a collision, false otherwise.
         */
        bool collision(Actor actor, out Vector2f position, 
                       out Vector2f velocity)
        body
        {
            return false;
        }

        ///Destroy this actor.
        void die()
        {
            ActorManager.get.remove_actor(this);
        }

        ~this()
        {
            assert(!ActorManager.get.has_actor(this), 
                   "Actor must be removed from the ActorManager before destruction");
        }

    protected:
        //Construct Actor with specified properties.
        this(Vector2f position, Vector2f velocity = Vector2f(0.0, 0.0)) 
        {
            Position = NextPosition = position;
            Velocity = velocity;
            ActorManager.get.add_actor(this);
        };
}

//TODO: Use package privacy class after separating to directories
///Return position of this actor next turn. DO NOT USE OUTSIDE ACTOR.UPDATE() .
Vector2f next_position(Actor a)
{
    return a.NextPosition;
}

