
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Scene manager subsystem.
module scene.scenemanager;
@safe


import std.algorithm;
import std.stdio;
import std.string;

import scene.actor;
import scene.actorcontainer;
import physics.physicsengine;
import spatial.spatialmanager;
import video.videodriver;
import math.vector2;
import time.time;
import time.timer;
import monitor.monitorable;
import monitor.monitordata;
import monitor.submonitor;
import monitor.graphmonitor;
import util.weaksingleton;
import util.signal;


///Stores monitoring statistics about the scene manager.
private struct Statistics
{
    ///Scene updates per second.
    real ups;
}

///Stores and manages all Actors.
final class SceneManager : ActorContainer, Monitorable
{
    mixin WeakSingleton;

    invariant()
    {
        assert(time_step_ >= 0.0, "Time step can't be negative");
        assert(game_time_ >= 0.0, "Frame time can't be negative");
        assert(time_speed_ >= 0.0, "Time speed can't be negative");
        assert(accumulated_time_ >= 0.0, "Accumulated time can't be negative");
    }

    private:
        ///Physics engine managing physics bodies of the actors.
        PhysicsEngine physics_engine_;

        ///Actors managed by the SceneManager.
        Actor[] actors_;
        ///Actors to be added at the beginning of the next update.
        Actor[] actors_to_add_;
        ///Actors to be removed at the beginning of the next update.
        Actor[] actors_to_remove_;

        ///Time taken by single game update.
        const real time_step_ = 1.0 / 90.0; 
        ///Time this update started, in game time.
        real game_time_;
        ///Time this frame (which can have multiple updates) started, in absolute time.
        real frame_start_;
        ///Time we're behind in updates.
        real accumulated_time_ = 0.0;
        ///Time speed multiplier. Zero means pause (stopped time).
        real time_speed_ = 1.0;

        ///Statistics data for monitoring.
        Statistics statistics_;

        ///Used to send statistics data to GL monitors.
        mixin Signal!(Statistics) send_statistics;

        ///Timer used to measure updates per second.
        Timer ups_timer_;

    public:
        /**
         * Construct the SceneManager.
         *
         * Params:  physics_engine = Physics engine for the actor manager to use.
         */
        this(PhysicsEngine physics_engine)
        {
            physics_engine_ = physics_engine;
            game_time_ = 0.0;
            frame_start_ = get_time();
            //dummy delay, not used.
            ups_timer_ = Timer(1.0);
            singleton_ctor();
        }

        ///Destroy the SceneManager.
        ~this()
        {
            this.clear();
            singleton_dtor();
        }

        ///Get update length in seconds, i.e. "update frame" length, not graphics.
        @property real time_step() const {return time_step_;}

        ///Get time when the current update started, in game time.
        @property real game_time() const {return game_time_;}

        ///Set time speed multiplier (0 for pause, 1 for normal speed).
        @property void time_speed(in real speed){time_speed_ = speed;}

        ///Get time speed multiplier.
        @property real time_speed() const {return time_speed_;}
        
        ///Update the actor manager.
        void update()
        {
            const real time = get_time();
            //time since last frame
            real frame_length = max(time - frame_start_, 0.0L);
            frame_start_ = time;

            //preventing spiral of death - if we can't keep up updating, slow down the game
            frame_length = min(frame_length * time_speed_, 0.25L);

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
                actors_ = remove!((Actor a){return a is actor;})(actors_);
                physics_engine_.remove_body(actor.physics_body);
            }

            //kill all actors still alive
            foreach(actor; actors_){actor.die();}
            actors_ = [];
            actors_to_add_ = [];
            actors_to_remove_ = [];
        }

        /**
         * Add a new actor. Will be added at the beginning of the next update.
         * 
         * Note: This should only be used by actor constructor.
         *
         * Params:  actor = Actor to add. Must not already be in the SceneManager.
         */
        void add_actor(Actor actor)
        in
        {
            assert(!canFind!"a is b"(actors_to_add_, actor) &&
                   !canFind!"a is b"(actors_, actor),
                   "Adding the same actor twice");
        }
        body{actors_to_add_ ~= actor;}

        /**
         * Remove an actor. Will be removed at the beginning of next frame.
         * 
         * Note: This should only be used by actor die() or destructor.
         *
         * Params:  actor = Actor to remove. Must be in the SceneManager.
         */
        void remove_actor(Actor actor)
        in
        {
            assert(canFind!"a is b"(actors_, actor),
                   "Can't remove an actor that is not in the SceneManager");
        }
        body{actors_to_remove_ ~= actor;}

        MonitorDataInterface monitor_data()
        {
            SubMonitor function(SceneManager)[string] ctors_;
            ctors_["UPS"] = &new_graph_monitor!(SceneManager, Statistics, "ups");
            return new MonitorData!(SceneManager)(this, ctors_);
        }

    package:
        ///Update all actors.
        void update_actors()
        {
            const real age = ups_timer_.age();
            ups_timer_.reset();
            //avoid divide by zero
            statistics_.ups = age == 0.0L ? 0.0 : 1.0 / age;
            send_statistics.emit(statistics_);

            //Add or remove any actors requested
            foreach(actor; actors_to_remove_)
            {
                actors_ = remove!((Actor a){return a is actor;})(actors_);
                physics_engine_.remove_body(actor.physics_body);
            }

            actors_ ~= actors_to_add_;
            foreach(actor; actors_to_add_)
            {
                physics_engine_.add_body(actor.physics_body);
            }

            actors_to_add_ = [];
            actors_to_remove_ = [];

            //Update actors' states
            foreach(actor; actors_)
            {
                actor.update_actor(time_step_, game_time_);
            }
        }
}
