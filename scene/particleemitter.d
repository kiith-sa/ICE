
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Base class for particle emitters.
module scene.particleemitter;


import std.math;
import std.random;

import scene.actor;
import scene.scenemanager;
import scene.particlesystem;
import physics.physicsbody;
import math.math;
import math.vector2;
import time.timer;
import util.factory;
import containers.vector;


///Single particle of a particle system.
private struct Particle
{
    ///Timer determining life time of the particle.
    Timer timer;
    ///Position of the particle in world space.
    Vector2f position;
    ///Velocity of the particle in world space.
    Vector2f velocity;
    
    /**
     * Update the particle.
     *
     * Params:  time_step = Time step of the update.
     */
    void update(const real timeStep) pure {position += velocity * timeStep;}
}

///Base class for particle emitters.
abstract class ParticleEmitter : ParticleSystem
{
    invariant()
    {
        assert(particleLife_ > 0.0, "Lifetime of particles emitted must be > 0");
        assert(emitFrequency_ >= 0.0, "Particle emit frequency must not be negative");
        assert(angleVariation_ >= 0.0, "Particle angle variation must not be negative");
    }

    private:
        ///Lifetime of particles emitted.
        real particleLife_    = 5.0;
        ///Time since the last particle was emitted.
        real timeAccumulated_ = 0.0;
        ///Variation of angles of particles' velocities (in radians).
        real angleVariation_  = PI / 2;
        ///Emit frequency in particles per second.
        real emitFrequency_   = 10.0;

    protected:
        ///Particles in the system.
        Vector!Particle particles_;

        ///Velocity to emit particles at.
        Vector2f emitVelocity_ = Vector2f(1.0, 0.0);
        ///Current game time.
        real gameTime_;

    public:
        ///Set life time of particles emitted.
        @property final void particleLife(const real life) pure 
        {
            particleLife_ = life;
        }
        
        ///Get life time of particles emitted.
        @property final real particleLife() const pure 
        {
            return particleLife_;
        }

        ///Set number of particles to emit per second.
        @property void emitFrequency(const real frequency) pure 
        {
            emitFrequency_ = frequency;
        }
        
        ///Get number of particles emitted per second.
        @property final real emitFrequency() const pure 
        {
            return emitFrequency_;
        }

        ///Set velocity to emit particles at.
        @property final void emitVelocity(const Vector2f velocity) pure 
        {
            emitVelocity_ = velocity;
        }

        ///Set angle variation of particles emitted in radians.
        @property final void angleVariation(const real variation) pure 
        {
            angleVariation_ = variation;
        }

    protected:
        /**
         * Construct a ParticleEmitter.
         *
         * Params:  physicsBody    = Physics body of the emitter.
         *          owner           = Class to attach the emitter to. 
         *                            If null, the emitter is independent.
         *          lifeTime       = Life time of the emitter. 
         *                            If negative, lifetime is indefinite.
         *          particleLife   = Life time of particles emitted.
         *          emitFrequency  = Frequency to emit particles at in particles per second.
         *          emitVelocity   = Base velocity of particles emitted.
         *          angleVariation = Variation of angle of emit velocity in radians.
         */                          
        this(PhysicsBody physicsBody, Actor owner, 
             const real lifeTime, const real particleLife, const real emitFrequency, 
             const Vector2f emitVelocity, const real angleVariation)
        {
            particleLife_   = particleLife;
            emitFrequency_  = emitFrequency;
            angleVariation_ = angleVariation;
            emitVelocity_   = emitVelocity;
            particles_.reserve(8);

            super(physicsBody, owner, lifeTime);
        }

        override void update(SceneManager manager)
        {
            //if attached, get position from the owner.
            if(owner_ !is null){physicsBody_.position = owner_.position;}

            gameTime_ = manager.gameTime;

            bool expired(ref Particle p){return p.timer.expired(manager.gameTime);}
            //remove expired particles
            particles_.remove(&expired);
                              
            //emit new particles
            emit(manager.timeStep);

            //update particles
            foreach(ref particle; particles_){particle.update(manager.timeStep);}

            super.update(manager);
        }

        /**
         * Emit particles if any should be emitted this frame.
         * 
         * Params:  timeStep = Time step in seconds.
         */
        void emit(const real timeStep)
        {
            timeAccumulated_ += timeStep;
            if(equals(emitFrequency_, 0.0L)){return;}
            const real emitPeriod = 1.0 / emitFrequency_;
            while(timeAccumulated_ >= emitPeriod)
            {
                //add a new particle
                Particle particle;
                with(particle)
                {
                    timer          = Timer(particleLife_, gameTime_);
                    position       = physicsBody_.position;
                    velocity       = emitVelocity_;
                    velocity.angle = particle.velocity.angle + 
                                     uniform(-angleVariation_, angleVariation_);
                }
                particles_ ~= particle;

                timeAccumulated_ -= emitPeriod;
            }
        }
}

/**
 * Base class for factories producing ParticleEmitter derived classes.
 *
 * Params:  particleLife   = Life time of particles emitted in seconds.
 *                            Default; 5.0
 *          emitFrequency  = Frequency to emit particles at in particles per second.
 *                            Default; 10.0
 *          emitVelocity   = Base velocity of particles emitted.
 *                            Default; Vector2f(1.0f, 1.0f)
 *          angleVariation = Variation of angle of emit velocity in radians.
 *                            Default; PI / 2
 */                          
abstract class ParticleEmitterFactory(T) : ParticleSystemFactory!T
{
    mixin(generateFactory("real $ particleLife $ 5.0",
                           "real $ emitFrequency $ 10.0",
                           "Vector2f $ emitVelocity $ Vector2f(1.0f, 1.0f)",
                           "real $ angleVariation $ PI / 2"));
}
