
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Component that provides a simple script to control an entity.
module component.dumbscriptcomponent;


import std.algorithm;

import containers.fixedarray;
import containers.lazyarray;
import math.vector2;
import util.yaml;


///Component that provides a simple script (in YAML) to control an entity.
///
///Used by ControllerSystem (there is no DumbScriptSystem)
struct DumbScriptComponent
{
    /// Alias for readability.
    alias LazyArrayIndex!(DumbScript) DumbScriptIndex;

    ///Index to the script in ControllerSystem.
    DumbScriptIndex scriptIndex;

    ///Using a placeholder dumbScript?
    bool placeholder;

    ///Which script instruction are we at?
    uint instruction = 0;

    ///Time we've been executing this instruction for.
    float instructionTime = 0.0f;

    ///Load from a YAML node. Throws YAMLException on error.
    this(ref YAMLNode yaml)
    {
        scriptIndex = DumbScriptIndex(yaml.as!string);
    }

    ///Are we done with the script?
    @property bool done() const pure nothrow {return instruction == uint.max;}

    ///Set the script to done, i.e. finished.
    void finish() pure nothrow {instruction = uint.max;}

    /**
     * Move to the next instruction in script.
     *
     * Params:  instructionCount = Instruction count. If we get to this 
     *                             number of instructions, the script is done.
     */
    void nextInstruction(const size_t instructionCount) pure nothrow 
    {
        ++instruction;
        if(instruction >= instructionCount){finish();}
        instructionTime = 0.0f;
    }
}


package:

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
    import std.ascii;
    import std.conv;
    import std.traits;

    import component.controllercomponent;
    import time.gametime;
    import util.bits;
    import util.frameprofiler;

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
