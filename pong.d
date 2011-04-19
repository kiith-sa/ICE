
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

/**
 * $(BIG Pong engine 0.1.0 API documentation)
 *
 * Introduction:
 * 
 * This is the complete API documentation for the Pong engine. It describes
 * all classes, structs, interfaces, functions, etc. .
 * This API documentation is intended to serve developers who want to
 * improve the Pong engine, as well as those who want to modify it for
 * their own needs.
 */
module pong;


import std.stdio;
import std.string;
import std.random;
import std.math;

import std.c.stdlib;     

import math.math;
import math.vector2;
import math.rectangle;
import video.videodriver;
import video.sdlglvideodriver;
import video.videodrivercontainer;
import scene.actor;
import scene.scenemanager;
import scene.actorcontainer;
import scene.particleemitter;
import scene.lineemitter;
import scene.linetrail;
import physics.physicsengine;
import physics.physicsbody;
import physics.contact;
import spatial.spatialmanager;
import spatial.gridspatialmanager;
import spatial.volumeaabbox;
import spatial.volumecircle;
import gui.guielement;
import gui.guimenu;
import gui.guibutton;
import gui.guistatictext;
import platform.platform;
import platform.sdlplatform;
import monitor.monitor;
import memory.memorymonitorable;
import time.time;
import time.timer;
import time.eventcounter;
import file.fileio;
import formats.image;
import util.signal;
import util.weaksingleton;
import util.factory;
import color;
import image;
import formats.cli;


/**
 * A rectangular wall in the game area.
 *
 * Signal:
 *     public mixin Signal!(BallBody) ball_hit
 *
 *     Emitted when a ball hits the wall. Will emit const BallBody after D2 move. 
 */
class Wall : Actor
{
    protected:
        ///Default color of the wall.
        Color default_color_ = Color(0, 0, 0, 0);
        ///Current color of the wall.
        Color color_;
        ///Default color of the wall border.
        Color default_color_border_ = Color(224, 224, 255, 224);
        ///Current color of the wall border.                 
        Color color_border_;
        ///Area taken up by the wall.
        Rectanglef box_;

    public:
        ///Emitted when a ball hits the wall. Will emit const BallBody after D2 move.
        mixin Signal!(BallBody) ball_hit;

        ///Set wall velocity.
        void velocity(Vector2f v){physics_body_.velocity = v;}

        override void die()
        {
            ball_hit.disconnect_all();
            super.die();
        }

    protected:
        /**
         * Construct a wall with specified parameters.
         *
         * Params:  container    = Actor container to manage the wall.
         *          physics_body = Physics body of the wall.
         *          box          = Rectangle used for graphical representation of the wall.
         */
        this(ActorContainer container, PhysicsBody physics_body, ref Rectanglef box)
        {
            super(container, physics_body);
            box_ = box;
            color_ = default_color_;
            color_border_ = default_color_border_;
        }

        override void draw(VideoDriver driver)
        {
            Vector2f position = physics_body_.position;
            driver.draw_rectangle(position + box_.min, position + box_.max, color_border_);
            driver.draw_filled_rectangle(position + box_.min, position + box_.max, color_);
        }

        override void update(real time_step, real game_time)
        {
            foreach(collider; physics_body_.colliders)
            {
                if(collider.classinfo is BallBody.classinfo)
                {
                    ball_hit.emit(cast(BallBody)collider);
                }
            }
        }
}             

/**
 * Base class for factories constructing Wall and derived classes.
 *
 * Params:  box_min = Minimum extent of the wall relative to its position.
 *                    Default; Vector2f(0.0f, 0.0f)
 *          box_max = Maximum extent of the wall relative to its position.
 *                    Default; Vector2f(1.0f, 1.0f)
 */
abstract class WallFactoryBase(T) : ActorFactory!(T)
{
    mixin(generate_factory("Vector2f $ box_min $ Vector2f(0.0f, 0.0f)", 
                           "Vector2f $ box_max $ Vector2f(1.0f, 1.0f)"));
    private:
        ///Get a collision aabbox based on factory parameters. Used in produce().
        VolumeAABBox bbox(){return new VolumeAABBox(box_min_, box_max_ - box_min_);}
        ///Get a bounds rectangle based on factory parameters. Used in produce().
        Rectanglef rectangle(){return Rectanglef(box_min_, box_max_);}
}

///Factory used to construct walls.
class WallFactory : WallFactoryBase!(Wall)
{
    public override Wall produce(ActorContainer container)
    {
        auto physics_body = new PhysicsBody(bbox, position_, velocity_, real.infinity);
        return new Wall(container, physics_body, rectangle);
    }
}


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
        real max_xy_ratio_ = 1.0;

        ///Limits of paddle body movement in world space.
        Rectanglef limits_;

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
        Vector2f reflected_ball_velocity(BallBody ball)
        {
            //Translate the aabbox to world space
            Rectanglef box = aabbox + position_;

            Vector2f closest = box.clamp(ball.position);

            Vector2f contact_direction = closest - ball.position;

            contact_direction.normalize_safe();

            Vector2f contact_point = ball.position + ball.radius * contact_direction;

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
                //rand() % 2 means random bool 
                y_mod *= std.random.rand() % 2 ? -1.0 : 1.0;
                velocity.y += y_mod;
            }

            //keep the same velocity
            velocity.normalize_safe();
            return velocity * ball.velocity.length;
        }

        override void update(real time_step, SpatialManager!(PhysicsBody) manager)
        {
            //keep the paddle within the limits
            Rectanglef box = aabbox;
            Rectanglef position_limits = Rectanglef(limits_.min - box.min,
                                                    limits_.max - box.max);
            position = position_limits.clamp(position);

            super.update(time_step, manager);
        }

        ///Get movement limits of this paddle body.
        final Rectanglef limits(){return limits_;}

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
        this(VolumeAABBox aabbox,Vector2f position, Vector2f velocity, real mass, 
             ref Rectanglef limits)
        {
            super(aabbox, position, velocity, mass);
            limits_ = limits;
        }

    private:
        ///Return rectangle representing bounding box of this body in world space.
        final Rectanglef aabbox()
        in
        {
            //checking here because invariant can't call public function members
            assert(volume.classinfo == VolumeAABBox.classinfo,
                   "Collision volume of a paddle must be an axis aligned bounding box");
        }
        body{return(cast(VolumeAABBox)volume).bounding_box;}
}

///A paddle controlled by a player or AI.
class Paddle : Wall
{
    invariant
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
        Color energy_color_ = Color(224, 224, 255, 192);

    public:
        ///Get movement limits of this paddle.
        Rectanglef limits(){return (cast(PaddleBody)physics_body_).limits;}

        ///Control the paddle to move right (used by player or AI).
        void move_right(){physics_body_.velocity = speed_ * Vector2f(1.0, 0.0);}

        ///Control the paddle to move left (used by player or AI).
        void move_left(){physics_body_.velocity = speed_ * Vector2f(-1.0, 0.0);}

        ///Control the paddle to stop (used by player or AI).
        void stop(){physics_body_.velocity = Vector2f(0.0, 0.0);}

        ///Destroy the paddle.
        override void die()
        {
            emitter_.life_time = 1.0;
            emitter_.emit_frequency = 0.0;
            emitter_.detach();
            super.die();
        }

    protected:
        /**
         * Construct a paddle with specified parameters.
         *
         * Params:  container    = Actor container to manage this paddle.
         *          physics_body = Physics body of the paddle.
         *          box          = Rectangle used for graphics representation of the paddle.
         *          speed        = Speed of paddle movement.
         *          emitter      = Particle emitter of the paddle.
         */
        this(ActorContainer container, PaddleBody physics_body, ref Rectanglef box,
             real speed, ParticleEmitter emitter)
        {
            default_color_ = Color(0, 0, 255, 32);
            super(container, physics_body, box);
            speed_ = default_speed_ = speed;
            emitter_ = emitter;
            default_emit_frequency_ = emitter_.emit_frequency;
            emitter.attach(this);
        }

        override void update(real time_step, real game_time)
        {
            energy_ = max(0.0L, energy_ - time_step * dissipate_rate_);
            foreach(collider; physics_body_.colliders)
            {
                if(!equals(collider.inverse_mass, 0.0L))
                {
                    energy_ += collider.velocity.length / collider.inverse_mass;
                }
            }

            real energy_ratio = energy_ * energy_mult_;

            color_ = energy_color_.interpolated(default_color_, min(energy_ratio, 1.0L));
            speed_ = default_speed_ * (1.0 + 1.5 * energy_ratio);
            emitter_.emit_frequency = default_emit_frequency_ * (1.0 + 10.0 * energy_ratio);

            super.update(time_step, game_time);
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
                           "real $ speed $ 135.0"));

    public override Paddle produce(ActorContainer container)
    {
        auto limits = Rectanglef(limits_min_, limits_max_);
        auto physics_body = new PaddleBody(bbox, position_, velocity_, real.infinity, limits);

        //construct particle system of the paddle
        LineEmitter emitter;
        with(new LineEmitterFactory)
        {
            particle_life = 3.0;
            emit_frequency = 30;
            emit_velocity = Vector2f(speed_ * 0.15, 0.0);
            angle_variation = 2 * PI;
            line_length = 2.0;
            line_width = 1;
            start_color = Color(255, 255, 255, 64);
            end_color = Color(64, 64, 255, 0);
            emitter = produce(container);
        }

        return new Paddle(container, physics_body, rectangle, speed_, emitter);
    }
}


/**
 * Physics body of a ball. 
 *
 * Overrides default collision response to get Arkanoid style ball behavior.
 */
class BallBody : PhysicsBody
{
    invariant{assert(radius_ > 1.0f, "Ball radius must be at least 1.0");}
    private:
        ///Radius of the ball body.
        float radius_;

    public:
        override void collision_response(ref Contact contact)
        {
            PhysicsBody other = this is contact.body_a ? contact.body_b : contact.body_a;
            //handle paddle collisions separately
            if(other.classinfo == PaddleBody.classinfo)
            {
                PaddleBody paddle = cast(PaddleBody)other;
                //let paddle reflect this ball
                velocity_ = paddle.reflected_ball_velocity(this);
                //prevent any further resolving (since we're not doing precise physics)
                contact.resolved = true;
                return;
            }
            super.collision_response(contact);
        }

        ///Get radius of this ball body.
        float radius(){return radius_;}

    protected:
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
        this(VolumeCircle circle, Vector2f position, Vector2f velocity, real mass, float radius)
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
            float speed = velocity_.length_safe;
            super.collision_response(contact);
            velocity_.normalize_safe();
            velocity_ *= speed;

            //prevent any further resolving (since we're not doing precise physics)
            contact.resolved = true;
        }

    protected:
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
        this(VolumeCircle circle, Vector2f position, Vector2f velocity, real mass, float radius)
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
        float radius(){return (cast(BallBody)physics_body_).radius;}

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
             ParticleEmitter emitter, float particle_speed, bool draw_ball)
        {
            super(container, physics_body);
            trail_ = trail;
            trail.attach(this);
            emitter_ = emitter;
            emitter.attach(this);
            particle_speed_ = particle_speed;
            draw_ball_ = draw_ball;
        }

        override void update(real time_step, real game_time)
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
            Vector2f position = physics_body_.position;
            driver.line_aa = true;
            driver.line_width = 3;
            driver.draw_circle(position, radius - 2, Color(240, 240, 255), 4);
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
                start_color = Color(240, 240, 255);
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
        final VolumeCircle circle(){return new VolumeCircle(Vector2f(0.0f, 0.0f), radius_);}

        ///Construct a ball body with factory parameters.
        BallBody ball_body(){return new BallBody(circle, position_, velocity_, 100.0, radius_);}

        ///Adjust particle effect factories. Used by derived classes.
        void adjust_factories(){};

        ///Determine if the produced ball should draw itself, instead of just particle systems.
        bool draw_ball(){return true;}
}             

///Factory used to produce dummy balls.
class DummyBallFactory : BallFactory
{
    protected:
        override BallBody ball_body()
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

///Player controlling a paddle.
abstract class Player
{
    protected:
        ///Player name.
        string name_;
        ///Current player score.
        uint score_ = 0;

        ///Paddle controlled by this player.
        Paddle paddle_;

    public:
        ///Increase score of this player.
        void score(BallBody ball_body){score_++;}

        ///Get score of this player.
        int score(){return score_;}

        ///Get name of this player.
        string name(){return name_;}

        /**
         * Update player state.
         * 
         * Params:  game = Reference to the game.
         */
        void update(Game game){}

        ///Destroy this player
        void die(){delete this;}

    protected:
        /**
         * Construct a player.
         * 
         * Params:  name   = Player name.
         *          paddle = Paddle controlled by the player.
         */
        this(string name, Paddle paddle)
        {
            name_ = name;
            paddle_ = paddle;
        }
}

///AI player.
final class AIPlayer : Player
{
    protected:
        ///Timer determining when to update the AI.
        Timer update_timer_;
        ///Position of the ball during last AI update.
        Vector2f ball_last_;

    public:
        /**
         * Construct an AI player.
         * 
         * Params:  name          = Player name.
         *          paddle        = Paddle controlled by the player.
         *          update_period = Time period of AI updates.
         */
        this(string name, Paddle paddle, real update_period)
        {
            super(name, paddle);
            update_timer_ = Timer(update_period);
        }

        override void update(Game game)
        {
            if(update_timer_.expired())
            {
                update_timer_.reset();

                //currently only support zero or one ball
                Ball[] balls = game.balls;
                assert(balls.length <= 1, "AI supports only zero or one ball at the moment");

                if(balls.length == 0)
                {
                    //Setting last ball position to center of paddle limits prevents
                    //any weird AI movements when ball first appears.
                    ball_last_ = paddle_.limits.center;
                    move_to_center();
                    return;
                }
                Ball ball = balls[0];

                float distance = paddle_.limits.distance(ball.position);
                float distance_last = paddle_.limits.distance(ball_last_);
                
                //If the ball is closing to paddle movement area
                if(distance_last >= distance){ball_closing(ball);}       
                //If the ball is moving away from paddle movement area
                else{move_to_center();}

                ball_last_ = ball.position;
            }
        }

    protected:
        ///React to the ball closing in.
        void ball_closing(Ball ball)
        {
            //If paddle x position is roughly equal to ball, no need to move
            if(equals(paddle_.position.x, ball.position.x, 16.0f)){paddle_.stop();}
            else if(paddle_.position.x < ball.position.x){paddle_.move_right();}
            else{paddle_.move_left();}
        }

        ///Move the paddle to center.
        void move_to_center()
        {
            Vector2f center = paddle_.limits.center;
            //If paddle x position is roughly in the center, no need to move
            if(equals(paddle_.position.x, center.x, 16.0f)){paddle_.stop();}
            else if(paddle_.position.x < center.x){paddle_.move_right();}
            else{paddle_.move_left();}
        }
}

///Human player controlling the game through user input.
final class HumanPlayer : Player
{
    private:
        ///Platform for user input.
        Platform platform_;

    public:
        /**
         * Construct a human player controlling specified paddle.
         *
         * Params:  platform = Platform for user input.
         *          name     = Name of the player.
         *          paddle   = Paddle controlled by the player.
         */
        this(Platform platform, string name, Paddle paddle)
        {
            super(name, paddle);
            platform_ = platform;
            platform_.key.connect(&key_handler);
        }
        
        ///Destroy this HumanPlayer.
        ~this(){platform_.key.disconnect(&key_handler);}

        /**
         * Process keyboard input.
         *
         * Params:  state   = State of the key.
         *          key     = Keyboard key.
         *          unicode = Unicode value of the key.
         */
        void key_handler(KeyState state, Key key, dchar unicode)
        {
            if(state == KeyState.Pressed)
            {
                if(key == Key.Right)
                {
                    paddle_.move_right();
                    return;
                }
                if(key == Key.Left)
                {
                    paddle_.move_left();
                    return;
                }
            }
            else if(state == KeyState.Released)
            {
                if(key == Key.Right)
                {
                    if(platform_.is_key_pressed(Key.Left))
                    {
                        paddle_.move_left();
                        return;
                    }
                    paddle_.stop();
                    return;
                }
                else if(key == Key.Left)
                {
                    if(platform_.is_key_pressed(Key.Right))
                    {
                        paddle_.move_right();
                        return;
                    }
                    paddle_.stop();
                    return;
                }
            }
        }
}

/**
 * Displays score screen at the end of game.
 *
 * Signal:
 *     public mixin Signal!() expired
 *
 *     Emitted when the score screen expires. 
 */
class ScoreScreen
{
    private:
        alias std.string.toString to_string;  
        
        ///Score screen ends when this timer expires.
        Timer timer_;

        ///Parent of the score screen container.
        GUIElement parent_;

        ///Container of all score screen GUI elements.
        GUIElement container_;
        ///Text showing the winner.
        GUIStaticText winner_text_;
        ///Text showing player names.
        GUIStaticText names_text_;
        ///Text showing player scores.
        GUIStaticText scores_text_;
        ///Text showing time the game took.
        GUIStaticText time_text_;

    public:
        ///Emitted when the score screen expires.
        mixin Signal!() expired;

        /**
         * Construct a score screen.
         *
         * Params: parent    = GUI element to attach the score screen to.
         *         player_1  = First player of the game.
         *         player_2  = Second player of the game.
         *         time      = Time the game took in seconds.
         */
        this(GUIElement parent, Player player_1, Player player_2, real time)
        in
        {
            assert(player_1.score != player_2.score, 
                   "Score screen shown but neither of the players is victorious");
        }
        body
        {
            with(new GUIElementFactory)
            {
                x = "p_right / 2 - 192";
                y = "p_bottom / 2 - 128";
                width = "384";
                height = "256";
                container_ = produce();
            }

            parent_ = parent;
            parent_.add_child(container_);

            string winner = player_1.score > player_2.score ? 
                            player_1.name : player_2.name;

            with(new GUIStaticTextFactory)
            {
                x = "p_left + 48";
                y = "p_top + 96";
                width = "128";
                height = "16";
                font_size = 14;
                text_color = Color(224, 224, 255, 160);
                font = "orbitron-light.ttf";
                text = "Time: " ~ time_string(time);
                //text showing time the game took
                time_text_ = produce();

                x = "p_left";
                y = "p_top + 16";
                width = "p_width";
                height = "32";
                font_size = 24;
                text_color = Color(192, 192, 255, 128);
                align_x = AlignX.Center;
                font = "orbitron-bold.ttf";
                text = "WINNER: " ~ winner;
                //text showing the winner of the game
                winner_text_ = produce();
            }

            container_.add_child(time_text_);
            container_.add_child(winner_text_);

            init_scores(player_1, player_2);

            timer_ = Timer(8);
        }

        ///Update the score screen (and check for expiration).
        void update()
        {
            if(timer_.expired){expired.emit();}
        }

        ///Destroy the score screen.
        void die()
        {
            container_.die();
            expired.disconnect_all();
        }
        
    private:
        ///Initialize players/scores list.
        void init_scores(Player player_1, Player player_2)
        {
            with(new GUIStaticTextFactory)
            {
                x = "p_left + 48";
                y = "p_top + 48";
                width = "128";
                height = "32";
                font_size = 14;
                text_color = Color(160, 160, 255, 128);
                font = "orbitron-light.ttf";
                text = player_1.name ~ "\n" ~ player_2.name;
                names_text_ = produce();

                x = "p_right - 128";
                width = "64";
                text_color = Color(224, 224, 255, 160);
                font = "orbitron-bold.ttf";
                text = to_string(player_1.score) ~ "\n" ~ to_string(player_2.score);
                align_x = AlignX.Right;
                scores_text_ = produce();
            }

            container_.add_child(names_text_);
            container_.add_child(scores_text_);
        }
}

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
    invariant
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
         * Construct a BallSpawner/
         * 
         * Params:    container    = Actor container to manage this spawner.
         *            physics_body = Physics body of the spawner.
         *            timer        = Ball will be spawned when this timer (game time) expires.
         *                           70% of the time will be taken by the rays effect.
         *            spread       = "Randomness" of the spawn directions.
         *                           Zero will result in only one definite direction,
         *                           1 will result in completely random direction
         *                           (except for horizontal directions that are 
         *                           disallowed to prevent ball from getting stuck)
         *            ball_speed   = Speed to spawn the ball at.
         */
        this(ActorContainer container, PhysicsBody physics_body, Timer timer, 
             real spread, real ball_speed)
        in{assert(spread >= 0.0, "Negative ball spawning spread");}
        body
        {                
            super(container, physics_body);

            ball_speed_ = ball_speed;
            timer_ = timer;
            //leave a third of time without the rays effect to give time to the player
            light_speed_ = (2 * PI) / (timer.delay * 0.70);

            generate_directions(spread);
        }

        override void die()
        {
            spawn_ball.disconnect_all();
            super.die();
        }

        override void update(real time_step, real game_time)
        {
            if(timer_.expired(game_time))
            {
                //emit the ball in a random, previously generated direction
                Vector2f direction = Vector2f(1.0f, 1.0f);
                direction.angle = directions_[std.random.rand % directions_.length];
                spawn_ball.emit(direction, ball_speed_);
                die();
                return;
            }
            if(!light_expired && light_ >= (2 * PI)){light_expired = true;}

            //update light direction
            light_ += light_speed_ * time_step;
        }

        override void draw(VideoDriver driver)
        {
            driver.line_aa = true;
            scope(exit){driver.line_aa = false;} 

            Vector2f center = physics_body_.position;
            //base color of the rays
            Color base_color = Color(224, 224, 255, 128);
            Color light_color = Color(224, 224, 255, 4);
            Color light_color_end = Color(224, 224, 255, 0);

            real ray_length = 600.0;

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
                real distance = std.math.abs(d - light_);
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
            real base = math.math.random(0.0, 1.0);
            //adjust spread according to how much of the circle is "allowed" 
            //directions - i.e. nearly horizontal directions are not allowed
            spread *= 1 - (2 * min_angle_) / PI; 

            for(uint d = 0; d < direction_count_; d++)
            {
                real direction = math.math.random(base - spread, base + spread);
                //integer part of the direction is stripped so that
                //it's in the 0.0 - 1.0 range
                direction = std.math.abs(direction - cast(int)direction);

                //"allowed" part of the circle in radians
                real range = 2.0 * PI - 4.0 * min_angle_;
                                                   
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
        this(real start_time){start_time_ = start_time;}

        override BallSpawner produce(ActorContainer container)
        {                          
            auto physics_body = new PhysicsBody(null, position_, velocity_, real.infinity);
            return new BallSpawner(container, physics_body, Timer(time_, start_time_),
                                   spread_, ball_speed_);
        }
}


///In game HUD.
class HUD
{
    private:
        alias std.string.toString to_string;  
     
        ///Parent of all HUD elements.
        GUIElement parent_;

        ///Displays player 1 score.
        GUIStaticText score_text_1_;
        ///Displays player 2 score.
        GUIStaticText score_text_2_;
        ///Displays time left in game.
        GUIStaticText time_text_;

        ///Maximum time the game can take in game time.
        real time_limit_;

    public:
        /**
         * Constructs HUD with specified parameters.
         *
         * Params:  parent     = Parent GUI element for all HUD elements.
         *          time_limit = Maximum time the game will take.
         */
        this(GUIElement parent, real time_limit)
        {
            parent_ = parent;
            time_limit_ = time_limit;

            with(new GUIStaticTextFactory)
            {
                x = "p_left + 8";
                y = "p_top + 8";
                width = "96";
                height = "16";
                font_size = 16;
                font = "orbitron-light.ttf";
                align_x = AlignX.Right;
                score_text_1_ = produce();

                y = "p_bottom - 24";
                score_text_2_ = produce();

                x = "p_right - 112";
                font = "orbitron-bold.ttf";
                time_text_ = produce();
            }

            parent_.add_child(score_text_1_);
            parent_.add_child(score_text_2_);
            parent_.add_child(time_text_);
        }

        /**
         * Update the HUD.
         *
         * Params:    time_left = Time left until time limit runs out.
         *            player_1  = First player of the game.
         *            player_2  = Second player of the game. 
         */
        void update(real time_left, Player player_1, Player player_2)
        {
            //update time display
            time_left = max(time_left, 0.0L);
            string time_str = time_string(time_left);
            static Color color_start = Color(160, 160, 255, 160);
            static Color color_end = Color.red;
            //only update if the text has changed
            if(time_str != time_text_.text)
            {
                time_text_.text = time_str != "0:0" ? time_str : time_str ~ " !";

                real t = max(time_left / time_limit_, 1.0L);
                time_text_.text_color = color_start.interpolated(color_end, t);
            }

            //update score displays
            string score_str_1 = player_1.name ~ ": " ~ to_string(player_1.score);
            string score_str_2 = player_2.name ~ ": " ~ to_string(player_2.score);
            //only update if the text has changed
            if(score_text_1_.text != score_str_1){score_text_1_.text = score_str_1;}
            if(score_text_2_.text != score_str_2){score_text_2_.text = score_str_2;}
        }

        ///Hide the HUD.
        void hide()
        {
            score_text_1_.hide();
            score_text_2_.hide();
            time_text_.hide();
        }

        ///Show the HUD.
        void show()
        {
            score_text_1_.show();
            score_text_2_.show();
            time_text_.show();
        }

        ///Destroy the HUD.
        void die()
        {
            score_text_1_.die();
            score_text_1_ = null;

            score_text_2_.die();
            score_text_2_ = null;

            time_text_.die();
            time_text_ = null;
        }
}

/**
 * Class holding all GUI used by Game (HUD, etc.).
 *
 * Signal:
 *     public mixin Signal!() score_expired
 *
 *     Emitted when the score screen expires. 
 */
class GameGUI
{
    private:
        ///Parent of all game GUI elements.
        GUIElement parent_;
        ///HUD.
        HUD hud_;
        ///Score screen shown at the end of game.
        ScoreScreen score_screen_;

    public:
        ///Emitted when the score screen expires.
        mixin Signal!() score_expired;

        /**
         * Construct a GameGUI with specified parameters.
         *
         * Params:  parent     = GUI element to attach all game GUI elements to.
         *          time_limit = Time limit of the game.
         */
        this(GUIElement parent, real time_limit)
        {
            parent_ = parent;
            hud_ = new HUD(parent, time_limit);
            hud_.hide();
        }

        ///Show the HUD.
        void show_hud(){hud_.show();}

        /**
         * Show score screen.
         *
         * Should only be called at the end of game.
         * Hides the HUD. When the score screen expires,
         * score_expired is emitted.
         *
         * Params:  time_total = Total time the game took, in game time.
         *          player_1   = First player of the game.
         *          player_2   = Second player of the game.
         */
        void show_scores(real time_total, Player player_1, Player player_2)
        in{assert(score_screen_ is null, "Can't show score screen twice");}
        body
        {
            hud_.hide();
            score_screen_ = new ScoreScreen(parent_, player_1, player_2, time_total);
            score_screen_.expired.connect(&score_expired.emit);
        }

        /**
         * Update the game GUI.
         * 
         * Params:  time_left = Time left in the game, in game time.
         *          player_1  = First player of the game.
         *          player_2  = Second player of the game.
         */
        void update(real time_left, Player player_1, Player player_2)
        {
            hud_.update(time_left, player_1, player_2);
            if(score_screen_ !is null){score_screen_.update();}
        }

        ///Destroy the game GUI.
        void die()
        {
            hud_.die();
            hud_ = null;
            if(score_screen_ !is null)
            {
                score_screen_.die();
                score_screen_ = null;
            }
            parent_ = null;
            score_expired.disconnect_all();
        }
}

class Game
{
    mixin WeakSingleton;
    private:
        ///Platform used for input.
        Platform platform_;
        ///Scene manager.
        SceneManager scene_manager_;

        ///Game area in world space.
        static Rectanglef game_area_ = Rectanglef(0.0f, 0.0f, 800.0f, 600.0f);
        
        ///Current game ball.
        Ball ball_;
        ///Default ball radius.
        real ball_radius_ = 6.0;
        ///Default ball speed.
        real ball_speed_ = 185.0;

        ///BallSpawner spawn time.
        real spawn_time_ = 4.0;
        ///BallSpawner spawn spread.
        real spawn_spread_ = 0.28;

        ///Dummy balls.
        Ball[] dummies_;
        ///Number of dummy balls.
        uint dummy_count_ = 20;

        ///Right wall of the game area.
        Wall wall_right_;
        ///Left wall of the game area.
        Wall wall_left_; 
        ///Top goal of the game area.
        Wall goal_up_; 
        ///Bottom goal of the game area.
        Wall goal_down_; 

        ///Player 1 paddle.
        Paddle paddle_1_;
        ///Player 2 paddle.
        Paddle paddle_2_;
        ///Player 1.
        Player player_1_;
        ///Player 2.
        Player player_2_;

        ///Continue running?
        bool continue_;

        ///Score limit.
        uint score_limit_;
        ///Time limit in game time.
        real time_limit_;
        ///Timer determining when the game ends.
        Timer game_timer_;

        ///GUI of the game, e.g. HUD, score screen.
        GameGUI gui_;

        ///True while the players are (still) playing the game.
        bool playing_;
        ///Has the game started?
        bool started_;

        ///Timer determining when to end the intro and start the game.
        Timer intro_timer_;

    public:
        /**
         * Update the game.
         *
         * Returns: True if the game should continue to run, false otherwise.
         */
        bool run()
        {
            real time = scene_manager_.game_time;
            if(playing_)
            {
                //update player state
                player_1_.update(this);
                player_2_.update(this);

                //check for victory conditions
                if(player_1_.score >= score_limit_ || player_2_.score >= score_limit_)
                {
                    game_won();
                }
                if(game_timer_.expired(time))
                {
                    if(player_1_.score != player_2_.score){game_won();}
                }
            }

            if(continue_)
            {
                real time_left = time_limit_ - game_timer_.age(time);
                gui_.update(time_left, player_1_, player_2_);
            }

            if(!started_ && intro_timer_.expired(time)){start_game(time);}

            scene_manager_.update();

            return continue_;
        }

        ///Start game intro.
        void intro()
        {
            intro_timer_ = Timer(2.5, scene_manager_.game_time);
            playing_ = started_ = false;
            continue_ = true;

            //construct walls and goals
            with(new WallFactory)
            {
                box_max = Vector2f(32.0f, 536.0f);
                //walls slowly move into place when game starts
                velocity = Vector2f(73.6f, 0.0f);
                position = Vector2f(-64.0f, 32.0f);
                wall_left_ = produce(scene_manager_);

                velocity = Vector2f(-73.6f, 0.0f);
                position = Vector2f(832.0, 32.0f);
                wall_right_ = produce(scene_manager_);

                box_max = Vector2f(560.0f, 28.0f);
                velocity = Vector2f(320.0f, 0.0f);
                position = Vector2f(-680.0f, 4.0f);
                goal_up_ = produce(scene_manager_);

                velocity = Vector2f(-320.0f, 0.0f);
                position = Vector2f(920.0f, 568.0f);
                goal_down_ = produce(scene_manager_);
            }

            //construct paddles.
            float limits_min_x = 152.0f + 2.0 * ball_radius_;
            float limits_max_x = 648.0f - 2.0 * ball_radius_;
            with(new PaddleFactory)
            {
                box_min = Vector2f(-32.0f, -4.0f);
                box_max = Vector2f(32.0f, 4.0f);
                position = Vector2f(400.0f, 56.0f);
                limits_min = Vector2f(limits_min_x, 36.0f);
                limits_max = Vector2f(limits_max_x, 76.0f);
                speed = 135.0;
                paddle_1_ = produce(scene_manager_);

                position = Vector2f(400.0f, 544.0f);
                limits_min = Vector2f(limits_min_x, 524.0f);
                limits_max = Vector2f(limits_max_x, 564.0f);
                paddle_2_ = produce(scene_manager_);
            }
            
            player_1_ = new AIPlayer("AI", paddle_1_, 0.15);
            player_2_ = new HumanPlayer(platform_, "Human", paddle_2_);

            platform_.key.connect(&key_handler);
        }

        ///Returns an array of balls currently used in the game.
        Ball[] balls()
        {
            Ball[] output;
            if(ball_ !is null){output ~= ball_;}
            return output;
        }

        /**
         * Draw the game.
         *
         * Params:  driver = VideoDriver to draw with.
         */
        void draw(VideoDriver driver){scene_manager_.draw(driver);}

        ///Get game area.
        static Rectanglef game_area(){return game_area_;}

        ///End the game, regardless of whether it has been won or not.
        void end_game()
        {
            if(started_){scene_manager_.time_speed = 1.0;}

            scene_manager_.clear();
            player_1_.die();
            player_2_.die();

            playing_ = continue_ = false;

            platform_.key.disconnect(&key_handler);
        }

    private:
        /**
         * Construct a Game.
         *
         * Params:  platform      = Platform used for input.
         *          scene_manager = SceneManager managing actors.
         *          gui           = Game GUI.
         *          score_limit   = Score limit of the game.
         *          time_limit    = Time limit of the game in game time.
         */
        this(Platform platform, SceneManager scene_manager, GameGUI gui, 
             uint score_limit, real time_limit)
        {
            singleton_ctor();
            gui_ = gui;
            platform_ = platform;
            scene_manager_ = scene_manager;
            score_limit_ = score_limit;
            time_limit_ = time_limit;
        }

        ///Destroy the Game.
        void die(){singleton_dtor();}

        ///Start the game, at specified game time.
        void start_game(real start_time)
        {
            //spawn dummy balls
            with(new DummyBallFactory)
            {
                radius = 8.0;

                for(uint dummy = 0; dummy < dummy_count_; dummy++)
                {
                    position = random_position!(float)(game_area_.center, 24.0f);
                    velocity = 2.5 * ball_speed_ * random_direction!(float)(); 
                    dummies_ ~= produce(scene_manager_);
                }
            }

            //should be set from options and INI when that is implemented.
            started_ = playing_ = true;

            wall_left_.velocity = Vector2f(0.0, 0.0);
            wall_right_.velocity = Vector2f(0.0, 0.0);
            goal_up_.velocity = Vector2f(0.0, 0.0);
            goal_down_.velocity = Vector2f(0.0, 0.0);
            
            with(new BallSpawnerFactory(start_time))
            {
                time = spawn_time_;
                spread = spawn_spread_;
                ball_speed = ball_speed_;
                position = game_area_.center;
                auto spawner = produce(scene_manager_);
                spawner.spawn_ball.connect(&spawn_ball);
            }

            goal_up_.ball_hit.connect(&player_2_.score);
            goal_down_.ball_hit.connect(&player_1_.score);
            goal_up_.ball_hit.connect(&destroy_ball);
            goal_down_.ball_hit.connect(&destroy_ball);

            gui_.show_hud();

            game_timer_ = Timer(time_limit_, start_time);
        }

        ///Destroy ball with specified ball body.
        void destroy_ball(BallBody ball_body)
        in
        {
            assert(ball_ !is null && ball_body is ball_.physics_body,
                   "Only one ball is supported right now yet "
                   "a ball body not belonging to this ball is used");
        }
        body
        {
            ball_.die();
            ball_ = null;

            with(new BallSpawnerFactory(scene_manager_.game_time))
            {
                time = spawn_time_;
                spread = spawn_spread_;
                ball_speed = ball_speed_;
                position = game_area_.center;
                auto spawner = produce(scene_manager_);
                spawner.spawn_ball.connect(&spawn_ball);
            }
        }

        /**
         * Spawn a ball.
         *
         * Params:  direction = Direction to spawn the ball in.
         *          speed     = Speed to spawn the ball at.
         */
        void spawn_ball(Vector2f direction, real speed)
        {
            with(new BallFactory)
            {
                position = game_area_.center;
                velocity = direction * speed;
                radius = ball_radius_;
                ball_ = produce(scene_manager_);
            }
        }

        ///Called when one of the players wins the game.
        void game_won()
        {
            //show the score screen and end the game after it expires
            gui_.show_scores(game_timer_.age(scene_manager_.game_time), player_1_, player_2_);
            gui_.score_expired.connect(&end_game);
            scene_manager_.time_speed = 0.0;

            playing_ = false;
        }

        /**
         * Process keyboard input.
         *
         * Params:  state   = State of the key.
         *          key     = Keyboard key.
         *          unicode = Unicode value of the key.
         */
        void key_handler(KeyState state, Key key, dchar unicode)
        {
            if(state == KeyState.Pressed)
            {
                switch(key)
                {
                    case Key.Escape:
                        end_game();
                        break;
                    case Key.K_P: //pause
                        if(equals(scene_manager_.time_speed, cast(real)0.0))
                        {
                            scene_manager_.time_speed = 1.0;
                        }
                        else{scene_manager_.time_speed = 0.0;}
                        break;
                    default:
                        break;
                }
            }
        }
}

///Container managing dependencies and construction of Game.
class GameContainer
{
    private:
        ///Spatial manager used by the physics engine for coarse collision detection.
        SpatialManager!(PhysicsBody) spatial_physics_;
        ///Physics engine used by the scene manager.
        PhysicsEngine physics_engine_;
        ///Actor manager used by the game.
        SceneManager scene_manager_;
        ///GUI of the game.
        GameGUI gui_;
        ///Game itself.
        Game game_;
        ///Monitor monitoring game subsystems.
        Monitor monitor_;

    public:
        /**
         * Produce a Game and return a reference to it.
         *
         * Params:  platform   = Platform to use for user input.
         *          monitor    = Monitor to monitor game subsystems.
         *          gui_parent = Parent for all GUI elements used by the game.
         *
         * Returns: Produced Game.
         */
        Game produce(Platform platform, Monitor monitor, GUIElement gui_parent)
        in
        {
            assert(spatial_physics_ is null &&
                   physics_engine_ is null && 
                   scene_manager_ is null &&
                   game_ is null,
                   "Can't produce two games at once with GameContainer");
        }
        body
        {
            monitor_ = monitor;
            spatial_physics_ = new GridSpatialManager!(PhysicsBody)
                                   (Vector2f(400.0f, 300.0f), 25.0f, 32);
            monitor_.add_monitorable(spatial_physics_, "Spatial(P)");
            physics_engine_ = new PhysicsEngine(spatial_physics_);
            monitor_.add_monitorable(physics_engine_, "Physics");
            scene_manager_ = new SceneManager(physics_engine_);
            gui_ = new GameGUI(gui_parent, 300.0);
            game_ = new Game(platform, scene_manager_, gui_, 10, 300.0);
            return game_;
        }

        ///Destroy the contained Game.
        void destroy()
        {
            game_.die();
            gui_.die();
            writefln("SceneManager statistics:\n", scene_manager_.statistics, "\n");
            scene_manager_.die();
            monitor_.remove_monitorable("Physics");
            physics_engine_.die();
            monitor_.remove_monitorable("Spatial(P)");
            spatial_physics_.die();
            game_ = null;
            scene_manager_ = null;
            physics_engine_ = null;
            spatial_physics_ = null;
            monitor_ = null;
        }
}

/**
 * Credits screen.
 *
 * Signal:
 *     public mixin Signal!() closed
 *
 *     Emitted when this credits dialog is closed.
 */
class Credits
{
    private:
        ///Credits text.
        static credits_ = 
        "Credits\n"
        ".\n"
        "Pong was written by Ferdinand Majerech aka Kiith-Sa in the D Programming language\n"
        ".\n"
        "Other tools used to create Pong:\n"
        ".\n"
        "OpenGL graphics programming API\n"
        "SDL library\n"
        "The Freetype Project\n"
        "Derelict D bindings\n"
        "CDC build script\n"
        "Linux OS\n"
        "Vim text editor\n"
        "Valgrind debugging and profiling suite\n"
        "Git revision control system\n"
        ".\n"
        "Pong is released under the terms of the Boost license.";

        ///Parent of the container.
        GUIElement parent_;

        ///GUI element containing all elements of the credits screen.
        GUIElement container_;
        ///Button used to close the screen.
        GUIButton close_button_;
        ///Credits text.
        GUIStaticText text_;

    public:
        ///Emitted when this credits dialog is closed.
        mixin Signal!() closed;

        /**
         * Construct a Credits screen.
         *
         * Params:  parent = GUI element to attach the credits screen to.
         */
        this(GUIElement parent)
        {
            parent_ = parent;

            with(new GUIElementFactory)
            {
                margin(16, 96, 16, 96);
                container_ = produce();
            }
            parent_.add_child(container_);

            with(new GUIStaticTextFactory)
            {
                margin(16, 16, 40, 16);
                text = credits_;
                this.text_ = produce();
            }

            with(new GUIButtonFactory)
            {
                x = "p_left + p_width / 2 - 72";
                y = "p_bottom - 32";
                width = "144";
                height = "24";
                text = "Close";
                close_button_ = produce();
            }

            container_.add_child(text_);
            container_.add_child(close_button_);
            close_button_.pressed.connect(&closed.emit);
        }

        ///Destroy this credits screen.
        void die()
        {
            container_.die();
            closed.disconnect_all();
        }
}

/** 
 * Class holding all GUI used by Pong (main menu, etc.).
 *
 * Signal:
 *     public mixin Signal!() game_start
 *
 *     Emitted when the player clicks the button to start the game.
 *
 * Signal:
 *     public mixin Signal!() credits_start
 *
 *     Emitted when the credits screen is opened. 
 *
 * Signal:
 *     public mixin Signal!() credits_end
 *
 *     Emitted when the credits screen is closed. 
 *
 * Signal:
 *     public mixin Signal!() quit
 *
 *     Emitted when the player clicks the button to quit. 
 *
 * Signal:
 *     public mixin Signal!() reset_video
 *
 *     Emitted when the player clicks the button to reset video mode. 
 */
class PongGUI
{
    private:
        ///Parent of all Pong GUI elements.
        GUIElement parent_;

        MonitorView monitor_;
        ///Container of the main menu.
        GUIElement menu_container_;
        ///Main menu.
        GUIMenu menu_;
        ///Credits screen (null unless shown).
        Credits credits_;

    public:
        ///Emitted when the player clicks the button to start the game.
        mixin Signal!() game_start;
        ///Emitted when the credits screen is opened.
        mixin Signal!() credits_start;
        ///Emitted when the credits screen is closed.
        mixin Signal!() credits_end;
        ///Emitted when the player clicks the button to quit.
        mixin Signal!() quit;
        ///Emitted when the player clicks the button to reset video mode.
        mixin Signal!() reset_video;

        /**
         * Construct PongGUI with specified parameters.
         *
         * Params:  parent  = GUI element to use as parent for all pong GUI elements.
         *          monitor = Monitor subsystem, used to initialize monitor GUI view.
         */
        this(GUIElement parent, Monitor monitor)
        {
            parent_ = parent;

            with(new MonitorViewFactory(monitor))
            {
                x = "16";
                y = "16";
                width ="192 + w_right / 4";
                height ="168 + w_bottom / 6";
                this.monitor_ = produce();
            }
            parent_.add_child(monitor_);
            monitor_.hide();

            with(new GUIElementFactory)
            {
                x = "p_right - 176";
                y = "16";
                width = "160";
                height = "p_bottom - 32";
                menu_container_ = produce();
            }
            parent_.add_child(menu_container_);

            with(new GUIMenuVerticalFactory)
            {
                x = "p_left";
                y = "p_top + 136";
                item_width = "144";
                item_height = "24";
                item_spacing = "8";
                add_item("Player vs AI", &game_start.emit);
                add_item("Credits", &credits_show);
                add_item("Quit", &quit.emit);
                add_item("(DEBUG) Reset video", &reset_video.emit);
                menu_ = produce();
            }
            menu_container_.add_child(menu_);
        }

        ///Destroy the PongGUI.
        void die()
        {
            monitor_.die();
            monitor_ = null;

            if(credits_ !is null)
            {
                credits_.die();
                credits_ = null;
            }
            menu_container_.die();
            menu_container_ = null;

            game_start.disconnect_all();
            credits_start.disconnect_all();
            credits_end.disconnect_all();
            quit.disconnect_all();
            reset_video.disconnect_all();
        }

        ///Get the monitor widget.
        MonitorView monitor(){return monitor_;}

        ///Toggle monitor display.
        void monitor_toggle()
        {
            if(monitor_.visible){monitor_.hide();}
            else{monitor_.show();}
        }

        ///Show main menu.
        void menu_show(){menu_container_.show();};

        ///Hide main menu.
        void menu_hide(){menu_container_.hide();};

    private:
        ///Show credits screen (and hide main menu).
        void credits_show()
        {
            menu_hide();
            credits_ = new Credits(parent_);
            credits_.closed.connect(&credits_hide);
            credits_start.emit();
        }

        ///Hide credits screen (and show main menu).
        void credits_hide()
        {
            credits_.die();
            credits_ = null;
            menu_show();
            credits_end.emit();
        }
}

class Pong
{
    mixin WeakSingleton;
    private:
        ///FPS counter.
        EventCounter fps_counter_;
        ///Continue running?
        bool continue_ = true;

        ///Platform used for user input.
        Platform platform_;

        ///Container managing video driver and its dependencies.
        VideoDriverContainer video_driver_container_;
        ///Video driver.
        VideoDriver video_driver_;

        ///Root of the GUI.
        GUIRoot gui_root_;
        ///Pong GUI.
        PongGUI gui_;

        ///Used for memory monitoring.
        MemoryMonitorable memory_;

        ///Container managing game and its dependencies.
        GameContainer game_container_;
        ///Game.
        Game game_;

        ///Monitor subsystem, providing debugging and profiling info.
        Monitor monitor_;

    public:
        ///Initialize Pong.
        this()
        {
            writefln("Initializing Pong");

            singleton_ctor();

            monitor_ = new Monitor();

            memory_ = new MemoryMonitorable;

            scope(failure)
            {
                monitor_.die();
                memory_.die();
                singleton_dtor();
            }
            monitor_.add_monitorable(memory_, "Memory");
            scope(failure){monitor_.remove_monitorable("Memory");}

            platform_ = new SDLPlatform;
            scope(failure){platform_.die();}

            video_driver_container_ = new VideoDriverContainer;
            video_driver_ = video_driver_container_.produce!(SDLGLVideoDriver)
                            (800, 600, ColorFormat.RGBA_8, false);
            scope(failure)
            {
                video_driver_.die();
                video_driver_container_.die();
            }
            monitor_.add_monitorable(video_driver_, "Video");
            scope(failure){monitor_.remove_monitorable("Video");}

            //initialize GUI
            gui_root_ = new GUIRoot(platform_);
            scope(failure){gui_root_.die();}

            gui_ = new PongGUI(gui_root_.root, monitor_);
            scope(failure){gui_.die();}
            gui_.credits_start.connect(&credits_start);
            gui_.credits_end.connect(&credits_end);
            gui_.game_start.connect(&game_start);
            gui_.quit.connect(&exit);
            gui_.reset_video.connect(&reset_video);

            game_container_ = new GameContainer();

            //Update FPS every second.
            fps_counter_ = new EventCounter(1.0);
            fps_counter_.update.connect(&fps_update);
        }

        ///Destroy Pong and all subsystems.
        void die()
        {
            writefln("Destroying Pong");

            //game might still be running if we're quitting
            //because the platform stopped to run
            if(game_ !is null)
            {
                game_.end_game();
                game_container_.destroy();
                game_ = null;
            }
            fps_counter_.die();

            monitor_.remove_monitorable("Memory");
            //video driver might be already destroyed in exceptional circumstances
            if(video_driver_ !is null){monitor_.remove_monitorable("Video");}

            monitor_.die();

            gui_.die();
            gui_root_.die();

            //video driver might be already destroyed in exceptional circumstances
            if(video_driver_ !is null)
            {
                video_driver_container_.destroy();
                video_driver_container_.die();
                video_driver_ = null;
            }
            platform_.die();
            memory_.die();
            singleton_dtor();
        }

        ///Update Pong.
        void run()
        {                           
            platform_.key.connect(&key_handler_global);
            platform_.key.connect(&key_handler);

            while(platform_.run() && continue_)
            {
                //Count this frame
                fps_counter_.event();

                bool game_run = game_ !is null && game_.run();
                if(game_ !is null && !game_run){game_end();}

                //update game state
                gui_root_.update();

                video_driver_.start_frame();

                if(game_run){game_.draw(video_driver_);}

                gui_root_.draw(video_driver_);
                video_driver_.end_frame();
                memory_.update();
            }
            writefln("FPS statistics:\n", fps_counter_.statistics, "\n");
        }

    private:
        ///Start game.
        void game_start()
        {
            gui_.menu_hide();
            platform_.key.disconnect(&key_handler);
            game_ = game_container_.produce(platform_, monitor_, gui_root_.root);
            game_.intro();
        }

        ///End game.
        void game_end()
        {
            game_container_.destroy();
            game_ = null;
            platform_.key.connect(&key_handler);
            gui_.menu_show();
        }

        ///Show credits screen.
        void credits_start(){platform_.key.disconnect(&key_handler);}

        ///Hide (destroy) credits screen.
        void credits_end(){platform_.key.connect(&key_handler);}

        ///Exit Pong.
        void exit(){continue_ = false;}

        /**
         * Process keyboard input.
         *
         * Params:  state   = State of the key.
         *          key     = Keyboard key.
         *          unicode = Unicode value of the key.
         */
        void key_handler(KeyState state, Key key, dchar unicode)
        {
            if(state == KeyState.Pressed)
            {
                switch(key)
                {
                    case Key.Escape:
                        exit();
                        break;
                    case Key.Return:
                        game_start();
                        break;
                    default:
                        break;
                }
            }
        }

        /**
         * Process keyboard input (global).
         *
         * This key handler is always connected, regardless of whether we're in
         * game or main menu.
         *
         * Params:  state   = State of the key.
         *          key     = Keyboard key.
         *          unicode = Unicode value of the key.
         */
        void key_handler_global(KeyState state, Key key, dchar unicode)
        {
            if(state == KeyState.Pressed)
            {
                switch(key)
                {
                    case Key.K_1:
                        video_driver_.draw_mode(DrawMode.Immediate);
                        break;
                    case Key.K_2:
                        video_driver_.draw_mode(DrawMode.RAMBuffers);
                        break;
                    case Key.K_3:
                        video_driver_.draw_mode(DrawMode.VRAMBuffers);
                        break;
                    case Key.F10:
                        gui_.monitor_toggle();
                        break;
                    case Key.Scrollock:
                        save_screenshot();
                        break;
                    default:
                        break;
                }
            }
        }

        ///Update FPS display.
        void fps_update(real fps)
        {
            platform_.window_caption = "FPS: " ~ std.string.toString(fps);
        }

        ///Reset video mode.
        void reset_video(){reset_video_driver(800, 600, ColorFormat.RGBA_8);}

        /**
         * Reset video driver with specified video mode.
         *
         * Params:  width  = Window/screen width to use.
         *          height = Window/screen height to use.
         *          format = Color format of video mode.
         */
        void reset_video_driver(uint width, uint height, ColorFormat format)
        {
            //game area
            Rectanglef area = game_.game_area;

            monitor_.remove_monitorable("Video");

            video_driver_container_.destroy();
            scope(failure){(video_driver_ = null);}
            try
            {
                video_driver_ = video_driver_container_.produce!(SDLGLVideoDriver)
                                (width, height, format, false);
            }
            catch(VideoDriverException e)
            {
                writefln("Video driver reset failed:", e.msg);
                exit();
                return;
            }

            //Zoom according to the new video mode.
            real w_mult = width / area.width;
            real h_mult = height / area.height;
            real zoom = min(w_mult, h_mult);

            //Center game area on screen.
            Vector2d offset;
            offset.x = area.min.x + (w_mult / zoom - 1.0) * 0.5 * area.width * -1.0; 
            offset.y = area.min.y + (h_mult / zoom - 1.0) * 0.5 * area.height * -1.0;

            video_driver_.zoom(zoom);
            video_driver_.view_offset(offset);
            gui_root_.realign(video_driver_);
            monitor_.add_monitorable(video_driver_, "Video");
        }

        ///Save screenshot (to data/main/screenshots).
        void save_screenshot()
        {
            Image screenshot = video_driver_.screenshot();
            scope(exit){delete screenshot;}

            try
            {
                ensure_directory_user("main::screenshots");

                //save screenshot with increasing suffix number.
                for(uint s = 0; s < 100000; s++)
                {
                    string file_name = format("main::screenshots/screenshot_%05d.png", s);
                    if(!file_exists_user(file_name))
                    {
                        write_image(screenshot, file_name);
                        return;
                    }
                }
                writefln("Screenshot saving error: too many screenshots");
            }
            catch(FileIOException e){writefln("Screenshot saving error: " ~ e.msg);}
            catch(ImageFileException e){writefln("Screenshot saving error: " ~ e.msg);}
        }
}


///Program entry point.
void main(string[] args)
{
    //will add -h/--help and generate usage info by itself
    auto cli = new CLI();
    cli.description = "DPong 0.1.0\n"
                      "Pong game written in D.\n"
                      "Copyright (C) 2010-2011 Ferdinand Majerech";
    cli.epilog = "Report errors at <kiithsacmp@gmail.com> (in English, Czech or Slovak).";

    //Root data and user data MUST be specified at startup
    cli.add_option(CLIOption("root_data").short_name('R')
                                         .target(&root_data).default_args("./data"));
    cli.add_option(CLIOption("user_data").short_name('U')
                                         .target(&user_data).default_args("./user_data"));

    if(!cli.parse(args)){return;}

    try
    {
        Pong pong = new Pong;
        scope(exit){pong.die();}
        pong.run();
    }
    catch(Exception e)
    {
        writefln("Unhandled exeption: ", e.toString(), " ", e.msg);
        exit(-1);
    }
}                                     
