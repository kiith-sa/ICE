
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
 * A level is composed of definitions of "waves" (groups of enemies
 * spawned simultaneously) and of a level script, which specifies when to 
 * spawn a wave.
 *
 * Example:
 * --------------------
 * wave wave1:
 *   spawner:
 *     - entity: ships/enemy1.yaml 
 *       components:
 *         physics: 
 *             position: [360, 32]
 *     - entity: ships/playerShip.yaml
 *       components:
 *         physics: 
 *             position: [440, 64]
 *         dumbScript: dumbscripts/enemy1.yaml
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
 * Waves contain units to be spawned when the wave command is used in the 
 * level. In ICE, waves are actually entities and are defined as entities.
 *
 * Thus, the units to spawn are specified in a spawner component, just like 
 * with an entity. Other components can be specified as well if needed, but 
 * that's not common.
 *
 * In this case, we spawn 2 units. We specify physics components for both 
 * (this is needed for the units to show up), and for one unit, we also 
 * specify the dumbScript component. Components specified here override 
 * the components specified in units' YAML files, so we can for instance change 
 * what weapons a unit is spawned with.
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
 * Examples:
 * --------------------
 * #Launch wave "wave1"
 * - wave: wave1 
 * #Launch wave "wave1" at offset [50, 100]
 * - wave: [wave1, [50, 100]] 
 * #Launch wave "wave1" at offset [100, 300], rotating it by 0.8 radians
 * - wave: 
 *     wave: wave2
 *     components:
 *       physics:
 *         position: [100, 300]
 *         rotation: 0.8
 * --------------------
 *
 * Launch wave defined in wave definition with specified name. The wave must be
 * defined.
 *
 * There are three ways to launch a wave, shown above. The first example simply
 * spawns the wave. The second example spawns the wave with an offset added to 
 * positions of spawned units.
 * Finally the third example spawns the wave, overriding its physics component,
 * utilizing the fact that the wave is really an entity. This can be used to 
 * create more complex scenarios.
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
 *
 *
 * effect:
 *
 * Examples:
 * --------------------
 * #Draws a huge red transparent "42" at the center of the screen for one second.
 * - effect text:
 *     text: 42
 *     font: default 
 *     fontSize: 512
 *     color: rgbaFF000080
 *     time: 1.0
 *     
 * #Draws random vertical lines quickly moving vertically through the screen.
 * #As time is not specified, they are drawn until the end of game.
 * - effect lines:
 *     minWidth: 0.6
 *     maxWidth: 1.0
 *     minLength: 16.0
 *     maxLength: 32.0
 *     verticalScrollingSpeed: 1500.0
 *     linesPerPixel: 0.000003
 *     detailLevel: 8
 *     color: rgbaF8F8ECA0
 * --------------------
 * 
 * Draw a graphics effect with specified parameters.
 *
 * Effect to draw is specified after "effect" in the instruction name, 
 * separated by space. 
 *
 * There are two effects to draw: text and lines.
 *
 * "text" draws a text in the center of the screen.
 *
 * Params:
 *     text     = Text to draw. This must be specified - there is no default.
 *     font     = Font to use. "default" is the default font. Default: "default"
 *     fontSize = Size of the font. Default: 28
 *     color    = Text color. Default: rgbaFFFFFFFF.
 *     time     = Time to display the text in seconds. 0 (default) means infinite.
 *
 * "lines" draws random lines on the screen tham might optionally vertically scroll.
 * 
 * This is used, for example, for the background scrolling "starfield" effect.
 *
 * Params:
 *     lineDirection = Line direction in radians. Default: 0
 *                     Note that this is not scrolling direction - that is always vertical -
 *                     it is the direction along which the lines are drawn.
 *     minWidth      = Minimum line width. Default: 1.0. Must be > 0.
 *     maxWidth      = Maximum line width. Default: 2.0. Must be > minWidth.
 *     minLength     = Minimum line length. Default: 1.0. Must be > 0.
 *     maxLength     = Maximum line length. Default: 10.0. Must be > minLength.
 *     linesPerPixel = Average number of lines drawn per "pixel" (1x1 game units)
 *                     of the screen. Default: 0.001 . Must be >= 0 and <= 1.
 *     detailLevel   = "Level of detail" of the effect. Higher values are less 
 *                     random, less "detailed" and consume less CPU power.
 *                     0 is maximum detail. Going below 16 is not advisable 
 *                     (although it might work, if there are few lines).
 *     color         = Text color. Default: rgbaFFFFFFFF.
 *     time          = Time to display the text in seconds. 0 (default) means infinite.
 *     verticalScrollingSpeed = Vertical scrolling speed of the lines.
 *                              Default: 250.0 . Use negative for opposite direction.
 *
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
                    bool delegate(const real, const GameTime, 
                                  ref RandomLinesEffect.Parameters) linesDeleg;
                    ///Control delegate for the Text effect.
                    bool delegate(const real, const GameTime, 
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
                     const GameTime gameTime, 
                     ref RandomLinesEffect.Parameters params)
                    {
                        const timeRatio = (gameTime.gameTime - startTime) / time;
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
                     const GameTime gameTime, 
                     ref TextEffect.Parameters params)
                    {
                        const timeRatio = (gameTime.gameTime - startTime) / time;
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
                    Effect
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
                    Effect effect_;
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
                    static if     (is(T == Wait))  {return wait_;}
                    else static if(is(T == Wave))  {return wave_;}
                    else static if(is(T == Text))  {return text_;}
                    else static if(is(T == Effect)){return effect_;}
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
                    else static assert(false, "Unknown instruction type: " ~ T.stringof);
                }
        }

        ///Dynamically allocated wave definition with a name.
        alias Tuple!(WaveDefinition*, "wave", string, "name") NamedWaveDefinition;

        ///Loaded wave definitions.
        Vector!NamedWaveDefinition waveDefinitions_;

        ///Instructions of the level script.
        Vector!Instruction levelScript_;

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
                default:
                    throw new E("Unknown level instruction in level \"" ~ 
                                name_ ~ "\": " ~ name_);
            }
            levelLoaded_ = true;
        }
}
