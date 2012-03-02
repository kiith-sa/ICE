//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Ball classes.
module pong.ball;


import std.math;

import pong.paddle;
import scene.actor;
import scene.scenemanager;
import scene.particleemitter;
import scene.lineemitter;
import scene.linetrail;
import physics.physicsbody;
import physics.contact;
import spatial.volumecircle;
import video.videodriver;
import math.vector2;
import util.factory;
import color;


/**
 * Physics body of a ball. 
 *
 * Overrides default collision response to get Arkanoid style ball behavior.
 */
class BallBody : PhysicsBody
{
    invariant(){assert(radius_ > 1.0f, "Ball radius must be at least 1.0");}
    private:
        ///Radius of the ball body.
        immutable float radius_;

    public:
        override void collisionResponse(ref Contact contact)
        {
            const PhysicsBody other = this is contact.bodyA ? contact.bodyB : contact.bodyA;
            //handle paddle collisions separately
            if(other.classinfo == PaddleBody.classinfo)
            {
                const PaddleBody paddle = cast(PaddleBody)other;
                //let paddle reflect this ball
                velocity_ = paddle.reflectedBallVelocity(this);
                //prevent any further resolving (since we're not doing precise physics)
                contact.resolved = true;
                return;
            }
            super.collisionResponse(contact);
        }

        ///Get radius of this ball body.
        @property float radius() const {return radius_;}

    private:
        /**
         * Construct a ball body with specified parameters.
         *
         * Params:  circle   = Collision circle of the body.
         *          position = Starting position.
         *          velocity = Starting velocity.
         *          mass     = Mass of the body.
         *          radius   = Radius of a circle representing bounding circle
         *                     of this body (centered at body's position).
         */
        this(VolumeCircle circle, in Vector2f position, in Vector2f velocity, 
             in real mass, in float radius)
        {
            radius_ = radius;
            super(circle, position, velocity, mass);
        }
}

/**
 * Physics body of a dummy ball. 
 *
 * Limits dummy ball speed to prevent it being thrown out of the gameplay
 * area after collision with a ball. (normal ball has no such limit- its speed
 * can change, slightly, by collisions with dummy balls)
 */
class DummyBallBody : BallBody
{
    public:
        override void collisionResponse(ref Contact contact)
        {
            //keep the speed unchanged
            const float speed = velocity_.length;
            super.collisionResponse(contact);
            velocity_.normalize();
            velocity_ *= speed;

            //prevent any further resolving (since we're not doing precise physics)
            contact.resolved = true;
        }

    private:
        /**
         * Construct a dummy ball body with specified parameters.
         *
         * Params:  circle   = Collision circle of the body.
         *          position = Starting position.
         *          velocity = Starting velocity.
         *          mass     = Mass of the body.
         *          radius   = Radius of a circle representing bounding circle
         *                     of this body (centered at body's position).
         */
        this(VolumeCircle circle, in Vector2f position, in Vector2f velocity, 
             in real mass, in float radius)
        {
            super(circle, position, velocity, mass, radius);
        }
}

///A ball that can bounce off other objects.
class Ball : Actor
{
    private:
        ///Particle trail of the ball.
        ParticleEmitter emitter_;
        ///Speed of particles emitted by the ball.
        float particleSpeed_;
        ///Line trail of the ball.
        LineTrail trail_;
        ///Draw the ball itself or only the particle systems?
        bool drawBall_;

    public:
        override void onDie(SceneManager manager)
        {
            trail_.lifeTime = 0.5;
            trail_.detach();
            emitter_.lifeTime = 2.0;
            emitter_.emitFrequency = 0.0;
            emitter_.detach();
        }
 
        ///Get the radius of this ball.
        @property float radius() const {return (cast(BallBody)physicsBody_).radius;}

    protected:
        /**
         * Construct a ball.
         *
         * Params:  physicsBody   = Physics body of the ball.
         *          trail          = Line trail of the ball.
         *          emitter        = Particle trail of the ball.
         *          particleSpeed = Speed of particles in the particle trail.
         *          drawBall      = Draw the ball itself or only particle effects?
         */
        this(BallBody physicsBody, LineTrail trail,
             ParticleEmitter emitter, in float particleSpeed, in bool drawBall)
        {
            super(physicsBody);
            trail_ = trail;
            trail.attach(this);
            emitter_ = emitter;
            emitter.attach(this);
            particleSpeed_ = particleSpeed;
            drawBall_ = drawBall;
        }

        override void update(SceneManager manager)
        {
            //Ball can only change direction, not speed, after a collision
            if(!physicsBody_.collided()){return;}
            emitter_.emitVelocity = -physicsBody_.velocity.normalized * particleSpeed_;
        }

        override void draw(VideoDriver driver)
        {
            if(!drawBall_){return;}
            const Vector2f position = physicsBody_.position;
            driver.lineAA = true;
            driver.lineWidth = 3;
            driver.drawCircle(position, radius - 2, rgb!"E0E0FF", 4);
            driver.lineWidth = 1;
            driver.drawCircle(position, radius, rgba!"C0C0FFC0");
            driver.lineAA = false;
        }
}

/**
 * Factory used to produce balls.
 *
 * Params:  radius         = Radius of the ball.
 *                           Default; 6.0
 *          particleSpeed = Speed of particles in the ball's particle trail.
 *                           Default; 25.0
 */
class BallFactory : ActorFactory!(Ball)
{
    mixin(generateFactory("float $ radius $ 6.0f",
                           "float $ particleSpeed $ 25.0f"));
    private:
        ///Factory for ball line trail.
        LineTrailFactory trailFactory_;
        ///Factory for ball particle trail.
        LineEmitterFactory emitterFactory_;

    public:
        ///Construct a BallFactory, initializing factory data.
        this()
        {
            trailFactory_   = new LineTrailFactory;
            emitterFactory_ = new LineEmitterFactory;
        }

        override Ball produce(SceneManager manager)
        {
            with(trailFactory_)
            {
                particleLife  = 0.5;
                emitFrequency = 60;
                startColor    = rgb!"E0E0FF";
                endColor      = rgba!"E0E0FF00";
            }

            with(emitterFactory_)
            {
                particleLife   = 2.0;
                emitFrequency  = 160;
                emitVelocity   = -this.velocity_.normalized * particleSpeed_;
                angleVariation = PI / 4;
                lineLength     = 2.0;
                startColor     = rgba!"E0E0FF20";
                endColor       = rgba!"E0E0FF00";
            }

            adjustFactories();
            return newActor(manager, 
                             new Ball(ballBody, 
                             trailFactory_.produce(manager),
                             emitterFactory_.produce(manager),
                             particleSpeed_, drawBall));
        }

    protected:
        ///Construct a collision circle with factory parameters.
        @property final VolumeCircle circle() const 
        {
            return new VolumeCircle(Vector2f(0.0f, 0.0f), radius_);
        }

        ///Construct a ball body with factory parameters.
        @property BallBody ballBody() const 
        {
            return new BallBody(circle, position_, velocity_, 100.0, radius_);
        }

        ///Adjust particle effect factories. Used by derived classes.
        void adjustFactories(){};

        ///Determine if the produced ball should draw itself, instead of just particle systems.
        bool drawBall(){return true;}
}             

///Factory used to produce dummy balls.
class DummyBallFactory : BallFactory
{
    protected:
        @property override BallBody ballBody() const
        {
            return new DummyBallBody(circle, position_, velocity_, 4.0, radius_);
        }

        override void adjustFactories()
        {
            trailFactory_.startColor = rgba!"F0F0FF08";
            with(emitterFactory_)
            {
                startColor    = rgba!"F0F0FF06";
                lineLength    = 3.0;
                emitFrequency = 24;
            }
        }

        override bool drawBall(){return false;}
}
