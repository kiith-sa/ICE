//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Game class.
module pong.game;


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
import math.rect;
import monitor.monitormanager;
import util.signal;
import util.weaksingleton;


/**
 * Class holding all GUI used by Game (HUD, etc.).
 *
 * Signal:
 *     public mixin Signal!() scoreExpired
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
        ScoreScreen scoreScreen_;

    public:
        ///Emitted when the score screen expires.
        mixin Signal!() scoreExpired;

        /**
         * Construct a GameGUI with specified parameters.
         *
         * Params:  parent     = GUI element to attach all game GUI elements to.
         *          timeLimit = Time limit of the game.
         */
        this(GUIElement parent, in real timeLimit)
        {
            parent_ = parent;
            hud_ = new HUD(parent, timeLimit);
            hud_.hide();
        }

        ///Show the HUD.
        void showHUD(){hud_.show();}

        /**
         * Show score screen.
         *
         * Should only be called at the end of game.
         * Hides the HUD. When the score screen expires,
         * scoreExpired is emitted.
         *
         * Params:  timeTotal = Total time the game took, in game time.
         *          player1   = First player of the game.
         *          player2   = Second player of the game.
         */
        void showScores(in real timeTotal, in Player player1, in Player player2)
        in{assert(scoreScreen_ is null, "Can't show score screen twice");}
        body
        {
            hud_.hide();
            scoreScreen_ = new ScoreScreen(parent_, player1, player2, timeTotal);
            scoreScreen_.expired.connect(&scoreExpired.emit);
        }

        /**
         * Update the game GUI.
         * 
         * Params:  timeLeft = Time left in the game, in game time.
         *          player1  = First player of the game.
         *          player2  = Second player of the game.
         */
        void update(in real timeLeft, in Player player1, in Player player2)
        {
            hud_.update(timeLeft, player1, player2);
            if(scoreScreen_ !is null){scoreScreen_.update();}
        }

        ///Destroy the game GUI.
        ~this()
        {
            clear(hud_);
            if(scoreScreen_ !is null){clear(scoreScreen_);}
            scoreExpired.disconnectAll();
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
        SceneManager sceneManager_;

        ///Game area in world space.
        static immutable Rectf gameArea_ = Rectf(0.0f, 0.0f, 800.0f, 600.0f);
        
        ///Current game ball.
        Ball ball_;
        ///Default ball radius.
        real ballRadius_ = 6.0;
        ///Default ball speed.
        real ballSpeed_ = 185.0;

        ///BallSpawner spawn time.
        real spawnTime_ = 4.0;
        ///BallSpawner spawn spread.
        real spawnSpread_ = 0.28;

        ///Dummy balls.
        Ball[] dummies_;
        ///Number of dummy balls.
        uint dummyCount_ = 20;

        ///Right wall of the game area.
        Wall wallRight_;
        ///Left wall of the game area.
        Wall wallLeft_; 
        ///Top goal of the game area.
        Wall goalUp_; 
        ///Bottom goal of the game area.
        Wall goalDown_; 

        ///Player 1 paddle.
        Paddle paddle1_;
        ///Player 2 paddle.
        Paddle paddle2_;
     
        ///Player 1.
        Player player1_;
        ///Player 2.
        Player player2_;
     
        ///Continue running?
        bool continue_;

        ///Score limit.
        immutable uint scoreLimit_;
        ///Time limit in game time.
        immutable real timeLimit_;
        ///Timer determining when the game ends.
        Timer gameTimer_;

        ///GUI of the game, e.g. HUD, score screen.
        GameGUI gui_;

        ///True while the players are (still) playing the game.
        bool playing_;
        ///Has the game started?
        bool started_;

        ///Timer determining when to end the intro and start the game.
        Timer introTimer_;

    public:
        /**
         * Update the game.
         *
         * Returns: True if the game should continue to run, false otherwise.
         */
        bool run()
        {
            const real time = sceneManager_.gameTime;
            if(playing_)
            {
                //update player state
                player1_.update(this);
                player2_.update(this);

                //check for victory conditions
                if(player1_.score >= scoreLimit_ || player2_.score >= scoreLimit_)
                {
                    gameWon();
                }
                if(gameTimer_.expired(time) && player1_.score != player2_.score)
                {
                    gameWon();
                }
            }

            if(continue_)
            {
                const real timeLeft = timeLimit_ - gameTimer_.age(time);
                gui_.update(timeLeft, player1_, player2_);
            }

            if(!started_ && introTimer_.expired(time)){startGame(time);}

            sceneManager_.update();

            return continue_;
        }

        ///Start game intro.
        void intro()
        {
            introTimer_ = Timer(2.5, sceneManager_.gameTime);
            playing_ = started_ = false;
            continue_ = true;

            //construct walls and goals
            with(new WallFactory)
            {
                boxMax     = Vector2f(32.0f, 536.0f);
                //walls slowly move into place when game starts
                velocity    = Vector2f(73.6f, 0.0f);
                position    = Vector2f(-64.0f, 32.0f);
                wallLeft_  = produce(sceneManager_);

                velocity    = Vector2f(-73.6f, 0.0f);
                position    = Vector2f(832.0, 32.0f);
                wallRight_ = produce(sceneManager_);

                boxMax     = Vector2f(560.0f, 28.0f);
                velocity    = Vector2f(320.0f, 0.0f);
                position    = Vector2f(-680.0f, 4.0f);
                goalUp_    = produce(sceneManager_);

                velocity    = Vector2f(-320.0f, 0.0f);
                position    = Vector2f(920.0f, 568.0f);
                goalDown_  = produce(sceneManager_);
            }

            //construct paddles.
            const float limitsMinX = 152.0f + 2.0 * ballRadius_;
            const float limitsMaxX = 648.0f - 2.0 * ballRadius_;
            with(new PaddleFactory)
            {
                boxMin    = Vector2f(-32.0f, -4.0f);
                boxMax    = Vector2f(32.0f, 4.0f);
                position   = Vector2f(400.0f, 56.0f);
                limitsMin = Vector2f(limitsMinX, 36.0f);
                limitsMax = Vector2f(limitsMaxX, 76.0f);
                speed      = 135.0;
                paddle1_  = produce(sceneManager_);

                position   = Vector2f(400.0f, 544.0f);
                limitsMin = Vector2f(limitsMinX, 524.0f);
                limitsMax = Vector2f(limitsMaxX, 564.0f);
                paddle2_  = produce(sceneManager_);
            }

            player1_ = new AIPlayer("AI", paddle1_, 0.15);
            player2_ = new HumanPlayer(platform_, "Human", paddle2_);

            platform_.key.connect(&keyHandler);
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
        void draw(VideoDriver driver){sceneManager_.draw(driver);}

        ///Get game area.
        @property static Rectf gameArea(){return gameArea_;}

        ///End the game, regardless of whether it has been won or not.
        void endGame()
        {
            if(started_){sceneManager_.timeSpeed = 1.0;}

            sceneManager_.clear();
            clear(player1_);
            clear(player2_);

            playing_ = continue_ = false;

            platform_.key.disconnect(&keyHandler);
        }

    private:
        /**
         * Construct a Game.
         *
         * Params:  platform      = Platform used for input.
         *          sceneManager = SceneManager managing actors.
         *          gui           = Game GUI.
         *          scoreLimit   = Score limit of the game.
         *          timeLimit    = Time limit of the game in game time.
         */
        this(Platform platform, SceneManager sceneManager, GameGUI gui, 
             in uint scoreLimit, in real timeLimit)
        {
            singletonCtor();
            gui_           = gui;
            platform_      = platform;
            sceneManager_ = sceneManager;
            scoreLimit_   = scoreLimit;
            timeLimit_    = timeLimit;
        }

        ///Destroy the Game.
        ~this(){singletonDtor();}

        ///Start the game, at specified game time.
        void startGame(in real startTime)
        {
            //spawn dummy balls
            with(new DummyBallFactory)
            {
                radius = 6.0;

                foreach(dummy; 0 .. dummyCount_)
                {
                    position = randomPosition!(float)(gameArea_.center, 26.0f);
                    velocity = 2.4 * ballSpeed_ * randomDirection!(float)(); 
                    dummies_ ~= produce(sceneManager_);
                }
            }

            //should be set from options and INI when that is implemented.
            started_ = playing_ = true;

            wallLeft_.velocity  = Vector2f(0.0, 0.0);
            wallRight_.velocity = Vector2f(0.0, 0.0);
            goalUp_.velocity    = Vector2f(0.0, 0.0);
            goalDown_.velocity  = Vector2f(0.0, 0.0);
            
            with(new BallSpawnerFactory(startTime))
            {
                time         = spawnTime_;
                spread       = spawnSpread_;
                ballSpeed   = this.ballSpeed_;
                position     = gameArea_.center;
                auto spawner = produce(sceneManager_);
                spawner.spawnBall.connect(&spawnBall);
            }

            goalUp_.ballHit.connect(&player2_.score);
            goalDown_.ballHit.connect(&player1_.score);
            goalUp_.ballHit.connect(&destroyBall);
            goalDown_.ballHit.connect(&destroyBall);

            gui_.showHUD();

            gameTimer_ = Timer(timeLimit_, startTime);
        }

        ///Destroy ball with specified ball body.
        void destroyBall(const BallBody ballBody)
        in
        {
            assert(ball_ !is null && ballBody is ball_.physicsBody,
                   "Only one ball is supported right now yet "
                   "a ball body not belonging to this ball is used");
        }
        body
        {
            ball_.die(sceneManager_.updateIndex);
            ball_ = null;

            with(new BallSpawnerFactory(sceneManager_.gameTime))
            {
                time         = spawnTime_;
                spread       = spawnSpread_;
                ballSpeed   = this.ballSpeed_;
                position     = gameArea_.center;
                auto spawner = produce(sceneManager_);
                spawner.spawnBall.connect(&spawnBall);
            }
        }

        /**
         * Spawn a ball.
         *
         * Params:  direction = Direction to spawn the ball in.
         *          speed     = Speed to spawn the ball at.
         */
        void spawnBall(Vector2f direction, real speed)
        {
            with(new BallFactory)
            {
                position = gameArea_.center;
                velocity = direction * speed;
                radius   = ballRadius_;
                ball_    = produce(sceneManager_);
            }
        }

        ///Called when one of the players wins the game.
        void gameWon()
        {
            //show the score screen and end the game after it expires
            gui_.showScores(gameTimer_.age(sceneManager_.gameTime), player1_, player2_);
            gui_.scoreExpired.connect(&endGame);
            sceneManager_.timeSpeed = 0.0;

            playing_ = false;
        }

        /**
         * Process keyboard input.
         *
         * Params:  state   = State of the key.
         *          key     = Keyboard key.
         *          unicode = Unicode value of the key.
         */
        void keyHandler(KeyState state, Key key, dchar unicode)
        {
            if(state == KeyState.Pressed) switch(key)
            {
                case Key.Escape:
                    endGame();
                    break;
                case Key.K_P: //pause
                    const paused = equals(sceneManager_.timeSpeed, cast(real)0.0);
                    sceneManager_.timeSpeed = paused ? 1.0 : 0.0;
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
        SpatialManager!(PhysicsBody) spatialPhysics_;
        ///Physics engine used by the scene manager.
        PhysicsEngine physicsEngine_;
        ///Scene manager used by the game.
        SceneManager sceneManager_;
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
         *          guiParent = Parent for all GUI elements used by the game.
         *
         * Returns: Produced Game.
         */
        Game produce(Platform platform, MonitorManager monitor, GUIElement guiParent)
        in
        {
            assert(spatialPhysics_ is null && physicsEngine_ is null && 
                   sceneManager_ is null && game_ is null,
                   "Can't produce two games at once with GameContainer");
        }
        body
        {
            monitor_ = monitor;
            spatialPhysics_ = new GridSpatialManager!PhysicsBody
                                   (Vector2f(400.0f, 300.0f), 25.0f, 32);
            physicsEngine_  = new PhysicsEngine(spatialPhysics_);
            sceneManager_   = new SceneManager(physicsEngine_);
            gui_            = new GameGUI(guiParent, 300.0);
            game_           = new Game(platform, sceneManager_, gui_, 10, 300.0);
            monitor_.addMonitorable(spatialPhysics_, "Spatial(P)");
            monitor_.addMonitorable(physicsEngine_, "Physics");
            monitor_.addMonitorable(sceneManager_, "Scene");
            return game_;
        }

        ///Destroy the contained Game.
        void destroy()
        {
            clear(game_);
            clear(gui_);
            monitor_.removeMonitorable("Scene");
            clear(sceneManager_);
            monitor_.removeMonitorable("Physics");
            clear(physicsEngine_);
            monitor_.removeMonitorable("Spatial(P)");
            clear(spatialPhysics_);
            game_            = null;
            sceneManager_   = null;
            physicsEngine_  = null;
            spatialPhysics_ = null;
            monitor_         = null;
        }
}
