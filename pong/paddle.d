//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Paddle actor.
module pong.paddle;
@safe


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
        immutable real max_xy_ratio_ = 1.0;

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
        Vector2f reflected_ball_velocity (in BallBody ball) const
        {
            //Translate the aabbox to world space
            const Rectanglef box = aabbox + position_;

            const Vector2f closest = box.clamp(ball.position);

            auto contact_direction = closest - ball.position;

            contact_direction.normalize_safe();

            const contact_point = ball.position + ball.radius * contact_direction;

            Vector2f velocity;
            
            //reflection angle depends on where on the paddle does the ball fall
            velocity.x = max_xy_ratio_ * (contact_point.x - position_.x) / 
                         (box.max.x - position_.x);
            velocity.y = (contact_point.y - position_.y) / 
                         (box.max.y - position_.y);

            //If the velocity is too horizontal, randomly nudge it up or down so that 
            //we don't end up with a ball bouncing between the same points forever
            //NOTE that this is a quick fix and it might not make sense if paddles 
            //are positioned on left-right sides of the screen instead of up/down
            if(velocity.y / velocity.x < 0.001)
            {
                float y_mod = velocity.x / 1000.0;
                //random bool
                y_mod *= uniform(-1.0, 1.0) > 0.0 ? -1.0 : 1.0;
                velocity.y += y_mod;
            }

            //keep the same velocity
            velocity.normalize_safe();
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

        override void update(in real time_step, SpatialManager!PhysicsBody manager)
        {
            //keep the paddle within the limits
            const Rectanglef box = aabbox;
            const position_limits = Rectanglef(limits_.min - box.min,
                                               limits_.max - box.max);
            position = position_limits.clamp(position);

            super.update(time_step, manager);
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
        Vector2f position = physics_body_.position;
        Rectanglef box = box_ + position;

        assert(equals(box.max.x - position.x, position.x - box.min.x, 1.0f),
               "Paddle not symmetric on the X axis");
        assert(equals(box.max.y - position.y, position.y - box.min.y, 1.0f),
               "Paddle not symmetric on the Y axis");
        assert(physics_body_.classinfo == PaddleBody.classinfo,
               "Physics body of a paddle must be a PaddleBody");
        assert(energy_ >= 0.0, "Energy of a paddle must not be negative");
        assert(energy_mult_ > 0.0, "Energy multiplier of a paddle must be positive");
        assert(dissipate_rate_ >= 0.0, "Dissipate rate of a paddle must not be negative");
    }

    private:
        ///Default speed of this paddle.
        real default_speed_;
        ///Current speed of this paddle.
        real speed_;
        ///Particle emitter of the paddle
        ParticleEmitter emitter_;
        ///Default emit frequency of the emitter.
        real default_emit_frequency_;
        ///"Energy" from collisions, affects speed and graphics.
        real energy_ = 0.0;
        ///Multiplier applied to energy related effects.
        real energy_mult_ = 0.00001;
        ///How much energy "dissipates" per second.
        real dissipate_rate_ = 12000.0;
        ///Color to interpolate to based on energy levels.
        Color energy_color_ = rgba!"E0E0FF80";

    public:
        override void on_die(SceneManager manager)
        {
            emitter_.life_time      = 1.0;
            emitter_.emit_frequency = 0.0;
            emitter_.detach();
        }

        ///Get movement limits of this paddle.
        @property Rectanglef limits() const 
        {
            return (cast(PaddleBody)physics_body_).limits;
        }

        ///Control the paddle to move right (used by player or AI).
        void move_right(){physics_body_.velocity = speed_ * Vector2f(1.0, 0.0);}

        ///Control the paddle to move left (used by player or AI).
        void move_left(){physics_body_.velocity = speed_ * Vector2f(-1.0, 0.0);}

        ///Control the paddle to stop (used by player or AI).
        void stop(){physics_body_.velocity = Vector2f(0.0, 0.0);}

    protected:
        /**
         * Construct a paddle.
         *
         * Params:  physics_body = Physics body of the paddle.
         *          box          = Rectangle used for graphics representation of the paddle.
         *          speed        = Speed of paddle movement.
         *          emitter      = Particle emitter of the paddle.
         */
        this(PaddleBody physics_body, const ref Rectanglef box,
             in real speed, ParticleEmitter emitter)
        {
            default_color_ = rgba!"0000FF20";
            super(physics_body, box);
            speed_ = default_speed_ = speed;
            emitter_ = emitter;
            default_emit_frequency_ = emitter_.emit_frequency;
            emitter.attach(this);
        }

        override void update(SceneManager manager)
        {
            energy_ = max(0.0L, energy_ - manager.time_step * dissipate_rate_);
            foreach(collider; physics_body_.colliders)
            {
                if(!equals(collider.inverse_mass, 0.0L))
                {
                    energy_ += collider.velocity.length / collider.inverse_mass;
                }
            }

            const real energy_ratio = energy_ * energy_mult_;

            color_ = energy_color_.interpolated(default_color_, min(energy_ratio, 1.0L));
            speed_ = default_speed_ * (1.0 + 1.5 * energy_ratio);
            emitter_.emit_frequency = default_emit_frequency_ * (1.0 + 10.0 * energy_ratio);

            super.update(manager);
        }
}

/**
 * Factory used to construct paddles.
 *
 * Params:  limits_min = Minimum extent of paddle movement limits in world space.
 *                       Default; Vector2f(-2.0f, -2.0f)
 *          limits_max = Maximum extent of paddle movement limits in world space.
 *                       Default; Vector2f(2.0f, 2.0f)
 *          speed      = Speed of paddle movement.
 *                       Default; 135.0
 */
class PaddleFactory : WallFactoryBase!(Paddle)
{
    mixin(generate_factory("Vector2f $ limits_min $ Vector2f(-2.0f, -2.0f)", 
                           "Vector2f $ limits_max $ Vector2f(2.0f, 2.0f)",
                           "real     $ speed      $ 135.0"));

    public override Paddle produce(SceneManager manager)
    {
        auto limits = Rectanglef(limits_min_, limits_max_);
        auto physics_body = new PaddleBody(bbox, position_, velocity_, real.infinity, limits);

        //construct particle system of the paddle
        LineEmitter emitter;
        with(new LineEmitterFactory)
        {
            particle_life   = 3.0;
            emit_frequency  = 30;
            emit_velocity   = Vector2f(speed_ * 0.15, 0.0);
            angle_variation = 2 * PI;
            line_length     = 2.0;
            line_width      = 1;
            start_color     = rgba!"FFFFFF40";
            end_color       = rgba!"4040FF00";
            emitter         = produce(manager);
        }

        auto rect = rectangle();
        return new_actor(manager, new Paddle(physics_body, rect, speed_, emitter));
    }
}
