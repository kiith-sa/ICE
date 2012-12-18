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
import std.stdio;
import std.typecons;

import dgamevfs._;

import audio.soundsystem;
import color;
import component.auralsystem;
import component.collisionsystem;
import component.collisionresponsesystem;
import component.controllersystem;
import component.enginesystem;
import component.entitysystem;
import component.healthsystem;
import component.movementconstraintsystem;
import component.physicssystem;
import component.playersystem;
import component.scoresystem;
import component.spatialsystem;
import component.spawnersystem;
import component.statisticscomponent;
import component.tagscomponent;
import component.tagssystem;
import component.timeoutsystem;
import component.warheadsystem;
import component.weaponcomponent;
import component.weaponsystem;
import component.system;
import component.visualsystem;
import gui2.exceptions;
import gui2.guisystem;
import math.math;
import math.vector2;
import math.rect;
import memory.memory;
import monitor.monitormanager;
import platform.platform;
import time.gametime;
import time.time;
import util.frameprofiler;
import util.resourcemanager;
import util.signal;
import util.yaml;
import video.videodriver;

import ice.gamegui;
import ice.graphicseffect;
import ice.guiswapper;
import ice.level;
import ice.player;
import ice.playerprofile;


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

    ///Get a reference to the sound system.
    @property SoundSystem sound() pure nothrow {return game_.sound_;}

    ///Get the game area.
    @property Rectf gameArea() const nothrow {return game_.gameArea;}

    ///Get a reference to the entity system (e.g. to add new entities).
    @property EntitySystem entitySystem() pure nothrow {return game_.entitySystem_;}
}

///Stores various data about the end of a game.
struct GameOverData
{
    /// Statistics of the player.
    StatisticsComponent playerStatistics;
    /// Did the player win the game?
    bool gameWon;
    /// Total time taken by the game, in game time seconds (i.e. not measuring pauses).
    real totalTime;
}

///Class managing a single game in a level.
class Game
{
private:
    /// Possible states of the player ship.
    enum PlayerState
    {
        /// THe player ship has not been spawned yet.
        PreSpawn,
        /// The player ship exists.
        Alive, 
        /// The player ship has died.
        Dead
    }

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

    /// Current state of the player ship.
    PlayerState playerState_;

    /// Statistics (kills, etc.) of the player ship.
    StatisticsComponent playerStatistics_;

    ///Platform used for input.
    Platform platform_;

    ///Game area in world space.
    static immutable Rectf gameArea_ = Rectf(0.0f, 0.0f, 800.0f, 600.0f);

    ///Player 1.
    Player player0_;

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

    ///Reference to the sound system.
    SoundSystem sound_;

    ///Profile of the player playing the game.
    PlayerProfile playerProfile_;

    ///Game time when the game started.
    real startTime_;

    ///Game time subsystem, schedules updates.
    GameTime gameTime_;

    /// Manages YAML file loading.
    ResourceManager!YAMLNode yamlResourceManager_;

    ///Game entity system.
    EntitySystem entitySystem_;

    /// Visual subsystem, draws entities.
    VisualSystem             visualSystem_;
    /// Controller subsystem, allows players to control ships.
    ControllerSystem         controllerSystem_;
    /// Physics subsystem. Handles movement and physics interaction.
    PhysicsSystem            physicsSystem_;
    /// Handles various delayed events.
    TimeoutSystem            timeoutSystem_;
    /// Handles weapons and firing.
    WeaponSystem             weaponSystem_;
    /// Handles engine components of the entities, allowing them to move.
    EngineSystem             engineSystem_;
    /// Handles spatial relations between entities.
    SpatialSystem            spatialSystem_;
    /// Handles collision detection.
    CollisionSystem          collisionSystem_;
    /// Handles collision response.
    CollisionResponseSystem  collisionResponseSystem_;
    /// Handles damage caused by warheads.
    WarheadSystem            warheadSystem_;
    /// Handles entity health and kills entities when they run out of health.
    HealthSystem             healthSystem_;
    /// Handles movement constraints (such as player being limited to the screen).
    MovementConstraintSystem movementConstraintSystem_;
    /// Handles spawning of entities.
    SpawnerSystem            spawnerSystem_;
    /// Handles entity tagging.
    TagsSystem               tagSystem_;
    /// Assigns game players to PlayerComponents.
    PlayerSystem             playerSystem_;
    /// Handles scoring.
    ScoreSystem              scoreSystem_;
    /// Handles entity sounds;
    AuralSystem              auralSystem_;

    ///Level the game is running.
    Level level_;

    ///Used to make draw calls.
    VideoDriver videoDriver_;

    ///Manages graphics effects.
    GraphicsEffectManager effectManager_;

public:
    /// Emitted when the game ends (regardless of who wins).
    mixin Signal!(GameOverData) atGameOver;

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
                player0_.update();

                if(gamePhase_ == gamePhase_.Over) {return false;}

                {
                    auto zone = Zone("Entity system update");
                    entitySystem_.update();
                }

                if(gamePhase_ == GamePhase.Playing)
                {
                    auto playerShip = entitySystem_.entityWithID(playerShipID_);

                    if(playerShip !is null)
                    {
                        playerState_ = PlayerState.Alive;

                        const statistics   = playerShip.statistics;
                        const weapon = playerShip.weapon;

                        if(statistics !is null)
                        {
                            playerStatistics_ = *statistics;
                            gui_.updatePlayerStatistics(playerStatistics_);
                        }
                        if(weapon !is null)
                        {
                            gui_.updatePlayerWeapon(*weapon);
                        }
                        const health = playerShip.health;
                        if(health !is null)
                        {
                            gui_.updatePlayerHealth(cast(float)health.health / 
                                                    cast(float)health.maxHealth);
                        }
                    }
                    // Player ship doesn't exist anymore; player has died.
                    else if(playerState_ == PlayerState.Alive)
                    {
                        playerState_ = PlayerState.Dead;
                        playerDied();
                    }

                    if(!level_.update())
                    {
                        assert(playerShip !is null, 
                               "Player ship doesn't exist even though the level was "
                               "successfully completed");
                        gameOver(Yes.success);

                        return true;
                    }
                }

                void zonedUpdate(string systemName)(System system)
                {
                    enum name = systemName ~ " system update";
                    auto zone = Zone(name);
                    system.update();
                }

                zonedUpdate!"Player"(playerSystem_);
                zonedUpdate!"Controller"(controllerSystem_);
                zonedUpdate!"Engine"(engineSystem_);
                zonedUpdate!"Weapon"(weaponSystem_);
                zonedUpdate!"Physics"(physicsSystem_);
                zonedUpdate!"MovementConstraint"(movementConstraintSystem_);
                zonedUpdate!"Spatial"(spatialSystem_);
                zonedUpdate!"Collision"(collisionSystem_);
                zonedUpdate!"Warhead"(warheadSystem_);
                zonedUpdate!"CollisionResponse"(collisionResponseSystem_);
                // Kills entities.
                zonedUpdate!"Health"(healthSystem_);
                // Systems which react to killed entities must be updated here.
                zonedUpdate!"Score"(scoreSystem_);
                zonedUpdate!"Aural"(auralSystem_);
                zonedUpdate!"Tag"(tagSystem_);
                zonedUpdate!"Timeout"(timeoutSystem_);
                zonedUpdate!"Spawner"(spawnerSystem_);

                return false;
            });

        }
        //Game might have been ended after a level update,
        //which left the component subsystems w/o update,
        //so don't draw either.
        if(!continue_){return false;}


        {
            auto zone = Zone("Visual system update");
            visualSystem_.update();
        }

        {
            auto zone = Zone("Effect manager draw");
            effectManager_.draw(videoDriver_, gameTime_.gameTime);
        }

        return true;
    }

    ///Set the VideoDriver used to draw game.
    @property void videoDriver(VideoDriver rhs) pure nothrow
    {
        videoDriver_              = rhs;
        visualSystem_.videoDriver = rhs;
    }

    ///Get game area.
    @property static Rectf gameArea() nothrow {return gameArea_;}

private:
    /**
     * Construct a Game.
     *
     * Params:  platform    = Platform used for input.
     *          gui         = Game GUI.
     *          video       = Video driver used to draw the game.
     *          gameDir     = Game data directory.
     *          profile     = Profile of the current player.
     *          yamlManager = Resource manager managing YAML files.
     *          sound       = Reference to the sound system.
     *          levelSource = YAML source of the level to load.
     */
    this(Platform platform, GameGUI gui, VideoDriver video, VFSDir gameDir,
         PlayerProfile profile, ResourceManager!YAMLNode yamlManager,
         SoundSystem sound, ref YAMLNode levelSource)
    {
        gui_                 = gui;
        platform_            = platform;
        playerProfile_       = profile;
        yamlResourceManager_ = yamlManager;
        sound_               = sound;

        scope(failure){clear(player0_);}
        player0_  = new HumanPlayer(platform_, "Human");
        gameDir_         = gameDir;

        initSystems();

        this.videoDriver = video;
        initYAML();

        scope(failure){destroySystems();}

        initGameState(levelSource);
    }

    ///Destroy the Game.
    ~this()
    {
        platform_.showCursor();
        if(gameStateInitialized_)
        {
            clear(player0_);
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
     * Params:  levelSource = YAML source of the level to load.
     * 
     * Throws:  GameStartException on failure.
     */
    void initGameState(ref YAMLNode levelSource)
    {
        scope(failure){clear(level_);}

        platform_.hideCursor();
        //Initialize the level.
        try
        {
            level_ = new DumbLevel(levelSource["name"].as!string, levelSource,
                                   GameSubsystems(this), playerProfile_.playerShipSpawner);
        }
        catch(LevelInitException e)
        {
            throw new GameStartException("Failed to initialize level " ~
                                         levelSource["name"].as!string ~ " : " ~ e.msg);
        }

        // Called every frame the player ship exists by the tagSystem_.
        void getPlayerShipID(const EntityID id)
        {
            playerShipID_ = id;
        }
        tagSystem_.callOnTag("_PLR", &getPlayerShipID);

        playerState_ = PlayerState.PreSpawn;

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
        writeln("Initializing Game subsystems at ", getTime());

        //Initialize entity system and game subsystems.
        entitySystem_             = new EntitySystem();
        visualSystem_             = new VisualSystem(entitySystem_, gameDir_);
        controllerSystem_         = new ControllerSystem(entitySystem_, gameTime_);
        physicsSystem_            = new PhysicsSystem   (entitySystem_, gameTime_);
        timeoutSystem_            = new TimeoutSystem   (entitySystem_, gameTime_);
        weaponSystem_             = new WeaponSystem    (entitySystem_, gameTime_);
        engineSystem_             = new EngineSystem    (entitySystem_, gameTime_);
        spatialSystem_            = new SpatialSystem(entitySystem_, 
                                                      Vector2f(400.0f, 300.0f), 
                                                      48.0f, 
                                                      24);
        collisionSystem_          = new CollisionSystem(entitySystem_, spatialSystem_);
        collisionResponseSystem_  = new CollisionResponseSystem(entitySystem_);
        warheadSystem_            = new WarheadSystem(entitySystem_);
        healthSystem_             = new HealthSystem(entitySystem_);
        movementConstraintSystem_ = new MovementConstraintSystem(entitySystem_);
        spawnerSystem_            = new SpawnerSystem(entitySystem_, gameTime_);
        tagSystem_                = new TagsSystem(entitySystem_);
        scoreSystem_              = new ScoreSystem(entitySystem_);
        auralSystem_              = new AuralSystem(entitySystem_, sound_);
        playerSystem_             = new PlayerSystem(entitySystem_, [player0_]);

        effectManager_            = new GraphicsEffectManager();
    }

    ///Destroy game subsystems.
    void destroySystems()
    {
        writeln("Denitializing Game subsystems at ", getTime());
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
        clear(auralSystem_);
        clear(scoreSystem_);
        clear(healthSystem_);
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

    /// Pass yamlResourceManager_ to subsystems.
    void initYAML()
    {
        weaponSystem_.yamlManager     = yamlResourceManager_;
        spawnerSystem_.yamlManager    = yamlResourceManager_;
        controllerSystem_.yamlManager = yamlResourceManager_;
        visualSystem_.yamlManager     = yamlResourceManager_;
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
                if(gui_.quitScreenVisible){break;}
                gameTime_.timeSpeed = 0.0;
                gui_.showQuitScreen();
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
                if(gui_.quitScreenVisible) 
                {
                    continue_ = false;
                    gui_.hideQuitScreen();
                }
                break;
            case Key.K_N:
                if(gui_.quitScreenVisible) 
                {
                    gameTime_.timeSpeed = 1.0;
                    gui_.hideQuitScreen();
                }
                break;
            default:
                break;
        }
    }

    ///Called when the player ship has died.
    void playerDied()
    {
        //Level is done already.
        if(gamePhase_ != GamePhase.Playing) {return;}

        gui_.updatePlayerHealth(0.0f);
        gameOver(No.success);
    }

    /**
     * Called when the player dies or succeeds in clearing the level.
     *
     * success    = Has the player succesfully cleared the level or died?
     */
    void gameOver(Flag!"success" success)
    {
        platform_.showCursor();
        GameOverData gameOverData;
        gameOverData.gameWon = success;
        gameOverData.playerStatistics = playerStatistics_;
        gameOverData.totalTime = gameTime_.gameTime - startTime_;
        atGameOver.emit(gameOverData);
        gamePhase_ = GamePhase.PreOver;
        //Game over enlarging text effect.
        GraphicsEffect effect = new TextEffect(gameTime_.gameTime,
           (const real startTime,
            const real currentTime,
            ref TextEffect.Parameters params)
           {
               const double timeRatio = (currentTime - startTime) / 1.0;
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
        const statistics = playerStatistics_;
        //After the first effect ends, destroy all entities and move to the game over phase.
        effect.onExpired.connect(
        { 
            entitySystem_.destroy();
            gamePhase_ = GamePhase.Over;
            gui_.showGameOverScreen(gameOverData);
        });
        effectManager_.addEffect(effect);

        //Start the random lines effect,
        //which will increase while displaying the game over text and decrease 
        //after that.
        effect = new RandomLinesEffect(gameTime_.gameTime,
        (const real startTime,
         const real currentTime,
         ref RandomLinesEffect.Parameters params)
        {
            const double timeRatio = (currentTime - startTime) / 2.0;
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
        //GUI of the game.
        GameGUI gui_;
        //Game itself.
        Game game_;
        //MonitorManager to add game subsystem monitors to.
        MonitorManager monitor_;

        // The following dependencies don't change between games.

        // A reference to the GUI system.
        GUISystem guiSystem_;
        // A reference to the sound system
        SoundSystem sound_;

    public:
        /// Produce a GameContainer with dependencies that never change between game instances.
        ///
        /// Params: guiSystem = A reference to the GUI system.
        ///         sound     = A reference to the sound system.
        this(GUISystem guiSystem, SoundSystem sound)
        {
            guiSystem_ = guiSystem;
            sound_     = sound;
        }

        /**
         * Produce a Game and return a reference to it.
         *
         * Params:  platform    = Platform to use for user input.
         *          monitor     = MonitorManager to monitor game subsystems.
         *          guiSwapper  = A reference to the GUI swapper.
         *          videoDriver = Video driver to draw graphics with.
         *          gameDir     = Game data directory.
         *          profile     = Profile of the current player.
         *          levelSource = YAML source of the level to load.
         *
         * Returns: Produced Game.
         *
         * Throws:  GameStartException if the game fails to start.
         */
        Game produce(Platform platform,
                     MonitorManager monitor,
                     GUISwapper guiSwapper,
                     VideoDriver videoDriver,
                     VFSDir gameDir,
                     ResourceManager!YAMLNode yamlManager,
                     PlayerProfile profile,
                     ref YAMLNode levelSource)
        in
        {
            assert(game_ is null,
                   "Can't produce two games at once with GameContainer");
        }
        body
        {
            monitor_ = monitor;

            try
            {
                gui_ = new GameGUI(guiSystem_, guiSwapper, gameDir);
            }
            catch(YAMLException e)
            {
                throw new GameStartException("Failed to initialize game GUI: " ~ e.msg);
            } 
            catch(VFSException e)
            {
                throw new GameStartException("Failed to initialize game GUI: " ~ e.msg);
            }

            scope(failure)
            {
                clear(gui_);
                game_    = null;
                gui_     = null;
                monitor_ = null;
            }
            game_ = new Game(platform, gui_, videoDriver, gameDir, profile, 
                             yamlManager, sound_, levelSource);
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
