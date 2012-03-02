//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Paddle actor.
module pong.paddle;


import std.algorithm;
import std.math;
import std.random;

import pong.ball;
import pong.wall;
import scene.actor;
import scene.lineemitter;
import scene.particleemitter;
import scene.scenemanager;
import math.math;
import math.vector2;
import math.rectangle;
import physics.physicsbody;
import physics.contact;
import spatial.volumeaabbox;
import spatial.spatialmanager;
import util.factory;
import color;


/**
 * Physics body of a paddle. 
 *
 * Contains functionality making Arkanoid style ball reflection possible.
 */
class PaddleBody : PhysicsBody
{
    private:
        /**
         * Max ratio of X and Y speed when reflecting the ball, i.e., if this is 1.0,
         * and the ball gets reflected from the corner of the paddle, ratio of X and Y
         * components of reflected ball velocity will be 1:1.
        */
        immutable real maxXyRatio_ = 1.0;

        ///Limits of paddle body movement in world space.
        immutable Rectanglef limits_;

    public:
        /**
         * Return velocity to reflect a BallBody at.
         *
         * Used by BallBody collision response.
         *
         * Params:  ball = BallBody to reflect.
         *
         * Returns: Velocity the BallBody should be reflected at.
         */
        Vector2f reflectedBallVelocity (in BallBody ball) const
        {
            //Translate the aabbox to world space
            const Rectanglef box = aabbox + position_;

            const Vector2f closest = box.clamp(ball.position);

            auto contactDirection = closest - ball.position;

            contactDirection.normalize();

            const contactPoint = ball.position + ball.radius * contactDirection;

            Vector2f velocity;
            
            //reflection angle depends on where on the paddle does the ball fall
            velocity.x = maxXyRatio_ * (contactPoint.x - position_.x) / 
                         (box.max.x - position_.x);
            velocity.y = (contactPoint.y - position_.y) / 
                         (box.max.y - position_.y);

            //If the velocity is too horizontal, randomly nudge it up or down so that 
            //we don't end up with a ball bouncing between the same points forever
            //NOTE that this is a quick fix and it might not make sense if paddles 
            //are positioned on left-right sides of the screen instead of up/down
            if(velocity.y / velocity.x < 0.001)
            {
                float yMod = velocity.x / 1000.0;
                //random bool
                yMod *= uniform(-1.0, 1.0) > 0.0 ? -1.0 : 1.0;
                velocity.y += yMod;
            }

            //keep the same velocity
            velocity.normalize();
            return velocity * ball.velocity.length;
        }

        ///Get movement limits of this paddle body.
        @property final Rectanglef limits() const {return limits_;}

    protected:
        /**
         * Construct a paddle body with specified parameters.
         *
         * Params:  aabbox   = Collision aabbox of the body. 
         *          position = Starting position of the body.
         *          velocity = Starting velocity of the body.
         *          mass     = Mass of the body.
         *          limits   = Limits of body's movement
         */
        this(VolumeAABBox aabbox, in Vector2f position, in Vector2f velocity, 
             in real mass, const ref Rectanglef limits)
        {
            super(aabbox, position, velocity, mass);
            limits_ = limits;
        }

        override void update(in real timeStep, SpatialManager!PhysicsBody manager)
        {
            //keep the paddle within the limits
            const Rectanglef box = aabbox;
            const positionLimits = Rectanglef(limits_.min - box.min,
                                               limits_.max - box.max);
            position = positionLimits.clamp(position);

            super.update(timeStep, manager);
        }

    private:
        ///Return rectangle representing bounding box of this body in world space.
        @property final Rectanglef aabbox() const
        in
        {
            //checking here because invariant can't call public function members
            assert(volume.classinfo == VolumeAABBox.classinfo,
                   "Collision volume of a paddle must be an axis aligned bounding box");
        }
        body{return(cast(VolumeAABBox)volume).rectangle;}
}

///A paddle controlled by a player or AI.
class Paddle : Wall
{
    invariant()
    {
        //this could be done by keeping reference to aabbox of the physics body
        //and translating that by physicsbody's position
        Vector2f position = physicsBody_.position;
        Rectanglef box = box_ + position;

        assert(equals(box.max.x - position.x, position.x - box.min.x, 1.0f),
               "Paddle not symmetric on the X axis");
        assert(equals(box.max.y - position.y, position.y - box.min.y, 1.0f),
               "Paddle not symmetric on the Y axis");
        assert(physicsBody_.classinfo == PaddleBody.classinfo,
               "Physics body of a paddle must be a PaddleBody");
        assert(energy_ >= 0.0, "Energy of a paddle must not be negative");
        assert(energyMult_ > 0.0, "Energy multiplier of a paddle must be positive");
        assert(dissipateRate_ >= 0.0, "Dissipate rate of a paddle must not be negative");
    }

    private:
        ///Default speed of this paddle.
        real defaultSpeed_;
        ///Current speed of this paddle.
        real speed_;
        ///Particle emitter of the paddle
        ParticleEmitter emitter_;
        ///Default emit frequency of the emitter.
        real defaultEmitFrequency_;
        ///"Energy" from collisions, affects speed and graphics.
        real energy_ = 0.0;
        ///Multiplier applied to energy related effects.
        real energyMult_ = 0.00001;
        ///How much energy "dissipates" per second.
        real dissipateRate_ = 12000.0;
        ///Color to interpolate to based on energy levels.
        Color energyColor_ = rgba!"E0E0FF80";

    public:
        override void onDie(SceneManager manager)
        {
            emitter_.lifeTime      = 1.0;
            emitter_.emitFrequency = 0.0;
            emitter_.detach();
        }

        ///Get movement limits of this paddle.
        @property Rectanglef limits() const 
        {
            return (cast(PaddleBody)physicsBody_).limits;
        }

        ///Control the paddle to move right (used by player or AI).
        void moveRight(){physicsBody_.velocity = speed_ * Vector2f(1.0, 0.0);}

        ///Control the paddle to move left (used by player or AI).
        void moveLeft(){physicsBody_.velocity = speed_ * Vector2f(-1.0, 0.0);}

        ///Control the paddle to stop (used by player or AI).
        void stop(){physicsBody_.velocity = Vector2f(0.0, 0.0);}

    protected:
        /**
         * Construct a paddle.
         *
         * Params:  physicsBody = Physics body of the paddle.
         *          box          = Rectangle used for graphics representation of the paddle.
         *          speed        = Speed of paddle movement.
         *          emitter      = Particle emitter of the paddle.
         */
        this(PaddleBody physicsBody, const ref Rectanglef box,
             in real speed, ParticleEmitter emitter)
        {
            defaultColor_ = rgba!"0000FF20";
            super(physicsBody, box);
            speed_ = defaultSpeed_ = speed;
            emitter_ = emitter;
            defaultEmitFrequency_ = emitter_.emitFrequency;
            emitter.attach(this);
        }

        override void update(SceneManager manager)
        {
            energy_ = max(0.0L, energy_ - manager.timeStep * dissipateRate_);
            foreach(collider; physicsBody_.colliders)
            {
                if(!equals(collider.inverseMass, 0.0L))
                {
                    energy_ += collider.velocity.length / collider.inverseMass;
                }
            }

            const real energyRatio = energy_ * energyMult_;

            color_ = energyColor_.interpolated(defaultColor_, min(energyRatio, 1.0L));
            speed_ = defaultSpeed_ * (1.0 + 1.5 * energyRatio);
            emitter_.emitFrequency = defaultEmitFrequency_ * (1.0 + 10.0 * energyRatio);

            super.update(manager);
        }
}

/**
 * Factory used to construct paddles.
 *
 * Params:  limitsMin = Minimum extent of paddle movement limits in world space.
 *                       Default; Vector2f(-2.0f, -2.0f)
 *          limitsMax = Maximum extent of paddle movement limits in world space.
 *                       Default; Vector2f(2.0f, 2.0f)
 *          speed      = Speed of paddle movement.
 *                       Default; 135.0
 */
class PaddleFactory : WallFactoryBase!(Paddle)
{
    mixin(generateFactory("Vector2f $ limitsMin $ Vector2f(-2.0f, -2.0f)", 
                           "Vector2f $ limitsMax $ Vector2f(2.0f, 2.0f)",
                           "real     $ speed      $ 135.0"));

    public override Paddle produce(SceneManager manager)
    {
        auto limits = Rectanglef(limitsMin_, limitsMax_);
        auto physicsBody = new PaddleBody(bbox, position_, velocity_, real.infinity, limits);

        //construct particle system of the paddle
        LineEmitter emitter;
        with(new LineEmitterFactory)
        {
            particleLife   = 3.0;
            emitFrequency  = 30;
            emitVelocity   = Vector2f(speed_ * 0.15, 0.0);
            angleVariation = 2 * PI;
            lineLength     = 2.0;
            lineWidth      = 1;
            startColor     = rgba!"FFFFFF40";
            endColor       = rgba!"4040FF00";
            emitter         = produce(manager);
        }

        auto rect = rectangle();
        return newActor(manager, new Paddle(physicsBody, rect, speed_, emitter));
    }
}
