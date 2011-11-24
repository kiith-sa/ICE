//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Game class.
module pong.game;
@safe


import pong.player;
import pong.hud;
import pong.scorescreen;
import pong.ball;
import pong.wall;
import pong.paddle;
import pong.ballspawner;
import scene.scenemanager;
import physics.physicsbody;
import physics.physicsengine;
import spatial.spatialmanager;
import spatial.gridspatialmanager;

import gui.guielement;
import video.videodriver;
import platform.platform;
import time.timer;
import math.math;
import math.vector2;
import math.rectangle;
import monitor.monitormanager;
import util.signal;
import util.weaksingleton;


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
        this(GUIElement parent, in real time_limit)
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
        void show_scores(in real time_total, in Player player_1, in Player player_2)
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
        void update(in real time_left, in Player player_1, in Player player_2)
        {
            hud_.update(time_left, player_1, player_2);
            if(score_screen_ !is null){score_screen_.update();}
        }

        ///Destroy the game GUI.
        ~this()
        {
            clear(hud_);
            hud_ = null;
            if(score_screen_ !is null)
            {
                clear(score_screen_);
                score_screen_ = null;
            }
            score_expired.disconnect_all();
            parent_ = null;
        }
}

///Class managing a single game between players.
class Game
{
    mixin WeakSingleton;
    private:
        ///Platform used for input.
        Platform platform_;
        ///Scene manager.
        SceneManager scene_manager_;

        ///Game area in world space.
        static immutable Rectanglef game_area_ = Rectanglef(0.0f, 0.0f, 800.0f, 600.0f);
        
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
        immutable uint score_limit_;
        ///Time limit in game time.
        immutable real time_limit_;
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
            const real time = scene_manager_.game_time;
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
                if(game_timer_.expired(time) && player_1_.score != player_2_.score)
                {
                    game_won();
                }
            }

            if(continue_)
            {
                const real time_left = time_limit_ - game_timer_.age(time);
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
                box_max    = Vector2f(32.0f, 536.0f);
                //walls slowly move into place when game starts
                velocity   = Vector2f(73.6f, 0.0f);
                position   = Vector2f(-64.0f, 32.0f);
                wall_left_ = produce(scene_manager_);

                velocity    = Vector2f(-73.6f, 0.0f);
                position    = Vector2f(832.0, 32.0f);
                wall_right_ = produce(scene_manager_);

                box_max  = Vector2f(560.0f, 28.0f);
                velocity = Vector2f(320.0f, 0.0f);
                position = Vector2f(-680.0f, 4.0f);
                goal_up_ = produce(scene_manager_);

                velocity   = Vector2f(-320.0f, 0.0f);
                position   = Vector2f(920.0f, 568.0f);
                goal_down_ = produce(scene_manager_);
            }

            //construct paddles.
            const float limits_min_x = 152.0f + 2.0 * ball_radius_;
            const float limits_max_x = 648.0f - 2.0 * ball_radius_;
            with(new PaddleFactory)
            {
                box_min    = Vector2f(-32.0f, -4.0f);
                box_max    = Vector2f(32.0f, 4.0f);
                position   = Vector2f(400.0f, 56.0f);
                limits_min = Vector2f(limits_min_x, 36.0f);
                limits_max = Vector2f(limits_max_x, 76.0f);
                speed      = 135.0;
                paddle_1_  = produce(scene_manager_);

                position   = Vector2f(400.0f, 544.0f);
                limits_min = Vector2f(limits_min_x, 524.0f);
                limits_max = Vector2f(limits_max_x, 564.0f);
                paddle_2_  = produce(scene_manager_);
            }

            player_1_ = new AIPlayer("AI", paddle_1_, 0.15);
            player_2_ = new HumanPlayer(platform_, "Human", paddle_2_);

            platform_.key.connect(&key_handler);
        }

        ///Returns an array of balls currently used in the game.
        @property Ball[] balls()
        {
            return ball_ !is null ? [ball_] : [];
        }

        /**
         * Draw the game.
         *
         * Params:  driver = VideoDriver to draw with.
         */
        void draw(VideoDriver driver){scene_manager_.draw(driver);}

        ///Get game area.
        @property static Rectanglef game_area(){return game_area_;}

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
             in uint score_limit, in real time_limit)
        {
            singleton_ctor();
            gui_           = gui;
            platform_      = platform;
            scene_manager_ = scene_manager;
            score_limit_   = score_limit;
            time_limit_    = time_limit;
        }

        ///Destroy the Game.
        ~this(){singleton_dtor();}

        ///Start the game, at specified game time.
        void start_game(in real start_time)
        {
            //spawn dummy balls
            with(new DummyBallFactory)
            {
                radius = 6.0;

                foreach(dummy; 0 .. dummy_count_)
                {
                    position = random_position!(float)(game_area_.center, 26.0f);
                    velocity = 2.4 * ball_speed_ * random_direction!(float)(); 
                    dummies_ ~= produce(scene_manager_);
                }
            }

            //should be set from options and INI when that is implemented.
            started_ = playing_ = true;

            wall_left_.velocity  = Vector2f(0.0, 0.0);
            wall_right_.velocity = Vector2f(0.0, 0.0);
            goal_up_.velocity    = Vector2f(0.0, 0.0);
            goal_down_.velocity  = Vector2f(0.0, 0.0);
            
            with(new BallSpawnerFactory(start_time))
            {
                time         = spawn_time_;
                spread       = spawn_spread_;
                ball_speed   = this.ball_speed_;
                position     = game_area_.center;
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
                time         = spawn_time_;
                spread       = spawn_spread_;
                ball_speed   = this.ball_speed_;
                position     = game_area_.center;
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
                radius   = ball_radius_;
                ball_    = produce(scene_manager_);
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
            if(state == KeyState.Pressed) switch(key)
            {
                case Key.Escape:
                    end_game();
                    break;
                case Key.K_P: //pause
                    const paused = equals(scene_manager_.time_speed, cast(real)0.0);
                    scene_manager_.time_speed = paused ? 1.0 : 0.0;
                    break;
                default:
                    break;
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
        ///Scene manager used by the game.
        SceneManager scene_manager_;
        ///GUI of the game.
        GameGUI gui_;
        ///Game itself.
        Game game_;
        ///MonitorManager to add game subsystem monitors to.
        MonitorManager monitor_;

    public:
        /**
         * Produce a Game and return a reference to it.
         *
         * Params:  platform   = Platform to use for user input.
         *          monitor    = MonitorManager to monitor game subsystems.
         *          gui_parent = Parent for all GUI elements used by the game.
         *
         * Returns: Produced Game.
         */
        Game produce(Platform platform, MonitorManager monitor, GUIElement gui_parent)
        in
        {
            assert(spatial_physics_ is null && physics_engine_ is null && 
                   scene_manager_ is null && game_ is null,
                   "Can't produce two games at once with GameContainer");
        }
        body
        {
            monitor_ = monitor;
            spatial_physics_ = new GridSpatialManager!(PhysicsBody)
                                   (Vector2f(400.0f, 300.0f), 25.0f, 32);
            physics_engine_  = new PhysicsEngine(spatial_physics_);
            scene_manager_   = new SceneManager(physics_engine_);
            gui_             = new GameGUI(gui_parent, 300.0);
            game_            = new Game(platform, scene_manager_, gui_, 10, 300.0);
            monitor_.add_monitorable(spatial_physics_, "Spatial(P)");
            monitor_.add_monitorable(physics_engine_, "Physics");
            monitor_.add_monitorable(scene_manager_, "Scene");
            return game_;
        }

        ///Destroy the contained Game.
        void destroy()
        {
            clear(game_);
            clear(gui_);
            monitor_.remove_monitorable("Scene");
            scene_manager_.die();
            monitor_.remove_monitorable("Physics");
            physics_engine_.die();
            monitor_.remove_monitorable("Spatial(P)");
            clear(spatial_physics_);
            game_            = null;
            scene_manager_   = null;
            physics_engine_  = null;
            spatial_physics_ = null;
            monitor_         = null;
        }
}
