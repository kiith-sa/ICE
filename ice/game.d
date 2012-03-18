//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Game class.
module ice.game;


import std.algorithm;
import std.array;
import std.conv;
import std.exception;
import std.string;
import std.traits;

import dgamevfs._;

import color;
import component.controllersystem;
import component.enginesystem;
import component.entitysystem;
import component.physicssystem;
import component.timeoutsystem;
import component.weaponsystem;
import component.system;
import component.visualsystem;
import gui.guielement;
import math.math;
import math.vector2;
import math.rect;
import memory.memory;
import memory.pool;
import monitor.monitormanager;
import scene.scenemanager;
import spatial.spatialmanager;
import spatial.gridspatialmanager;
import physics.physicsengine;
import platform.platform;
import time.gametime;
import util.yaml;
import util.signal;
import util.weaksingleton;
import video.videodriver;

import ice.player;
import ice.hud;


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

///Thrown when the game fails to start.
class GameStartException : Exception 
{
    public this(string msg, string file = __FILE__, int line = __LINE__)
    {
        super(msg, file, line);
    }
}

/**
 * Construct the player ship entity and return its ID.
 *
 * Params:  name     = Name, used for debugging.
 *          system   = Game entity system.
 *          position = Starting position of the ship.
 *          yaml     = YAML node to load the ship from.
 */
EntityID constructPlayerShip(string name, EntitySystem system, Vector2f position, YAMLNode yaml)
{
    import component.physicscomponent;
    import component.controllercomponent;
    auto prototype = EntityPrototype(name, yaml);
    with(prototype)
    {
        physics    = PhysicsComponent(position, Vector2f(0.0f, -1.0f).angle,
                                      Vector2f(0.0f, 0.0f));
        controller = ControllerComponent();
    }
    return system.newEntity(prototype);
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

        ///Player ship entity ID (temp, until we have levels).
        EntityID playerShipID_;
     
        ///Continue running?
        bool continue_;

        ///GUI of the game, e.g. HUD, score screen.
        GameGUI gui_;

        ///Game data directory.
        VFSDir gameDir_;

        ///Game time subsystem, schedules updates.
        GameTime gameTime_;

        ///Game entity system.
        EntitySystem entitySystem_;

        ///Systems operating on entities.
        System[] systems_;

        ///Visual subsystem, draws entities.
        VisualSystem     visualSystem_;
        ///Controller subsystem, allows players to control ships.
        ControllerSystem controllerSystem_;
        ///Physics subsystem. Handles movement and physics interaction.
        PhysicsSystem    physicsSystem_;
        ///Handles various delayed events.
        TimeoutSystem    timeoutSystem_;
        ///Handles weapons and firing.
        WeaponSystem     weaponSystem_;
        ///Handles engine components of the entities, allowing them to move.
        EngineSystem     engineSystem_;

    public:
        /**
         * Update the game.
         *
         * Returns: True if the game should continue to run, false otherwise.
         */
        bool run()
        {
            if(!continue_){return false;}

            player1_.update();

            gui_.update();

            //Does as many game logic updates as needed (even zero)
            //to keep constant game update tick.
            gameTime_.doGameUpdates
            ({
                entitySystem_.update();
                controllerSystem_.update();
                engineSystem_.update();
                weaponSystem_.update();
                physicsSystem_.update();
                timeoutSystem_.update();
            });

            visualSystem_.update();

            return true;
        }

        ///Start game.
        void startGame()
        {
            assert(gameDir_ !is null, "Starting Game but gameDir_ has not been set");

            //Initialize player ship.
            try
            {
                playerShipID_ = constructPlayerShip("playership", entitySystem_,
                                                    Vector2f(400.0f, 536.0f),
                                                    loadYAML(gameDir_.file("ships/playership.yaml")));
            }
            catch(YAMLException e)
            {
                throw new GameStartException("Failed to start game: could not " ~
                                             "initialize player ship: " ~ e.msg);
            }
            catch(VFSException e)
            {
                throw new GameStartException("Failed to start game: could not " ~
                                             "initialize player ship: " ~ e.msg);
            }

            continue_ = true;
            player1_  = new HumanPlayer(platform_, "Human");
            platform_.key.connect(&keyHandler);

            controllerSystem_.setEntityController(playerShipID_, player1_);
        }

        ///End the game, regardless of whether it has been won or not.
        void endGame()
        {
            sceneManager_.clear();
            clear(player1_);
            continue_ = false;
            platform_.key.disconnect(&keyHandler);
        }

        ///Set the VideoDriver used to draw game.
        @property void videoDriver(VideoDriver rhs) pure nothrow
        {
            visualSystem_.videoDriver = rhs;
        }

        ///Set the game data directory.
        @property void gameDir(VFSDir rhs) pure nothrow 
        {
            gameDir_              = rhs;
            visualSystem_.gameDir  = rhs;
            weaponSystem_.gameDir = rhs;
        }

        ///Get game area.
        @property static Rectf gameArea(){return gameArea_;}

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
            gui_              = gui;
            platform_         = platform;
            sceneManager_     = sceneManager;
            
            gameTime_         = new GameTime();

            //Initialize entity system and game subsystems.
            entitySystem_     = new EntitySystem();
            visualSystem_     = new VisualSystem(entitySystem_);
            controllerSystem_ = new ControllerSystem(entitySystem_);
            physicsSystem_    = new PhysicsSystem(entitySystem_, gameTime_);
            timeoutSystem_    = new TimeoutSystem(entitySystem_, gameTime_);
            weaponSystem_     = new WeaponSystem(entitySystem_, gameTime_);
            engineSystem_     = new EngineSystem(entitySystem_, gameTime_);

            systems_ ~= visualSystem_;
            systems_ ~= controllerSystem_;
            systems_ ~= physicsSystem_;
            systems_ ~= timeoutSystem_;
            systems_ ~= weaponSystem_;
            systems_ ~= engineSystem_;
        }

        ///Destroy the Game.
        ~this()
        {
            //Destroy game subsystems.
            foreach(system; systems_)
            {
                clear(system);
            }

            entitySystem_.destroy();

            singletonDtor();
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
                case Key.K_P: //Pause.
                    const paused = equals(gameTime_.timeSpeed, cast(real)0.0);
                    gameTime_.timeSpeed = paused ? 1.0 : 0.0;
                    break;
                default:
                    break;
            }
        }
}

///Container managing dependencies and construction of Game.
class GameContainer
{
    import physics.physicsbody;
    private:
        ///Spatial manager used by the physics engine for coarse collision detection.
        SpatialManager!PhysicsBody spatialPhysics_;
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
         *          guiParent  = Parent for all GUI elements used by the game.
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
