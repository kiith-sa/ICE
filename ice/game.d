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
import std.random;
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
import component.statisticscomponent;
import component.timeoutsystem;
import component.warheadsystem;
import component.weaponsystem;
import component.system;
import component.visualsystem;
import gui.guielement;
import gui.guistatictext;
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
import video.videodriver;

import ice.graphicseffect;
import ice.hud;
import ice.level;
import ice.player;


/**
 * Class holding all GUI used by Game (HUD, etc.).
 */
class GameGUI
{
    private:
        ///Parent of all game GUI elements.
        GUIElement parent_;
        ///Game over screen (with stats, etc). Null if not shown.
        GUIElement gameOver_;
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

        /**
         * Show the game over screen, with statistics, etc.
         *
         * Params:  statistics = Player statistics.
         *          totalTime  = Total time taken by the game, in game time
         *                       seconds (i.e. not measuring pauses).
         */
        void showGameOverScreen(const StatisticsComponent statistics,
                                const real totalTime) 
        {
            with(new GUIElementFactory)
            {
                x      = "p_left + p_width / 2 - 300";
                y      = "p_top + p_height / 2 - 200";
                width  = "600";
                height = "400";
                gameOver_ = produce();
            }

            with(new GUIStaticTextFactory)
            {
                //Death message.
                x        = "p_left + 16";
                y        = "p_top + 16";
                width    = "p_width - 32";
                height   = "24";
                font     = "orbitron-bold.ttf";
                fontSize = 20;
                alignX   = AlignX.Center;
                text     = randomDeathMessage();
                gameOver_.addChild(produce());

                //Time elapsed.
                y        = "p_top + 64";
                alignX   = AlignX.Left;
                font     = "orbitron-light.ttf";
                fontSize = 16;
                text     = "Time elapsed:";
                gameOver_.addChild(produce());

                alignX   = AlignX.Right;
                text     = format("%.2f", totalTime);
                gameOver_.addChild(produce());

                //Shots fired.
                y        = "p_top + 88";
                alignX   = AlignX.Left;
                text     = "Shots fired:";
                gameOver_.addChild(produce());

                alignX   = AlignX.Right;
                text     = to!string(statistics.burstsFired);
                gameOver_.addChild(produce());

                //Ships killed.
                y        = "p_top + 112";
                alignX   = AlignX.Left;
                text     = "Ships killed:";
                gameOver_.addChild(produce());

                alignX   = AlignX.Right;
                text     = to!string(statistics.entitiesKilled);
                gameOver_.addChild(produce());
            }

            parent_.addChild(gameOver_);
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
            if(gameOver_ !is null)
            {
                gameOver_.die();
                gameOver_ = null;
            }
        }

        ///Get a random death message.
        static string randomDeathMessage()
        {
            static messages = ["You have been murderized",
                               "Fail",
                               "LOL U MAD?",
                               "You were killed",
                               "You are dead"];

            return messages[uniform(0, messages.length)];
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
    private:
        enum GamePhase
        {
            Playing,
            Over
        }

        GamePhase gamePhase_ = GamePhase.Playing;

        ///Platform used for input.
        Platform platform_;

        ///Game area in world space.
        static immutable Rectf gameArea_ = Rectf(0.0f, 0.0f, 800.0f, 600.0f);
     
        ///Player 1.
        Player player1_;

        ///Player ship entity ID (temp, until we have levels).
        EntityID playerShipID_;
     
        ///Was initGameState successful?
        bool gameStateInitialized_;

        ///Continue running?
        bool continue_;

        ///GUI of the game, e.g. HUD, score screen.
        GameGUI gui_;

        ///Game data directory.
        VFSDir gameDir_;

        ///Game time when the game started.
        real startTime_;

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

        ///Used to make draw calls.
        VideoDriver videoDriver_;

        ///Manages graphics effects.
        GraphicsEffectManager effectManager_;

    public:
        /**
         * Update the game.
         *
         * Returns: true if the game should continue to run, false otherwise.
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

                if(gamePhase_ == GamePhase.Playing)
                {
                    if(!level_.update(gui_))
                    {
                        continue_ = false;
                        return 1;
                    }
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
            if(!continue_){return false;}

            visualSystem_.update();

            effectManager_.draw(videoDriver_, gameTime_);

            return true;
        }

        ///Set the VideoDriver used to draw game.
        @property void videoDriver(VideoDriver rhs) pure nothrow
        {
            videoDriver_ = rhs;
            visualSystem_.videoDriver = rhs;
        }

        ///Set the game data directory.
        @property void gameDir(VFSDir rhs) 
        {
            gameDir_                  = rhs;
            controllerSystem_.gameDir = rhs;
            visualSystem_.gameDir     = rhs;
            weaponSystem_.gameDir     = rhs;
            if(level_ !is null){level_.gameDir = rhs;}
        }

        ///Get game area.
        @property static Rectf gameArea(){return gameArea_;}

    private:
        /**
         * Construct a Game.
         *
         * Params:  platform = Platform used for input.
         *          gui      = Game GUI.
         *          video    = Video driver used to draw the game.
         *          gameDir  = Game data directory.
         */
        this(Platform platform, GameGUI gui, VideoDriver video, VFSDir gameDir)
        {
            gui_             = gui;
            platform_        = platform;

            initSystems();

            this.videoDriver = video;
            this.gameDir     = gameDir;

            scope(failure){destroySystems();}

            initGameState();
        }

        ///Destroy the Game.
        ~this()
        {
            if(gameStateInitialized_)
            {
                clear(player1_);
                clear(level_);
                platform_.key.disconnect(&keyHandler);
            }
            destroySystems();
        }

        /**
         * Initialize game state.
         *
         * At the end of this method, we've either succeeded and level 
         * and player are initialized, or we've failed and they are not 
         * (they are cleaned up if they are already initialized but initGameState fails)
         * 
         * Throws:  GameStartException on failure.
         */
        void initGameState()
        {
            scope(failure){clear(player1_);}
            player1_  = new HumanPlayer(platform_, "Human");
            auto levelName = "levels/level1.yaml";

            scope(failure){clear(level_);}

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


            //Background scrolling starfield effect (each effect is a single layer).
            auto effect = new RandomLinesEffect(gameTime_.gameTime,
            (const real startTime,
             const GameTime gameTime, 
             ref RandomLinesEffect.Parameters params)
            {
                if(gamePhase_ == GamePhase.Over){return true;}
                params.bounds   = Rectf(gameArea.min.x, gameArea.min.y - 64.0f,
                                        gameArea.max.x, gameArea.max.y + 64.0f);
                params.minWidth = 0.6;
                params.maxWidth = 1.2;
                params.minLength = 6.0;
                params.maxLength = 24.0;
                params.verticalScrollingSpeed = 1000.0f;

                params.linesPerPixel = 0.000005;
                params.detailLevel = 8;
                params.color    = rgba!"F0F0E0A0";
                return false;
            });

            effectManager_.addEffect(effect);

            effect = new RandomLinesEffect(gameTime_.gameTime,
            (const real startTime,
             const GameTime gameTime, 
             ref RandomLinesEffect.Parameters params)
            {
                if(gamePhase_ == GamePhase.Over){return true;}
                params.bounds   = Rectf(gameArea.min.x, gameArea.min.y - 64.0f,
                                        gameArea.max.x, gameArea.max.y + 64.0f);
                params.minWidth = 0.3;
                params.maxWidth = 1.2;
                params.minLength = 4.0;
                params.maxLength = 16.0;
                params.verticalScrollingSpeed = 250.0f;

                params.linesPerPixel = 0.0015;
                params.detailLevel = 6;
                params.color    = rgba!"C8C8FF38";
                return false;
            });

            effectManager_.addEffect(effect);

            effect = new RandomLinesEffect(gameTime_.gameTime,
            (const real startTime,
             const GameTime gameTime, 
             ref RandomLinesEffect.Parameters params)
            {
                if(gamePhase_ == GamePhase.Over){return true;}
                params.bounds   = Rectf(gameArea.min.x, gameArea.min.y - 64.0f,
                                        gameArea.max.x, gameArea.max.y + 64.0f);
                params.minWidth = 0.225;
                params.maxWidth = 0.9;
                params.minLength = 3.0;
                params.maxLength = 12.0;
                params.verticalScrollingSpeed = 187.5f;

                params.linesPerPixel = 0.00225;
                params.detailLevel = 5;
                params.color    = rgba!"D0D0FF2A";
                return false;
            });

            effectManager_.addEffect(effect);

            effect = new RandomLinesEffect(gameTime_.gameTime,
            (const real startTime,
             const GameTime gameTime, 
             ref RandomLinesEffect.Parameters params)
            {
                if(gamePhase_ == GamePhase.Over){return true;}
                params.bounds   = Rectf(gameArea.min.x, gameArea.min.y - 64.0f,
                                        gameArea.max.x, gameArea.max.y + 64.0f);
                params.minWidth = 0.15;
                params.maxWidth = 0.6;
                params.minLength = 2.0;
                params.maxLength = 8.0;
                params.verticalScrollingSpeed = 125.0f;

                params.linesPerPixel = 0.003;
                params.detailLevel = 4;
                params.color    = rgba!"D8D8FF1C";
                return false;
            });

            effectManager_.addEffect(effect);

            effect = new RandomLinesEffect(gameTime_.gameTime,
            (const real startTime,
             const GameTime gameTime, 
             ref RandomLinesEffect.Parameters params)
            {
                if(gamePhase_ == GamePhase.Over){return true;}
                params.bounds   = Rectf(gameArea.min.x, gameArea.min.y - 64.0f,
                                        gameArea.max.x, gameArea.max.y + 64.0f);
                params.minWidth = 0.10;
                params.maxWidth = 0.4;
                params.minLength = 1.0;
                params.maxLength = 4.0;
                params.verticalScrollingSpeed = 75.0f;

                params.linesPerPixel = 0.005;
                params.detailLevel = 3;
                params.color    = rgba!"FFFFFF0C";
                return false;
            });

            effectManager_.addEffect(effect);
            gameStateInitialized_ = true;
        }

        ///Initialize game subsystems.
        void initSystems()
        {
            gameTime_  = new GameTime();
            startTime_ = gameTime_.gameTime;      

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

            effectManager_           = new GraphicsEffectManager();
        }

        ///Destroy game subsystems.
        void destroySystems()
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

            clear(effectManager_);
            if(entitySystem_ !is null)
            {
                entitySystem_.destroy();
                clear(entitySystem_);
                entitySystem_ = null;
            }
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
                    continue_ = false;
                    break;
                case Key.Return:
                    if(gamePhase_ == GamePhase.Over)
                    {
                        continue_ = false;
                    }
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
            //Game over enlarging text effect.
            GraphicsEffect effect = new TextEffect(gameTime_.gameTime,
               (const real startTime,
                const GameTime gameTime, 
                ref TextEffect.Parameters params)
               {
                   const double timeRatio = (gameTime.gameTime - startTime) / 1.0;
                   if(timeRatio > 1.0){return true;}

                   auto gameOver = "GAME OVER";

                   const chars = round!uint(timeRatio * 5.0 * (gameOver.length));
                   params.text = gameOver[0 .. min(gameOver.length, chars)];

                   params.font = "orbitron-bold.ttf";
                   params.fontSize = 80 + round!uint(max(0.0, (timeRatio - 0.2) * 16.0) ^^ 2); 

                   //Must set videodriver font and font size to measure text size.
                   videoDriver_.font     = "orbitron-bold.ttf";
                   videoDriver_.fontSize = params.fontSize;
                   const textSize        = videoDriver_.textSize(params.text).to!float;
                   const area            = Game.gameArea;
                   params.offset         = (area.min + (area.size - textSize) * 0.5).to!int;

                   params.color = rgba!"8080F0FF".interpolated(rgba!"8080F000", 
                                                               1.0 - timeRatio ^^ 2);
                   return false;
               });

            //Must copy here as the entity system, with the player ship,
            //will be destroyed by the time the effect expires and
            //statistics are passed to the GUI.
            const statistics = *(playerShip.statistics);
            //After the first effect ends, destroy all entities and move to the game over phase.
            effect.onExpired.connect(
            { 
                entitySystem_.destroy();
                gamePhase_ = GamePhase.Over;
                gui_.showGameOverScreen(statistics, gameTime_.gameTime - startTime_);
            });
            effectManager_.addEffect(effect);

            //Start the random lines effect,
            //which will increase while displaying the game over text and decrease 
            //after that.
            effect = new RandomLinesEffect(gameTime_.gameTime,
            (const real startTime,
             const GameTime gameTime, 
             ref RandomLinesEffect.Parameters params)
            {
                const double timeRatio = (gameTime.gameTime - startTime) / 2.0;
                if(timeRatio > 1.0){return true;}
                params.bounds   = Game.gameArea;
                params.minWidth = 0.3;
                params.maxWidth = 2.0;
                //This speed ensures we always see completely random lines.
                params.verticalScrollingSpeed = 72000.0f;
                //Full screen width.
                params.minLength = 5000.0f;
                params.maxLength = 10000.0f;
                params.detailLevel = 1;

                params.lineDirection = Vector2f(1.0f, 0.0f);

                const linesBase = timeRatio > 0.5 ? 1.0 - 2.0 * (timeRatio - 0.5)
                                                  : 2.0 * (timeRatio); 
                const linesSqrt = 40 * clamp(linesBase, 0.0, 1.0);
                params.linesPerPixel = (linesSqrt ^^ 2) / round!uint(gameArea_.area)/*100000.0f*/;
                params.color    = rgba!"8080F040";
                return false;
            });
            effectManager_.addEffect(effect);
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
         * Params:  platform    = Platform to use for user input.
         *          monitor     = MonitorManager to monitor game subsystems.
         *          guiParent   = Parent for all GUI elements used by the game.
         *          videoDriver = Video driver to draw graphics with.
         *          gameDir     = Game data directory.
         *
         * Returns: Produced Game.
         *
         * Throws:  GameStartException if the game fails to start.
         */
        Game produce(Platform platform, 
                     MonitorManager monitor, 
                     GUIElement guiParent,
                     VideoDriver videoDriver,
                     VFSDir gameDir)
        in
        {
            assert(game_ is null,
                   "Can't produce two games at once with GameContainer");
        }
        body
        {
            monitor_ = monitor;
            gui_ = new GameGUI(guiParent);
            scope(failure)
            {
                clear(gui_);
                game_    = null;
                gui_     = null;
                monitor_ = null;
            }
            game_ = new Game(platform, gui_, videoDriver, gameDir);
            return game_;
        }

        ///Destroy the contained Game.
        void destroy()
        {
            clear(game_);
            clear(gui_);
            game_    = null;
            gui_     = null;
            monitor_ = null;
        }
}
