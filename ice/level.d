
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

import audio.soundsystem;
import color;
import component.entitysystem;
import component.controllercomponent;
import component.physicscomponent;
import component.spawnercomponent;
import containers.fixedarray;
import containers.lazyarray;
import containers.vector;
import math.rect;
import math.vector2;
import memory.memory;
import time.gametime;
import util.yaml;
import video.videodriver;

import ice.graphicseffect;
import ice.game;


///Thrown when the level fails to initialize.
class LevelInitException : Exception 
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

        ///Provides access to game subsystems (such as EntitySystem, VideoDriver, etc.).
        GameSubsystems subsystems_;

    public:
        /**
         * Construct a Level.
         *
         * Params:  name       = Name of the level.
         *          subsystems = Provides access to game subsystems 
         *                       (e.g. EntitySystem to spawn entities).
         */
        this(string name, GameSubsystems subsystems) pure nothrow
        {
            name_       = name;
            subsystems_ = subsystems;
        }

        /**
         * Update the level state, executing level script.
         *
         * This might spawn new enemies, display text, etc.
         *
         * Returns: true if the level is still running, false if the level has been 
         *          finished.
         */
        bool update();
}

/**
 * Level implementation based on a dumb YAML script.
 *
 * Described in more detail in modding documentation.
 */
class DumbLevel : Level 
{
    private:
        /**
         * Defines what entities should be spawned in a wave.
         *
         * Wave is actually just an entity that spawns other entities.
         * 
         * Of course, the wave entities must be spawned as well, which is done 
         * by the level.
         */
        struct WaveDefinition
        {
            @disable this(this);
            @disable void opAssign(WaveDefinition);

            public:
                /**
                 * Base prototype of the entity that spawns the wave.
                 *
                 * Components of this prototype might yet be overridden
                 * when the wave is spawned.
                 */
                EntityPrototype* spawnerPrototype;

                /**
                 * Construct a WaveDefinition from YAML.
                 *
                 * Params:  name = Name of the wave definition (for debugging).
                 *          yaml = YAML node to load the definition from.
                 *
                 * Throws:  YAMLException if the WaveDefinition failed to load.
                 */
                this(string name, ref YAMLNode yaml)
                {
                    spawnerPrototype = alloc!EntityPrototype("wave: " ~ name, yaml);
                }

                ///Destroy a WaveDefinition.
                ~this()
                {
                    // Allocation might have failed.
                    if(null is spawnerPrototype){return;}
                    free(spawnerPrototype);
                }
        }

        ///Wave level script instruction.
        struct Wave 
        {
            ///YAML node defining the wave to spawn.
            YAMLNode waveNode;
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

        ///Graphics effect script instruction.
        struct Effect 
        {
            public:
                ///Effect types.
                enum Type
                {
                    Lines,
                    Text
                }

                ///Effect type.
                Type type;

                union
                {
                    ///Control delegate for the Lines effect.
                    bool delegate(const real, const real, 
                                  ref RandomLinesEffect.Parameters) linesDeleg;
                    ///Control delegate for the Text effect.
                    bool delegate(const real, const real, 
                                  ref TextEffect.Parameters) textDeleg;
                }

                /**
                 * Initialize an Effect instruction from YAML.
                 *
                 * Params:  level       = Level this effect belongs to
                 *                        (for debugging and subsystem access)
                 *          instruction = Instruction key from YAML.
                 *          yaml        = Instruction parameters.
                 *
                 * Throws:  YAMLException or LevelInitException
                 *          on failure.
                 */
                this(Level level, string instruction, ref YAMLNode yaml)
                {
                    alias LevelInitException E;
                    auto parts = instruction.split();
                    //Instruction has format "effect xxx", where xxx is effect type.
                    auto type = parts[1];
                    if(parts.length < 2)
                    {
                        throw new E("Effect instruction in level \"" ~ 
                                    level.name_ ~ "\" needs to include effect type");
                    }
                    switch(type)
                    {
                        case "lines": loadLines(level, yaml); break;
                        case "text":  loadText(level, yaml); break;
                        default:
                            throw new E("Unknown effect in script of level \"" ~ 
                                        level.name_ ~ "\": " ~ type);
                    }
                }

            private:
                ///Load a Lines effect.
                void loadLines(Level level, ref YAMLNode yaml)
                {
                    alias LevelInitException E;
                    //YAML error context.
                    const ctx = "\"effect lines\" instruction in level \"" ~ level.name_ ~ "\"";

                    //Load parameters with defaults if not specified,
                    //and validate them.
                    const lineDirection = 
                        yaml.containsKey("lineDirection") 
                        ? angleToVector(fromYAML!float(yaml["lineDirection"], ctx))
                        : Vector2f(0.0f, 1.0f);
                    const minWidth  = 
                        yaml.containsKey("minWidth")
                        ? fromYAML!(float, "a > 0.0f")(yaml["minWidth"], ctx)
                        : 1.0f;
                    const maxWidth  = yaml.containsKey("maxWidth")
                        ? fromYAML!(float, "a > 0.0f")(yaml["maxWidth"], ctx)
                        : 2.0f;
                    const minLength = yaml.containsKey("minLength")
                        ? fromYAML!(float, "a > 0.0f")(yaml["minLength"], ctx)
                        : 1.0f;
                    const maxLength = yaml.containsKey("maxLength")
                        ? fromYAML!(float, "a > 0.0f")(yaml["maxLength"], ctx)
                        : 10.0f;
                    enforce(minWidth <= maxWidth && minLength <= minLength,
                            new E("\"effect lines\" instruction in level \"" ~ 
                                  level.name_ ~ "\": minWidth <= maxWidth && "
                                  "minLength <= maxLength must be true"));

                    const lpp = yaml.containsKey("linesPerPixel")
                        ? fromYAML!(float, "a >= 0.0f && a <= 1.0")(yaml["linesPerPixel"], ctx)
                        : 0.001;
                    const vss = yaml.containsKey("verticalScrollingSpeed")
                        ? fromYAML!(float, "a >= 0.0f")(yaml["verticalScrollingSpeed"], ctx)
                        : 250.0f;
                    const detail = yaml.containsKey("detailLevel")
                        ? yaml["detailLevel"].as!uint
                        : 3;
                    const color = yaml.containsKey("color")
                        ? yaml["color"].as!Color
                        : rgb!"FFFFFF";
                    const time  = yaml.containsKey("time")
                        ? fromYAML!(float, "a >= 0.0")(yaml["time"], ctx)
                        : 0.0f;

                    //Create a control delegate for the effect.
                    linesDeleg = 
                    (const real startTime,
                     const real currentTime,
                     ref RandomLinesEffect.Parameters params)
                    {
                        const timeRatio = (currentTime - startTime) / time;
                        //0 is infinite time
                        if(time != 0.0f && timeRatio > 1.0){return true;}

                        params.bounds                 = level.subsystems_.gameArea;
                        params.lineDirection          = lineDirection;
                        params.minWidth               = minWidth;
                        params.maxWidth               = maxWidth;
                        params.minLength              = minLength;
                        params.maxLength              = maxLength;
                        params.linesPerPixel          = lpp;
                        params.verticalScrollingSpeed = vss;
                        params.detailLevel            = detail;
                        params.color                  = color;

                        return false;
                    };

                    type = Type.Lines;
                }

                ///Load a Text effect.
                void loadText(Level level, ref YAMLNode yaml)
                {
                    //YAML error context.
                    const ctx = "\"effect lines\" instruction in level \"" ~ level.name_ ~ "\"";

                    //Load parameters with defaults if not specified 
                    //(except for text, which must be specified),
                    //and validate them.
                    const text = yaml["text"].as!string;
                    const font = yaml.containsKey("font")
                        ? yaml["font"].as!string  
                        : "default";
                    const fontSize = yaml.containsKey("fontSize")
                        ? yaml["fontSize"].as!uint  
                        : 28;
                    const color = yaml.containsKey("color")
                        ? yaml["color"].as!Color  
                        : rgb!"FFFFFF";
                    const time = yaml.containsKey("time")
                        ? fromYAML!(float, "a >= 0.0")(yaml["time"], ctx)  
                        : 0.0f;

                    //Create a control delegate for the effect.
                    textDeleg =
                    (const real startTime,
                     const real currentTime, 
                     ref TextEffect.Parameters params)
                    {
                        const timeRatio = (currentTime - startTime) / time;
                        //0 is infinite time
                        if(time != 0.0f && timeRatio > 1.0){return true;}

                        params.text = text;
                        params.font = font;
                        params.fontSize = fontSize;
                        params.color = color;

                        auto video = level.subsystems_.videoDriver;
                        video.font = font;
                        video.fontSize = fontSize;
                        const textSize  = video.textSize(text).to!float;
                        const area      = level.subsystems_.gameArea;
                        params.offset   = (area.min + (area.size - textSize) * 0.5).to!int;

                        return false;
                    };
                    type = Type.Text;
                }
        }

        ///Music start script instruction.
        struct Music
        {
            ///Name of the music file to play.
            string music;
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
                    Text,
                    Effect,
                    Music
                }

            private:
                ///Instruction storage.
                union
                {
                    Wave   wave_;
                    Wait   wait_;
                    Text   text_;
                    Effect effect_;
                    Music  music_;
                }
                ///Type of this instruction.
                Type type_ = Type.Uninitialized;

            public:
                ///Construct an instruction. rhs must be a level instruction struct.
                this(T)(T rhs)
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
                    static if     (is(T == Wait))  {return wait_;}
                    else static if(is(T == Wave))  {return wave_;}
                    else static if(is(T == Text))  {return text_;}
                    else static if(is(T == Effect)){return effect_;}
                    else static if(is(T == Music)) {return music_;}
                    else static assert(false, "Unknown instruction type: " ~ T.stringof);
                }

                ///Get type of the instruction.
                @property Type type() const pure nothrow {return type_;}

            private:
                ///Return instruction type matching T (T must be a level instruction).
                static Type instructionType(T)() pure nothrow
                {
                    static if     (is(T == Wait))  {return Type.Wait;}
                    else static if(is(T == Wave))  {return Type.Wave;}
                    else static if(is(T == Text))  {return Type.Text;}
                    else static if(is(T == Effect)){return Type.Effect;}
                    else static if(is(T == Music)) {return Type.Music;}
                    else static assert(false, "Unknown instruction type: " ~ T.stringof);
                }
        }

        ///Dynamically allocated wave definition with a name.
        alias Tuple!(WaveDefinition*, "wave", string, "name") NamedWaveDefinition;

        ///Loaded wave definitions.
        Vector!NamedWaveDefinition waveDefinitions_;

        ///Instructions of the level script. Not using Vector because of a DMD 2.061 error.
        Instruction[] levelScript_;

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
         * Params:  levelName           = Name of the level (used for debugging).
         *          yaml                = YAML source of the level.
         *          subsystems          = Provides access to game subsystems 
         *                                (e.g. EntitySystem to spawn entities).
         *          playerSpawnerSource = YAML source of an entity to spawn the
         *                                player ship.
         *
         * Throws:  LevelInitException on failure.
         */
        this(string levelName, YAMLNode yaml, GameSubsystems gameSybsystems,
             YAMLNode playerSpawnerSource)
        {
            alias LevelInitException E;
            super(levelName, gameSybsystems);
            foreach(string key, ref YAMLNode value; yaml)
            {
                const parts = key.split();
                switch(parts[0])
                {
                    case "wave":  loadWaveDefinition(parts[1], value); break;
                    case "level": loadLevelScript(value);              break;
                    // Used by campaign, not here
                    case "name":  break;
                    default: throw new E("Unknown top-level key in level \"" ~
                                         name_ ~ "\": " ~ key);
                }
            }
            auto playerSpawnerPrototype =
                EntityPrototype("playerShipSpawner", playerSpawnerSource);
            subsystems_.entitySystem.newEntity(playerSpawnerPrototype);
            validateScript();
            enforce(levelLoaded_,
                    new E("Level \"" ~ name_ ~ "\" has no level definition"));
        }

        ///Destroy the level, deleting any loaded units and wave definitions.
        ~this()
        {
            foreach(ref definition; waveDefinitions_)
            {
                free(definition.wave);
            }
        }

        override bool update() 
        {
            instructionTime_ += subsystems_.gameTime.timeStep;

            //Process the instructions until we're done with the level script
            //or an instruction interrupts (usually due to running out of time).
            while(!done) 
            {
                if(updateVM()){break;}
            }

            return !done;
        }

    private:
        ///Update the script virtual machine. Returns true on interrupt, false otherwise.
        bool updateVM()
        {
            auto instruction = levelScript_[instruction_];
            final switch(instruction.type)
            {
                case Instruction.Type.Uninitialized:
                    assert(false, "Uninitialized DumbLevel instruction");
                case Instruction.Type.Wave:   return executeWave(instruction.as!Wave);
                case Instruction.Type.Wait:   return executeWait(instruction.as!Wait);
                case Instruction.Type.Text:   return executeText(instruction.as!Text);
                case Instruction.Type.Effect: return executeEffect(instruction.as!Effect);
                case Instruction.Type.Music:  return executeMusic(instruction.as!Music);
            }
        }

        ///Execute a Wave instruction. Returns true on interrupt, false otherwise.
        bool executeWave(ref Wave instruction) 
        {
            auto node = instruction.waveNode;

            //Get prototype of spawner of wave with specified name, or throw.
            ref EntityPrototype waveSpawnerPrototype(string name)
            {
                const idx = waveDefinitions_[].countUntil!((a,b) => a.name == b)(name);
                alias LevelInitException E;
                enforce(idx >= 0, 
                        new E("Trying to spawn undefined wave: \"" ~ name ~ "\""));
                return *(waveDefinitions_[idx].wave.spawnerPrototype);
            }

            string name = "<invalid_or_missing_name>";
            try
            {
                EntityPrototype wavePrototype;
                if(node.isScalar)
                {
                    name = node.as!string;
                    wavePrototype.clone(waveSpawnerPrototype(name));
                }
                else if(node.isSequence)
                {
                    name = node[0].as!string;
                    const position = fromYAML!Vector2f(node[1]);
                    wavePrototype.clone(waveSpawnerPrototype(name));
                    if(wavePrototype.physics.isNull)
                    {
                        wavePrototype.physics = PhysicsComponent();
                    }
                    wavePrototype.physics.position = position;
                }
                else if(node.isMapping)
                {
                    name = node["wave"].as!string;
                    wavePrototype.clone(waveSpawnerPrototype(name));
                    wavePrototype.overrideComponents(node["components"]);
                }
                else assert(false, "Unknown YAML node type");

                subsystems_.entitySystem.newEntity(wavePrototype);
            }
            catch(YAMLException e)
            {
                writeln("Invalid wave \"" ~ name ~ "\" in a level script. "
                        "Ignoring, not spawning. Details: " ~ e.msg);
            }
            catch(LevelInitException e)
            {
                writeln("Invalid wave \"" ~ name ~ "\" in a level script. "
                        "Ignoring, not spawning. Details: " ~ e.msg);
            }

            nextInstruction();
            return false;
        }

        ///Execute a Wait instruction. Returns true on interrupt, false otherwise.
        bool executeWait(ref Wait instruction) pure nothrow
        {
            if(instructionTime_ > instruction.seconds)
            {
                nextInstruction();
                //We're done with this instruction and 
                //still have time for the next (if any) instruction
                return false;
            }
            //We're not done with this instruction,
            //and it will continue to the next update,
            //so interrupt execution for now.
            return true;
        }

        ///Execute a Text instruction. Returns true on interrupt, false otherwise.
        bool executeText(ref Text instruction) 
        {
            subsystems_.gui.messageText(instruction.text, 3.0f);
            nextInstruction();
            return false;
        }

        ///Execute an Effect instruction. Returns true on interrupt, false otherwise.
        bool executeEffect(ref Effect instruction) 
        {
            GraphicsEffect effect;
            final switch(instruction.type)
            {
                case Effect.Type.Lines:
                    effect = new RandomLinesEffect(subsystems_.gameTime.gameTime,
                                                   instruction.linesDeleg);
                    break;
                case Effect.Type.Text:
                    effect = new TextEffect(subsystems_.gameTime.gameTime,
                                            instruction.textDeleg);
                    break;
            }
            subsystems_.effectManager.addEffect(effect);
            nextInstruction();
            return false;
        }

        ///Execute a Music instruction. Returns true on interrupt, false otherwise.
        bool executeMusic(ref Music instruction) 
        {
            try
            {
                subsystems_.sound.playMusic(instruction.music);
            }
            catch(MusicInitException e)
            {
                writeln("Failed to play music ", instruction.music, " : ", e.msg);
                subsystems_.sound.haltMusic();
            }
            nextInstruction();
            return false;
        }

        /**
         * Validate level script (called after loading the script).
         *
         * Throws: LevelInitException on failure.
         */
        void validateScript() 
        {
            alias LevelInitException E;
            //Nothing here at the moment.
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

        /**
         * Load wave definition with specified name from YAML.
         *
         * Throws:  YAMLException on failure.
         */
        void loadWaveDefinition(string name, ref YAMLNode yaml)
        {
            alias LevelInitException E;

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
                waveDefinitions_ ~=
                    NamedWaveDefinition(alloc!WaveDefinition(name, yaml), name);
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
         * Throws: LevelInitException on failure.
         */
        void loadLevelScript(ref YAMLNode yaml)
        {
            if(levelLoaded_)
            {
                writeln("Duplicate level definition in level \"" ~ name_ ~ 
                        "\" Ignoring any definition except the first.");
            }

            alias LevelInitException E;
            alias Instruction I;
            foreach(string name, ref YAMLNode params; yaml) switch(name.split()[0])
            {
                case "wait":
                    levelScript_ ~= I(Wait(fromYAML!(float, "a >= 0.0")(params, "wait")));
                    break;
                case "wave":   levelScript_ ~= I(Wave(params));               break;
                case "text":   levelScript_ ~= I(Text(params.as!string));     break;
                case "effect": levelScript_ ~= I(Effect(this, name, params)); break; 
                case "music":  levelScript_ ~= I(Music(params.as!string));    break; 
                default:
                    throw new E("Unknown level instruction in level \"" ~ 
                                name_ ~ "\": " ~ name_);
            }
            levelScript_.assumeSafeAppend();
            levelLoaded_ = true;
        }
}
