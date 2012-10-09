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
import std.typecons;

import dgamevfs._;

import color;
import component.collisionsystem;
import component.collisionresponsesystem;
import component.controllersystem;
import component.enginesystem;
import component.entitysystem;
import component.healthsystem;
import component.movementconstraintsystem;
import component.ondeathsystem;
import component.physicssystem;
import component.spatialsystem;
import component.spawnersystem;
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
import monitor.monitormanager;
import platform.platform;
import time.gametime;
import util.frameprofiler;
import util.signal;
import util.yaml;
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
        ///"Really quit?" message after pressing Escape.
        GUIStaticText reallyQuit_;
        ///HUD.
        HUD hud_;

        ///Messages shown when the player dies.
        static deathMessages_ = ["You have been murderized",
                                 "Fail",
                                 "LOL U MAD?",
                                 "All your base are belong to us",
                                 "The trifurcator is exceptionally green",
                                 "Cake is a lie",
                                 "Swim, swim, hungry!",
                                 "Snake? Snake?! SNAAAAAKE!!!!",
                                 "42",
                                 "You were killed",
                                 "Longcat is looooooooooooooooooooooooooooooong",
                                 "Delirious Biznasty",
                                 ":o) hOnK",
                                 "There's a cake in the toilet.",
                                 "DIE FISH HITLER DIE!"
                                     "                                                                                "
                                     "I WONT LET YOU KILL MY PEOPLE!",
                                 "I'm glasses.",
                                 "You are dead"];

        ///Messages shown when the player successfully clears the level.
        static successMessages_ = ["Level cleared",
                                   "You survived",
                                   "Nice~",
                                   "Still alive",
                                   "You aren't quite dead yet",
                                   "MoThErFuCkInG MiRaClEs",
                                   "PCHOOOOOOOO!",
                                   "where doing it man WHERE MAKING THIS HAPEN",
                                   "42"];
    
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
         * Params:  success    = Did the player succeesfully finish the level?
         *          statistics = Player statistics.
         *          totalTime  = Total time taken by the game, in game time
         *                       seconds (i.e. not measuring pauses).
         */
        void showGameOverScreen(const Flag!"success" success,
                                const StatisticsComponent statistics,
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
                text     = randomSample(success ? successMessages_ : deathMessages_, 1).front;
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

        ///Show the "Really quit?" message.
        void showReallyQuit()
        in
        {
            assert(!reallyQuitVisible, 
                   "Trying to show the \"Really quit?\" message "
                   "but it's already shown");
        }
        body
        {
            with(new GUIStaticTextFactory)
            {
                x        = "p_width / 2 - 192";
                y        = "p_height / 2 - 32";
                width    = "384";
                height   = "64";
                font     = "orbitron-bold.ttf";
                fontSize = 32;
                alignX   = AlignX.Center;
                alignY   = AlignY.Center;
                text     = "Really quit? (Y/N)";
                reallyQuit_ = produce();
            }
            parent_.addChild(reallyQuit_);
        }

        ///Hide the "Really quit?" message.
        void hideReallyQuit()
        in
        {
            assert(reallyQuitVisible, 
                   "Trying to hide the \"Really quit?\" message "
                   "but it's not shown");
        }
        body
        {
            reallyQuit_.die();
            reallyQuit_ = null;
        }

        ///Is the "Really quit?" message shown?
        @property bool reallyQuitVisible() const pure nothrow 
        {
            return reallyQuit_ !is null;
        }

        ///Update player health display in the HUD. Must be at least 0 and at most 1.
        void updatePlayerHealth(float health)
        {
            hud_.updatePlayerHealth(health);
        }

        ///Draw any parts of the GUI that need to be drawn manually, not by the GUI subsystem.
        ///
        ///This is a hack to be used until we have a decent GUI subsystem.
        void draw(VideoDriver driver)
        {
            hud_.draw(driver);
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

        ///Destroy the game GUI.
        ~this()
        {
            clear(hud_);
            if(gameOver_ !is null)
            {
                gameOver_.die();
                gameOver_ = null;
            }
            if(reallyQuitVisible)
            {
                hideReallyQuit();
            }
        }

        /**
         * Update the game GUI, using game time subsystem to measure time.
         */
        void update(const GameTime gameTime)
        {
            hud_.update(gameTime);
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
 * Provided by Game to allow access its subsystems.
 *
 * Passed to classes that need access to many game subsystems 
 * but shouldn't be able to e.g. update the game state.
 */
struct GameSubsystems
{
    private:
        ///Game whose subsystems we're accessing.
        Game game_;

    public:
        ///Get a reference to the game GUI.
        @property GameGUI gui() pure nothrow {return game_.gui_;}

        ///Get a reference to the video driver used to draw the game.
        @property VideoDriver videoDriver() pure nothrow {return game_.videoDriver_;}

        ///Get a const reference to the game time subsystem.
        @property const(GameTime) gameTime() const pure nothrow {return game_.gameTime_;}

        ///Get the game data directory.
        @property VFSDir gameDir() pure nothrow {return game_.gameDir_;}

        ///Get a reference to the graphics effect manager.
        @property GraphicsEffectManager effectManager() pure nothrow 
        {
            return game_.effectManager_;
        }

        ///Get the game area.
        @property Rectf gameArea() const nothrow {return game_.gameArea;}

        ///Get a reference to the entity system (e.g. to add new entities).
        @property EntitySystem entitySystem() pure nothrow {return game_.entitySystem_;}
}

///Class managing a single game between players.
class Game
{
    private:
        ///Game phases.
        enum GamePhase
        {
            ///Gameplay phase.
            Playing,
            ///Phase during the game over effect, before the score screen shows up.
            PreOver,
            ///Game over - we're not playing but we still aren't out of the game (e.g. score screen).
            Over
        }

        ///Game phase we're currently in.
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
        VisualSystem             visualSystem_;
        ///Controller subsystem, allows players to control ships.
        ControllerSystem         controllerSystem_;
        ///Physics subsystem. Handles movement and physics interaction.
        PhysicsSystem            physicsSystem_;
        ///Handles various delayed events.
        TimeoutSystem            timeoutSystem_;
        ///Handles weapons and firing.
        WeaponSystem             weaponSystem_;
        ///Handles engine components of the entities, allowing them to move.
        EngineSystem             engineSystem_;
        ///Handles spatial relations between entities.
        SpatialSystem            spatialSystem_;
        ///Handles collision detection.
        CollisionSystem          collisionSystem_;
        ///Handles collision response.
        CollisionResponseSystem  collisionResponseSystem_;
        ///Handles damage caused by warheads.
        WarheadSystem            warheadSystem_;
        ///Handles entity health and kills entities when they run out of health.
        HealthSystem             healthSystem_;
        ///Handles callbacks on death of entities.
        OnDeathSystem            onDeathSystem_;
        ///Handles movement constraints (such as player being limited to the screen).
        MovementConstraintSystem movementConstraintSystem_;
        ///Handles spawning of entities.
        SpawnerSystem            spawnerSystem_;

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

            gui_.update(gameTime_);

            {
                auto zone = Zone("Game subsystem updates");
                //Does as many game logic updates as needed (even zero)
                //to keep constant game update tick.
                gameTime_.doGameUpdates
                ({
                    player1_.update();

                    if(gamePhase_ == gamePhase_.Over) {return false;}

                    entitySystem_.update();

                    if(gamePhase_ == GamePhase.Playing)
                    {
                        auto playerShip = entitySystem_.entityWithID(playerShipID_);

                        if(playerShip !is null)
                        {
                            const health = playerShip.health;
                            if(health !is null)
                            {
                                gui_.updatePlayerHealth(cast(float)health.health / 
                                                        cast(float)health.maxHealth);
                            }
                        }

                        if(!level_.update())
                        {
                            assert(playerShip !is null, 
                                   "Player ship doesn't exist even though the level was "
                                   "successfully completed");
                            gameOver(*playerShip, Yes.success);

                            return true;
                        }
                    }

                    controllerSystem_.update();
                    engineSystem_.update();
                    weaponSystem_.update();
                    physicsSystem_.update();
                    movementConstraintSystem_.update();
                    spatialSystem_.update();
                    collisionSystem_.update();
                    warheadSystem_.update();
                    collisionResponseSystem_.update();
                    healthSystem_.update();
                    timeoutSystem_.update();

                    spawnerSystem_.update();
                    onDeathSystem_.update();

                    return false;
                });

            }
            //Game might have been ended after a level update,
            //which left the component subsystems w/o update,
            //so don't draw either.
            if(!continue_){return false;}

            visualSystem_.update();
            gui_.draw(videoDriver_);

            effectManager_.draw(videoDriver_, gameTime_);

            return true;
        }

        ///Set the VideoDriver used to draw game.
        @property void videoDriver(VideoDriver rhs) pure nothrow
        {
            videoDriver_              = rhs;
            visualSystem_.videoDriver = rhs;
        }

        ///Set the game data directory.
        @property void gameDir(VFSDir rhs) 
        {
            gameDir_                  = rhs;
            controllerSystem_.gameDir = rhs;
            visualSystem_.gameDir     = rhs;
            weaponSystem_.gameDir     = rhs;
            spawnerSystem_.gameDir    = rhs;
        }

        ///Get game area.
        @property static Rectf gameArea() nothrow {return gameArea_;}

    private:
        /**
         * Construct a Game.
         *
         * Params:  platform  = Platform used for input.
         *          gui       = Game GUI.
         *          video     = Video driver used to draw the game.
         *          gameDir   = Game data directory.
         *          levelName = File name of the level to load.
         */
        this(Platform platform, GameGUI gui, VideoDriver video, VFSDir gameDir,
             const string levelName)
        {
            gui_             = gui;
            platform_        = platform;

            initSystems();

            this.videoDriver = video;
            this.gameDir     = gameDir;

            scope(failure){destroySystems();}

            initGameState(levelName);
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
         * Params:  levelName = Name of the level to load.
         * 
         * Throws:  GameStartException on failure.
         */
        void initGameState(const string levelName)
        {
            scope(failure){clear(player1_);}
            player1_  = new HumanPlayer(platform_, "Human");

            scope(failure){clear(level_);}

            //Initialize the level.
            try
            {
                level_ = new DumbLevel(levelName, loadYAML(gameDir_.file(levelName)),
                                       GameSubsystems(this));
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

            gameStateInitialized_ = true;
        }

        ///Initialize game subsystems.
        void initSystems()
        {
            gameTime_  = new GameTime();
            startTime_ = gameTime_.gameTime;      

            //Initialize entity system and game subsystems.
            entitySystem_             = new EntitySystem();
            visualSystem_             = new VisualSystem(entitySystem_);
            controllerSystem_         = new ControllerSystem(entitySystem_, gameTime_);
            physicsSystem_            = new PhysicsSystem   (entitySystem_, gameTime_);
            timeoutSystem_            = new TimeoutSystem   (entitySystem_, gameTime_);
            weaponSystem_             = new WeaponSystem    (entitySystem_, gameTime_);
            engineSystem_             = new EngineSystem    (entitySystem_, gameTime_);
            spatialSystem_            = new SpatialSystem(entitySystem_, 
                                                          Vector2f(400.0f, 300.0f), 
                                                          32.0f, 
                                                          32);
            collisionSystem_          = new CollisionSystem(entitySystem_, spatialSystem_);
            collisionResponseSystem_  = new CollisionResponseSystem(entitySystem_);
            warheadSystem_            = new WarheadSystem(entitySystem_);
            healthSystem_             = new HealthSystem(entitySystem_);
            onDeathSystem_            = new OnDeathSystem(entitySystem_);
            movementConstraintSystem_ = new MovementConstraintSystem(entitySystem_);
            spawnerSystem_            = new SpawnerSystem(entitySystem_, gameTime_);

            effectManager_            = new GraphicsEffectManager();
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
            clear(onDeathSystem_);
            clear(movementConstraintSystem_);
            clear(spawnerSystem_);

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
                    //If the game is over, just quit.
                    if(gamePhase_ != GamePhase.Playing)
                    {
                        continue_ = false;
                        break;
                    }

                    //Show the "Really quit?" message, unless already shown.
                    if(gui_.reallyQuitVisible){break;}
                    gameTime_.timeSpeed = 0.0;
                    gui_.showReallyQuit();
                    break;
                case Key.Return:
                    if(gamePhase_ == GamePhase.Over)
                    {
                        continue_ = false;
                    }
                    break;
                case Key.K_P: 
                    //Pause.
                    const paused = equals(gameTime_.timeSpeed, cast(real)0.0);
                    gameTime_.timeSpeed = paused ? 1.0 : 0.0;
                    break;
                case Key.K_Y:
                    if(gui_.reallyQuitVisible) 
                    {
                        continue_ = false;
                        gui_.hideReallyQuit();
                    }
                    break;
                case Key.K_N:
                    if(gui_.reallyQuitVisible) 
                    {
                        gameTime_.timeSpeed = 1.0;
                        gui_.hideReallyQuit();
                    }
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
        EntityID constructPlayerShip(string name, YAMLNode yaml)
        {
            import component.controllercomponent;
            import component.ondeathcomponent;
            import component.physicscomponent;
            import component.playercomponent;
            import component.spawnercomponent;
            import component.statisticscomponent;

            auto prototype = EntityPrototype(name, yaml);
            with(prototype)
            {
                if(!prototype.weapon.isNull && prototype.spawner.isNull)
                {
                    spawner = SpawnerComponent();
                }

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
            //Level is done already.
            if(gamePhase_ != GamePhase.Playing) {return;}

            gui_.updatePlayerHealth(0.0f);
            gameOver(playerShip, No.success);
        }


        /**
         * Called when the player dies or succeeds in clearing the level.
         *
         * playerShip = Player ship entity to get statistics from.
         * success    = Has the player succesfully cleared the level or died?
         */
        void gameOver(ref Entity playerShip, Flag!"success" success)
        {
            gamePhase_ = GamePhase.PreOver;
            //Game over enlarging text effect.
            GraphicsEffect effect = new TextEffect(gameTime_.gameTime,
               (const real startTime,
                const GameTime gameTime, 
                ref TextEffect.Parameters params)
               {
                   const double timeRatio = (gameTime.gameTime - startTime) / 1.0;
                   if(timeRatio > 1.0){return true;}

                   auto gameOver = success ? "LEVEL DONE" : "GAME OVER";

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
                gui_.showGameOverScreen(success,
                                        statistics, 
                                        gameTime_.gameTime - startTime_);
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
         *          levelName   = Name of the level to load.
         *
         * Returns: Produced Game.
         *
         * Throws:  GameStartException if the game fails to start.
         */
        Game produce(Platform platform, 
                     MonitorManager monitor, 
                     GUIElement guiParent,
                     VideoDriver videoDriver,
                     VFSDir gameDir,
                     const string levelName)
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
            game_ = new Game(platform, gui_, videoDriver, gameDir, levelName);
            monitor_.addMonitorable(game_.entitySystem_, "Entities");
            return game_;
        }

        ///Destroy the contained Game.
        void destroy()
        {
            monitor_.removeMonitorable("Entities");
            clear(game_);
            clear(gui_);
            game_    = null;
            gui_     = null;
            monitor_ = null;
        }
}
