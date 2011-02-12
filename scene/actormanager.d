
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module scene.scenemanager;


import std.string;
import std.stdio;

import scene.actor;
import scene.actorcontainer;
import physics.physicsengine;
import spatial.spatialmanager;
import video.videodriver;
import math.vector2;
import time.time;
import time.timer;
import time.eventcounter;
import util.weaksingleton;
import containers.array;


///Stores and manages all Actors.
final class SceneManager : ActorContainer
{
    mixin WeakSingleton;

    invariant
    {
        assert(time_step_ >= 0.0, "Time step can't be negative");
        assert(game_time_ >= 0.0, "Frame time can't be negative");
        assert(time_speed_ >= 0.0, "Time speed can't be negative");
        assert(accumulated_time_ >= 0.0, "Accumulated time can't be negative");
    }

    private:
        //Physics engine managing physics bodies of the actors.
        PhysicsEngine physics_engine_;

        //Actors managed by the SceneManager.
        Actor[] actors_;
        //Actors to be added at the beginning of the next frame
        Actor[] actors_to_add_;
        //Actors to be removed at the beginning of the next frame
        Actor[] actors_to_remove_;

        //Time taken by single game update.
        real time_step_ = 1.0 / 120.0; 
        //Time this update started, in game time
        real game_time_;
        //Time this frame (which can have multiple updates) started, in absolute time
        real frame_start_;
        //Time we're behind in updates.
        real accumulated_time_ = 0;
        //Time speed multiplier
        real time_speed_ = 1.0;

        //collects statistics about actor updates
        EventCounter update_counter_;

    public:
        /**
         * Construct the SceneManager; set up update frequency.
         *
         * Params:  physics_engine = Physics engine for the actor manager to use.
         */
        this(PhysicsEngine physics_engine)
        {
            physics_engine_ = physics_engine;
            update_counter_ = new EventCounter(1.0);
            update_counter_.update.connect(&ups_update);
            game_time_ = 0.0;
            frame_start_ = get_time();
            singleton_ctor();
        }

        ///Destroy the SceneManager.
        void die()
        {
            clear();
            update_counter_.update.disconnect(&ups_update);
            singleton_dtor();
        }

        ///Get frame length in seconds, i.e. update "frame" length, not graphics.
        real time_step(){return time_step_;}

        ///Get time when the current update started, in game time.
        real game_time(){return game_time_;}

        ///Set time speed multiplier (0 for pause, 1 for normal speed).
        void time_speed(real speed){time_speed_ = speed;}

        ///Get time speed multiplier.
        real time_speed(){return time_speed_;}
        
        ///Update the actor manager.
        void update()
        {
            real time = get_time();
            //time since last frame
            real frame_length = math.math.max(time - frame_start_, 0.0L);
            frame_start_ = time;

            //preventing spiral of death
            frame_length = math.math.min(frame_length * time_speed_, 0.25L);

            accumulated_time_ += frame_length;

            while(accumulated_time_ >= time_step_)
            {
                game_time_ += time_step_;
                accumulated_time_ -= time_step_;
                physics_engine_.update(time_step_);
                update_actors();
            }
        }

        /**
         * Draw all actors.
         *
         * Params:  driver = Video driver to draw with.
         */
        void draw(VideoDriver driver)
        {
            foreach(actor; actors_){actor.draw_actor(driver);}
        }

        ///Remove all actors.
        void clear()
        {
            //these actors are already dead, so remove them first
            foreach(actor; actors_to_remove_)
            {
                alias containers.array.remove remove;
                actors_.remove(actor, true);
                physics_engine_.remove_body(actor.physics_body);
            }

            //kill all actors still alive
            foreach(actor; actors_){actor.die();}
            actors_ = [];
            actors_to_add_ = [];
            actors_to_remove_ = [];
        }

        ///Return a string with statistics about SceneManager run.
        string statistics(){return "UPS statistics:\n" ~ update_counter_.statistics();}

        /**
         * Add a new actor. Will be added at the beginning of next frame.
         * 
         * Note: this should only be used by actor constructor.
         *
         * Params:  actor = Actor to add. Must not already be in the SceneManager.
         */
        void add_actor(Actor actor)
        in
        {
            assert(!actors_to_add_.contains(actor, true) && 
                   !actors_.contains(actor, true), 
                   "Adding the same actor twice");
        }
        body{actors_to_add_ ~= actor;}

        /**
         * Remove an actor. Will be removed at the beginning of next frame.
         * 
         * Note: this should only be used by actor die() or destructor.
         *
         * Params:  actor = Actor to remove. Must be in the SceneManager.
         */
        void remove_actor(Actor actor)
        in
        {
            assert(actors_.contains(actor, true), 
                   "Can't remove an actor that is not in the SceneManager");
        }
        body{actors_to_remove_ ~= actor;}

    package:
        //Update all actors
        void update_actors()
        {
            update_counter_.event();

            //Add or remove any actors requested
            foreach(actor; actors_to_remove_)
            {
                alias containers.array.remove remove;
                actors_.remove(actor, true);
                physics_engine_.remove_body(actor.physics_body);
            }

            actors_ ~= actors_to_add_;
            foreach(actor; actors_to_add_)
            {
                physics_engine_.add_body(actor.physics_body);
            }

            actors_to_add_ = [];
            actors_to_remove_ = [];
            update_counter_.event();

            //Update actors' states
            foreach(actor; actors_)
            {
                actor.update_actor(time_step_, game_time_);
            }
        }
        
        //Update updates per second output
        void ups_update(real ups){writefln("UPS: ", ups);}
}
