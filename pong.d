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
import video.videodriverutil;
import video.gldriver;
import actor.actormanager;
import actor.particlesystem;
import gui.guielement;
import gui.guiroot;
import gui.guibutton;
import platform.platform;
import platform.sdlplatform;
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
        Rectanglef Size;

    public:
        ///Emitted when a ball hits the wall.
        mixin Signal!(Ball) ball_hit;

        ///Construct a wall with specified position and size.
        this(Vector2f position, Rectanglef size)
        {
            Size = size;
            super(position, Vector2f(0.0f, 0.0f));
        }

        override void draw()
        {
            static c = Color(240, 255, 240, 255);
            draw_rectangle(Position + Size.min, Position + Size.max);
        }

        override bool collision(Actor actor, out Vector2f position, 
                       out Vector2f velocity)
        in
        {
            assert(actor !is null);
        }
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
            Rectanglef size = Size + Position + Velocity * frame_length;
            
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
                    ball_position -= (ball.velocity - Velocity) * step_length;
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
            Rectanglef size = Size + Position;

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
        Rectanglef box = Size + Position;
        assert(box.max.x <= Limits.max.x && 
               box.max.y <= Limits.max.y &&
               box.min.x >= Limits.min.x && 
               box.min.y >= Limits.min.y,
               "Paddle outside of limits");
        assert(equals(box.max.x - Position.x, Position.x - box.min.x, 1.0f),
               "Paddle not symmetric on the X axis");
        assert(equals(box.max.y - Position.y, Position.y - box.min.y, 1.0f),
               "Paddle not symmetric on the Y axis");
    }

    private:
        //Limits of movement of this paddle
        Rectanglef Limits;

        //Speed of this paddle
        real Speed;

        //Max ratio of X and Y speed when reflecting the ball,
        //i.e., if this is 1.0, and the ball gets reflected from
        //the corner of the paddle, ratio of X and Y members of
        //reflected ball velocity will be 1:1.
        real MaxXYRatio = 1.0;

    public:
        ///Construct a paddle with specified parameters.
        this(Vector2f position, Rectanglef size, Rectanglef limits, real speed)
        {
            super(position, size);
            Speed = speed;
            Limits = limits;
        }

        ///Return limits of movement of this paddle.
        Rectanglef limits()
        {
            return Limits;
        }

        ///Control the paddle to move right (used by player or AI).
        void move_right()
        {   
            Velocity = Speed * Vector2f(1.0, 0.0); 
        }

        ///Control the paddle to move left (used by player or AI).
        void move_left()
        {   
            Velocity = Speed * Vector2f(-1.0, 0.0); 
        }

        ///Control the paddle to stop (used by player or AI).
        void stop()
        {
            Velocity = Vector2f(0.0, 0.0);
        }

        override void update_physics()
        {
            NextPosition = Position + 
                           Velocity * ActorManager.get.frame_length();

            Rectanglef position_limits = Rectanglef(Limits.min - Size.min,
                                                    Limits.max - Size.max);

            //If we're going outside limits, stop
            if(NextPosition != position_limits.clamp(NextPosition))
            {
                stop();
                NextPosition = Position;
            }
        }

    protected:
        override Vector2f reflect_ball(Ball ball, Vector2f collision_point)
        {
            //Translate the rectangle to world space
            Rectanglef size = Size + Position;

            Vector2f velocity;
            
            //reflection angle depends on where on the paddle does the ball
            //fall
            velocity.x = MaxXYRatio * (collision_point.x - Position.x) / 
                         (size.max.x - Position.x);
            velocity.y = (collision_point.y - Position.y) / 
                         (size.max.y - Position.y);

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
        assert(Velocity.length > 0.0, "A ball can't be static");
        assert(Radius >= 1.0, "A ball can't have radius lower than 1.0");
    }

    private:
        //Particle trail of the ball
        LineEmitter Emitter;

        //Speed of particles emitted by the ball
        real ParticleSpeed;

        //Line trail of the ball (particle effect)
        LineTrail Trail;

        //Radius of the ball (used for collision detection)
        real Radius;

    public:
        ///Construct a ball with specified parameters.
        this(Vector2f position, Vector2f velocity, real radius)
        {
            super(position, velocity);

            Radius = radius;

            Trail = new LineTrail(this);
                                  
            with(Trail)
            {
                particle_life = 0.5;
                start_color = Color(240, 240, 255, 255);
                end_color = Color(240, 240, 255, 0);
                line_width = 1;
            }

            ParticleSpeed = 25.0;
            
            Emitter = new LineEmitter(this);
            with(Emitter)
            {
                particle_life = 2.0;
                emit_frequency = 160;
                emit_velocity = -this.Velocity.normalized * ParticleSpeed;
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
            Trail.life_time = 0.5;
            Trail.detach();
            Emitter.life_time = 2.0;
            Emitter.emit_frequency = 0.0;
            Emitter.detach();
            super.die();
        }
 
        ///Return the radius of this ball.
        float radius()
        {
            return Radius;
        }

        override void update_physics()
        {
            real frame_length = ActorManager.get.frame_length;
            NextPosition = Position + Velocity * frame_length;
            
            Vector2f position;
            Vector2f velocity;
            if(ActorManager.get.collision(this, 
                                               position,
                                               velocity))
            {
                NextPosition = position;
                Velocity = velocity;
                Emitter.emit_velocity = -Velocity.normalized * ParticleSpeed;
            }
        }

        override void update()
        {
            Position = NextPosition;
        }

        override void draw()
        {
            VideoDriver.get.line_aa = true;
            VideoDriver.get.line_width = 3;
            draw_circle(Position, Radius - 2, Color(240, 240, 255, 255), 4);
            VideoDriver.get.line_width = 1;
            draw_circle(Position, Radius, Color(192, 192, 255, 192));
            VideoDriver.get.line_width = 1;                  
            VideoDriver.get.line_aa = false;
        }
}

class Player
{
    protected:
        //Name of this player
        string Name;
        //Current score of this player
        uint Score = 0;

        //Paddle controlled by this player
        Paddle PlayerPaddle;

    public:
        ///Increase score of this player.
        void score(Ball ball)
        {
            Score++;
            writefln(Name, " score: ", Score);
        }

        ///Get score of this player.
        int score()
        {
            return Score;
        }

        ///Get name of this player.
        string name()
        {
            return Name;
        }

        ///Update the player state.
        void update()
        {
        }

        ///Destroy this player
        void die()
        {
            delete this;
        }

    protected:
        ///Construct a player with given name.
        this(string name, Paddle paddle)
        {
            Name = name;
            PlayerPaddle = paddle;
        }
}

class AIPlayer : Player
{
    protected:
        //Timer determining when to update the AI
        Timer UpdateTimer;

    public:
        ///Construct an AI controlling specified paddle
        this(string name, Paddle paddle, real update_time)
        {
            super(name, paddle);
            UpdateTimer(update_time);
        }

        override void update()
        {
            if(UpdateTimer.expired())
            {
                real frame_length = ActorManager.get.frame_length;

                Ball ball = Pong.get.ball;
                float distance = PlayerPaddle.limits.distance(ball.position);
                Vector2f ball_next = ball.position + ball.velocity * frame_length;
                float distance_next = PlayerPaddle.limits.distance(ball_next);
                
                //If the ball is closing to paddle movement area
                if(distance_next <= distance)
                {
                    ball_closing();
                }       
                //If the ball is moving away from paddle movement area
                else
                {
                    move_to_center();
                }

                UpdateTimer.reset();
            }
        }

    protected:
        //React to the ball closing in
        void ball_closing()
        {
            Ball ball = Pong.get.ball;
            //If paddle x position is roughly equal to ball, no need to move
            if(equals(PlayerPaddle.position.x, ball.position.x, 16.0f))
            {
                PlayerPaddle.stop();
            }
            else if(PlayerPaddle.position.x < ball.position.x)
            {
                PlayerPaddle.move_right();
            }
            else 
            {
                PlayerPaddle.move_left();
            }
        }

        //Move the paddle to center
        void move_to_center()
        {
            Vector2f center = PlayerPaddle.limits.center;
            //If paddle x position is roughly in the center, no need to move
            if(equals(PlayerPaddle.position.x, center.x, 16.0f))
            {
                PlayerPaddle.stop();
            }
            else if(PlayerPaddle.position.x < center.x)
            {
                PlayerPaddle.move_right();
            }
            else 
            {
                PlayerPaddle.move_left();
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
                    PlayerPaddle.move_right();
                    return;
                }
                if(key == Key.Left)
                {
                    PlayerPaddle.move_left();
                    return;
                }
            }
            else if(state == KeyState.Released)
            {
                if(key == Key.Right)
                {
                    if(Platform.get.is_key_pressed(Key.Left))
                    {
                        PlayerPaddle.move_left();
                        return;
                    }
                    PlayerPaddle.stop();
                    return;
                }
                else if(key == Key.Left)
                {
                    if(Platform.get.is_key_pressed(Key.Right))
                    {
                        PlayerPaddle.move_right();
                        return;
                    }
                    PlayerPaddle.stop();
                    return;
                }
            }
        }
}

class Pong
{
    mixin Singleton;
    private:
        Ball GameBall;
        real BallRadius = 6.0;
        real BallSpeed = 215.0;

        Wall WallRight;
        Wall WallLeft;

        Wall GoalUp;
        Wall GoalDown;

        Paddle Paddle1;
        Paddle Paddle2;

        Player Player1;
        Player Player2;
        
        //Continue running?
        bool Continue;

    public:
        ///Start a Pong game.
        this(){singleton_ctor();}

        bool run()
        {
            Player1.update();
            Player2.update();
            return Continue;
        }

        void die(){}

        void start_game()
        {
            Continue = true;

            WallLeft = new Wall(Vector2f(64.0, 64.0),
                                Rectanglef(Vector2f(0.0, 0.0), 
                                           Vector2f(64.0, 472.0)));
            WallRight = new Wall(Vector2f(672.0, 64.0),
                                 Rectanglef(Vector2f(0.0, 0.0), 
                                            Vector2f(64.0, 472.0)));
            GoalUp = new Wall(Vector2f(64.0, 32.0),
                              Rectanglef(Vector2f(0.0, 0.0), 
                                         Vector2f(672.0, 32.0)));
            GoalDown = new Wall(Vector2f(64.0, 536.0),
                                Rectanglef(Vector2f(0.0, 0.0), 
                                           Vector2f(672.0, 32.0)));
            auto limits1 = Rectanglef(Vector2f(128 + BallRadius * 2, 64), 
                                      Vector2f(672 - BallRadius * 2, 128)); 
            auto size = Rectanglef(Vector2f(-32, -8), Vector2f(32, 8)); 
            Paddle1 = new Paddle(Vector2f(400, 96), size, limits1, 144);

            auto limits2 = Rectanglef(Vector2f(128 + BallRadius * 2, 472), 
                                      Vector2f(672 - BallRadius * 2, 536)); 
            Paddle2 = new Paddle(Vector2f(400, 504), size, limits2, 144);

            spawn_ball(BallSpeed);

            Player1 = new AIPlayer("Player 1", Paddle1, 0.15);
            Player2 = new HumanPlayer("Player 2", Paddle2);

            GoalUp.ball_hit.connect(&respawn_ball);
            GoalDown.ball_hit.connect(&respawn_ball);
            GoalUp.ball_hit.connect(&Player2.score);
            GoalDown.ball_hit.connect(&Player1.score);

            Platform.get.key.connect(&key_handler);
        }

        void end_game()
        {
            ActorManager.get.clear();
            Player1.die();
            Player2.die();

            Platform.get.key.disconnect(&key_handler);
        }

        Ball ball()
        {
            return GameBall;
        }

        void draw()
        {
            uint score1 = Player1.score;
            uint score2 = Player2.score;
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
            GameBall.die();
            spawn_ball(BallSpeed);
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
            GameBall = new Ball(Vector2f(400.0, 300.0), direction * speed, 
                                BallRadius);
        }

        void key_handler(KeyState state, Key key, dchar unicode)
        {
            if(state == KeyState.Pressed)
            {
                switch(key)
                {
                    case Key.Escape:
                        Continue = false;
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

class Menu
{
    mixin Singleton;
    private:
        EventCounter FPSCounter;
        bool RunPong = false;
        bool Continue = true;

        GUIElement MenuGUI;
        GUIButton StartButton;
        GUIButton ExitButton;

    public:

        ///Initialize Pong.
        this()
        {
            singleton_ctor();
            ActorManager.initialize!(ActorManager);
            GUIRoot.initialize!(GUIRoot);
            VideoDriver.get.set_video_mode(800, 600, ColorFormat.RGBA_8, 
                                                false);

            //Update FPS every second
            FPSCounter = new EventCounter(1.0);
            FPSCounter.update.connect(&fps_update);



            uint width = VideoDriver.get.screen_width;
            uint height = VideoDriver.get.screen_height;
            MenuGUI = new GUIElement(GUIRoot.get, 
                                     Vector2i(width - 176, 16),
                                     Vector2u(160, height - 32));
            StartButton = new GUIButton(MenuGUI, Vector2i(8, 144),
                                        Vector2u(144, 24), "Player vs AI");
            ExitButton = new GUIButton(MenuGUI, Vector2i(8, 144 + 32),
                                       Vector2u(144, 24), "Quit game");

            Platform.get.mouse_motion.connect(&GUIRoot.get.mouse_move);
            Platform.get.mouse_key.connect(&GUIRoot.get.mouse_key);
            StartButton.pressed.connect(&pong_start);
            ExitButton.pressed.connect(&exit);
        }

        void die()
        {
            VideoDriver.get.die();
            Platform.get.die();
            FPSCounter.update.disconnect(&fps_update);
            GUIRoot.get.die();
        }

        void run()
        {                           
            Platform.get.key.connect(&key_handler);
            while(Platform.get.run() && Continue)
            {
                //Count this frame
                FPSCounter.event();
                if(RunPong && !Pong.get.run())
                {
                    pong_end();
                }

                //update game state
                ActorManager.get.update();
                VideoDriver.get.start_frame();
                if(RunPong)
                {
                    Pong.get.draw();
                }
                else
                {
                    draw();
                }
                GUIRoot.get.draw();
                ActorManager.get.draw();
                VideoDriver.get.end_frame();

            }
            Pong.get.die();
            writefln("FPS statistics:\n", FPSCounter.statistics, "\n");
            writefln("ActorManager statistics:\n", 
                     ActorManager.get.statistics, "\n");
        }

        void draw()
        {
        }

    private:
        void pong_end()
        {
            Pong.get.end_game();
            Platform.get.key.connect(&key_handler);
            GUIRoot.get.add_child(MenuGUI);
            RunPong = false;
        }

        void pong_start()
        {
            RunPong = true;
            GUIRoot.get.remove_child(MenuGUI);
            Platform.get.key.disconnect(&key_handler);
            Pong.get.start_game();
        }

        void exit()
        {
            Continue = false;
        }

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

        void fps_update(real fps)
        {
            Platform.get.window_caption = "FPS: " ~
                                               std.string.toString(fps);
        }
}

void main()
{
    Time.initialize!(Time);
    Platform.initialize!(SDLPlatform);
    VideoDriver.initialize!(GLVideoDriver);

    try
    {
        Menu.initialize!(Menu);
        Pong.initialize!(Pong);
        Menu.get.run();
        Menu.get.die();
    }
    catch(Exception e)
    {
        writefln("ERROR: ", e.toString());
        exit(-1);
    }
}                                     
