//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


module pong.ball;
@safe


import std.math;

import pong.paddle;
import scene.actor;
import scene.actorcontainer;
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
        override void collision_response(ref Contact contact)
        {
            const PhysicsBody other = this is contact.body_a ? contact.body_b : contact.body_a;
            //handle paddle collisions separately
            if(other.classinfo == PaddleBody.classinfo)
            {
                const PaddleBody paddle = cast(PaddleBody)other;
                //let paddle reflect this ball
                velocity_ = paddle.reflected_ball_velocity(this);
                //prevent any further resolving (since we're not doing precise physics)
                contact.resolved = true;
                return;
            }
            super.collision_response(contact);
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
        override void collision_response(ref Contact contact)
        {
            //keep the speed unchanged
            const float speed = velocity_.length_safe;
            super.collision_response(contact);
            velocity_.normalize_safe();
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
        float particle_speed_;
        ///Line trail of the ball.
        LineTrail trail_;
        ///Draw the ball itself or only the particle systems?
        bool draw_ball_;

    public:
        override void die()
        {
            trail_.life_time = 0.5;
            trail_.detach();
            emitter_.life_time = 2.0;
            emitter_.emit_frequency = 0.0;
            emitter_.detach();
            super.die();
        }
 
        ///Get the radius of this ball.
        @property float radius() const {return (cast(BallBody)physics_body_).radius;}

    protected:
        /**
         * Construct a ball with specified parameters.
         *
         * Params:  container      = Actor container to manage this ball.
         *          physics_body   = Physics body of the ball.
         *          trail          = Line trail of the ball.
         *          emitter        = Particle trail of the ball.
         *          particle_speed = Speed of particles in the particle trail.
         *          draw_ball      = Draw the ball itself or only particle effects?
         */
        this(ActorContainer container, BallBody physics_body, LineTrail trail,
             ParticleEmitter emitter, in float particle_speed, in bool draw_ball)
        {
            super(container, physics_body);
            trail_ = trail;
            trail.attach(this);
            emitter_ = emitter;
            emitter.attach(this);
            particle_speed_ = particle_speed;
            draw_ball_ = draw_ball;
        }

        override void update(in real time_step, in real game_time)
        {
            //Ball can only change direction, not speed, after a collision
            if(physics_body_.collided())
            {
                emitter_.emit_velocity = -physics_body_.velocity.normalized * particle_speed_;
            }
        }

        override void draw(VideoDriver driver)
        {
            if(!draw_ball_){return;}
            const Vector2f position = physics_body_.position;
            driver.line_aa = true;
            driver.line_width = 3;
            driver.draw_circle(position, radius - 2, Color(240, 240, 255, 255), 4);
            driver.line_width = 1;
            driver.draw_circle(position, radius, Color(192, 192, 255, 192));
            driver.line_width = 1;                  
            driver.line_aa = false;
        }
}

/**
 * Factory used to produce balls.
 *
 * Params:  radius         = Radius of the ball.
 *                           Default; 6.0
 *          particle_speed = Speed of particles in the ball's particle trail.
 *                           Default; 25.0
 */
class BallFactory : ActorFactory!(Ball)
{
    mixin(generate_factory("float $ radius $ 6.0f",
                           "float $ particle_speed $ 25.0f"));
    private:
        ///Factory for ball line trail.
        LineTrailFactory trail_factory_;
        ///Factory for ball particle trail.
        LineEmitterFactory emitter_factory_;

    public:
        ///Construct a BallFactory, initializing factory data.
        this()
        {
            trail_factory_ = new LineTrailFactory;
            emitter_factory_ = new LineEmitterFactory;
        }

        override Ball produce(ActorContainer container)
        {
            with(trail_factory_)
            {
                particle_life = 0.5;
                emit_frequency = 60;
                start_color = Color(240, 240, 255, 255);
                end_color = Color(240, 240, 255, 0);
            }

            with(emitter_factory_)
            {
                particle_life = 2.0;
                emit_frequency = 160;
                emit_velocity = -this.velocity_.normalized * particle_speed_;
                angle_variation = PI / 4;
                line_length = 2.0;
                start_color = Color(224, 224, 255, 32);
                end_color = Color(224, 224, 255, 0);
            }

            adjust_factories();
            return new Ball(container, ball_body, 
                            trail_factory_.produce(container),
                            emitter_factory_.produce(container),
                            particle_speed_, draw_ball);
        }

    protected:
        ///Construct a collision circle with factory parameters.
        final VolumeCircle circle() const 
        {
            return new VolumeCircle(Vector2f(0.0f, 0.0f), radius_);
        }

        ///Construct a ball body with factory parameters.
        BallBody ball_body() const 
        {
            return new BallBody(circle, position_, velocity_, 100.0, radius_);
        }

        ///Adjust particle effect factories. Used by derived classes.
        void adjust_factories(){};

        ///Determine if the produced ball should draw itself, instead of just particle systems.
        bool draw_ball(){return true;}
}             

///Factory used to produce dummy balls.
class DummyBallFactory : BallFactory
{
    protected:
        override BallBody ball_body() const
        {
            return new DummyBallBody(circle, position_, velocity_, 4.0, radius_);
        }

        override void adjust_factories()
        {
            trail_factory_.start_color = Color(240, 240, 255, 8); 
            with(emitter_factory_)
            {
                start_color = Color(240, 240, 255, 6);
                line_length = 3.0;
                emit_frequency = 24;
            }
        }

        override bool draw_ball(){return false;}
}
