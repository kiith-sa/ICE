//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Ball spawning actor.
module pong.ballspawner;
@safe


import std.math;
import std.random;

import scene.actor;
import scene.scenemanager;
import physics.physicsbody;
import video.videodriver;
import time.timer;
import math.vector2;
import util.signal;
import util.factory;
import color;


/**
 * Handles ball respawning and related effects.
 *
 * When the spawner is created, it generates a set of directions the ball can be 
 * spawned at, in roughly the same direction (determined by specified spread) Then, 
 * during its lifetime, it displays the directions to the player (as rays), gives the
 * player a bit of time and spawns the ball in one of generated directions.
 *
 * Signal:
 *     public mixin Signal!(Vector2f, real) spawn_ball
 *
 *     Emitted when the spawner expires, passing direction and speed to emit the ball at.
 */
class BallSpawner : Actor
{
    invariant()
    {
        assert(min_angle_ < PI * 0.5, 
               "Ball spawn angle restriction larger or equal than PI / 2 "
               "would make it impossible to spawn a ball in any direction");
        assert(ball_speed_ > 1.0, "Too low ball speed");
        assert(direction_count_ > 0, 
               "There must be at least one direction to spawn the ball with");
        assert(light_speed_ > 0.0, "Zero light speed");
        assert(light_width_ > 0.0, "Zero light width");
    }

    private:
        ///When this timer expires, the ball is spawned and the spawner destroyed.
        Timer timer_;
        
        ///Speed to spawn balls at.
        real ball_speed_;

        /**
         * Minimum angle difference from 0.5*pi or 1.5*pi (from horizontal line).
         * Prevents the ball from being spawned too horizontally.
         */
        real min_angle_ = PI * 0.125;
        ///Number of possible spawn directions to generate.
        uint direction_count_ = 12;
        ///Directions the ball can be spawned at in radians.
        real[] directions_;

        /**
         * "Light" direction used by the rays effect.
         * The light rotates and shows the rays within its range.
         */
        real light_ = 0;
        ///Rotation speed of the "light", in radians per second.
        real light_speed_;
        ///Angular width of the "light" in radians.
        real light_width_ = PI / 6.0; 
        ///Draw the "light" ?
        bool light_expired = false;

    public:
        ///Emitted when the spawner expires, passing direction and speed to emit the ball at.
        mixin Signal!(Vector2f, real) spawn_ball;

    protected:
        /**
         * Construct a BallSpawner.
         * 
         * Params:    physics_body = Physics body of the spawner.
         *            timer        = Ball will be spawned when this timer (game time) expires.
         *                           70% of the time will be taken by the rays effect.
         *            spread       = "Randomness" of the spawn directions.
         *                           Zero will result in only one definite direction,
         *                           1 will result in completely random direction
         *                           (except for horizontal directions that are 
         *                           disallowed to prevent ball from getting stuck)
         *            ball_speed   = Speed to spawn the ball at.
         */
        this(PhysicsBody physics_body, in Timer timer, in real spread, in real ball_speed)
        in{assert(spread >= 0.0, "Negative ball spawning spread");}
        body
        {                
            super(physics_body);

            ball_speed_ = ball_speed;
            timer_ = timer;
            //leave a third of time without the rays effect to give time to the player
            light_speed_ = (2 * PI) / (timer.delay * 0.70);

            generate_directions(spread);
        }

        override void on_die(SceneManager manager)
        {
            spawn_ball.disconnect_all();
        }

        override void update(SceneManager manager)
        {
            if(timer_.expired(manager.game_time))
            {
                //emit the ball in a random, previously generated direction
                Vector2f direction = Vector2f(1.0f, 1.0f);
                direction.angle = directions_[uniform(0, directions_.length)];
                spawn_ball.emit(direction, ball_speed_);
                die(manager.update_index);
                return;
            }
            if(!light_expired && light_ >= (2 * PI)){light_expired = true;}

            //update light direction
            light_ += light_speed_ * manager.time_step;
        }

        override void draw(VideoDriver driver)
        {
            driver.line_aa = true;
            scope(exit){driver.line_aa = false;} 

            Vector2f center = physics_body_.position;
            //base color of the rays
            const base_color = Color(224, 224, 255, 128);
            const light_color = Color(224, 224, 255, 4);
            const light_color_end = Color(224, 224, 255, 0);

            const real ray_length = 600.0;

            Vector2f direction = Vector2f(1.0f, 1.0f);
            if(!light_expired)
            {
                //draw the light
                direction.angle = light_ + light_width_;
                driver.draw_line(center, center + direction * ray_length, 
                                 light_color, light_color_end);
                direction.angle = light_ - light_width_;
                driver.draw_line(center, center + direction * ray_length, 
                                 light_color, light_color_end);
            }

            driver.line_width = 2;
            scope(exit){driver.line_width = 1;} 
            
            //draw the rays in range of the light
            foreach(d; directions_)
            {
                const real distance = abs(d - light_);
                if(distance > light_width_){continue;}

                Color color = base_color;
                color.a *= 1.0 - distance / light_width_;

                direction.angle = d;
                driver.draw_line(center, center + direction * ray_length, color, color);
            }
        }

    private:
        /**
         * Generate directions the ball might be spawned at.
         * 
         * Params:    spread = "Randomness" of the spawn directions.
         *                     Zero will result in only one definite direction,
         *                     1 will result in completely random direction
         *                     (except for horizontal directions that are 
         *                     disallowed to prevent ball from getting stuck)
         */
        void generate_directions(real spread)
        {
            //base direction of all generated directions
            const real base = uniform(0.0, 1.0);
            //adjust spread according to how much of the circle is "allowed" 
            //directions - i.e. nearly horizontal directions are not allowed
            spread *= 1 - (2 * min_angle_) / PI; 

            for(uint d = 0; d < direction_count_; d++)
            {
                real direction = uniform(base - spread, base + spread);
                //integer part of the direction is stripped so that
                //it's in the 0.0 - 1.0 range
                direction = std.math.abs(direction - cast(int)direction);

                //"allowed" part of the circle in radians
                const real range = 2.0 * PI - 4.0 * min_angle_;
                                                   
                //0.0 - 0.5 gets mapped to 0.5pi+min_angle - 1.5pi-min_angle range
                if(direction < 0.5){direction = PI * 0.5 + min_angle_ + direction * range;}
                //0.5 - 1.0 gets mapped to 1.5pi+min_angle - 0.5pi-min_angle range
                else{direction = PI * 1.5 + min_angle_ + (direction - 0.5) * range;}

                directions_ ~= direction;
            }
        }
}

/**
 * Factory used to construct ball spawners.
 *
 * Params:  time       = Time to spawn the ball in.
 *                       Default; 5.0
 *          spread     = "Randomness" of the spawn directions.
 *                       Zero will result in only one definite direction,
 *                       1 will result in completely random direction
 *                       (except for horizontal directions that are 
 *                       disallowed to prevent ball from getting stuck)
 *                       Default; 0.25
 *          ball_speed = Speed of the spawned ball.
 *                       Default; 200
 */
final class BallSpawnerFactory : ActorFactory!(BallSpawner)
{
    mixin(generate_factory("real $ time $ 5.0",
                           "real $ spread $ 0.25",
                           "real $ ball_speed $ 200"));
    private:
        ///Start time of the spawners' timer.
        real start_time_;
    public:
        /**
         * Construct a BallSpawnerFactory.
         *
         * Params: start_time = Start time of the produced spawner.
         *                      The time when the ball will be spawned
         *                      is relative to this time.
         */
        this(in real start_time){start_time_ = start_time;}

        override BallSpawner produce(SceneManager manager)
        {                          
            auto physics_body = new PhysicsBody(null, position_, velocity_, real.infinity);
            return new_actor(manager, 
                             new BallSpawner(physics_body, Timer(time_, start_time_),
                                             spread_, ball_speed_));
        }
}
