
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Handles execution of a single game level.
module ice.level;


import std.algorithm;
import std.array;
import std.exception;
import std.stdio;
import std.traits;
import std.typecons;
import std.variant;

import dgamevfs._;

import component.entitysystem;
import containers.fixedarray;
import containers.vector;
import memory.memory;
import time.gametime;
import util.yaml;

import ice.game;


///Thrown when the level fails to initialize.
class LevelInitializationFailureException : Exception 
{
    public this(string msg, string file = __FILE__, int line = __LINE__)
    {
        super(msg, file, line);
    }
}

/**
 * Handles execution of a single game level.
 *
 * Note that it is expected to explicitly destroy the Level using clear()
 * once it is not used anymore.
 */
abstract class Level 
{
    protected:
        ///Name of the level (used for debugging).
        const string name_;

        ///EntitySystem to spawn new entities.
        EntitySystem entitySystem_;

        ///Game time subsystem.
        const GameTime gameTime_;

        ///Game directory to load levels and units from.
        VFSDir gameDir_;

    public:
        /**
         * Construct a Level.
         *
         * Params:  name         = Name of the level.
         *          entitySystem = EntitySystem to spawn new entities with.
         *          gameTime     = Game time subsystem.
         *          gameDir      = Game data directory to load levels and units from.
         */
        this(string name, EntitySystem entitySystem, const GameTime gameTime,
             VFSDir gameDir) pure nothrow
        {
            name_         = name;
            entitySystem_ = entitySystem;
            gameTime_     = gameTime;
            gameDir_      = gameDir;
        }

        /**
         * Set the game data directory.
         *
         * Note that this will NOT reload units and levels that are already loaded.
         */
        @property void gameDir(VFSDir rhs) pure nothrow
        {
            gameDir_ = rhs;
        }

        /**
         * Update the level state, executing level script.
         *
         * This might spawn new enemies, display text, etc.
         *
         * Returns: true if the level is still running, false if the level has been 
         *          finished.
         */
        bool update(GameGUI gui);
}

/**
 * Level implementation based on a dumb YAML script.
 *
 * A level is composed of definitions of "waves" (groups of enemies
 * spawned simultaneously) and of a level script, which specifies when to 
 * spawn a wave.
 *
 * Example:
 * --------------------
 * wave wave1:
 *   spawn:
 *     - unit: ships/enemy1.yaml
 *       physics: 
 *           position: [360, 32]
 *           rotation: 0
 *     - unit: ships/playership.yaml
 *       physics: 
 *           position: [440, 64]
 *           rotation: 0
 *       dumbScript: dumbscripts/enemy1.yaml
 * 
 * level:
 *   !!pairs
 *   - wait: 2.0
 *   - wave: wave1
 *   - wait: 5.0
 *   - text: Lorem Ipsum  #at top or bottom of screen 
 *   - wait: 5.0
 *   - text: Level done!
 * --------------------
 *
 * Wave definition:
 *
 * A wave definition starts with a mapping key named $(B wave xxx) where xxx is 
 * the name of the wave. Wave names $(B must not contain spaces) .
 *
 * There can be any number of wave definitions, but there must not be two 
 * wave definitions with identical name.
 *
 * Currently, the wave definition has one section, $(B spawn), which is a 
 * sequence of units (entities) to be spawned. Each unit is a mapping with one
 * required key, $(B unit), which specifies filename of the unit to spawn. The 
 * unit might contain more keys, which define components to override components 
 * loaded from the unit definition. This allows, for example, for a particular 
 * spawned unit to use a different script or weapon.
 *
 * Level script:
 *
 * The level script starts with a mapping key named $(B level), and is composed of
 * pairs of instructions and their parameters.
 *
 * Current DumbLevel instructions:
 *
 * wait:
 *
 * Example:
 * --------------------
 * - wait: 2.0 #Wait 2 seconds
 * --------------------
 * Wait for specified time, in seconds. Must not be negative.
 *
 *
 * wave:
 *
 * Example:
 * --------------------
 * - wave: wave1 #Launch wave "wave1"
 * --------------------
 *
 * Launch wave defined in wave definition with specified name. The wave must be
 * defined.
 *
 *
 * text:
 *
 * Example:
 *
 * --------------------
 * - text: Lorem Ipsum #Display specified text
 * --------------------
 *
 * Display specified text on the HUD.
 */
class DumbLevel : Level 
{
    private:
        ///Defines what entities should be spawned in a wave.
        struct WaveDefinition
        {
            @disable this(this);
            @disable void opAssign(WaveDefinition);

            private:
                ///Prototypes of entities to spawn in this wave.
                FixedArray!(EntityPrototype*) spawns_;

            public:
                /**
                 * Construct a WaveDefinition fro YAML.
                 *
                 * Params:  level = Level that uses this definition.
                 *                  Used to load unit prototypes.
                 *
                 * Throws:  YAMLException if the WaveDefinition failed to load.
                 */
                this(DumbLevel level, ref YAMLNode yaml)
                {
                    import component.controllercomponent;

                    auto spawns = yaml["spawn"];
                    spawns_ = FixedArray!(EntityPrototype*)(spawns.length);
                    uint spawnIdx = 0;
                    foreach(ref YAMLNode spawn; spawns)
                    {
                        auto name = spawn["unit"].as!string;
                        EntityPrototype* prototype = level.unitPrototype(name);
                        spawns_[spawnIdx] = alloc!EntityPrototype;
                        spawns_[spawnIdx].clone(*prototype);
                        spawns_[spawnIdx].controller = ControllerComponent();
                        spawns_[spawnIdx].overrideComponents(spawn);
                        ++spawnIdx;
                    }
                }

                ///Destroy the WaveDefinition, freeing all memory it uses.
                ~this()
                {
                    foreach(ref spawn; spawns_)
                    {
                        free(spawn);
                    }
                }

                ///Launch the wave, spawning its entities.
                void launch(EntitySystem entitySystem)
                {
                    foreach(ref spawn; spawns_)
                    {
                        entitySystem.newEntity(*spawn);
                    }
                }
        }

        ///Wave level script instruction.
        struct Wave 
        {
            ///Name of the wave to launch.
            string waveName;
        }

        ///Wait level script instruction.
        struct Wait
        {
            ///Number of seconds to wait.
            float seconds;
        }

        ///Wave level script instruction.
        struct Text 
        {
            ///Text to display on the HUD.
            string text;
        }

        ///Single level script instruction.
        struct Instruction
        {
            public:
                ///Instruction types.
                enum Type : ubyte
                {
                    Uninitialized = 0,
                    Wave, 
                    Wait, 
                    Text
                }

            private:
                ///Zero-initialize when manually allocating.
                static bool CAN_INITIALIZE_WITH_ZEROES;
                ///Instruction storage.
                union
                {
                    Wave wave_;
                    Wait wait_;
                    Text text_;
                }
                ///Type of this instruction.
                Type type_ = Type.Uninitialized;

            public:
                ///Construct an instruction. rhs must be a level instruction struct.
                this(T)(T rhs) pure nothrow
                {
                    alias Unqual!T U;
                    type_ = instructionType!U();
                    as!U = rhs;
                }

                /**
                 * Access the instruction as specified type. 
                 *
                 * T must match the actual instruction type.
                 */
                @property ref inout auto as(T)() inout pure nothrow
                {
                    assert(type_ == instructionType!T(),
                           "Unexpected instruction type (expected\"" ~ T.stringof ~ "\")");
                    static if     (is(T == Wait)){return wait_;}
                    else static if(is(T == Wave)){return wave_;}
                    else static if(is(T == Text)){return text_;}
                    else static assert(false, "Unknown instruction type: " ~ T.stringof);
                }

                ///Get type of the instruction.
                @property Type type() const pure nothrow {return type_;}

            private:
                ///Return instruction type matching T (T must be a level instruction).
                static Type instructionType(T)() pure nothrow
                {
                    static if     (is(T == Wait)){return Type.Wait;}
                    else static if(is(T == Wave)){return Type.Wave;}
                    else static if(is(T == Text)){return Type.Text;}
                    else static assert(false, "Unknown instruction type: " ~ T.stringof);
                }
        }

        ///Dynamically allocated wave definition with a name.
        alias Tuple!(WaveDefinition*, "wave", string, "name") NamedWaveDefinition;
        ///Dynamically allocated unit (entity) prototype with a name.
        alias Tuple!(EntityPrototype*, "prototype", string, "name") NamedUnit;

        ///Loaded wave definitions.
        Vector!NamedWaveDefinition waveDefinitions_;

        ///Instructions of the level script.
        Vector!Instruction levelScript_;

        ///Loaded unit prototypes.
        Vector!NamedUnit unitPrototypes_;

        ///Has the level been successfully loaded?
        bool levelLoaded_ = false;

        ///Current instruction in the level script.
        uint instruction_ = 0;

        ///Time the current instruction has taken so far.
        float instructionTime_ = 0.0f;

    public:

        /**
         * Construct a DumbLevel.
         *
         * Params:  levelName    = Name of the level (used for debugging).
         *          yaml         = YAML source of the level.
         *          entitySystem = EntitySystem to spawn entities into.
         *          gameTime     = Game time subsystem.
         *          gameDir      = Game data directory to load levels/units from.
         *
         * Throws:  LevelInitializationFailureException on failure.
         */
        this(string levelName, YAMLNode yaml, EntitySystem entitySystem, 
             const GameTime gameTime, VFSDir gameDir)
        {
            alias LevelInitializationFailureException E;
            super(levelName, entitySystem, gameTime, gameDir);
            foreach(string key, ref YAMLNode value; yaml)
            {
                const parts = key.split();
                switch(parts[0])
                {
                    case "wave":  loadWaveDefinition(parts[1], value); break;
                    case "level": loadLevelScript(value);          break;
                    default: throw new E("Unknown top-level key in level \"" ~
                                         name_ ~ "\": " ~ key);
                }
            }
            validateScript();
            enforce(levelLoaded_,
                    new E("Level \"" ~ name_ ~ "\" has no level definition"));
        }

        ///Destroy the level, deleting any loaded units and wave definitions.
        ~this()
        {
            foreach(ref unit; unitPrototypes_)
            {
                free(unit.prototype);
            }
            foreach(ref definition; waveDefinitions_)
            {
                free(definition.wave);
            }
        }

        override bool update(GameGUI gui) 
        {
            instructionTime_ += gameTime_.timeStep;
            //Process the instructions until we're done with the level script
            //or an instruction interrupts (usually due to running out of time).
            interrupt: while(!done) 
            {
                auto instruction = levelScript_[instruction_];
                final switch(instruction.type)
                {
                    case Instruction.Type.Uninitialized:
                        assert(false, "Uninitialized DumbLevel instruction");
                    case Instruction.Type.Wave:
                        spawnWave(instruction.as!Wave.waveName);
                        nextInstruction();
                        break;
                    case Instruction.Type.Wait:
                        if(instructionTime_ > instruction.as!Wait.seconds)
                        {
                            nextInstruction();
                            //We're done with this instruction and 
                            //still have time for the next (if any) instruction
                            break;
                        }
                        //We're not done with this instruction,
                        //and it will continue to the next update,
                        //so interrupt execution for now.
                        break interrupt;
                    case Instruction.Type.Text:
                        gui.messageText(instruction.as!Text.text, 3.0f);
                        nextInstruction();
                        break;
                }
            }

            return !done;
        }

    private:
        ///Validate level script (called after loading the script).
        void validateScript() 
        {
            alias LevelInitializationFailureException E;
            //Ensure every used wave is defined.
            foreach(ref i; levelScript_) if(i.type == Instruction.Type.Wave)
            {
                auto wave = i.as!Wave.waveName;
                enforce(waveDefinitions_[].canFind!((a, b) => a.name == b)(wave),
                        new E("Undefined wave \"" ~ wave ~ "\" in level \"" 
                              ~ name_ ~ "\""));
            }
        }

        ///Is the level script finished?
        @property bool done() const pure nothrow 
        {
            return instruction_ >= levelScript_.length;
        }

        ///Move to the next instruction in the level script.
        void nextInstruction() pure nothrow
        {
            ++instruction_;
            instructionTime_ = 0.0f;
        }

        ///Spawn wave with specified name.
        void spawnWave(string name)
        {
            const waveIdx = waveDefinitions_[].countUntil!((a,b) => a.name == b)(name);
            assert(waveIdx >= 0, 
                   "Trying to spawn undefined wave (this should have been " ~ 
                   "detected at level load): \"" ~ name ~ "\"");
            waveDefinitions_[waveIdx].wave.launch(entitySystem_);
        }

        ///Get a pointer to prototype of unit with given file name, loading it if needed.
        EntityPrototype* unitPrototype(string name)
        {
            const unitIdx = unitPrototypes_[].countUntil!((a,b) => a.name == b)(name);
            if(unitIdx < 0)
            {
                loadUnit(name);
                return unitPrototypes_.back.prototype;
            }
            return unitPrototypes_[unitIdx].prototype;
        }

        ///Load unit with specified file name.
        void loadUnit(string name)
        {
            void fail(string msg)
            {
                writeln("Failed to load unit ", name, ": ", msg);
                writeln("Falling back to placeholder unit...");
                assert(false, "TODO - Placeholder unit not yet implemented");
            }
            try
            {
                auto yaml = loadYAML(gameDir_.file(name));
                unitPrototypes_ ~= NamedUnit(alloc!EntityPrototype(name, yaml), name);
            }
            catch(YAMLException e){fail(e.msg);}
            catch(VFSException e) {fail(e.msg);}
        }

        /**
         * Load wave definition with specified name from YAML.
         *
         * Throws:  YAMLException on failure.
         */
        void loadWaveDefinition(string name, ref YAMLNode yaml)
        {
            alias LevelInitializationFailureException E;

            //Enforce we don't have duplicate wave definitions.
            if(waveDefinitions_[].canFind!((a,b) => a.name == b)(name))
            {
                writeln("Duplicate definition of wave \"" ~ name ~ "\" in " ~ 
                        "level \"" ~ name_ ~ "\" . Ignoring any " ~
                        "definition except the first.");
                return;
            }

            try
            {
                //Add the wave definition.
                waveDefinitions_ ~= NamedWaveDefinition(alloc!WaveDefinition(this, yaml), name);
            }
            catch(YAMLException e)
            {
                throw new E("Failed to load wave definition \"" ~ name ~ "\" :" ~
                            e.msg);
            }
        }

        /**
         * Load level script from YAML.
         * 
         * Throws: LevelInitializationFailureException on failure.
         */
        void loadLevelScript(ref YAMLNode yaml)
        {
            if(levelLoaded_)
            {
                writeln("Duplicate level definition in level \"" ~ name_ ~ 
                        "\" Ignoring any definition except the first.");
            }

            alias LevelInitializationFailureException E;
            alias Instruction I;
            foreach(string name, ref YAMLNode params; yaml) switch(name)
            {
                case "wait":
                    levelScript_ ~= I(Wait(fromYAML!(float, "a >= 0.0")(params, "wait")));
                    break;
                case "wave": levelScript_ ~= I(Wave(params.as!string)); break;
                case "text": levelScript_ ~= I(Text(params.as!string)); break;
                default:
                    throw new E("Unknown level instruction in level \"" ~ 
                                name_ ~ "\": " ~ name_);
            }
            levelLoaded_ = true;
        }
}
