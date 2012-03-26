
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Component based entity system.
module component.entitysystem;


import std.algorithm;
import std.array;
import std.ascii;
import std.conv;
import std.string;
import std.traits;
import std.typecons;

import math.vector2;
import util.traits;
import util.yaml;

import component.controllercomponent;
import component.deathtimeoutcomponent;
import component.enginecomponent;
import component.exceptions;
import component.physicscomponent;
import component.visualcomponent;
import component.volumecomponent;
import component.weaponcomponent;


private:

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
    "VolumeComponent"
);

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
bool knownComponentType(T)() pure nothrow
{
    foreach(type; componentTypes) if(type == T.stringof){return true;}
    return false;
}

///Get name of a component type (strip the "Component" part).
string name(string componentType) nothrow
{
    assertIsComponent(componentType);
    return componentType[0 .. $ - "Component".length];
}

///Get camelCased name of a component type.
string nameCamelCased(string componentType)
{
    auto name = componentType.name;
    return name[0 .. 1].toLower() ~ name[1 .. $];
}
static assert(nameCamelCased("DeathTimeoutComponent") == "deathTimeout");

///Get name of an array containing components of specified type.
string arrayName(string componentType) 
{
    assertIsComponent(componentType);
    return componentType[0 .. 1].toLower() ~ componentType[1 .. $] ~ "s_";
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
        assert(b > 2, "Too many component types for a 64bit enum");
    }

    //FLIP_VALIDITY determines whether we should flip the INVALID_ENTITY bit
    //on next update (killing/creating an entity).
    //INVALID_ENTITY specifies whether an entity is valid(alive) or not(dead).
    result ~= 
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


public:

///Uniquely identifies an entity in an entity system.
struct EntityID
{
    private:
        ///ID itself.
        ulong id_;

    public:
        ///Equality comparison with another ID.
        bool opEquals(EntityID rhs) const pure nothrow
        {
            return id_ == rhs.id_;
        }

        ///Get string representation for debugging.
        string toString() const 
        {
            return to!string(id_);
        }
}

/**
 * Game entity.
 *
 * Entity is an extremely lightweight struct that just specifies what
 * components it has, in an on/off fashion. The only way to access the 
 * components of a particular entity is by iterating the entity and component 
 * arrays in lockstep in EntitySystem.
 */
struct Entity
{
    private:
        ///Bits specifiying components in the entity.
        ulong components_;

        ///Unique ID of the entity.
        EntityID id_;

    public:
        ///Is the entity valid (alive)?
        @property bool valid() const pure nothrow
        {
            return !cast(bool)(components_ & ComponentType.INVALID_ENTITY);
        }

        ///Get the ID of the entity.
        EntityID id() const pure nothrow
        {
            return id_;
        }


        /**
         * Kill the entity.
         *
         * This will make the entity invalid on next EntitySystem update.
         * The entity stays valid during the current update.
         */
        void kill() 
        in
        {
            assert(valid, "Trying to kill an entity that is not valid");
        }
        body
        {
            components_ |= ComponentType.FLIP_VALIDITY;
        }

    private:
        @disable this();

        ///Construct an Entity with specified ID.
        this(const ulong id) pure nothrow
        {
            //Will only be valid on next EntitySystem update.
            components_ = ComponentType.INVALID_ENTITY | ComponentType.FLIP_VALIDITY;
            id_.id_     = id;
        }

        ///Flip entity validity (making it dead/alive) and disable the FLIP_VALIDITY bit.
        void flipValidity()
        in
        {
            assert(components_ & ComponentType.FLIP_VALIDITY, 
                   "flipValidity() can only be called on entities "
                   "with the FLIP_VALIDITY bit set");
        }
        body
        {
            valid = !valid;
            components_ = components_ & (~ComponentType.FLIP_VALIDITY);
        }

        ///Set entity validity (making it dead/alive).
        @property void valid(const bool rhs) pure nothrow
        {
            components_ = rhs ? (components_ & (~ComponentType.INVALID_ENTITY))
                              : (components_ | ComponentType.INVALID_ENTITY);
        }
        unittest
        {
            auto entity = Entity(0);
            assert(!entity.valid);
            entity.valid = true;
            assert(entity.valid);
            entity.valid = false;
            assert(!entity.valid);
        }
}

/**
 * Prototype for game entities.
 *
 * The prototype is passed to EntitySystem to construct an entity which will
 * copy its components. The prototype's components are loaded from YAML and/or
 * manually specified in code.
 */
struct EntityPrototype
{
    private:
        ///Defines all components as nullable structs.
        static string ctfeComponents()
        {
            string result = "";
            foreach(c; componentTypes)
            {
                result ~= "Nullable!" ~ c ~ " " ~ c.nameCamelCased ~ ";\n";
            }
            return result;
        }

    public:
        mixin(ctfeComponents());

        /**
         * Load an EntityPrototype from YAML.
         *
         * Params:  name = Name of the prototype (used for debugging).
         *          yaml = YAML node to load from.
         *
         * Throws:  YAMLException if the EntityPrototype could not be loaded.
         */
        this(string name, ref YAMLNode yaml)
        {
            try foreach(string key, ref YAMLNode value; yaml) 
            {
                loadComponent(key, value);
            }
            catch(YAMLException e)
            {
                throw new YAMLException("Failed loading entity prototype " ~ name ~
                                        " from YAML: " ~ e.msg);
            }
        }

    private:
        ///Does this prototype have a component of specified type?
        @property bool hasComponent(string componentType)() const
        {
            mixin("return !" ~ componentType.nameCamelCased ~ ".isNull;");
        }

        ///Get a reference to the component of specified type.
        @property auto ref component(string componentType)() 
        {
            mixin("return " ~ componentType.nameCamelCased ~ ".get;");
        }

        /**
         * Load a component from YAML.
         *
         * Params:  name = Component type name. The name should be camelCased,
         *                 without the Component part. E.g. for 
         *                 DeathTimeoutComponent, it should be deathTimeout.
         *                 If the name is unknown, no component is loaded and a
         *                 warning is printed.
         *          data = YAML node to load the component from.
         */
        void loadComponent(string name, ref YAMLNode data) 
        {
            import std.stdio;
            foreach(type; componentTypes) if(type.nameCamelCased == name)
            {
                mixin(type.nameCamelCased ~ " = " ~ type ~ "(data);\n");
                return;
            }
            writeln("WARNING: unknown component type: \"", name, "\". Ignoring.");
        }
}

/**
 * Stores game entities and their components and provides access to them.
 *
 * An Entity is a collection of components with zero or one component of each
 * type. 
 *
 * A Component is a simple struct with public data members and no 
 * functionality at all (setters might be used, though).
 *
 * To add a new Component type, you must import it in this file and add it to
 * the componentTypes tuple on top of the file. 
 *
 * Every component type must be copiable without invalidating its state - 
 * it is copied between EntityPrototype and EntitySystem.
 * 
 * 
 * The only way to access entities is to iterate using foreach over Entity
 * and one or more component types. This iterates only over entities that have
 * all of the specified components.
 *
 * Examples:
 * --------------------
 * EntitySystem system; //set elsewhere
 *
 * foreach(ref Entity entity,
 *         ref PhysicsComponent physics,
 *         ref VisualComponent visual;
 *         system)
 * {
 *     //Do stuff with physics and visual.
 * }
 * --------------------
 *
 * This works similarly to a select in a relational database that only selects
 * rows where specified columns are nonnull.
 *
 * Note that Entities and their Components might be moved around in memory, so
 * keeping pointers to them is not safe.
 *
 * However, they are never moved in memory between updates, so it is safe to use
 * such pointers within a game update.
 *
 */
class EntitySystem
{
    private:
        ///Game entities.
        Entity[] entities_;

        ///Are we currently constructing a new entity (used for contracts)?
        bool constructing_ = false;

        ///Defines arrays of all component types, named arrayName(componentType).
        static string ctfeComponentArrays() 
        {
            string result = "";
            foreach(c; componentTypes){result ~= c ~ "[] " ~ c.arrayName ~ ";\n";}
            return result;
        }
        mixin(ctfeComponentArrays());

        ///ID of the next entity to construct.
        ulong nextEntityID_ = 0;

    public:
        ///Destroy all entities and components, returning to initial state.
        void destroy()
        {
            clear(entities_);
            foreach(type; componentTypes)
            {
                mixin
                (
                    "foreach(ref c; " ~ type.arrayName ~ ")" ~
                    "{" ~
                    "    clear(c);" ~
                    "}" ~
                    "clear(" ~ type.arrayName ~ ");"
                );
            }
            nextEntityID_ = 0;
        }

        ///Construct an entity with components from specified prototype.
        final EntityID newEntity(ref EntityPrototype proto)
        {
            entityConstructStart();
            foreach(type; componentTypes) if(proto.hasComponent!type)
            {
                entityConstructAddComponent(proto.component!type);
            }
            return entityConstructFinish();
        }

        ///Construct an entity by explicitly passing components.
        final EntityID entityConstruct(Types ...)(auto ref Types args) 
        {
            entityConstructStart();
            foreach(ref arg; args)
            {
                entityConstructAddComponent(arg);
            }
            return entityConstructFinish();
        }

        /**
         * Update the EntitySystem.
         *
         * This should be called once per game logic update. This is where 
         * entities created or killed in previous frame are actually 
         * added/removed.
         */
        final void update()
        {
            foreach(ref entity; entities_) 
            {
                if(entity.components_ & ComponentType.FLIP_VALIDITY)
                {
                    entity.flipValidity();
                }
            }
        }

        /**
         * Iterate over entities with specified components.
         *
         * This will only iterate over entities that have all of specified
         * component types.
         */
        final int opApply(Types ...)(int delegate(ref Entity, ref Types) dg)
        in
        {
            assert(!constructing_, 
                   "Trying to iterate over entities while constructing an entity");
            foreach(T; Types)
            {
                static assert(knownComponentType!T(), "Unknown component type: " ~ T.stringof);
            }
        }
        body
        {
            mixin(ctfeIterateEntitiesWithComponentsOfTypes(tupleToStrings!Types()));
        }

    private:
        ///Start constructing a new entity.
        final void entityConstructStart() pure nothrow
        in
        {
            assert(!constructing_, 
                   "Starting construction of an entity while we're already "
                   "constructing something");
        }
        body
        {
            constructing_ = true;
            entities_ ~= Entity(nextEntityID_++);
        }

        ///Add a component to an entity that is currently being constructed.
        final void entityConstructAddComponent(T)(auto ref T component)
        {
            static assert(knownComponentType!T(), "Unknown component type: " ~ T.stringof);
            mixin("entities_[$ - 1].components_ |= " ~ ctfeTypeEnum(T.stringof) ~ ";\n");
            mixin(T.stringof.arrayName ~ " ~= component;\n"); 
        }

        ///Finish constructing a new entity and return its ID.
        final EntityID entityConstructFinish() pure nothrow
        in
        {
            assert(constructing_, 
                   "Finishing construction of an entity but we're not "
                   "constructing anything");
        }
        body
        {
            constructing_ = false;
            return entities_[$ - 1].id_;
        }

        ///Return string represenation of ComponentType enum value matching specified type.
        static string ctfeTypeEnum(string type)
        {
            return "ComponentType." ~ type.name;
        }

        ///Generate code that iterates over entities with specified components.
        static string ctfeIterateEntitiesWithComponentsOfTypes(string[] types...)
        {
            //Generate flags corresponding to the components 
            //(e.g. ComponentType.Visual | ComponentType.Physics for 
            //visual and physics components)
            static string componentFlags(string[] types)
            {
                string[] result;
                foreach(type; types){result ~= ctfeTypeEnum(type);}
                return result.join(" | ");
            }

            //Generate name of the index into the array of specified component type.
            static string typeIndex(string type)
            {
                return toLower(type[0 .. 1]) ~ type[1 .. $] ~ "Idx";
            }

            //Generate code that declares indices into component arrays.
            static string declareIndices(string[] types)
            {
                string result;
                foreach(type; types)
                {
                    result ~= "size_t " ~ typeIndex(type) ~ " = 0;\n";
                }
                return result;
            }

            //Generate code that increments component array indices based on components in an entity.
            static string increaseIndices(string[] types)
            {
                string result;
                foreach(type; types)
                {
                    string inc = "cast(bool)(entity.components_ & " ~ ctfeTypeEnum(type) ~ ")";
                    result ~= "    " ~ typeIndex(type) ~ " += " ~ inc ~ ";\n";
                }
                return result;
            }

            //Generate parameters to the foreach delegate.
            static string foreachParameters(string[] types)
            {
                string[] result;
                foreach(type; types)
                {
                    result ~= type.arrayName ~ "[" ~ typeIndex(type) ~ "]";
                }
                return result.join(", ");
            }

            string result;

            result ~= "int result;\n";
            result ~= "ulong componentFlags = " ~ componentFlags(types) ~ ";\n";
            //Declare indices to arrays of all component types we're iterating.
            result ~= declareIndices(types);
            result ~= "foreach(ref entity; entities_)\n";
            result ~= "{\n";
            //If the entity is valid and its components_ match componentFlags,
            //pass it to the foreach delegate.
            result ~= "    if(!(entity.components_ & ComponentType.INVALID_ENTITY) &&\n";
            result ~= "        ((entity.components_ & componentFlags) == componentFlags))\n";
            result ~= "    {\n";
            result ~= "        result = dg(entity, " ~ foreachParameters(types) ~ ");\n";
            result ~= "        if(result){break;}\n";
            result ~= "    }\n";
            //Increase component array indices to move to the next entity.
            result ~= increaseIndices(types);
            result ~= "}\n";
            result ~= "return result;\n";

            return  result;
        }
}
unittest
{
    EntitySystem system = new EntitySystem();

    void constructPos()
    {
        auto id = system.entityConstruct(PhysicsComponent(Vector2f(1.0f, 2.0f),
                                                          0.0f, Vector2f(0.0f, 0.0f)));
    }

    void constructPosVis()
    {
        system.entityConstruct(PhysicsComponent(Vector2f(1.0f, 0.0f),
                                                0.0f, Vector2f(0.0f, 0.0f)),
                               VisualComponent());
    }

    constructPos();
    constructPosVis();
    constructPos();
    constructPosVis();
    constructPos();
    constructPos();

    //Newly constructed entities only get valid after update.
    system.update();

    uint posvis = 0;
    foreach(Entity e, ref VisualComponent v, ref PhysicsComponent p; system)
    {
        assert(p.position == Vector2f(1.0f, 0.0f));
        ++posvis;
    }
    assert(posvis == 2);
    uint pos = 0;
    foreach(Entity e, ref PhysicsComponent p; system)
    {
        assert(p.position.x == 1.0f);
        ++pos;
    }
    assert(pos == 6);
}