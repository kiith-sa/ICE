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
import component.collisionsystem;
import component.collisionresponsesystem;
import component.controllersystem;
import component.enginesystem;
import component.entitysystem;
import component.healthsystem;
import component.ondeathsystem;
import component.physicssystem;
import component.spatialsystem;
import component.timeoutsystem;
import component.warheadsystem;
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
import platform.platform;
import time.gametime;
import util.yaml;
import util.signal;
import util.weaksingleton;
import video.videodriver;

import ice.hud;
import ice.level;
import ice.player;


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
        ///Show the HUD.
        void showHUD(){hud_.show();}

        ///Set the message text on the bottom of the HUD for specified time in seconds.
        void messageText(string text, float time) 
        {
            hud_.messageText(text, time);
        }

    private:
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

        /**
         * Update the game GUI, using game time subsystem to measure time.
         */
        void update(const GameTime gameTime)
        {
            hud_.update(gameTime);
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

///Class managing a single game between players.
class Game
{
    mixin WeakSingleton;
    private:
        ///Platform used for input.
        Platform platform_;

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

        ///Visual subsystem, draws entities.
        VisualSystem            visualSystem_;
        ///Controller subsystem, allows players to control ships.
        ControllerSystem        controllerSystem_;
        ///Physics subsystem. Handles movement and physics interaction.
        PhysicsSystem           physicsSystem_;
        ///Handles various delayed events.
        TimeoutSystem           timeoutSystem_;
        ///Handles weapons and firing.
        WeaponSystem            weaponSystem_;
        ///Handles engine components of the entities, allowing them to move.
        EngineSystem            engineSystem_;
        ///Handles spatial relations between entities.
        SpatialSystem           spatialSystem_;
        ///Handles collision detection.
        CollisionSystem         collisionSystem_;
        ///Handles collision response.
        CollisionResponseSystem collisionResponseSystem_;
        ///Handles damage caused by warheads.
        WarheadSystem           warheadSystem_;
        ///Handles entity health and kills entities when they run out of health.
        HealthSystem            healthSystem_;
        ///Handles callbacks on death of entities.
        OnDeathSystem           onDeathSystem_;

        ///Level the game is running.
        Level level_;

    public:
        /**
         * Update the game.
         *
         * Returns: True if the game should continue to run, false otherwise.
         */
        bool run()
        {
            if(!continue_){return false;}

            //Does as many game logic updates as needed (even zero)
            //to keep constant game update tick.
            gameTime_.doGameUpdates
            ({
                player1_.update();
                gui_.update(gameTime_);

                entitySystem_.update();

                if(!level_.update(gui_))
                {
                    continue_ = false;
                    return 1;
                }

                controllerSystem_.update();
                engineSystem_.update();
                weaponSystem_.update();
                physicsSystem_.update();
                spatialSystem_.update();
                collisionSystem_.update();
                warheadSystem_.update();
                collisionResponseSystem_.update();
                healthSystem_.update();
                timeoutSystem_.update();
                onDeathSystem_.update();

                return 0;
            });

            //Game might have been ended after a level update,
            //which left the component subsystems w/o update,
            //so don't draw either.
            if(!continue_)
            {
                endGame();
                return false;
            }

            visualSystem_.update();

            return true;
        }

        ///Start game.
        void startGame()
        {
            assert(gameDir_ !is null, "Starting Game but gameDir_ has not been set");


            player1_  = new HumanPlayer(platform_, "Human");
            auto levelName = "levels/level1.yaml";

            //Initialize the level.
            try
            {
                level_ = new DumbLevel(levelName, loadYAML(gameDir_.file(levelName)),
                                       entitySystem_, gameTime_, gameDir_);
            }
            catch(LevelInitializationFailureException e)
            {
                throw new GameStartException("Failed to initialize level " ~
                                             levelName ~ " : " ~ e.msg);
            }

            //Initialize player ship.
            try
            {
                playerShipID_ = constructPlayerShip("playership", 
                                                    Vector2f(400.0f, 536.0f),
                                                    loadYAML(gameDir_.file("ships/playership.yaml")));
            }
            catch(YAMLException e)
            {
                throw new GameStartException("Failed to start game: could not " ~
                                             "initialize ships: " ~ e.msg);
            }
            catch(VFSException e)
            {
                throw new GameStartException("Failed to start game: could not " ~
                                             "initialize ships: " ~ e.msg);
            }

            gui_.showHUD();

            continue_ = true;
            platform_.key.connect(&keyHandler);
        }

        ///End the game, regardless of whether it has been won or not.
        void endGame()
        {
            clear(player1_);
            clear(level_);
            continue_ = false;
            platform_.key.disconnect(&keyHandler);
        }

        ///Set the VideoDriver used to draw game.
        @property void videoDriver(VideoDriver rhs) pure nothrow
        {
            visualSystem_.videoDriver = rhs;
        }

        ///Set the game data directory.
        @property void gameDir(VFSDir rhs) 
        {
            gameDir_                  = rhs;
            controllerSystem_.gameDir = rhs;
            visualSystem_.gameDir     = rhs;
            weaponSystem_.gameDir     = rhs;
            if(level_ !is null){level_.gameDir            = rhs;}
        }

        ///Get game area.
        @property static Rectf gameArea(){return gameArea_;}

    private:
        /**
         * Construct a Game.
         *
         * Params:  platform = Platform used for input.
         *          gui      = Game GUI.
         */
        this(Platform platform, GameGUI gui)
        {
            singletonCtor();
            gui_              = gui;
            platform_         = platform;
            
            gameTime_         = new GameTime();

            //Initialize entity system and game subsystems.
            entitySystem_            = new EntitySystem();
            visualSystem_            = new VisualSystem(entitySystem_);
            controllerSystem_        = new ControllerSystem(entitySystem_, gameTime_);
            physicsSystem_           = new PhysicsSystem   (entitySystem_, gameTime_);
            timeoutSystem_           = new TimeoutSystem   (entitySystem_, gameTime_);
            weaponSystem_            = new WeaponSystem    (entitySystem_, gameTime_);
            engineSystem_            = new EngineSystem    (entitySystem_, gameTime_);
            spatialSystem_           = new SpatialSystem(entitySystem_, 
                                                         Vector2f(400.0f, 300.0f), 
                                                         32.0f, 
                                                         32);
            collisionSystem_         = new CollisionSystem(entitySystem_, spatialSystem_);
            collisionResponseSystem_ = new CollisionResponseSystem(entitySystem_);
            warheadSystem_           = new WarheadSystem(entitySystem_);
            healthSystem_            = new HealthSystem(entitySystem_);
            onDeathSystem_           = new OnDeathSystem(entitySystem_);
        }

        ///Destroy the Game.
        ~this()
        {
            clear(visualSystem_);
            clear(controllerSystem_);
            clear(physicsSystem_);
            clear(timeoutSystem_);
            clear(weaponSystem_);
            clear(engineSystem_);
            clear(collisionSystem_);
            clear(collisionResponseSystem_);
            clear(spatialSystem_);
            clear(warheadSystem_);
            clear(healthSystem_);
            clear(onDeathSystem_);

            clear(player1_);

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

        /**
         * Construct the player ship entity and return its ID.
         *
         * Params:  name      = Name, used for debugging.
         *          position  = Starting position of the ship.
         *          yaml      = YAML node to load the ship from.
         */
        EntityID constructPlayerShip(string name, 
                                     Vector2f position, 
                                     YAMLNode yaml)
        {
            import component.controllercomponent;
            import component.ondeathcomponent;
            import component.physicscomponent;
            import component.playercomponent;
            import component.statisticscomponent;

            auto prototype = EntityPrototype(name, yaml);
            with(prototype)
            {
                physics    = PhysicsComponent(position, Vector2f(0.0f, -1.0f).angle,
                                              Vector2f(0.0f, 0.0f));
                controller = ControllerComponent();
                player     = PlayerComponent(player1_);

                onDeath    = OnDeathComponent(&playerDied);

                statistics = StatisticsComponent();
            }
            return entitySystem_.newEntity(prototype);
        }

        ///Called when the player ship has died.
        void playerDied(ref Entity playerShip)
        {
            import std.stdio;
            continue_ = false;
            writeln("Player died");
        }

}

///Container managing dependencies and construction of Game.
class GameContainer
{
    import physics.physicsbody;
    private:
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
            assert(game_ is null,
                   "Can't produce two games at once with GameContainer");
        }
        body
        {
            monitor_ = monitor;
            gui_            = new GameGUI(guiParent);
            game_           = new Game(platform, gui_);
            return game_;
        }

        ///Destroy the contained Game.
        void destroy()
        {
            clear(game_);
            clear(gui_);
            game_           = null;
            monitor_        = null;
        }
}
