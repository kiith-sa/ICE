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
import physics.physicsbody;
import physics.collisionaabbox;
import physics.collisioncircle;
import physics.contact;
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
import weaksingleton;
import color;


///A wall of game area.
class Wall : Actor
{
    protected:
        //Area taken up by the wall
        Rectanglef box_;

    public:
        ///Emitted when a ball hits the wall. Will emit const BallBody after D2 move.
        mixin Signal!(BallBody) ball_hit;

        ///Construct a wall with specified position and box.
        this(Vector2f position, Rectanglef box, PhysicsBody physics_body = null)
        {
            box_ = box;
            auto aabbox = new CollisionAABBox(box.min, box.max - box.min);
            
            if(physics_body is null)
            {
                physics_body = new PhysicsBody(aabbox, position, 
                                               Vector2f(0.0f, 0.0f), real.infinity);
            }
            super(physics_body);
        }

        override void draw()
        {
            static c = Color(240, 255, 240, 255);
            Vector2f position = physics_body_.position;
            VideoDriver.get.draw_rectangle(position + box_.min, position + box_.max);
        }

        override void update()
        {
            foreach(collider; physics_body_.colliders)
            {
                if(collider.classinfo == BallBody.classinfo)
                {
                    ball_hit.emit(cast(BallBody)collider);
                }
            }
        }

        ///Set wall velocity.
        void velocity(Vector2f v){physics_body_.velocity = v;}
}             

/**
 * Physics body of a paddle. 
 *
 * Contains functionality to make Arkanoid style ball reflection possible.
 */
class PaddleBody : PhysicsBody
{
    private:
        //Max ratio of X and Y speed when reflecting the ball,
        //i.e., if this is 1.0, and the ball gets reflected from
        //the corner of the paddle, ratio of X and Y members of
        //reflected ball velocity will be 1:1.
        real max_xy_ratio_ = 1.0;

        //Limits of paddle body movement in world space.
        Rectanglef limits_;

    public:
        /**
         * Construct a paddle body with specified parameters.
         *
         * Params:  position = Starting position of the body.
         *          velocity = Starting velocity of the body.
         *          mass     = Mass of the body.
         *          box      = Rectangle representing aligned bounding box of the
         *                     body in world space.
         */
        this(Vector2f position, Vector2f velocity, real mass, ref Rectanglef box, 
             ref Rectanglef limits)
        {
            auto aabbox = new CollisionAABBox(box.min, box.max - box.min); 
            super(aabbox, position, velocity, mass);
            limits_ = limits;
        }

        /**
         * Return velocity to reflect given BallBody at.
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

        override void update()
        {
            //keep the paddle within the limits
            Rectanglef box = aabbox;
            Rectanglef position_limits = Rectanglef(limits_.min - box.min,
                                                    limits_.max - box.max);
            position = position_limits.clamp(position);

            super.update();
        }

        ///Return limits of movement of this paddle body.
        public Rectanglef limits(){return limits_;}

    private:
        ///Return rectangle representing bounding box of this body in world space.
        Rectanglef aabbox()
        in
        {
            //checking here because invariant can't call public function members
            assert(collision_volume.classinfo == CollisionAABBox.classinfo,
                   "Collision volume of a paddle must be an axis aligned bounding box");
        }
        body{return (cast(CollisionAABBox)collision_volume).bounding_box;}
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
    }

    private:
        //Speed of this paddle
        real speed_;

        //Particle trail of the paddle
        LineEmitter emitter_;
    public:
        ///Construct a paddle with specified parameters.
        this(Vector2f position, ref Rectanglef box, ref Rectanglef limits, real speed)
        {
            super(position, box, 
                  new PaddleBody(position, Vector2f(0.0f, 0.0f), real.infinity, box, limits));
            speed_ = speed;

            emitter_ = new LineEmitter(this);
            with(emitter_)
            {
                particle_life = 3.0;
                emit_frequency = 30;
                emit_velocity = Vector2f(speed * 0.15, 0.0);
                angle_variation = 2 * PI;
                line_length = 2.0;
                line_width = 1;
                start_color = Color(255, 255, 255, 64);
                end_color = Color(64, 64, 255, 0);
            }
        }

        ///Return limits of movement of this paddle.
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
        float radius_;

    public:
        /**
         * Construct a ball body with specified parameters.
         *
         * Params:  position = Starting position of the body.
         *          velocity = Starting velocity of the body.
         *          mass     = Mass of the body.
         *          radius   = Radius of a circle representing bounding circle
         *                     of this body (centered at body's position).
         */
        this(Vector2f position, Vector2f velocity, real mass, float radius)
        {
            radius_ = radius;
            auto circle = new CollisionCircle(Vector2f(0.0f, 0.0f), radius);
            super(circle, position, velocity, mass);
        }

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

        ///Returns radius of this ball body.
        float radius(){return radius_;}
}

///A ball that can bounce off other objects.
class Ball : Actor
{
    private:
        //Particle trail of the ball
        LineEmitter emitter_;

        //Speed of particles emitted by the ball
        real particle_speed_;

        //Line trail of the ball (particle effect)
        LineTrail trail_;
    public:
        ///Construct a ball with specified parameters.
        this(Vector2f position, Vector2f velocity, float radius)
        {
            super(init_body(position, velocity, radius));

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
                emit_velocity = -this.physics_body_.velocity.normalized * particle_speed_;
                angle_variation = PI / 4;
                line_length = 2.0;
                line_width = 1;
                start_color = Color(224, 224, 255, 32);
                end_color = Color(224, 224, 255, 0);
            }
        }

        ///Destroy this ball.
        override void die()
        {
            trail_.life_time = 0.5;
            trail_.detach();
            emitter_.life_time = 2.0;
            emitter_.emit_frequency = 0.0;
            emitter_.detach();
            super.die();
        }
 
        ///Return the radius of this ball.
        float radius(){return (cast(BallBody)physics_body_).radius;}

        override void update()
        {
            //Ball can only change direction after a collision
            if(physics_body_.collided())
            {
                emitter_.emit_velocity = -physics_body_.velocity.normalized * particle_speed_;
            }
        }

        override void draw()
        {
            auto driver = VideoDriver.get;
            Vector2f position = physics_body_.position;
            driver.line_aa = true;
            driver.line_width = 3;
            driver.draw_circle(position, radius - 2, Color(240, 240, 255, 255), 4);
            driver.line_width = 1;
            driver.draw_circle(position, radius, Color(192, 192, 255, 192));
            driver.line_width = 1;                  
            driver.line_aa = false;
        }

    protected:
        /**
         * Initializes and returns physics body to be used by this ball.
         *
         * Params:  position = Starting position of the body.
         *          velocity = Starting velocity of the body.
         *          radius   = Radius of the body.
         * 
         * Returns: Physics body to use.
         */
        PhysicsBody init_body(Vector2f position, Vector2f velocity, float radius)
        {
            return new BallBody(position, velocity, 100.0, radius);
        }
}

/**
 * Physics body of a dummy ball. 
 *
 * Limits dummy ball speed to prevent it being thrown out of the gameplay
 * area after collision with a ball. (normal ball has no limits- it's speed
 * can change, slightly, by collisions with dummy balls)
 */
class DummyBallBody : BallBody
{
    public:
        /**
         * Construct a dummy ball body with specified parameters.
         *
         * Params:  position = Starting position of the body.
         *          velocity = Starting velocity of the body.
         *          mass     = Mass of the body.
         *          radius   = Radius of a circle representing bounding circle
         *                     of this body (centered at body's position).
         */
        this(Vector2f position, Vector2f velocity, real mass, float radius)
        {
            super(position, velocity, mass, radius);
        }

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
}

///A dummy ball that doesn't affect gameplay, only exists for graphics effect.
class DummyBall : Ball
{
    public:
        /**                                               
         * Construct a dummy ball with specified parameters.
         *
         * Params:    position = Position to spawn the ball at.
         *            velocity = Starting velocity of the ball.
         */
        this(Vector2f position, Vector2f velocity)
        {
            super(position, velocity, 5.0);

            physics_body_.mass = 2;
            trail_.start_color = Color(240, 240, 255, 8);
            with(emitter_)
            {
                start_color = Color(240, 240, 255, 6);
                line_length = 3.0;
                emit_frequency = 24;
            }
        }

        ///Overrides parent draw() so that we don't draw the ball itself.
        override void draw(){}

    protected:
        override PhysicsBody init_body(Vector2f position, Vector2f velocity, float radius)
        {
            return new DummyBallBody(position, velocity, 100.0, radius);
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
        void score(BallBody ball_body){score_++;}

        ///Get score of this player.
        int score(){return score_;}

        ///Get name of this player.
        string name(){return name_;}

        /**
         * Update the player state.
         * 
         * Params:  game = Reference to the game that updates the player.
         */
        void update(Game game){}

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

        override void update(Game game)
        {
            if(update_timer_.expired())
            {
                update_timer_.reset();
                real frame_length = ActorManager.get.time_step;

                //currently only support zero or one ball
                Ball[] balls = game.balls;
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
class ScoreScreen
{
    private:
        alias std.string.toString to_string;  
        
        //score screen ends when this timer expires.
        Timer timer_;

        GUIElement container_;

        GUIStaticText winner_text_;
        GUIStaticText names_text_;
        GUIStaticText scores_text_;
        GUIStaticText time_text_;

    public:
        mixin Signal!() expired;

        /**
         * Construct a score screen.
         *
         * Params: container = GUI element to use as container in which score screen
         *                     widgets will be placed.
         *         player_1  = First player of the game.
         *         player_2  = Second player of the game.
         *         time      = Time the game took in seconds.
         */
        this(GUIElement container, Player player_1, Player player_2, real time)
        in
        {
            assert(player_1.score != player_2.score, 
                   "Score screen shown but neither of the players is victorious");
        }
        body
        {
            container_ = container;

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
                width = "p_right - p_left";
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

        void update()
        {
            if(timer_.expired){expired.emit();}
        }

        void die()
        {
            GUIRoot.get.remove_child(container_);
            container_.die();
        }
        
    private:
        //Initialize players/scores list.
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
            super(null);

            ball_speed_ = ball_speed;
            timer_ = Timer(time, ActorManager.get.game_time);
            //leave a third of time without the rays effect to give time
            //to the player
            light_speed_ = (2 * PI) / (time * 0.70);

            generate_directions(spread);
        }

        void update()
        {
            if(timer_.expired(ActorManager.get.game_time))
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
            light_ += light_speed_ * ActorManager.get.time_step();
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

///In game HUD.
class HUD
{
    private:
        alias std.string.toString to_string;  
     
        //Displays players' scores.
        GUIStaticText score_text_1_, score_text_2_;
        //Displays time left.
        GUIStaticText time_text_;

        //Maximum time the game can take.
        real time_limit_;

    public:
        /**
         * Constructs HUD with specified parameters.
         *
         * Params:    time_limit = Maximum time the game will take.
         */
        this(real time_limit)
        {
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

            GUIRoot.get.add_child(score_text_1_);
            GUIRoot.get.add_child(score_text_2_);
            GUIRoot.get.add_child(time_text_);
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
            static Color color_end = Color(255, 0, 0, 255);
            //only update if the text has changed
            if(time_str != time_text_.text)
            {
                time_text_.text = time_str != "0:0" 
                                  ? time_str : time_str ~ " !";

                real t = time_left / time_limit_;
                time_text_.text_color = color_start.interpolated(color_end, t);
            }

            //update score displays
            string score_str_1 = player_1.name ~ ": " ~ to_string(player_1.score);
            string score_str_2 = player_2.name ~ ": " ~ to_string(player_2.score);
            //only update if the text has changed
            if(score_text_1_.text != score_str_1){score_text_1_.text = score_str_1;}
            if(score_text_2_.text != score_str_2){score_text_2_.text = score_str_2;}
        }

        ///Destroy the HUD.
        void die()
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
}

class Game
{
    mixin WeakSingleton;
    private:
        Ball ball_;
        real ball_radius_ = 6.0;
        real ball_speed_ = 185.0;

        real spawn_time_ = 4.0;
        real spawn_spread_ = 0.28;

        DummyBall[] dummies_;
        uint dummy_count_ = 55;

        Wall wall_right_, wall_left_; 
        Wall goal_up_, goal_down_; 
        Paddle paddle_1_, paddle_2_;

        Player player_1_, player_2_;

        //Continue running?
        bool continue_;

        uint score_limit_;
        real time_limit_;
        Timer game_timer_;

        ScoreScreen score_screen_;

        HUD hud_;

        //true while the players are playing the game
        bool playing_;
        bool started_;

        Timer intro_timer_;

    public:
        this(){singleton_ctor();}

        bool run()
        {
            if(playing_)
            {
                real time_left = time_limit_ - 
                                 game_timer_.age(ActorManager.get.game_time);
                hud_.update(time_left, player_1_, player_2_);

                //update player state
                player_1_.update(this);
                player_2_.update(this);

                //check for victory conditions
                if(player_1_.score >= score_limit_ || 
                   player_2_.score >= score_limit_)
                {
                    game_won();
                }
                if(game_timer_.expired(ActorManager.get.game_time))
                {
                    if(player_1_.score != player_2_.score){game_won();}
                }
            }

            if(score_screen_ !is null){score_screen_.update();}

            if(!started_ && intro_timer_.expired(ActorManager.get.game_time))
            {
                start_game();
            }

            return continue_;
        }

        void die(){singleton_dtor();}

        void intro()
        {
            intro_timer_ = Timer(2.5, ActorManager.get.game_time);
            playing_ = started_ = false;
            continue_ = true;

            auto wall_rect = Rectanglef(0.0, 0.0, 32.0, 536.0);
            wall_left_ = new Wall(Vector2f(-64.0, 32.0), wall_rect);
            wall_left_.velocity = Vector2f(73.6, 0.0);
            wall_right_ = new Wall(Vector2f(832.0, 32.0), wall_rect);
            wall_right_.velocity = Vector2f(-73.6, 0.0);

            auto goal_rect = Rectanglef(0.0, 0.0, 560.0, 28.0);
            goal_up_ = new Wall(Vector2f(-680.0, 4.0), goal_rect);
            goal_up_.velocity = Vector2f(320.0, 0.0);
            goal_down_ = new Wall(Vector2f(920.0, 568.0), goal_rect);
            goal_down_.velocity = Vector2f(-320.0, 0.0);

            auto size = Rectanglef(-32, -8, 32, 8); 
            auto limits1 = Rectanglef(152 + ball_radius_ * 2, 36, 
                                      648 - ball_radius_ * 2, 76); 
            paddle_1_ = new Paddle(Vector2f(400, 56), size, limits1, 135);
            auto limits2 = Rectanglef(152 + ball_radius_ * 2, 524, 
                                      648 - ball_radius_ * 2, 564); 
            paddle_2_ = new Paddle(Vector2f(400, 544), size, limits2, 135);

            player_1_ = new AIPlayer("AI", paddle_1_, 0.15);
            player_2_ = new HumanPlayer("Human", paddle_2_);

            Platform.get.key.connect(&key_handler);
        }

        void start_game()
        {
            for(uint dummy = 0; dummy < dummy_count_; dummy++)
            {
                dummies_ ~= new DummyBall(random_position!(float)(Vector2f(400.0f, 300.0f),
                                                                  12.0f),
                                          2.5 * ball_speed_ * random_direction!(float)());
            }

            //should be set from options and INI when that is implemented.
            score_limit_ = 10;
            time_limit_ = 300;
            started_ = playing_ = true;

            wall_left_.velocity = Vector2f(0.0, 0.0);
            wall_right_.velocity = Vector2f(0.0, 0.0);
            goal_up_.velocity = Vector2f(0.0, 0.0);
            goal_down_.velocity = Vector2f(0.0, 0.0);

            auto spawner = new BallSpawner(spawn_time_, spawn_spread_, ball_speed_);
            spawner.spawn_ball.connect(&spawn_ball);

            goal_up_.ball_hit.connect(&player_2_.score);
            goal_down_.ball_hit.connect(&player_1_.score);
            goal_up_.ball_hit.connect(&destroy_ball);
            goal_down_.ball_hit.connect(&destroy_ball);

            hud_ = new HUD(time_limit_);

            game_timer_ = Timer(time_limit_, ActorManager.get.game_time);
        }

        ///Returns an array of balls currently used in the game.
        Ball[] balls()
        {
            Ball[] output;
            if(ball_ !is null){output ~= ball_;}
            return output;
        }

        void draw(){}

    private:
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
            GUIElement container;
            with(new GUIElementFactory)
            {
                x = "p_right / 2 - 192";
                y = "p_bottom / 2 - 128";
                width = "384";
                height = "256";
                container = produce();
            }
            GUIRoot.get.add_child(container);
            //show the score screen and end the game after it expires
            score_screen_ = new ScoreScreen(container, player_1_, player_2_,
                                            game_timer_.age(ActorManager.get.game_time));
            score_screen_.expired.connect(&end_game);
            ActorManager.get.time_speed = 0.0;

            playing_ = false;
        }

        void end_game()
        {
            if(started_)
            {
                hud_.die();
                hud_ = null;
                if(score_screen_ !is null)
                {
                    score_screen_.die();
                    score_screen_ = null;
                }
                ActorManager.get.time_speed = 1.0;
            }

            ActorManager.get.clear();
            player_1_.die();
            player_2_.die();

            playing_ = continue_ = false;

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
class Credits
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

        GUIElement container_;
        GUIButton close_button_;
        GUIStaticText text_;

    public:
        ///Emitted when this credits dialog is closed.
        mixin Signal!() closed;

        /**
         * Construct a Credits screen.
         *
         * Params:  container = GUI element used as a container for the credits GUI elements.
         */
        this(GUIElement container)
        {
            container_ = container;

            with(new GUIStaticTextFactory)
            {
                x = "p_left + 16";
                y = "p_top + 16";
                width = "p_right - p_left - 32";
                height = "p_bottom - p_top - 56";
                text = credits_;
                this.text_ = produce();
            }

            with(new GUIButtonFactory)
            {
                x = "p_left + (p_right - p_left) / 2 - 72";
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
            GUIRoot.get.remove_child(container_);
            container_.die();
        }
}

class Pong
{
    mixin WeakSingleton;
    private:
        EventCounter fps_counter_;
        bool run_pong_ = false;
        bool continue_ = true;

        GUIElement menu_container_;
        GUIMenu menu_;
        Game game;

        Credits credits_;

    public:
        ///Initialize Pong.
        this()
        {
            singleton_ctor();

            ActorManager.initialize!(ActorManager);
            GUIRoot.initialize!(GUIRoot);
            VideoDriver.get.set_video_mode(800, 600, ColorFormat.RGBA_8, false);

            game = new Game;

            //Update FPS every second
            fps_counter_ = new EventCounter(1.0);
            fps_counter_.update.connect(&fps_update);

            uint width = VideoDriver.get.screen_width;
            uint height = VideoDriver.get.screen_height;

            with(new GUIElementFactory)
            {
                x = "p_right - 176";
                y = "16";
                width = "160";
                height = "p_bottom - 32";
                menu_container_ = produce();
            }

            GUIRoot.get.add_child(menu_container_);

            with(new GUIMenuFactory)
            {
                x = "p_left";
                y = "p_top + 136";
                item_width = "144";
                item_height = "24";
                item_spacing = "8";
                add_item("Player vs AI", &pong_start);
                add_item("Credits", &credits_start);
                add_item("Quit", &exit);
                menu_ = produce();
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

            singleton_dtor();
        }

        void run()
        {                           
            Platform.get.key.connect(&key_handler_global);
            Platform.get.key.connect(&key_handler);
            while(Platform.get.run() && continue_)
            {
                //Count this frame
                fps_counter_.event();

                if(run_pong_ && !game.run()){pong_end();}

                //update game state
                ActorManager.get.update();
                GUIRoot.get.update();

                VideoDriver.get.start_frame();

                if(run_pong_){game.draw();}
                else{draw();}

                ActorManager.get.draw();
                GUIRoot.get.draw();
                VideoDriver.get.end_frame();
            }
            game.die();
            writefln("FPS statistics:\n", fps_counter_.statistics, "\n");
            writefln("ActorManager statistics:\n", ActorManager.get.statistics, "\n");
        }

        void draw(){}

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
            game.intro();
        }

        void credits_start()
        {
            menu_container_.hide();
            Platform.get.key.disconnect(&key_handler);

            GUIElement container;
            with(new GUIElementFactory)
            {
                x = "p_left + 96";
                y = "p_top + 16";
                width = "p_right - 192";
                height = "p_bottom - 32";
                container = produce();
            }
            GUIRoot.get.add_child(container);
            credits_ = new Credits(container);
            credits_.closed.connect(&credits_end);
        }

        void credits_end()
        {
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
        Pong pong = new Pong;
        pong.run();
        pong.die();
    }
    catch(Exception e)
    {
        writefln("ERROR: ", e.toString());
        exit(-1);
    }
}                                     
