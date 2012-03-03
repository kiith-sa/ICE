//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Game class.
module ice.game;


import ice.player;
import ice.hud;
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

    public:
        /**
         * Construct a GameGUI with specified parameters.
         *
         * Params:  parent     = GUI element to attach all game GUI elements to.
         */
        this(GUIElement parent)
        {
            parent_ = parent;
            hud_ = new HUD(parent);
            hud_.hide();
        }

        ///Show the HUD.
        void showHUD(){hud_.show();}

        /**
         * Update the game GUI.
         */
        void update()
        {
            hud_.update();
        }

        ///Destroy the game GUI.
        ~this()
        {
            clear(hud_);
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
     
        ///Player 1.
        Player player1_;
     
        ///Continue running?
        bool continue_;

        ///GUI of the game, e.g. HUD, score screen.
        GameGUI gui_;

    public:
        /**
         * Update the game.
         *
         * Returns: True if the game should continue to run, false otherwise.
         */
        bool run()
        {
            if(!continue_){return false;}

            //update player state
            player1_.update(this);

            gui_.update();
            sceneManager_.update();

            return true;
        }

        ///Start game.
        void startGame()
        {
            continue_ = true;
            player1_  = new HumanPlayer(platform_, "Human");
            platform_.key.connect(&keyHandler);
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
            sceneManager_.clear();
            clear(player1_);
            continue_ = false;
            platform_.key.disconnect(&keyHandler);
        }

    private:
        /**
         * Construct a Game.
         *
         * Params:  platform     = Platform used for input.
         *          sceneManager = SceneManager managing actors.
         *          gui          = Game GUI.
         */
        this(Platform platform, SceneManager sceneManager, GameGUI gui)
        {
            singletonCtor();
            gui_           = gui;
            platform_      = platform;
            sceneManager_ = sceneManager;
        }

        ///Destroy the Game.
        ~this(){singletonDtor();}

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
            gui_            = new GameGUI(guiParent);
            game_           = new Game(platform, sceneManager_, gui_);
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
            game_           = null;
            sceneManager_   = null;
            physicsEngine_  = null;
            spatialPhysics_ = null;
            monitor_        = null;
        }
}
