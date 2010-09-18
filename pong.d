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
import signal;
import time;
import timer;
import eventcounter;
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
            writefln(name_, " score: ", score_);
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
                real frame_length = ActorManager.get.frame_length;

                Ball ball = Game.get.ball;
                float distance = paddle_.limits.distance(ball.position);
                Vector2f ball_next = ball.position + ball.velocity * frame_length;
                float distance_next = paddle_.limits.distance(ball_next);
                
                //If the ball is closing to paddle movement area
                if(distance_next <= distance){ball_closing();}       
                //If the ball is moving away from paddle movement area
                else{move_to_center();}

                update_timer_.reset();
            }
        }

    protected:
        //React to the ball closing in
        void ball_closing()
        {
            Ball ball = Game.get.ball;
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

class Game
{
    mixin Singleton;
    private:
        Ball ball_;
        real ball_radius_ = 6.0;
        real ball_speed_ = 215.0;

        Wall wall_right_;
        Wall wall_leftt_;

        Wall goal_up_;
        Wall goal_down_;

        Paddle paddle_1_;
        Paddle paddle_2_;

        Player player_1_;
        Player player_2_;
        
        //Continue running?
        bool continue_;

    public:
        this(){singleton_ctor();}

        bool run()
        {
            player_1_.update();
            player_2_.update();
            return continue_;
        }

        void die(){}

        void start_game()
        {
            continue_ = true;

            wall_leftt_ = new Wall(Vector2f(64.0, 64.0),
                                Rectanglef(0.0, 0.0, 64.0, 472.0));
            wall_right_ = new Wall(Vector2f(672.0, 64.0),
                                 Rectanglef(0.0, 0.0, 64.0, 472.0));
            goal_up_ = new Wall(Vector2f(64.0, 32.0),
                              Rectanglef(0.0, 0.0, 672.0, 32.0));
            goal_down_ = new Wall(Vector2f(64.0, 536.0),
                                Rectanglef(0.0, 0.0, 672.0, 32.0));
            auto limits1 = Rectanglef(128 + ball_radius_ * 2, 64, 
                                      672 - ball_radius_ * 2, 128); 
            auto size = Rectanglef(-32, -8, 32, 8); 
            paddle_1_ = new Paddle(Vector2f(400, 96), size, limits1, 144);

            auto limits2 = Rectanglef(128 + ball_radius_ * 2, 472, 
                                      672 - ball_radius_ * 2, 536); 
            paddle_2_ = new Paddle(Vector2f(400, 504), size, limits2, 144);

            spawn_ball(ball_speed_);

            player_1_ = new AIPlayer("Player 1", paddle_1_, 0.15);
            player_2_ = new HumanPlayer("Player 2", paddle_2_);

            goal_up_.ball_hit.connect(&respawn_ball);
            goal_down_.ball_hit.connect(&respawn_ball);
            goal_up_.ball_hit.connect(&player_2_.score);
            goal_down_.ball_hit.connect(&player_1_.score);

            Platform.get.key.connect(&key_handler);
        }

        void end_game()
        {
            ActorManager.get.clear();
            player_1_.die();
            player_2_.die();

            Platform.get.key.disconnect(&key_handler);
        }

        Ball ball(){return ball_;}

        void draw()
        {
            uint score1 = player_1_.score;
            uint score2 = player_2_.score;
            Vector2f position = Vector2f(32, 8);
            Vector2f line_end;
            for(uint score = 0; score < score1; ++score)
            {
                line_end = position + Vector2f(0, 16);
                VideoDriver.get.draw_line(position, line_end);
                position.x += 4;
            }
            position = Vector2f(32, 576);
            for(uint score = 0; score < score2; ++score)
            {
                line_end = position + Vector2f(0, 16);
                VideoDriver.get.draw_line(position, line_end);
                position.x += 4;
            }
        }

    private:
        void respawn_ball(Ball ball)
        {
            ball_.die();
            spawn_ball(ball_speed_);
        }

        void spawn_ball(real speed)
        {
            long x = std.random.rand();
            long y = std.random.rand();
            Vector2f direction;
            direction.random_direction();
            //if the angle is too horizontal, adjust it
            while(abs(direction.y / direction.x) < 0.2)
            {
                direction.random_direction();
            }
            ball_ = new Ball(Vector2f(400.0, 300.0), direction * speed, 
                                ball_radius_);
        }

        void key_handler(KeyState state, Key key, dchar unicode)
        {
            if(state == KeyState.Pressed)
            {
                switch(key)
                {
                    case Key.Escape:
                        continue_ = false;
                        ActorManager.get.time_speed = 1.0;
                        break;
                    case Key.K_P:
                        if(equals(ActorManager.get.time_speed, cast(real)0.0))
                        {
                            ActorManager.get.time_speed = 1.0;
                        }
                        else
                        {
                            ActorManager.get.time_speed = 0.0;
                        }
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
                position_x = "w_right - 176";
                position_y = "16";
                width = "160";
                height = "w_bottom - 32";
            }
            GUIRoot.get.add_child(menu_container_);

            menu_ = new GUIMenu;
            with(menu_)
            {
                position_x = "w_right - 176";
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
            writefln("ActorManager statistics:\n", 
                     ActorManager.get.statistics, "\n");
        }

        void draw()
        {
        }

    private:
        void pong_end()
        {
            Game.get.end_game();
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
