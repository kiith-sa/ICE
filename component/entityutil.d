//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Utility functions for Entity code.
module component.entityutil;


import std.algorithm;
import std.array;
import std.typecons;

import util.stringctfe;

public import component.collidablecomponent;
public import component.controllercomponent;
public import component.deathtimeoutcomponent;
public import component.dumbscriptcomponent;
public import component.enginecomponent;
public import component.exceptions;
public import component.healthcomponent;
public import component.movementconstraintcomponent;
public import component.ownercomponent;
public import component.physicscomponent;
public import component.playercomponent;
public import component.scorecomponent;
public import component.spawnercomponent;
public import component.statisticscomponent;
public import component.tagscomponent;
public import component.visualcomponent;
public import component.volumecomponent;
public import component.warheadcomponent;
public import component.weaponcomponent;

/**
 * Every component type must be named here with a string matching its type name.
 *
 * Every component type must be copiable without invalidating its state - 
 * it is copied between EntityPrototype and EntitySystem.
 *
 * Every component type name must end with "Component".
 */
enum componentTypes =
tuple 
(
    "VisualComponent",
    "PhysicsComponent",
    "ControllerComponent",
    "EngineComponent",
    "DeathTimeoutComponent",
    "WeaponComponent",
    "VolumeComponent",
    "CollidableComponent",
    "WarheadComponent",
    "HealthComponent",
    "OwnerComponent",
    "PlayerComponent",
    "DumbScriptComponent",
    "StatisticsComponent",
    "MovementConstraintComponent",
    "SpawnerComponent",
    "TagsComponent",
    "ScoreComponent"
);

///Last 8 bits are reserved for special uses.
static assert(componentTypes.length < 56,
              "At most 56 component types supported");

///Enforce at compile time that all component type names are valid.
static assert(
{
    bool ok = true;
    foreach(c; componentTypes)
    {
        if(!c.endsWith("Component") || c.length <= "Component".length){ok = false;}
    }
    return ok;
}(), "One or more names in the \"componentTypes\" is not valid");

///Assert that a string is a component type name.
void assertIsComponent(string componentType) pure nothrow
{
    bool found = false;
    foreach(type; componentTypes) if(type == componentType)
    {
        found = true;
    }
    assert(found, "Unknown component type: " ~ componentType);
}

///Is T a known component type?
template knownComponentType(T)
{
    string knownComponentType_(T)() pure 
    {
        foreach(type; componentTypes) if(type == T.stringof){return "true";}
        return "false";
    }
    mixin("enum knownComponentType = " ~ knownComponentType_!T ~ ";");
}

///Get name of a component type (strip the "Component" part).
string name(string componentType) pure nothrow
{
    assertIsComponent(componentType);
    return componentType[0 .. $ - "Component".length];
}

///Get camelCased name of a component type.
string nameCamelCased(string componentType) pure nothrow
{
    auto name = name(componentType);
    return toLowerCtfe(name[0]) ~ name[1 .. $];
}
static assert(nameCamelCased("DeathTimeoutComponent") == "deathTimeout");

///Get name of an array containing components of specified type.
string arrayName(string componentType) pure nothrow
{
    assertIsComponent(componentType);
    return toLowerCtfe(componentType[0]) ~ componentType[1 .. $] ~ "s_";
}

///Is name a camelCased name of a component type (e.g. a component member in a prototype)?
bool isCamelCasedComponentName(string name)
{
    foreach(c; componentTypes)
    {
        enum camelCased = c.nameCamelCased;
        if(camelCased == name){return true;}
    }
    return false;
}

///Generate an component type ID enum. Each value has the bit corresponding to its type set.
string ctfeComponentTypeEnum() 
{
    string result = "enum ComponentType : ulong\n{\n";
    uint b = 64;
    foreach(c; componentTypes)
    {
        result ~= "   " ~ c.name ~ " =\n" ~ 
                  "   0b" ~ "0".replicate(b - 1) ~ "1" ~ "0".replicate(64 - b) ~ ",\n";
        --b;
    }

    //JUST_SPAWNED is 1 for the first update after spawning the entity.
    //FLIP_VALIDITY determines whether we should flip the INVALID_ENTITY bit
    //on next update (killing/creating an entity).
    //INVALID_ENTITY specifies whether an entity is valid(alive) or not(dead).
    result ~= 
          "    JUST_SPAWNED  =\n"
          "        0b0010000000000000000000000000000000000000000000000000000000000000,\n"
          "    FLIP_VALIDITY  =\n"
          "        0b0100000000000000000000000000000000000000000000000000000000000000,\n"
          "    INVALID_ENTITY =\n"
          "        0b1000000000000000000000000000000000000000000000000000000000000000\n"
          "}\n";
    return result;
}


/**
 * Defines the ComponentType enum.
 *
 * ComponentType has a value for each component type.
 * This value is also a bit mask with only one bit, corresponding to that
 * component type, is 1.
 *
 * A bitwise or of ComponentType values specifies which components an entity has.
 */
mixin(ctfeComponentTypeEnum());

///Get a ComponentType corresponding to a component type name.
ComponentType componentType(string type)() pure nothrow
{
    mixin("return ComponentType." ~ type.name ~ ";");
}

