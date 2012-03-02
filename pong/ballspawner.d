//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Ball spawning actor.
module pong.ballspawner;


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
 * When created, it generates a set of directions the ball can be 
 * spawned at, in roughly the same direction (determined by specified spread).
 * During its lifetime, it displays the directions to the player (as rays), gives the
 * player a bit of time and spawns the ball in one of generated directions.
 *
 * Signal:
 *     public mixin Signal!(Vector2f, real) spawnBall
 *
 *     Emitted when the spawner expires, passing direction and speed to emit the ball at.
 */
class BallSpawner : Actor
{
    invariant()
    {
        assert(minAngle_ < PI * 0.5, 
               "Ball spawn angle restriction larger or equal than PI / 2 "
               "would make it impossible to spawn a ball in any direction");
        assert(ballSpeed_ > 1.0, "Too low ball speed");
        assert(directionCount_ > 0, 
               "There must be at least one direction to spawn the ball with");
        assert(lightSpeed_ > 0.0, "Zero light speed");
        assert(lightWidth_ > 0.0, "Zero light width");
    }

    private:
        ///When this timer expires, the ball is spawned and the spawner destroyed.
        Timer timer_;
        
        ///Speed to spawn balls at.
        real ballSpeed_;

        /**
         * Minimum angle difference from 0.5*pi or 1.5*pi (from horizontal line).
         * Prevents the ball from being spawned too horizontally.
         */
        real minAngle_ = PI * 0.125;
        ///Number of possible spawn directions to generate.
        uint directionCount_ = 12;
        ///Directions the ball can be spawned at in radians.
        real[] directions_;

        /**
         * "Light" direction used by the rays effect.
         * The light rotates and shows the rays within its range.
         */
        real light_ = 0;
        ///Rotation speed of the "light", in radians per second.
        real lightSpeed_;
        ///Angular width of the "light" in radians.
        real lightWidth_ = PI / 6.0; 
        ///Draw the "light" ?
        bool lightExpired = false;

    public:
        ///Emitted when the spawner expires, passing direction and speed to emit the ball at.
        mixin Signal!(Vector2f, real) spawnBall;

    protected:
        /**
         * Construct a BallSpawner.
         * 
         * Params:    physicsBody = Physics body of the spawner.
         *            timer        = Ball will be spawned when this timer (game time) expires.
         *                           70% of the time will be taken by the rays effect.
         *            spread       = "Randomness" of the spawn directions.
         *                           Zero will result in only one definite direction,
         *                           1 will result in completely random direction
         *                           (except for horizontal directions that are 
         *                           disallowed to prevent ball from getting stuck)
         *            ballSpeed   = Speed to spawn the ball at.
         */
        this(PhysicsBody physicsBody, in Timer timer, in real spread, in real ballSpeed)
        in{assert(spread >= 0.0, "Negative ball spawning spread");}
        body
        {                
            super(physicsBody);

            ballSpeed_ = ballSpeed;
            timer_ = timer;
            //leave a third of time without the rays effect to give time to the player
            lightSpeed_ = (2 * PI) / (timer.delay * 0.70);

            generateDirections(spread);
        }

        override void onDie(SceneManager manager)
        {
            spawnBall.disconnectAll();
        }

        override void update(SceneManager manager)
        {
            if(timer_.expired(manager.gameTime))
            {
                //emit the ball in a random, previously generated direction
                auto direction  = Vector2f(1.0f, 1.0f);
                direction.angle = directions_[uniform(0, directions_.length)];
                spawnBall.emit(direction, ballSpeed_);
                die(manager.updateIndex);
                return;
            }
            if(!lightExpired && light_ >= (2 * PI)){lightExpired = true;}

            //update light direction
            light_ += lightSpeed_ * manager.timeStep;
        }

        override void draw(VideoDriver driver)
        {
            driver.lineAA = true;
            scope(exit){driver.lineAA = false;} 

            Vector2f center = physicsBody_.position;
            //base color of the rays
            const baseColor      = rgba!"E0E0FF80";
            const lightColor     = rgba!"E0E0FF04";
            const lightColorEnd = rgba!"E0E0FF00";

            const real rayLength = 600.0;

            auto direction = Vector2f(1.0f, 1.0f);
            if(!lightExpired)
            {
                //draw the light
                direction.angle = light_ + lightWidth_;
                driver.drawLine(center, center + direction * rayLength, 
                                 lightColor, lightColorEnd);
                direction.angle = light_ - lightWidth_;
                driver.drawLine(center, center + direction * rayLength, 
                                 lightColor, lightColorEnd);
            }

            driver.lineWidth = 2;
            scope(exit){driver.lineWidth = 1;} 
            
            //draw the rays in range of the light
            foreach(d; directions_)
            {
                const real distance = abs(d - light_);
                if(distance > lightWidth_){continue;}

                Color color = baseColor;
                color.a *= 1.0 - distance / lightWidth_;

                direction.angle = d;
                driver.drawLine(center, center + direction * rayLength, color, color);
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
        void generateDirections(real spread)
        {
            //base direction of all generated directions
            const real base = uniform(0.0, 1.0);
            //adjust spread according to how much of the circle is "allowed" 
            //directions - i.e. nearly horizontal directions are not allowed
            spread *= 1 - (2 * minAngle_) / PI; 

            for(uint d = 0; d < directionCount_; d++)
            {
                real direction = uniform(base - spread, base + spread);
                //integer part of the direction is stripped so that
                //it's in the 0.0 - 1.0 range
                direction = std.math.abs(direction - cast(int)direction);

                //"allowed" part of the circle in radians
                const real range = 2.0 * PI - 4.0 * minAngle_;
                                                   
                //0.0 - 0.5 gets mapped to 0.5pi+minAngle - 1.5pi-minAngle range
                if(direction < 0.5){direction = PI * 0.5 + minAngle_ + direction * range;}
                //0.5 - 1.0 gets mapped to 1.5pi+minAngle - 0.5pi-minAngle range
                else{direction = PI * 1.5 + minAngle_ + (direction - 0.5) * range;}

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
 *          ballSpeed = Speed of the spawned ball.
 *                       Default; 200
 */
final class BallSpawnerFactory : ActorFactory!(BallSpawner)
{
    mixin(generateFactory("real $ time       $ 5.0",
                           "real $ spread     $ 0.25",
                           "real $ ballSpeed $ 200"));
    private:
        ///Start time of the spawners' timer.
        real startTime_;
    public:
        /**
         * Construct a BallSpawnerFactory.
         *
         * Params: startTime = Start time of the produced spawner.
         *                      The time when the ball will be spawned
         *                      is relative to this time.
         */
        this(in real startTime){startTime_ = startTime;}

        override BallSpawner produce(SceneManager manager)
        {                          
            auto physicsBody = new PhysicsBody(null, position_, velocity_, real.infinity);
            return newActor(manager, 
                             new BallSpawner(physicsBody, Timer(time_, startTime_),
                                             spread_, ballSpeed_));
        }
}
