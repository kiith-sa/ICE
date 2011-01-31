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
import actor.actorcontainer;
import actor.particleemitter;
import actor.lineemitter;
import actor.linetrail;
import physics.physicsengine;
import physics.physicsbody;
import physics.collisionaabbox;
import physics.collisioncircle;
import physics.contact;
import gui.guielement;
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
import factory;


///A rectangular wall in the game area.
class Wall : Actor
{
    protected:
        //Area taken up by the wall
        Rectanglef box_;

    public:
        ///Emitted when a ball hits the wall. Will emit const BallBody after D2 move.
        mixin Signal!(BallBody) ball_hit;

        ///Set wall velocity.
        void velocity(Vector2f v){physics_body_.velocity = v;}

    protected:
        /*
         * Construct a wall with specified parameters.
         *
         * Params:  container    = Container to manage the wall.
         *          physics_body = Physics body of the wall.
         *          box          = Rectangle used for graphical representation of the
         *                         wall.
         */
        this(ActorContainer container, PhysicsBody physics_body, ref Rectanglef box)
        {
            super(container, physics_body);
            box_ = box;
        }

        override void draw(VideoDriver driver)
        {
            static c = Color(240, 255, 240);
            Vector2f position = physics_body_.position;
            driver.draw_rectangle(position + box_.min, position + box_.max);
        }

        override void update(real time_step, real game_time)
        {
            foreach(collider; physics_body_.colliders)
            {
                if(collider.classinfo == BallBody.classinfo)
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
 *                    Default: Vector2f(0.0f, 0.0f)
 *          box_max = Maximum extent of the wall relative to its position.
 *                    Default: Vector2f(1.0f, 1.0f)
 */
abstract class WallFactoryBase(T) : ActorFactory!(T)
{
    mixin(generate_factory("Vector2f $ box_min $ Vector2f(0.0f, 0.0f)", 
                           "Vector2f $ box_max $ Vector2f(1.0f, 1.0f)"));
    private:
        //Get a collision aabbox based on factory parameters. Used in produce().
        CollisionAABBox bbox(){return new CollisionAABBox(box_min_, box_max_ - box_min_);}
        //Get a bounds rectangle based on factory parameters. Used in produce().
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

        override void update(real time_step)
        {
            //keep the paddle within the limits
            Rectanglef box = aabbox;
            Rectanglef position_limits = Rectanglef(limits_.min - box.min,
                                                    limits_.max - box.max);
            position = position_limits.clamp(position);

            super.update(time_step);
        }

        ///Return limits of movement of this paddle body.
        public Rectanglef limits(){return limits_;}

    protected:
        /*
         * Construct a paddle body with specified parameters.
         *
         * Params:  aabbox   = Collision aabbox of the body. 
         *          position = Starting position of the body.
         *          velocity = Starting velocity of the body.
         *          mass     = Mass of the body.
         *          limits   = Limits of body's movement
         */
        this(CollisionAABBox aabbox,Vector2f position, Vector2f velocity, 
             real mass, ref Rectanglef limits)
        {
            super(aabbox, position, velocity, mass);
            limits_ = limits;
        }

    private:
        ///Return rectangle representing bounding box of this body in world space.
        Rectanglef aabbox()
        in
        {
            //checking here because invariant can't call public function members
            assert(collision_volume.classinfo == CollisionAABBox.classinfo,
                   "Collision volume of a paddle must be an axis aligned bounding box");
        }
        body{return(cast(CollisionAABBox)collision_volume).bounding_box;}
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

        //Particle emitter of the paddle
        ParticleEmitter emitter_;

    public:
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

    protected:
        /*
         * Construct a paddle with specified parameters.
         *
         * Params:  container    = Container to manage this actor.
         *          physics_body = Physics body of the paddle.
         *          box          = Rectangle used for graphics representation of the paddle.
         *          speed        = Speed of paddle movement.
         *          emitter      = Particle emitter of the paddle.
         */
        this(ActorContainer container, PaddleBody physics_body, ref Rectanglef box,
             real speed, ParticleEmitter emitter)
        {
            super(container, physics_body, box);
            speed_ = speed;
            emitter_ = emitter;
            emitter.attach(this);
        }
}

/**
 * Factory used to construct paddles.
 *
 * Params:  limits_min = Minimum extent of paddle movement limits in world space.
 *                       Default: Vector2f(-2.0f, -2.0f)
 *          limits_max = Maximum extent of paddle movement limits in world space.
 *                       Default: Vector2f(2.0f, 2.0f)
 *          speed      = Speed of paddle movement.
 *                       Default: 135.0
 */
class PaddleFactory : WallFactoryBase!(Paddle)
{
    mixin(generate_factory("Vector2f $ limits_min $ Vector2f(-2.0f, -2.0f)", 
                           "Vector2f $ limits_max $ Vector2f(2.0f, 2.0f)",
                           "real $ speed $ 135.0"));

    public override Paddle produce(ActorContainer container)
    {
        auto limits = Rectanglef(limits_min_, limits_max_);
        auto physics_body = new PaddleBody(bbox, position_, velocity_, real.infinity,
                                           limits);

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

        ///Returns radius of this ball body for drawing.
        float radius(){return radius_;}

    protected:
        /**
         * Construct a ball body with specified parameters.
         *
         * Params:  circle   = Collision circle of the ball.
         *          position = Starting position of the body.
         *          velocity = Starting velocity of the body.
         *          mass     = Mass of the body.
         *          radius   = Radius of a circle representing bounding circle
         *                     of this body (centered at body's position).
         */
        this(CollisionCircle circle, Vector2f position, Vector2f velocity, 
             real mass, float radius)
        {
            radius_ = radius;
            super(circle, position, velocity, mass);
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
         *          position = Starting position of the body.
         *          velocity = Starting velocity of the body.
         *          mass     = Mass of the body.
         *          radius   = Radius of a circle representing bounding circle
         *                     of this body (centered at body's position).
         */
        this(CollisionCircle circle, Vector2f position, Vector2f velocity, 
             real mass, float radius)
        {
            super(circle, position, velocity, mass, radius);
        }

}

///A ball that can bounce off other objects.
class Ball : Actor
{
    private:
        //Particle trail of the ball.
        ParticleEmitter emitter_;
        //Speed of particles emitted by the ball.
        float particle_speed_;
        //Line trail of the ball (particle effect).
        LineTrail trail_;
        //Draw the ball itself or only the particle systems?
        bool draw_ball_;

    public:
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

    protected:
        /*
         * Construct a ball with specified parameters.
         *
         * Params:  container      = Container to manage this actor.
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
            //Ball can only change direction after a collision
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
 *                           Default: Vector2f(-2.0f, -2.0f)
 *          particle_speed = Speed of particles in the ball's particle trail.
 *                           Default: Vector2f(-2.0f, -2.0f)
 */
class BallFactory : ActorFactory!(Ball)
{
    mixin(generate_factory("float $ radius $ 6.0f",
                           "float $ particle_speed $ 25.0f"));
    private:
        //factory for ball line trail
        LineTrailFactory trail_factory_;
        //factory for ball particle trail
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
        //Construct collision circle with factory parameters.
        final CollisionCircle circle()
        {
            return new CollisionCircle(Vector2f(0.0f, 0.0f), radius_);
        }

        //Construct ball body with factory parameters.
        BallBody ball_body()
        {
            return new BallBody(circle, position_, velocity_, 100.0, radius_);
        }

        //Adjust particle effect factories. Used by derived classes.
        void adjust_factories(){};

        //Determine if the produced ball should draw itself, instead of just particle systems.
        bool draw_ball(){return true;}
}             

///Factory used to produce dummy balls.
class DummyBallFactory : BallFactory
{
    protected:
        override BallBody ball_body()
        {
            return new DummyBallBody(circle, position_, velocity_, 2.0, radius_);
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
        //Position of the ball during last AI update.
        Vector2f ball_last_;

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

                //currently only support zero or one ball
                Ball[] balls = game.balls;
                assert(balls.length <= 1, 
                       "AI supports only zero or one ball at the moment");
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

        //Parent of the score screen container.
        GUIElement parent_;

        //Container of all score screen GUI elements.
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
            parent_.remove_child(container_);
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

/**
 * Handles ball respawning and related effects.
 *
 * When the spawner is created, it generates a set of directions the ball
 * can be spawned at, in roughly the same direction (determined by specified spread)
 * Then, during its lifetime, it displays the directions to the player 
 * (as rays), gives the player a bit of time and spawns the ball with one
 * of generated directions.
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

    protected:
        /*
         * Constructs a BallSpawner with specified parameters.
         * 
         * Params:    container  = Container to manage this actor.
         *            timer      = Ball will be spawned when this timer (game time) expires.
         *                         70% of the time will be taken by the rays effect.
         *            spread     = "Randomness" of the spawn directions.
         *                         Zero will result in only one definite direction,
         *                         1 will result in completely random direction
         *                         (except for horizontal directions that are 
         *                         disallowed to prevent ball from getting stuck)
         *            ball_speed = Speed to spawn the ball at.
         */
        this(ActorContainer container, Timer timer, real spread, real ball_speed)
        in{assert(spread >= 0.0, "Negative ball spawning spread");}
        body
        {                
            super(container, new PhysicsBody(null, Vector2f(400.0f, 300.0f), 
                                             Vector2f(0.0f, 0.0f), real.infinity));

            ball_speed_ = ball_speed;
            timer_ = timer;
            //leave a third of time without the rays effect to give time
            //to the player
            light_speed_ = (2 * PI) / (timer.delay * 0.70);

            generate_directions(spread);
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

        void draw(VideoDriver driver)
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

/**
 * Factory used to construct ball spawners.
 *
 * Params:  time       = Time to spawn the ball in.
 *                       Default: 5.0
 *          spread     = "Randomness" of the spawn directions.
 *                       Zero will result in only one definite direction,
 *                       1 will result in completely random direction
 *                       (except for horizontal directions that are 
 *                       disallowed to prevent ball from getting stuck)
 *                       Default: 0.25
 *          ball_speed = Speed of the spawned ball.
 *                       Default: 200
 */
final class BallSpawnerFactory : ActorFactory!(BallSpawner)
{
    mixin(generate_factory("real $ time $ 5.0",
                           "real $ spread $ 0.25",
                           "real $ ball_speed $ 200"));
    private:
        //Start time of the spawners' timer.
        real start_time_;
    public:
        /**
         * Construct a BallSpawnerFactory with specified start time.
         *
         * Params: start_time = Start time of the produced spawner.
         *                      The time when the ball will be spawned
         *                      is relative to this time.
         */
        this(real start_time){start_time_ = start_time;}

        override BallSpawner produce(ActorContainer container)
        {
            return new BallSpawner(container, Timer(time_, start_time_), spread_, ball_speed_);
        }
}


///In game HUD.
class HUD
{
    private:
        alias std.string.toString to_string;  
     
        //Parent of all the elements in the HUD.
        GUIElement parent_;

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
         * Params:  parent     = Parent GUI element for all the elements in the HUD.  
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
                time_text_.text = time_str != "0:0" 
                                  ? time_str : time_str ~ " !";

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
            parent_.remove_child(score_text_1_);
            score_text_1_.die();
            score_text_1_ = null;

            parent_.remove_child(score_text_2_);
            score_text_2_.die();
            score_text_2_ = null;

            parent_.remove_child(time_text_);
            time_text_.die();
            time_text_ = null;
        }
}

///Class holding all GUI used by Game (HUD, etc.).
class GameGUI
{
    private:
        //Parent of all game GUI elements.
        GUIElement parent_;
        //Game HUD.
        HUD hud_;
        //Score screen show at the end of game.
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
        }
}

class Game
{
    mixin WeakSingleton;
    private:
        ActorManager actor_manager_;
        
        Ball ball_;
        real ball_radius_ = 6.0;
        real ball_speed_ = 185.0;

        real spawn_time_ = 4.0;
        real spawn_spread_ = 0.28;

        Ball[] dummies_;
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

        ///GUI of the game, e.g. HUD, score screen
        GameGUI gui_;

        //true while the players are playing the game
        bool playing_;
        bool started_;

        Timer intro_timer_;

    public:
        bool run()
        {
            real time = actor_manager_.game_time;
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

            actor_manager_.update();

            return continue_;
        }

        void intro()
        {
            intro_timer_ = Timer(2.5, actor_manager_.game_time);
            playing_ = started_ = false;
            continue_ = true;

            with(new WallFactory)
            {
                box_max = Vector2f(32.0f, 536.0f);
                //walls slowly move into place when game starts
                velocity = Vector2f(73.6f, 0.0f);
                position = Vector2f(-64.0f, 32.0f);
                wall_left_ = produce(actor_manager_);

                velocity = Vector2f(-73.6f, 0.0f);
                position = Vector2f(832.0, 32.0f);
                wall_right_ = produce(actor_manager_);

                box_max = Vector2f(560.0f, 28.0f);
                velocity = Vector2f(320.0f, 0.0f);
                position = Vector2f(-680.0f, 4.0f);
                goal_up_ = produce(actor_manager_);

                velocity = Vector2f(-320.0f, 0.0f);
                position = Vector2f(920.0f, 568.0f);
                goal_down_ = produce(actor_manager_);
            }

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
                paddle_1_ = produce(actor_manager_);

                position = Vector2f(400.0f, 544.0f);
                limits_min = Vector2f(limits_min_x, 524.0f);
                limits_max = Vector2f(limits_max_x, 564.0f);
                paddle_2_ = produce(actor_manager_);
            }
            
            player_1_ = new AIPlayer("AI", paddle_1_, 0.15);
            player_2_ = new HumanPlayer("Human", paddle_2_);

            Platform.get.key.connect(&key_handler);
        }

        ///Returns an array of balls currently used in the game.
        Ball[] balls()
        {
            Ball[] output;
            if(ball_ !is null){output ~= ball_;}
            return output;
        }

        void draw(){actor_manager_.draw();}

    private:
        this(ActorManager actor_manager, GameGUI gui, uint score_limit, real time_limit)
        {
            singleton_ctor();
            gui_ = gui;
            actor_manager_ = actor_manager;
            score_limit_ = score_limit;
            time_limit_ = time_limit;
        }

        void die(){singleton_dtor();}

        ///Start the game, at specified game time
        void start_game(real start_time)
        {
            with(new DummyBallFactory)
            {
                radius = 5.0;

                for(uint dummy = 0; dummy < dummy_count_; dummy++)
                {
                    position = random_position!(float)(Vector2f(400.0f, 300.0f), 12.0f);
                    velocity = 2.5 * ball_speed_ * random_direction!(float)(); 
                    dummies_ ~= produce(actor_manager_);
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
                auto spawner = produce(actor_manager_);
                spawner.spawn_ball.connect(&spawn_ball);
            }

            goal_up_.ball_hit.connect(&player_2_.score);
            goal_down_.ball_hit.connect(&player_1_.score);
            goal_up_.ball_hit.connect(&destroy_ball);
            goal_down_.ball_hit.connect(&destroy_ball);

            gui_.show_hud();

            game_timer_ = Timer(time_limit_, start_time);
        }

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

            with(new BallSpawnerFactory(actor_manager_.game_time))
            {
                time = spawn_time_;
                spread = spawn_spread_;
                ball_speed = ball_speed_;
                auto spawner = produce(actor_manager_);
                spawner.spawn_ball.connect(&spawn_ball);
            }
        }

        void spawn_ball(Vector2f direction, real speed)
        {
            with(new BallFactory)
            {
                position = Vector2f(400.0, 300.0);
                velocity = direction * speed;
                radius = ball_radius_;
                ball_ = produce(actor_manager_);
            }
        }

        //Called when one of the players wins the game.
        void game_won()
        {
            //show the score screen and end the game after it expires
            gui_.show_scores(game_timer_.age(actor_manager_.game_time), 
                             player_1_, player_2_);
            gui_.score_expired.connect(&end_game);
            actor_manager_.time_speed = 0.0;

            playing_ = false;
        }

        void end_game()
        {
            if(started_){actor_manager_.time_speed = 1.0;}

            actor_manager_.clear();
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
                        if(equals(actor_manager_.time_speed, cast(real)0.0))
                        {
                            actor_manager_.time_speed = 1.0;
                        }
                        else{actor_manager_.time_speed = 0.0;}
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
        //Physics engine used by the actor manager.
        PhysicsEngine physics_engine_;
        //Actor manager used by the game.
        ActorManager actor_manager_;
        //GUI of the game.
        GameGUI gui_;
        //Game itself.
        Game game_;
        //Monitor monitoring game subsystems.
        Monitor monitor_;

    public:
        /**
         * Produce a Game and return a reference to it.
         *
         * Params:  monitor      = Monitor to monitor game subsystems.
         *          gui_parent   = Parent for all GUI elements used by the game.
         *          video_driver = VideoDriver used to draw the game.
         */
        Game produce(Monitor monitor, GUIElement gui_parent, VideoDriver video_driver)
        in
        {
            assert(physics_engine_ is null && 
                   actor_manager_ is null && 
                   game_ is null,
                   "Can't produce two games at once with GameContainer");
        }
        body
        {
            monitor_ = monitor;
            physics_engine_ = new PhysicsEngine;
            monitor_.add_monitorable("Physics", physics_engine_);
            actor_manager_ = new ActorManager(physics_engine_, video_driver);
            gui_ = new GameGUI(gui_parent, 300.0);
            game_ = new Game(actor_manager_, gui_, 2, 300.0);
            return game_;
        }

        ///Destroy the contained Game.
        void destroy()
        {
            game_.die();
            gui_.die();
            writefln("ActorManager statistics:\n", actor_manager_.statistics, "\n");
            actor_manager_.die();
            monitor_.remove_monitorable(physics_engine_);
            physics_engine_.die();
            game_ = null;
            actor_manager_ = null;
            physics_engine_ = null;
            monitor_ = null;
        }
}

///Credits screen.
class Credits
{
    private:
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

        //Parent of the container.
        GUIElement parent_;

        //GUI element containing all elements of the credits screen.
        GUIElement container_;
        GUIButton close_button_;
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
                x = "p_left + 96";
                y = "p_top + 16";
                width = "p_right - 192";
                height = "p_bottom - 32";
                container_ = produce();
            }
            parent_.add_child(container_);

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
            parent_.remove_child(container_);
            container_.die();
        }
}

///Class holding all GUI used by Pong (main menu, etc.).
class PongGUI
{
    private:
        //Parent of all Pong GUI elements.
        GUIElement parent_;

        //Monitor used for debugging, profiling, etc.
        Monitor monitor_;
        //Container of the main menu,
        GUIElement menu_container_;
        //Main menu.
        GUIMenu menu_;
        //Credits screen (null unless shown)
        Credits credits_;

    public:
        ///Emitted when the player hits the button to start the game.
        mixin Signal!() game_start;
        ///Emitted when the credits screen is opened.
        mixin Signal!() credits_start;
        ///Emitted when the credits screen is closed.
        mixin Signal!() credits_end;
        ///Emitted when the player hits the button to quit..
        mixin Signal!() quit;

        /**
         * Construct PongGUI with specified parameters.
         *
         * Params:  parent = GUI element to use as parent for all pong GUI elements.
         */
        this(GUIElement parent)
        {
            parent_ = parent;

            //Construct the monitor.
            with(new MonitorFactory)
            {
                x = "16";
                y = "16";
                width ="192 + w_right / 4";
                height ="168 + w_bottom / 6";
                add_monitorable("Video", VideoDriver.get);
                monitor_ = produce();
            }
            parent_.add_child(monitor_);
            //We don't want to see the monitor unless the user requests it.
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
                menu_ = produce();
            }
            menu_container_.add_child(menu_);
        }

        ///Destroy the PongGUI.
        void die()
        {
            parent_.remove_child(monitor_);
            parent_.remove_child(menu_container_);
            if(credits_ !is null)
            {
                credits_.die();
                credits_ = null;
            }
            monitor_.die();                   
            menu_container_.die();
            monitor_ = null;
            menu_container_ = null;
        }

        ///Get the monitor widget.
        Monitor monitor(){return monitor_;}

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
        EventCounter fps_counter_;
        bool run_pong_ = false;
        bool continue_ = true;

        GameContainer game_container_;
        Game game_;

        //Root of the GUI.
        GUIRoot gui_root_;

        //Pong GUI.
        PongGUI gui_;

    public:
        ///Initialize Pong.
        this()
        {
            singleton_ctor();

            VideoDriver.get.set_video_mode(800, 600, ColorFormat.RGBA_8, false);
            gui_root_ = new GUIRoot();

            game_container_ = new GameContainer();

            //Update FPS every second.
            fps_counter_ = new EventCounter(1.0);
            fps_counter_.update.connect(&fps_update);

            gui_ = new PongGUI(gui_root_.root);
            gui_.credits_start.connect(&credits_start);
            gui_.credits_end.connect(&credits_end);
            gui_.game_start.connect(&pong_start);
            gui_.quit.connect(&exit);
        }

        ///Destroy all subsystems.
        void die()
        {
            fps_counter_.update.disconnect(&fps_update);
            gui_.die();
            gui_root_.die();
            VideoDriver.get.die();
            Platform.get.die();
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

                if(run_pong_ && !game_.run()){pong_end();}

                //update game state
                gui_root_.update();

                VideoDriver.get.start_frame();

                if(run_pong_){game_.draw();}

                gui_root_.draw(VideoDriver.get);
                VideoDriver.get.end_frame();
            }
            writefln("FPS statistics:\n", fps_counter_.statistics, "\n");
        }

    private:
        void pong_end()
        {
            game_container_.destroy();
            game_ = null;
            Platform.get.key.connect(&key_handler);
            gui_.menu_show();
            run_pong_ = false;
        }

        void pong_start()
        {
            run_pong_ = true;
            gui_.menu_hide();
            Platform.get.key.disconnect(&key_handler);
            game_ = game_container_.produce(gui_.monitor, gui_root_.root,
                                            VideoDriver.get);
            game_.intro();
        }

        void credits_start(){Platform.get.key.disconnect(&key_handler);}

        void credits_end(){Platform.get.key.connect(&key_handler);}

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
                    case Key.F10:
                        gui_.monitor_toggle();
                        break;
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
