module pong;


import std.stdio;
import std.string;
import std.random;
import std.math;

import std.c.stdlib;     

import math.math;
import math.vector2;
import math.line2;
import math.rectangle;
import video.videodriver;
import video.sdlglvideodriver;
import actor.actor;
import actor.actormanager;
import actor.lineemitter;
import actor.linetrail;
import gui.guielement;
import gui.guiroot;
import gui.guimenu;
import gui.guibutton;
import gui.guistatictext;
import platform.platform;
import platform.sdlplatform;
import monitor.monitor;
import time.time;
import time.timer;
import time.eventcounter;
import signal;
import singleton;
import color;


///A wall of game area.
class Wall : Actor
{
    protected:
        //Area taken up by the wall
        Rectanglef size_;

    public:
        ///Emitted when a ball hits the wall.
        mixin Signal!(Ball) ball_hit;

        ///Construct a wall with specified position and size.
        this(Vector2f position, Rectanglef size)
        {
            size_ = size;
            super(position, Vector2f(0.0f, 0.0f));
        }

        override void draw()
        {
            static c = Color(240, 255, 240, 255);
            VideoDriver.get.draw_rectangle(position_ + size_.min, position_ + size_.max);
        }

        final override bool collision(Actor actor, out Vector2f position, 
                       out Vector2f velocity)
        in{assert(actor !is null);}
        body
        {
            if(actor.classinfo == Ball.classinfo)
            {
                Ball ball = cast(Ball)actor;
                Vector2f collision_point;

                if(collision_ball(ball, position, collision_point))
                {
                    velocity = reflect_ball(ball, collision_point);
                    ball_hit.emit(ball);
                    return true;
                }
            }
            return false;
        }

    protected:
        //Note: This test doesn't handle tunnelling, so it can result in
        //undetected collisions with very high speeds or low FPS
        //Collision test with a ball
        bool collision_ball(Ball ball, out Vector2f position, 
                            out Vector2f collision_point)
        {
            real frame_length = ActorManager.get.frame_length;
            //Translate the rectangle to world space
            Rectanglef size = size_ + position_ + velocity_ * frame_length;
            
            //Get the closest point to the ball on this wall
            Vector2f closest = size.clamp(ball.position);

            //If the ball collides with the ball
            if((ball.position - closest).length < ball.radius)
            {
                //Time step used to move the ball back
                real step_length = 1.0 / ball.velocity.length();
                //Ball position at the end of the frame
                Vector2f ball_position = ball.position() + ball.velocity() 
                                         * frame_length;
                
                //Moving the ball back to the point where it didn't collide.
                while((ball_position - closest).length < ball.radius)
                {
                    ball_position -= (ball.velocity - velocity_) * step_length;
                    closest = size.clamp(ball_position);
                }

                position = ball_position;
                collision_point = closest;

                return true;
            }
            return false;
        }
        
        //Reflect a ball off the wall - return new velocity of the ball.
        Vector2f reflect_ball(Ball ball, Vector2f collision_point)
        {
            //Translate the rectangle to world space
            Rectanglef size = size_ + position_;

            //If we're reflecting off the vertical sides of the wall
            if(equals(collision_point.x, size.min.x) || 
               equals(collision_point.x, size.max.x))
            {
                return Vector2f(-ball.velocity.x, ball.velocity.y);
            }
            //If we're reflecting off the horizontal sides of the wall
            else
            {
                return Vector2f(ball.velocity.x, -ball.velocity.y);
            }
        }
}             

///A paddle controlled by a player or AI.
class Paddle : Wall
{
    invariant
    {
        Rectanglef box = size_ + position_;
        assert(box.max.x <= limits_.max.x && 
               box.max.y <= limits_.max.y &&
               box.min.x >= limits_.min.x && 
               box.min.y >= limits_.min.y,
               "Paddle outside of limits");
        assert(equals(box.max.x - position_.x, position_.x - box.min.x, 1.0f),
               "Paddle not symmetric on the X axis");
        assert(equals(box.max.y - position_.y, position_.y - box.min.y, 1.0f),
               "Paddle not symmetric on the Y axis");
    }

    private:
        //Limits of movement of this paddle
        Rectanglef limits_;

        //Speed of this paddle
        real speed_;

        //Max ratio of X and Y speed when reflecting the ball,
        //i.e., if this is 1.0, and the ball gets reflected from
        //the corner of the paddle, ratio of X and Y members of
        //reflected ball velocity will be 1:1.
        real max_xy_ratio_ = 1.0;

    public:
        ///Construct a paddle with specified parameters.
        this(Vector2f position, Rectanglef size, Rectanglef limits, real speed)
        {
            super(position, size);
            speed_ = speed;
            limits_ = limits;
        }

        ///Return limits of movement of this paddle.
        Rectanglef limits(){return limits_;}

        ///Control the paddle to move right (used by player or AI).
        void move_right(){velocity_ = speed_ * Vector2f(1.0, 0.0);}

        ///Control the paddle to move left (used by player or AI).
        void move_left(){velocity_ = speed_ * Vector2f(-1.0, 0.0);}

        ///Control the paddle to stop (used by player or AI).
        void stop(){velocity_ = Vector2f(0.0, 0.0);}

        override void update_physics()
        {
            next_position_ = position_ + velocity_ * ActorManager.get.frame_length();

            Rectanglef position_limits = Rectanglef(limits_.min - size_.min,
                                                    limits_.max - size_.max);

            //If we're going outside limits, stop
            if(next_position_ != position_limits.clamp(next_position_))
            {
                stop();
                next_position_ = position_;
            }
        }

    protected:
        override Vector2f reflect_ball(Ball ball, Vector2f collision_point)
        {
            //Translate the rectangle to world space
            Rectanglef size = size_ + position_;

            Vector2f velocity;
            
            //reflection angle depends on where on the paddle does the ball
            //fall
            velocity.x = max_xy_ratio_ * (collision_point.x - position_.x) / 
                         (size.max.x - position_.x);
            velocity.y = (collision_point.y - position_.y) / 
                         (size.max.y - position_.y);

            //If the velocity is too horizontal, randomly nudge it up or down
            //so that we don't end up with a ball bouncing between the same
            //points forever
            //NOTE that this is a quick fix and it might not make sense
            //if non-rectangular paddles are added or they are positioned
            //on left-right sides of the screen instead of up/down
            if(velocity.y / velocity.x < 0.001)
            {
                float y_mod = velocity.x / 1000.0;
                //rand() % 2 means random bool 
                y_mod *= std.random.rand() % 2 ? -1.0 : 1.0;
                velocity.y += y_mod;
            }
            velocity = velocity.normalized * ball.velocity.length;

            return velocity;
        }
}

///A ball that can bounce off other objects.
class Ball : Actor
{
    invariant
    {
        assert(velocity_.length > 0.0, "A ball can't be static");
        assert(radius_ >= 1.0, "A ball can't have radius lower than 1.0");
    }

    private:
        //Particle trail of the ball
        LineEmitter emitter_;

        //Speed of particles emitted by the ball
        real particle_speed_;

        //Line trail of the ball (particle effect)
        LineTrail trail_;

        //Radius of the ball (used for collision detection)
        real radius_;

    public:
        ///Construct a ball with specified parameters.
        this(Vector2f position, Vector2f velocity, real radius)
        {
            super(position, velocity);

            radius_ = radius;

            trail_ = new LineTrail(this);
                                  
            with(trail_)
            {
                particle_life = 0.5;
                start_color = Color(240, 240, 255, 255);
                end_color = Color(240, 240, 255, 0);
                line_width = 1;
            }

            particle_speed_ = 25.0;
            
            emitter_ = new LineEmitter(this);
            with(emitter_)
            {
                particle_life = 2.0;
                emit_frequency = 160;
                emit_velocity = -this.velocity_.normalized * particle_speed_;
                angle_variation = PI / 4;
                line_length = 2.0;
                line_width = 1;
                start_color = Color(224, 224, 255, 32);
                end_color = Color(224, 224, 255, 0);
            }
        }

        ///Destroy this ball.
        void die()
        {
            trail_.life_time = 0.5;
            trail_.detach();
            emitter_.life_time = 2.0;
            emitter_.emit_frequency = 0.0;
            emitter_.detach();
            super.die();
        }
 
        ///Return the radius of this ball.
        float radius(){return radius_;}

        override void update_physics()
        {
            real frame_length = ActorManager.get.frame_length;
            next_position_ = position_ + velocity_ * frame_length;
            
            Vector2f position;
            Vector2f velocity;
            if(ActorManager.get.collision(this, position, velocity))
            {
                next_position_ = position;
                velocity_ = velocity;
                emitter_.emit_velocity = -velocity_.normalized * particle_speed_;
            }
        }

        override void update(){position_ = next_position_;}

        override void draw()
        {
            auto driver = VideoDriver.get;
            driver.line_aa = true;
            driver.line_width = 3;
            driver.draw_circle(position_, radius_ - 2, Color(240, 240, 255, 255), 4);
            driver.line_width = 1;
            driver.draw_circle(position_, radius_, Color(192, 192, 255, 192));
            driver.line_width = 1;                  
            driver.line_aa = false;
        }
}

///Player controlling a paddle.
abstract class Player
{
    protected:
        //Name of this player
        string name_;
        //Current score of this player
        uint score_ = 0;

        //Paddle controlled by this player
        Paddle paddle_;

    public:
        ///Increase score of this player.
        void score(Ball ball)
        {
            score_++;
        }

        ///Get score of this player.
        int score(){return score_;}

        ///Get name of this player.
        string name(){return name_;}

        ///Update the player state.
        void update(){}

        ///Destroy this player
        void die(){delete this;}

    protected:
        ///Construct a player with given name.
        this(string name, Paddle paddle)
        {
            name_ = name;
            paddle_ = paddle;
        }
}

//AI player
class AIPlayer : Player
{
    protected:
        //Timer determining when to update the AI
        Timer update_timer_;

    public:
        ///Construct an AI controlling specified paddle
        this(string name, Paddle paddle, real update_time)
        {
            super(name, paddle);
            update_timer_ = Timer(update_time);
        }

        override void update()
        {
            if(update_timer_.expired())
            {
                update_timer_.reset();
                real frame_length = ActorManager.get.frame_length;

                //currently only support zero or one ball
                Ball[] balls = Game.get.balls;
                assert(balls.length <= 1, 
                       "AI supports only zero or one ball at the moment");
                if(balls.length == 0)
                {
                    move_to_center;
                    return;
                }
                Ball ball = balls[0];

                float distance = paddle_.limits.distance(ball.position);
                Vector2f ball_next = ball.position + ball.velocity * frame_length;
                float distance_next = paddle_.limits.distance(ball_next);
                
                //If the ball is closing to paddle movement area
                if(distance_next <= distance){ball_closing(ball);}       
                //If the ball is moving away from paddle movement area
                else{move_to_center();}
            }
        }

    protected:
        //React to the ball closing in
        void ball_closing(Ball ball)
        {
            //If paddle x position is roughly equal to ball, no need to move
            if(equals(paddle_.position.x, ball.position.x, 16.0f))
            {
                paddle_.stop();
            }
            else if(paddle_.position.x < ball.position.x)
            {
                paddle_.move_right();
            }
            else 
            {
                paddle_.move_left();
            }
        }

        //Move the paddle to center
        void move_to_center()
        {
            Vector2f center = paddle_.limits.center;
            //If paddle x position is roughly in the center, no need to move
            if(equals(paddle_.position.x, center.x, 16.0f))
            {
                paddle_.stop();
            }
            else if(paddle_.position.x < center.x)
            {
                paddle_.move_right();
            }
            else 
            {
                paddle_.move_left();
            }
        }
}

//Human player controlling the game through user input.
class HumanPlayer : Player
{
    public:
        ///Construct a human player controlling specified paddle.
        this(string name, Paddle paddle)
        {
            super(name, paddle);
            Platform.get.key.connect(&key_handler);
        }
        
        ///Destroy this HumanPlayer.
        ~this()
        {
            Platform.get.key.disconnect(&key_handler);
        }

        ///Handle input
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
                    if(Platform.get.is_key_pressed(Key.Left))
                    {
                        paddle_.move_left();
                        return;
                    }
                    paddle_.stop();
                    return;
                }
                else if(key == Key.Left)
                {
                    if(Platform.get.is_key_pressed(Key.Right))
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

///Displays score screen at the end of game.
class ScoreScreen : GUIElement
{
    private:
        alias std.string.toString to_string;  
        
        //score screen ends when this timer expires.
        Timer timer_;

        GUIStaticText winner_text_;
        GUIStaticText names_text_;
        GUIStaticText scores_text_;
        GUIStaticText time_text_;

    public:
        mixin Signal!() expired;

        this(Player player_1, Player player_2, real time)
        in
        {
            assert(player_1.score != player_2.score, 
                   "Score screen shown but neither of the players is victorious");
        }
        body
        {
            position_x = "p_right / 2 - 192";
            position_y = "p_bottom / 2 - 128";
            width = "384";
            height = "256";

            border_color_ = Color(160, 160, 255, 160);

            string winner = player_1.score > player_2.score ? 
                            player_1.name : player_2.name;

            //text showing the winner of the game
            winner_text_ = new GUIStaticText;
            with(winner_text_)
            {
                position_x = "p_left";
                position_y = "p_top + 16";
                width = "p_right - p_left";
                height = "32";
                font_size = 24;
                text_color = Color(192, 192, 255, 128);
                alignment_x = AlignX.Center;
                font = "orbitron-bold.ttf";
                text = "WINNER: " ~ winner;
            }
            add_child(winner_text_);

            //text showing time the game took
            time_text_ = new GUIStaticText;
            with(time_text_)
            {
                position_x = "p_left + 48";
                position_y = "p_top + 96";
                width = "128";
                height = "16";
                font_size = 14;
                text_color = Color(224, 224, 255, 160);
                font = "orbitron-light.ttf";
                text = "Time: " ~ time_string(time);
            }
            add_child(time_text_);

            init_scores(player_1, player_2);

            timer_ = Timer(8);
        }

    protected:
        override void update()
        {
            super.update();
            if(timer_.expired){expired.emit();}
        }
        
    private:
        //Initialize players/scores list.
        void init_scores(Player player_1, Player player_2)
        {
            names_text_ = new GUIStaticText;
            with(names_text_)
            {
                position_x = "p_left + 48";
                position_y = "p_top + 48";
                width = "128";
                height = "32";
                font_size = 14;
                text_color = Color(160, 160, 255, 128);
                font = "orbitron-light.ttf";
                text = player_1.name ~ "\n" ~ player_2.name;
            }
            add_child(names_text_);

            scores_text_ = new GUIStaticText;
            with(scores_text_)
            {
                position_x = "p_right - 128";
                position_y = "p_top + 48";
                width = "64";
                height = "32";
                font_size = 14;
                text_color = Color(224, 224, 255, 160);
                font = "orbitron-bold.ttf";
                text = to_string(player_1.score) ~ "\n" 
                       ~ to_string(player_2.score);
                alignment_x = AlignX.Right;
            }
            add_child(scores_text_);
        }
}

///Handles ball respawning and related effects.
/**
  When the spawner is created, it generates a set of directions the ball
  can be spawned at, in roughly the same direction (determined by specified spread)
  Then, during its lifetime, it displays the directions to the player 
  (as rays), gives the player a bit of time and spawns the ball with one
  of generated directions.
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
        //When this timer expires, the ball is spawned and the spawner destroyed.
        Timer timer_;
        
        //Speed to spawn balls with.
        real ball_speed_;

        //Minimum angle difference from 0.5*pi or 1.5*pi (from horizontal line).
        //Prevents the ball from being spawned too horizontally.
        real min_angle_ = PI * 0.125;
         
        //Number of possible directions to spawn the ball at to generate.
        uint direction_count_ = 12;
        
        //Directions the ball can be spawned at, in radians.
        real[] directions_;

        //"light" direction used by the rays effect.
        //The light rotates and shows the rays within its range.
        real light_ = 0;

        //Rotation speed of the "light", in radians per second.
        real light_speed_;

        //Angular width of the "light" in radians.
        real light_width_ = PI / 6.0; 

        //Draw the "light" ?
        bool light_expired = false;

    public:
        mixin Signal!(Vector2f, real) spawn_ball;
        
        /**
         * Constructs a BallSpawner with specified parameters.
         * 
         * Params:    time       = Time until the ball is spawned.
         *                         70% of this time will be taken by
         *                         the rays effect.
         *            spread     = "Randomness" of the spawn directions.
         *                         Zero will result in only one definite direction,
         *                         1 will result in completely random direction
         *                         (except for horizontal directions that are 
         *                         disallowed to prevent ball from getting stuck)
         *            ball_speed = Speed to spawn the ball at.
         *
         */
        this(real time, real spread, real ball_speed)
        in
        {
            assert(time >= 0.0, "Negative ball spawning time");
            assert(spread >= 0.0, "Negative ball spawning spread");
        }
        body
        {                
            super(Vector2f(0.0, 0.0));

            ball_speed_ = ball_speed;
            timer_ = Timer(time);
            //leave a third of time without the rays effect to give time
            //to the player
            light_speed_ = (2 * PI) / (time * 0.70);

            generate_directions(spread);
        }

        void update()
        {
            if(timer_.expired)
            {
                //emit the ball in a random, previously generated direction
                Vector2f direction = Vector2f(1.0f, 1.0f);
                direction.angle = directions_[std.random.rand % directions_.length];
                spawn_ball.emit(direction, ball_speed_);
                die();
            }
            if(!light_expired && light_ >= (2 * PI)){light_expired = true;}

            //update light direction
            light_ += light_speed_ * ActorManager.get.frame_length();
        }

        void draw()
        {
            VideoDriver.get.line_aa = true;
            scope(exit){VideoDriver.get.line_aa = false;} 

            Vector2f center = Vector2f(400.0, 300.0);
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
                VideoDriver.get.draw_line(center, center + direction * ray_length, 
                                          light_color, light_color_end);
                direction.angle = light_ - light_width_;
                VideoDriver.get.draw_line(center, center + direction * ray_length, 
                                          light_color, light_color_end);
            }

            VideoDriver.get.line_width = 2;
            scope(exit){VideoDriver.get.line_width = 1;} 
            
            //draw the rays in range of the light
            foreach(d; directions_)
            {
                real distance = std.math.abs(d - light_);
                if(distance > light_width_){continue;}

                Color color = base_color;
                color.a *= 1.0 - distance / light_width_;

                direction.angle = d;
                VideoDriver.get.draw_line(center, center + direction * ray_length, 
                                          color, color);
            }
        }

    private:
        /**
         * Generate the directions ball might be spawned with.
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
                if(direction < 0.5)
                {
                    direction = PI * 0.5 + min_angle_ + direction * range;
                }
                //0.5 - 1.0 gets mapped to 1.5pi+min_angle - 0.5pi-min_angle range
                else
                {
                    direction = PI * 1.5 + min_angle_ + (direction - 0.5) * range;
                }

                directions_ ~= direction;
            }
        }
}

class Game
{
    mixin Singleton;
    private:
        alias std.string.toString to_string;  
     
        Ball ball_;
        real ball_radius_ = 6.0;
        real ball_speed_ = 215.0;

        real spawn_time_ = 4.0;
        real spawn_spread_ = 0.32;

        Wall wall_right_;
        Wall wall_left_;

        Wall goal_up_;
        Wall goal_down_;

        Paddle paddle_1_;
        Paddle paddle_2_;

        Player player_1_;
        Player player_2_;

        //Continue running?
        bool continue_;

        GUIStaticText score_text_1_;
        GUIStaticText score_text_2_;
        GUIStaticText time_text_;

        uint score_limit_;
        real time_limit_;
        Timer game_timer_;

        ScoreScreen score_screen_;

        //true while the players are playing the game
        bool playing_;

    public:
        this(){singleton_ctor();}

        bool run()
        {
            if(playing_)
            {
                //update time display
                real time = time_limit_ - game_timer_.age;
                time = max(time, 0.0L);
                string time_str = time_string(time);
                static Color color_start = Color(160, 160, 255, 160);
                static Color color_end = Color(255, 0, 0, 255);
                if(time_str != time_text_.text)
                {
                    time_text_.text = time_str != "0:0" 
                                      ? time_str : time_str ~ " !";

                    real t = time / time_limit_;
                    time_text_.text_color = color_start.interpolated(color_end, t);
                }

                //update player state
                player_1_.update();
                player_2_.update();

                //check for victory conditions
                if(player_1_.score >= score_limit_ || 
                   player_2_.score >= score_limit_)
                {
                    game_won();
                }
                if(game_timer_.expired)
                {
                    if(player_1_.score != player_2_.score){game_won();}
                }
            }

            return continue_;
        }

        void die(){}

        void start_game()
        {
            //should be set from options and INI when that is implemented.
            score_limit_ = 10;
            time_limit_ = 300;
            continue_ = true;
            playing_ = true;

            auto wall_rect = Rectanglef(0.0, 0.0, 32.0, 536.0);
            wall_left_ = new Wall(Vector2f(120.0, 32.0), wall_rect);
            wall_right_ = new Wall(Vector2f(648.0, 32.0), wall_rect);

            auto goal_rect = Rectanglef(0.0, 0.0, 560.0, 28.0);
            goal_up_ = new Wall(Vector2f(120.0, 4.0), goal_rect);
            goal_down_ = new Wall(Vector2f(120.0, 568.0), goal_rect);

            auto size = Rectanglef(-32, -8, 32, 8); 
            auto limits1 = Rectanglef(152 + ball_radius_ * 2, 36, 
                                      648 - ball_radius_ * 2, 76); 
            paddle_1_ = new Paddle(Vector2f(400, 56), size, limits1, 144);
            auto limits2 = Rectanglef(152 + ball_radius_ * 2, 524, 
                                      648 - ball_radius_ * 2, 564); 
            paddle_2_ = new Paddle(Vector2f(400, 544), size, limits2, 144);

            auto spawner = new BallSpawner(spawn_time_, spawn_spread_, ball_speed_);
            spawner.spawn_ball.connect(&spawn_ball);

            player_1_ = new AIPlayer("AI", paddle_1_, 0.15);
            player_2_ = new HumanPlayer("Human", paddle_2_);

            goal_up_.ball_hit.connect(&destroy_ball);
            goal_down_.ball_hit.connect(&destroy_ball);
            goal_up_.ball_hit.connect(&player_2_.score);
            goal_down_.ball_hit.connect(&player_1_.score);
            goal_up_.ball_hit.connect(&update_score);
            goal_down_.ball_hit.connect(&update_score);

            Platform.get.key.connect(&key_handler);

            init_hud();
            update_score();

            game_timer_ = Timer(time_limit_);
        }

        ///Returns an array of balls currently used in the game.
        Ball[] balls()
        {
            Ball[] output;
            if(ball_ !is null){output ~= ball_;}
            return output;
        }

        //the argument is redunant here (at least for now) - 
        //used for compatibility with signal 
        void update_score(Ball ball = null)
        {
            score_text_1_.text = player_1_.name ~ ": " ~ to_string(player_1_.score);
            score_text_2_.text = player_2_.name ~ ": " ~ to_string(player_2_.score);
        }

        void draw()
        {
        }

    private:
        void init_hud()
        {
            score_text_1_ = new GUIStaticText;
            with(score_text_1_)
            {
                position_x = "p_left + 8";
                position_y = "p_top + 8";
                width = "96";
                height = "16";
                alignment_x = AlignX.Right;
                font = "orbitron-light.ttf";
                font_size = 16;
            }
            GUIRoot.get.add_child(score_text_1_);

            score_text_2_ = new GUIStaticText;
            with(score_text_2_)
            {
                position_x = "p_left + 8";
                position_y = "p_bottom - 24";
                width = "96";
                height = "16";
                alignment_x = AlignX.Right;
                font = "orbitron-light.ttf";
                font_size = 16;
            }
            GUIRoot.get.add_child(score_text_2_);

            time_text_ = new GUIStaticText;
            with(time_text_)
            {
                position_x = "p_right - 112";
                position_y = "p_bottom - 24";
                width = "96";
                height = "16";
                font = "orbitron-bold.ttf";
                font_size = 16;
            }
            GUIRoot.get.add_child(time_text_);
        }

        void destroy_hud()
        {
            GUIRoot.get.remove_child(score_text_1_);
            score_text_1_.die();
            score_text_1_ = null;

            GUIRoot.get.remove_child(score_text_2_);
            score_text_2_.die();
            score_text_2_ = null;

            GUIRoot.get.remove_child(time_text_);
            time_text_.die();
            time_text_ = null;
        }

        void destroy_ball(Ball ball)
        {
            ball_.die();
            ball_ = null;

            auto spawner = new BallSpawner(spawn_time_, spawn_spread_, ball_speed_);
            spawner.spawn_ball.connect(&spawn_ball);
        }

        void spawn_ball(Vector2f direction, real speed)
        {
            ball_ = new Ball(Vector2f(400.0, 300.0), direction * speed, ball_radius_);
        }

        //Called when one of the players wins the game.
        void game_won()
        {
            //hide the HUD
            score_text_1_.hide();
            score_text_2_.hide();
            time_text_.hide();

            //show the score screen and end the game after it expires
            score_screen_ = new ScoreScreen(player_1_, player_2_, game_timer_.age());
            GUIRoot.get.add_child(score_screen_);
            score_screen_.expired.connect(&end_game);
            ActorManager.get.time_speed = 0.0;

            playing_ = false;
        }

        void end_game()
        {
            destroy_hud();
            if(score_screen_ !is null)
            {
                GUIRoot.get.remove_child(score_screen_);
                score_screen_.die();
                score_screen_ = null;
            }
            playing_ = false;
            continue_ = false;
            ActorManager.get.time_speed = 1.0;

            ActorManager.get.clear();
            player_1_.die();
            player_2_.die();

            Platform.get.key.disconnect(&key_handler);
        }

        void key_handler(KeyState state, Key key, dchar unicode)
        {
            if(state == KeyState.Pressed)
            {
                switch(key)
                {
                    case Key.Escape:
                        end_game();
                        break;
                    case Key.K_P:
                        if(equals(ActorManager.get.time_speed, cast(real)0.0))
                        {
                            ActorManager.get.time_speed = 1.0;
                        }
                        else{ActorManager.get.time_speed = 0.0;}
                        break;
                    default:
                        break;
                }
            }
        }
}


///Credits screen.
class Credits : GUIElement
{
    private:
        static credits_ = 
        "Credits\n"~
        ".\n"~
        "Pong was written by Ferdinand Majerech aka Kiith-Sa in the D Programming language\n"~
        ".\n"~
        "Other tools used to create Pong:\n"~
        ".\n"
        "OpenGL graphics programming API\n"~
        "SDL library\n"~
        "The Freetype Project\n"~
        "Derelict D bindings\n"~
        "CDC build script\n"~
        "Linux OS\n"~
        "Vim text editor\n"~
        "Valgrind debugging and profiling suite\n"~
        "Git revision control system\n"~
        ".\n"~
        "Pong is released under the terms of the Boost license."
        ;

        GUIButton close_button_;
        GUIStaticText text_;

    public:
        ///Emitted when this credits dialog is closed.
        mixin Signal!() closed;

        this()
        {
            position_x = "p_left + 96";
            position_y = "p_top + 16";
            width = "p_right - 192";
            height = "p_bottom - 32";

            close_button_ = new GUIButton;
            with(close_button_)
            {
                position_x = "p_left + (p_right - p_left) / 2 - 72";
                position_y = "p_bottom - 32";
                width = "144";
                height = "24";
                text = "Close";
            }
            add_child(close_button_);
            close_button_.pressed.connect(&closed.emit);

            text_ = new GUIStaticText;
            with(text_)
            {
                position_x = "p_left + 16";
                position_y = "p_top + 16";
                width = "p_right - p_left - 32";
                height = "p_bottom - p_top - 56";
                text = credits_;
            }
            add_child(text_);
        }
}

class Pong
{
    mixin Singleton;
    private:
        EventCounter fps_counter_;
        bool run_pong_ = false;
        bool continue_ = true;

        GUIElement menu_container_;
        GUIMenu menu_;

        Credits credits_;

    public:
        ///Initialize Pong.
        this()
        {
            singleton_ctor();
            Game.initialize!(Game);
            ActorManager.initialize!(ActorManager);
            GUIRoot.initialize!(GUIRoot);
            VideoDriver.get.set_video_mode(800, 600, ColorFormat.RGBA_8, false);

            //Update FPS every second
            fps_counter_ = new EventCounter(1.0);
            fps_counter_.update.connect(&fps_update);

            uint width = VideoDriver.get.screen_width;
            uint height = VideoDriver.get.screen_height;

            menu_container_ = new GUIElement;
            with(menu_container_)
            {
                position_x = "p_right - 176";
                position_y = "16";
                width = "160";
                height = "p_bottom - 32";
            }
            GUIRoot.get.add_child(menu_container_);

            menu_ = new GUIMenu;
            with(menu_)
            {
                position_x = "p_left";
                position_y = "p_top + 136";

                add_item("Player vs AI", &pong_start);
                add_item("Credits", &credits_start);
                add_item("Quit", &exit);

                item_width = "144";
                item_height = "24";
                item_spacing = "8";
            }
            menu_container_.add_child(menu_);
        }

        void die()
        {
            ActorManager.get.die();
            VideoDriver.get.die();
            Platform.get.die();
            fps_counter_.update.disconnect(&fps_update);
            GUIRoot.get.die();
        }

        void run()
        {                           
            Platform.get.key.connect(&key_handler_global);
            Platform.get.key.connect(&key_handler);
            while(Platform.get.run() && continue_)
            {
                //Count this frame
                fps_counter_.event();

                if(run_pong_ && !Game.get.run()){pong_end();}

                //update game state
                ActorManager.get.update();
                GUIRoot.get.update();

                VideoDriver.get.start_frame();

                if(run_pong_){Game.get.draw();}
                else{draw();}

                ActorManager.get.draw();
                GUIRoot.get.draw();
                VideoDriver.get.end_frame();
            }
            Game.get.die();
            writefln("FPS statistics:\n", fps_counter_.statistics, "\n");
            writefln("ActorManager statistics:\n", ActorManager.get.statistics, "\n");
        }

        void draw()
        {
        }

    private:
        void pong_end()
        {
            Platform.get.key.connect(&key_handler);
            menu_container_.show();
            run_pong_ = false;
        }

        void pong_start()
        {
            run_pong_ = true;
            menu_container_.hide();
            Platform.get.key.disconnect(&key_handler);
            Game.get.start_game();
        }

        void credits_start()
        {
            menu_container_.hide();
            Platform.get.key.disconnect(&key_handler);
            credits_ = new Credits;
            GUIRoot.get.add_child(credits_);
            credits_.closed.connect(&credits_end);
        }

        void credits_end()
        {
            GUIRoot.get.remove_child(credits_);
            credits_.die();
            credits_ = null;
            Platform.get.key.connect(&key_handler);
            menu_container_.show();
        }

        void exit(){continue_ = false;}

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
                        pong_start();
                        break;
                    default:
                        break;
                }
            }
        }

        void key_handler_global(KeyState state, Key key, dchar unicode)
        {
            if(state == KeyState.Pressed)
            {
                switch(key)
                {
                    default:
                        break;
                }
            }
        }

        void fps_update(real fps)
        {
            Platform.get.window_caption = "FPS: " ~ std.string.toString(fps);
        }
}

void main()
{
    Platform.initialize!(SDLPlatform);
    VideoDriver.initialize!(SDLGLVideoDriver);

    try
    {
        Pong.initialize!(Pong);
        Pong.get.run();
        Pong.get.die();
    }
    catch(Exception e)
    {
        writefln("ERROR: ", e.toString());
        exit(-1);
    }
}                                     
