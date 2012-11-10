
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///System that handles player/script control of entities.
module component.controllersystem;


import std.algorithm;
import std.conv;
import std.math;

import dgamevfs._;

import ice.player;
import math.vector2;
import containers.fixedarray;
import containers.lazyarray;
import time.gametime;
import util.frameprofiler;
import util.yaml;

import component.controllercomponent;
import component.dumbscriptcomponent;
import component.enginecomponent;
import component.entitysystem;
import component.playercomponent;
import component.physicscomponent;
import component.system;


///System that handles player/script control of entities.
class ControllerSystem : System
{
    private:
        ///Entity system whose data we're processing.
        EntitySystem entitySystem_;

        ///Game directory to load scripts from.
        VFSDir gameDir_;

        ///Game time subsystem.
        const GameTime gameTime_;

        /**
         * Simple script in YAML.
         *
         * DumbScripts have no flow control and they are composed from a sequence
         * of simple instructions. They are started when the entity is created.
         *
         * The script is composed from pairs of instructions with their parameters.
         *
         * Example:
         * --------------------
         * !!pairs
         * - for 0.25:
         *     move-direction: 0.5
         * - for 0.5:
         *     move-direction: -0.5
         *     move-speed: 0.5
         * - for 0.5:
         *     fire: [0, 1]
         * - die:
         * --------------------
         * 
         *
         * Current DumbScript instructions:
         *
         * for time:
         *
         * Example:
         * --------------------
         * - for 1.0:   #For duration of one second
         *     move-direction: 0.5 #move in direction of 0.5 radians relative to current rotation
         *     move-speed: 0.5     #move at 50% speed
         *     fire [0, 2]         #fire weapons 0 and 2
         * --------------------
         * 
         * Perform an action for specified time (in seconds):
         * 
         * Params:
         *     move-direction = Move in direction specified in radians relative to current
         *                      direction.
         *     move-speed     = Movement speed relative to max speed. Must be >= -1 and <= 1 . 
         *     fire           = Fire weapons specified in the sequence. As there are only
         *                      256 weapon slots, the values must be between >= 0 and  <= 255 .
         * 
         * die:
         *
         * Example:
         * --------------------
         * - die: #Kill the entity.
         * --------------------
         *
         * Kill the entity. Any instructions after this are not executed.
         */
        struct DumbScript 
        {
            import std.algorithm;
            import std.ascii;
            import std.traits;

            import util.bits;

            private:
                //Each instruction is represented by a struct, which must 
                //match a value of the Instruction.Type enum.

                ///Die instruction. Currently has no parameters.
                struct Die {}

                ///Performs specified actions for specified time.
                struct ForTime
                {
                    ///Duration of movement in seconds.
                    float duration;
                    ///Direction vector of movement.
                    /// 
                    ///Calculated from movement-direction and movement-speed
                    ///parameters of a ForTime instruction.
                    Vector2f direction;
                    ///Which weapons to fire, if any?
                    Bits!256 fire;
                }

                ///Represents one instruction in the script.
                struct Instruction
                {
                    /**
                     * Instruction type. 
                     * 
                     * Every value except Uninitialized must match instruction 
                     * struct type name.
                     */
                    enum Type : ubyte
                    {
                        Uninitialized = 0,
                        ForTime,
                        Die
                    }

                    //Can't use a union due to initialization during memory allocation.
                    ///Storage of the instruction, essentially a union.
                    ubyte[max(ForTime.sizeof, Die.sizeof)] storage;

                    ///Type of the instruction.
                    Type type;


                    ///Construct from a specific instruction (e.g. ForTime, etc).
                    this(T)(T rhs) pure nothrow
                    {
                        *(cast(Unqual!T*)storage.ptr) = rhs;
                        mixin("type = Type." ~ Unqual!T.stringof ~ ";");
                    }

                    /**
                     * Read the stored instruction as type specified in camelCase.
                     *
                     * E.g. to read as ForTime, use Instruction.forTime . 
                     * This will automatically assert that the instruction has 
                     * specified type.
                     */
                    ref auto opDispatch(dstring type)()
                    {
                        enum typeStr = toUpper(type[0]) ~ type[1 .. $];
                        mixin("const valid = this.type == Type." ~ typeStr ~ ";");
                        assert(valid, 
                               "Trying to get instruction as type " ~ to!string(typeStr) ~ 
                               "(with the " ~ to!string(type) ~ " property), even "
                               "though its actual type is " ~ to!string(this.type));
                        mixin("return *cast(" ~ typeStr ~ "*)storage.ptr;");
                    }
                }

                ///Instructions of the script.
                FixedArray!Instruction instructions_;

            public:
                ///Load a DumbScript from specified file.
                this(YAMLNode yaml)
                {
                    {
                        auto zone = Zone("DumbScript instructions allocation");
                        instructions_ = FixedArray!Instruction(yaml.length);
                    }
                    uint idx = 0;
                    foreach(string type, ref YAMLNode args; yaml)
                    {
                        if(type == "die")
                        {
                            instructions_[idx++] = Instruction(Die());
                        }
                        else if(type.startsWith("for"))
                        {
                            ForTime f;
                            Vector2f dir;
                            float speed = 1.0;
                            if(!args.isNull)
                            {
                                if(args.containsKey("move-direction"))
                                {
                                    dir = angleToVector(args["move-direction"].as!float);
                                }
                                if(args.containsKey("fire"))
                                {
                                    foreach(ubyte weapon; args["fire"])
                                    {
                                        f.fire[weapon] = true;
                                    }
                                }
                                if(args.containsKey("move-speed"))
                                {
                                    speed = fromYAML!(float, "a >= -1.0f && a <= 1.0f")
                                                     (args["move-speed"], "move-speed");
                                }
                            }
                            f.direction = dir * speed;
                            f.duration = to!float(type[4 .. $]);
                            if(f.duration < 0.0)
                            {
                                throw new YAMLException("Negative dumbscript " ~
                                                        "for duration");
                            }
                            instructions_[idx++] = Instruction(f);
                        }
                        else
                        {
                            throw new YAMLException("Unknown dumb script " ~
                                                    "instruction type: " ~ type);
                        }
                    }
                }

                /**
                 * Control a ControllerComponent by this DumbScript.
                 *
                 * Params:  control  = ControllerComponent of the entity to control.
                 *          script   = DumbScriptComponent of the entity,
                 *                     containing current execution state of the script.
                 *          timeStep = Game time step.
                 */
                void control(ref ControllerComponent control, 
                             ref DumbScriptComponent script,
                             const real timeStep)
                {
                    //We even increase this when the script is done, 
                    //but that has no effect. (except for measuring time 
                    //since the script's beed done, I guess).
                    script.instructionTime += timeStep;
                    interrupt: while(!script.done) 
                    {
                        auto instruction = instructions_[script.instruction];
                        final switch(instruction.type)
                        {
                            case Instruction.Type.Uninitialized:
                                assert(false, "Uninitialized dumb script instruction");
                            case Instruction.Type.ForTime:
                                //Set the ControllerComponent's movement direction.
                                //based on any movement instructions in the script.
                                //Note that if more movement instructions happen in
                                //one update, only the last one sets the movement.
                                control.movementDirection = instruction.forTime.direction;
                                control.firing = instruction.forTime.fire;
                                const duration = instruction.forTime.duration;
                                if(script.instructionTime > duration)
                                {
                                    script.nextInstruction(instructions_.length);
                                    //We're done with this instruction and 
                                    //still have time for the next (if any) instruction
                                    break;
                                }
                                //We're not done with this instruction,
                                //and it will continue to the next update,
                                //so interrupt execution for now.
                                break interrupt;
                            case Instruction.Type.Die:
                                control.die = true;
                                script.nextInstruction(instructions_.length);
                                //We're done with this instruction, and while we 
                                //might have tintme for some extra instructions,
                                //we're dead, so there's no point.
                                //Interrupt execution.
                                break interrupt;
                        }
                    }
                }
        }

        ///Loaded dumb scripts.
        LazyArray!DumbScript dumbScripts_;

    public:
        /**
         * Construct a ControllerSystem working on entities from specified EntitySystem
         * and using specified game time subsystem to determine time.
         */
        this(EntitySystem entitySystem, const GameTime gameTime)
        {
            entitySystem_ = entitySystem;
            gameTime_     = gameTime;
            dumbScripts_.loaderDelegate(&loadDumbScript);
        }

        ///Set the game directory to load scripts from.
        @property void gameDir(VFSDir rhs) 
        {
            gameDir_ = rhs;
        }

        /**
         * Update the ControllerSystem, processing entities with ControllerComponents.
         *
         * Player controls the ControllerComponent, which in turn is used to
         * control the EngineComponent of the entity.
         */
        void update()
        {
            //Could be moved to a DumbScriptSystem.

            //Allow dumb scripts to control their entities.
            foreach(ref Entity e,
                    ref ControllerComponent control,
                    ref DumbScriptComponent scriptComponent; 
                    entitySystem_)
            {
                DumbScript* script = dumbScripts_[scriptComponent.scriptIndex];
                if(script is null)
                {
                    import std.stdio;
                    writeln("WARNING: Could not load dumb scipt ", 
                            scriptComponent.scriptIndex.id);
                    writeln("Falling back to a placeholder (idle) dumb script");
                    assert(false, "TODO - Placeholder dumb script not implemented");
                }

                script.control(control, scriptComponent, gameTime_.timeStep);
            }

            //Could be moved to a PlayerControlSystem.

            //Allow players to control their entities' ControllerComponents.
            foreach(ref Entity e, 
                    ref ControllerComponent control,
                    ref PlayerComponent     playerComponent;
                    entitySystem_)
            {
                if(playerComponent.player is null) {continue;}
                playerComponent.player.control(e.id, control);
            }

            //Set engines' acceleration directions based on controller data.
            foreach(ref Entity e, 
                    ref ControllerComponent control,
                    ref EngineComponent     engine;
                    entitySystem_)
            {
                engine.accelerationDirection = control.movementDirection;
            }

            //Kill entities if specified by their controller.
            foreach(ref Entity e, ref ControllerComponent control; entitySystem_)
            {
                if(control.die){e.kill();}
            }
        }

    private:
        /**
         * Load a dumb script from specified source file.
         *
         * Params:  sourceName = Name of the script source file in the game directory.
         *          output     = Loaded script will be written here.
         *
         * Returns: true on success, false on failure.
         */
        bool loadDumbScript(string sourceName, out DumbScript output)
        {
            import std.stdio;
            string fail(){return "Failed to load dumb script " ~ sourceName ~ ": ";}
            try
            {
                YAMLNode yamlSource;
                {
                    auto zone = Zone("DumbScript file reading & YAML parsing");
                    yamlSource = loadYAML(gameDir_.file(sourceName));
                }
                output = DumbScript(yamlSource);
            }
            catch(YAMLException e){writeln(fail(), e.msg); return false;}
            catch(VFSException e) {writeln(fail(), e.msg); return false;}
            return true;
        }
}

