
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Component that provides a simple script to control an entity.
module component.dumbscriptcomponent;


import containers.lazyarray;
import util.yaml;


///Component that provides a simple script (in YAML) to control an entity.
///
///Used by ControllerSystem (there is no DumbScriptSystem)
struct DumbScriptComponent
{
    ///Index to the script in ControllerSystem.
    LazyArrayIndex scriptIndex;

    ///Which script instruction are we at?
    uint instruction = 0;

    ///Time we've been executing this instruction for.
    float instructionTime = 0.0f;

    ///Load from a YAML node. Throws YAMLException on error.
    this(ref YAMLNode yaml)
    {
        scriptIndex = LazyArrayIndex(yaml.as!string);
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
