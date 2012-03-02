
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Scene manager subsystem.
module scene.scenemanager;


import std.algorithm;
import std.stdio;
import std.string;

import scene.actor;
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
final class SceneManager : Monitorable
{
    mixin WeakSingleton;

    invariant()
    {
        assert(timeStep_ >= 0.0, "Time step can't be negative");
        assert(gameTime_ >= 0.0, "Frame time can't be negative");
        assert(timeSpeed_ >= 0.0, "Time speed can't be negative");
        assert(accumulatedTime_ >= 0.0, "Accumulated time can't be negative");
    }

    private:
        ///Physics engine managing physics bodies of the actors.
        PhysicsEngine physicsEngine_;

        ///Actors managed by the SceneManager.
        Actor[] actors_;
        ///Actors to be added at the beginning of the next update.
        Actor[] actorsToAdd_;

        ///Time taken by single game update.
        const real timeStep_ = 1.0 / 90.0; 
        ///Time this update started, in game time.
        real gameTime_;
        ///Time this frame (which can have multiple updates) started, in absolute time.
        real frameStart_;
        ///Time we're behind in updates.
        real accumulatedTime_ = 0.0;
        ///Time speed multiplier. Zero means pause (stopped time).
        real timeSpeed_ = 1.0;
        ///Number of the current update.
        size_t updateIndex_ = 0;

        ///Statistics data for monitoring.
        Statistics statistics_;

        ///Used to send statistics data to GL monitors.
        mixin Signal!Statistics sendStatistics;

        ///Timer used to measure updates per second.
        Timer upsTimer_;

    public:
        /**
         * Construct the SceneManager.
         *
         * Params:  physicsEngine = Physics engine for the actor manager to use.
         */
        this(PhysicsEngine physicsEngine)
        {
            physicsEngine_ = physicsEngine;
            gameTime_ = 0.0;
            frameStart_ = getTime();
            //dummy delay, not used.
            upsTimer_ = Timer(1.0);
            singletonCtor();
        }

        ///Destroy the SceneManager.
        ~this()
        {
            this.clear();
            singletonDtor();
        }

        ///Get update length in seconds, i.e. "update frame" length, not graphics.
        @property real timeStep() const {return timeStep_;}

        ///Get time when the current update started, in game time.
        @property real gameTime() const pure {return gameTime_;}

        ///Get index of the current update since start, first update being zero.
        @property size_t updateIndex() const pure {return updateIndex_;}

        ///Set time speed multiplier (0 for pause, 1 for normal speed).
        @property void timeSpeed(const real speed){timeSpeed_ = speed;}

        ///Get time speed multiplier.
        @property real timeSpeed() const pure {return timeSpeed_;}
        
        ///Update the scene manager.
        void update()
        {
            const real time = getTime();
            //time since last frame
            real frameLength = max(time - frameStart_, 0.0L);
            frameStart_ = time;

            //preventing spiral of death - if we can't keep up updating, slow down the game
            frameLength = min(frameLength * timeSpeed_, 0.25L);

            accumulatedTime_ += frameLength;

            while(accumulatedTime_ >= timeStep_)
            {
                gameTime_ += timeStep_;
                accumulatedTime_ -= timeStep_;
                physicsEngine_.update(timeStep_);
                updateActors();
                collectDead();
                physicsEngine_.collectDead(updateIndex_);
                ++updateIndex_;
            }
        }

        /**
         * Draw all actors.
         *
         * Params:  driver = Video driver to draw with.
         */
        void draw(VideoDriver driver)
        {
            foreach(actor; actors_){actor.drawActor(driver);}
        }

        ///Remove all actors.
        void clear()
        {
            //kill all actors still alive in a separate pass -
            //so the dying actors don't interact with cleared actors.

            foreach(actor; actors_) if(!actor.dead(updateIndex_))
            {
                actor.die(updateIndex_);
                actor.onDiePackage(this);
            }
            foreach(actor; actors_){.clear(actor);}
            .clear(actors_);
            .clear(actorsToAdd_);
        }

        /**
         * Add a new actor. Will be added at the beginning of the next update.
         * 
         * Note: This should only be used by actor constructor.
         *
         * Params:  actor = Actor to add. Must not already be in the SceneManager.
         */
        void addActor(Actor actor)
        in
        {
            assert(!canFind!"a is b"(actorsToAdd_, actor) &&
                   !canFind!"a is b"(actors_, actor),
                   "Adding the same actor twice");
        }
        body{actorsToAdd_ ~= actor;}

        MonitorDataInterface monitorData()
        {
            SubMonitor function(SceneManager)[string] ctors_;
            ctors_["UPS"] = &newGraphMonitor!(SceneManager, Statistics, "ups");
            return new MonitorData!(SceneManager)(this, ctors_);
        }

    package:
        ///Call onDie() of all dead actors and remove them.
        void collectDead()
        {
            foreach(actor; actors_) if(actor.dead(updateIndex_))
            {
                actor.onDiePackage(this);
            }

            auto l = 0;
            for(size_t actorFrom = 0; actorFrom < actors_.length; ++actorFrom)
            {
                auto actor = actors_[actorFrom];
                if(actor.dead(updateIndex_))
                {
                    .clear(actor);
                    continue;
                }
                actors_[l] = actor;
                ++l;
            } 
            actors_.length = l;
        }

        ///Update all actors.
        void updateActors()
        {
            const real age = upsTimer_.age();
            upsTimer_.reset();
            //avoid divide by zero
            statistics_.ups = age == 0.0L ? 0.0 : 1.0 / age;
            sendStatistics.emit(statistics_);

            actors_ ~= actorsToAdd_;
            foreach(actor; actorsToAdd_)
            {
                physicsEngine_.addBody(actor.physicsBody);
            }

            actorsToAdd_.length = 0;

            foreach(actor; actors_){actor.updatePackage(this);}
        }
}
