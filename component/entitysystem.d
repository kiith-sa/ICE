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

import containers.segmentedvector;
import containers.vector;
import math.vector2;
import monitor.graphmonitor;
import monitor.monitordata;
import monitor.monitorable;
import monitor.submonitor;
import util.signal;
import util.stringctfe;
import util.traits;
import util.unittests;
import util.yaml;

import component.entityutil;

public import component.entityprototype;


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

        ///Comparison for sorting.
        long opCmp(EntityID rhs) const pure nothrow
        {
            return cast(long)id_ - cast(long)rhs.id_;
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
 * Entity is specifies what components it has, in an on/off fashion, 
 * as well as indices to its components stored in the EntitySystem.
 *
 * The most effective way to access the 
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

        ///EntitySystem that owns this entity.
        EntitySystem entitySystem_;

        ///Indices to components of this entity.
        static ctfeComponentIndices() 
        {
            string result;
            foreach(type; componentTypes)
            {
                result ~= "uint " ~ type.nameCamelCased ~ "Idx_ = uint.max;\n";
            }
            return result;
        }
        mixin(ctfeComponentIndices());

    public:
        ///Is the entity valid (alive)?
        @property bool valid() const pure nothrow
        {
            return !cast(bool)(components_ & ComponentType.INVALID_ENTITY);
        }

        ///Get the ID of the entity.
        @property EntityID id() const pure nothrow
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

        ///Has this entity been killed during current update?
        @property bool killed() const pure nothrow 
        in
        {
            assert(valid, "Determining if an invalid entity has been killed this update");
        }
        body
        {
            return cast(bool)(components_ & ComponentType.FLIP_VALIDITY);
        }

        ///Has this entity been spawned at the beginning of the current update?
        @property bool spawned() const pure nothrow 
        in
        {
            assert(valid, "Determining if an invalid entity has been spawned this update");
        }
        body
        {
            return cast(bool)(components_ & ComponentType.JUST_SPAWNED);
        }

        ///Getters to access components of this entity.
        static ctfeComponentGetters()
        {
            string result;
            foreach(type; componentTypes)
            {
                result ~= "@property " ~ type ~ "* " ~ type.nameCamelCased ~ "() pure nothrow\n";
                result ~= "{\n";
                result ~= "    const idx = " ~ type.nameCamelCased ~ "Idx_;\n";
                result ~= "    if(idx == uint.max){return null;}\n";
                result ~= "    assert(entitySystem_." ~ type.arrayName ~ ".length > idx,\n";
                result ~= "           \"" ~ type ~ " index out of range\");\n";
                result ~= "    return &(entitySystem_." ~ type.arrayName ~ "[idx]);\n";
                result ~= "}\n";
            }
            return result;
        }
        mixin(ctfeComponentGetters());

    private:
        @disable this();

        ///Construct an Entity with specified ID owned by specified EntitySystem.
        this(const ulong id, EntitySystem entitySystem) pure nothrow
        {
            //Will only be valid on next EntitySystem update.
            components_   = ComponentType.INVALID_ENTITY | 
                            ComponentType.FLIP_VALIDITY |
                            ComponentType.JUST_SPAWNED;
            id_.id_       = id;
            entitySystem_ = entitySystem;
        }

        /**
         * Recycle an Entity with a new ID owned by specified EntitySystem.
         *
         * Recycling means overwriting a dead entity with a new entity with 
         * the same components used.
         */
        void recycle(const ulong id, EntitySystem entitySystem) pure nothrow
        {
            //Will only be valid on next EntitySystem update.
            components_ = componentMask |
                          ComponentType.INVALID_ENTITY | 
                          ComponentType.FLIP_VALIDITY |
                          ComponentType.JUST_SPAWNED;
            id_.id_       = id;
            entitySystem_ = entitySystem;
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

        ///Flip the JUST_SPAWNED bit (one update after spawning).
        void flipSpawned()
        in
        {
            assert(valid,
                   "flipSpawned() can only be called on valid entities.");
        }
        body
        {
            components_ = components_ & (~ComponentType.JUST_SPAWNED);
        }
        
        ///Get a reference to the index of specified component. Used during entity construction.
        @property ref uint componentIdx(C)() pure nothrow 
        {
            mixin("return " ~ C.stringof.nameCamelCased ~ "Idx_;\n");
        }

        ///Get a mask specifying which components the entity has (ignoring special bits).
        @property ulong componentMask() const pure nothrow
        {
            return components_ & 
                   0b0000000011111111111111111111111111111111111111111111111111111111;
        }

        ///Set entity validity (making it dead/alive).
        @property void valid(const bool rhs) pure nothrow
        {
            components_ = rhs ? (components_ & (~ComponentType.INVALID_ENTITY))
                              : (components_ | ComponentType.INVALID_ENTITY);
        }
        private static void unittestValid()
        {
            auto entity = Entity(0, null);
            assert(!entity.valid);
            entity.valid = true;
            assert(entity.valid);
            entity.valid = false;
            assert(!entity.valid);
        }
        mixin registerTest!(unittestValid, "Entity.valid");
}
pragma(msg, "Entity size is " ~ to!string(Entity.sizeof));

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
 * Note that Entities and their Components might be moved around in memory 
 * between updates, so keeping pointers to them is not safe.
 * It is safe for duration of one update, so that pointers can be stored for
 * various in-update operations.
 */
class EntitySystem : Monitorable
{
    private:
        ///Statistics used for monitoring/debugging.
        struct Statistics
        {
            ///Total number of allocated entities at the moment.
            uint entities;
            ///Total number of living entities at the moment.
            uint alive;
            ///Total number of dead entities at the moment.
            uint dead;
        }

        ///Game entities.
        SegmentedVector!(Entity, 16384)  entities_;

        ///Indices of entities that are dead.
        Vector!uint freeEntityIndices_;

        ///Are we currently constructing a new entity (used for contracts)?
        bool constructing_ = false;

        ///Defines arrays of all component types, named arrayName(componentType).
        static string ctfeComponentArrays() 
        {
            string result = "";
            foreach(c; componentTypes){result ~= "SegmentedVector!(" ~ c ~ ", 4096) " ~ c.arrayName ~ ";\n";}
            return result;
        }
        mixin(ctfeComponentArrays());

        ///ID of the next entity to construct. (0 is the default ID value - invalid)
        ulong nextEntityID_ = 1;

        ///Maps entity IDs to entity pointers.
        Entity*[EntityID] idToEntity_;

        ///Monitoring statistics.
        Statistics statistics_;

        ///Used to send statistics data to EntitySystem monitor/s.
        mixin Signal!Statistics sendStatistics;

    public:
        this()
        {
            enum freeEntityIndicesPrealloc = 32768;
            freeEntityIndices_.reserve(freeEntityIndicesPrealloc);
        }

        ///Destroy all entities and components, returning to initial state.
        void destroy()
        {
            clear(entities_);
            clear(idToEntity_);
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
        final EntityID newEntity(ref EntityPrototype prototype)
        {
            return constructEntity(prototype);
        }

        /**
         * Get a pointer to the entity with specified ID.
         *
         * This is the safe way to keep "pointers" to entities between game updates.
         *
         * If the entity with specified ID doesn't exist (e.g. was destroyed),
         * this returns null.
         */
        final Entity* entityWithID(const ref EntityID id)
        {
            if(null is (id in idToEntity_) ||
               null is *(id in idToEntity_))
            {
                return null;
            }
            return idToEntity_[id];
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
            uint entityIndex = 0;
            foreach(ref entity; entities_) 
            {
                if(entity.components_ & ComponentType.FLIP_VALIDITY)
                {
                    if(entity.valid)
                    {
                        assert(null !is (entity.id in idToEntity_) &&
                               null !is *(entity.id in idToEntity_),
                               "Removing entity ID that doesn't exist");

                        clearComponents(entity);

                        //TEMP:
                        //Due to a compiler bug, we're setting to null 
                        //instead of removing here.
                        //Once the bug is fixed, use remove and remove checks for 
                        //null in all idToEntity_ related code/asserts.

                        //idToEntity_.remove(entity.id);
                        idToEntity_[entity.id] = null;
                        --statistics_.alive;

                        freeEntityIndices_ ~= entityIndex;
                    }
                    else
                    {
                        assert(null is (entity.id in idToEntity_) ||
                               null is *(entity.id in idToEntity_),
                               "Adding entity ID that already exists");
                        idToEntity_[entity.id] = &entity;
                        ++statistics_.alive;
                    }
                    entity.flipValidity();
                }
                //We're not flipping validity and we're valid 
                //- we're alive at least for one update.
                else if(entity.valid)
                {
                    //We've just been spawned at the previous update.
                    if(entity.spawned)
                    {
                        entity.flipSpawned();
                    }
                }

                ++entityIndex;
            }

            //Update statistics and send them to the monitor.
            statistics_.entities = cast(uint)entities_.length;
            //Alive is incremented/decremented as entities are added/removed.
            statistics_.dead = statistics_.entities - statistics_.alive;

            sendStatistics.emit(statistics_);
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
                static assert(knownComponentType!T, "Unknown component type: " ~ T.stringof);
            }
        }
        body
        {
            mixin(ctfeIterateEntitiesWithComponentsOfTypes(tupleToStrings!Types()));
        }

        ///Provide an interface for the Monitor subsystem to monitor the EntitySystem.
        MonitorDataInterface monitorData()
        {
            SubMonitor function(EntitySystem)[string] ctors_;
            ctors_["Entities"] = &newGraphMonitor!(EntitySystem, Statistics, 
                                                   "entities", "alive", "dead");
            return new MonitorData!EntitySystem(this, ctors_);
        }

    private:
        /**
         * Construct an Entity.
         *
         * Params:  system    = EntitySystem that will own the constructed entity.
         *          prototype = Prototype of the entity to construct.
         *
         * Returns: ID of the newly constructed entity.
         */
        EntityID constructEntity(ref EntityPrototype prototype)
        {
            //Recycle an entity if possible, add a new one otherwise.
            auto entityIndex = findRecyclableEntity(prototype.componentMask);
            bool recycling = false;
            if(entityIndex < 0)
            {
                //Add a new entity
                entities_ ~= Entity(nextEntityID_++, this);
                entityIndex = cast(int)entities_.length - 1;
            }
            else 
            {
                //Recycle an existing entity (with the same components enabled).
                entities_[entityIndex].recycle(nextEntityID_++, this);
                recycling = true;
            }

            auto entity = &(entities_[entityIndex]);

            //Add components to the entity.
            foreach(type; componentTypes) if(prototype.hasComponent!type)
            {
                constructEntityAddComponent(entity, recycling, prototype.component!type.get);
            }

            assert(prototype.componentMask == entity.componentMask, "Component mask of "
                   "a newly constructed entity doesn't match the prototype");
            assert(!entity.valid, "Newly constructed entity should not be valid yet");

            return entity.id;
        }

        /**
         * Add a component to currently constructed entity.
         *
         * Params:  entity    = Entity we're constructing at the moment.
         *          recycling = Are we recycling an already existing(dead) entity?
         *          component = Component to add to the entity.
         */
        void constructEntityAddComponent(C)(Entity* entity, const bool recycling, 
                                            ref C component)
        {
            static assert(knownComponentType!C, 
                          "Unknown component type: " ~ C.stringof);

            entity.components_ |= componentType!(C.stringof);
            SegmentedVector!(C, 4096)* components = &componentArray!C();

            //If we're recycling, reuse an existing component.
            //Otherwise must add new one.
            if(!recycling)
            {
                //Set component index (and add new component, not init yet)
                const length = cast(uint)(*components).length;
                entity.componentIdx!C = length;
                components.length = length + 1;
            }

            (*components)[entity.componentIdx!C] = component;
        }

        ///Find a recyclable (dead) entity with specified component mask and return its index.
        int findRecyclableEntity(const ulong componentMask) 
        {
            uint idxIdx = 0;
            foreach(uint entityIdx; freeEntityIndices_)
            {
                if(entities_[entityIdx].componentMask == componentMask)
                {
                    //The index is not free anymore, so remove it
                    freeEntityIndices_[idxIdx] = freeEntityIndices_.back;
                    freeEntityIndices_.length  = freeEntityIndices_.length - 1;
                    return entityIdx;
                }
                ++idxIdx;
            }
            return -1;
        }

        ///Destroys all components of an entity (called at entity death).
        ///
        ///Components that have an "annotation" member 
        ///DO_NOT_DESTROY_AT_ENTITY_DEATH will not be destroyed.
        ///This is an optimization to avoid destroying components that 
        ///don't need it (i.e. only contain plain data, no arrays, etc.).
        final void clearComponents(ref Entity entity)
        {
            foreach(c; componentTypes)
            {
                mixin("alias " ~ c ~ " C;");
                enum noNeedToClear = __traits(hasMember, C, "DO_NOT_DESTROY_AT_ENTITY_DEATH");
                static if(!noNeedToClear)
                {
                    mixin("auto componentPtr = entity." ~ nameCamelCased(c) ~ ";");
                    if(componentPtr !is null)
                    {
                        clear(*componentPtr);
                    }
                }
            }
        }

        ///Get the component array of specified type.
        ref inout(SegmentedVector!(T, 4096)) componentArray(T)() inout pure
            if(knownComponentType!T)
        {
            mixin("return " ~ T.stringof.arrayName ~ ";");
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
                //Matches any entity
                if(types.empty){return "0";}
                string[] result;
                foreach(type; types){result ~= ctfeTypeEnum(type);}
                return result.join(" | ");
            }

            //Generate name of the index into the array of specified component type.
            static string typeIndex(string type) pure nothrow
            {
                return toLowerCtfe(type[0]) ~ type[1 .. $] ~ "Idx";
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
                if(types.empty){return "";}
                string result;
                foreach(type; types)
                {
                    result ~= ", " ~ type.arrayName ~ "[" ~ typeIndex(type) ~ "]";
                }
                return result;
            }

            string result;

            result ~= "int result;\n";
            result ~= "ulong componentFlags = " ~ componentFlags(types) ~ ";\n";
            //Declare indices to arrays of all component types we're iterating.
            result ~= declareIndices(types);
            result ~= "const entityCount = entities_.length;\n";
            result ~= "foreach(size_t e; 0 .. entityCount)\n";
            result ~= "{\n";
            result ~= "    auto entity = &entities_[e];\n";
            //If the entity is valid and its components_ match componentFlags,
            //pass it to the foreach delegate.
            result ~= "    if(!(entity.components_ & ComponentType.INVALID_ENTITY) &&\n";
            result ~= "        ((entity.components_ & componentFlags) == componentFlags))\n";
            result ~= "    {\n";
            result ~= "        result = dg(*entity" ~ foreachParameters(types) ~ ");\n";
            result ~= "        if(result){break;}\n";
            result ~= "    }\n";
            //Increase component array indices to move to the next entity.
            result ~= increaseIndices(types);
            result ~= "}\n";
            result ~= "return result;\n";

            return  result;
        }
}
void unittestEntitySystem()
{
    EntitySystem system = new EntitySystem();
    scope(exit){system.destroy();}

    void constructPos()
    {
        EntityPrototype prototype;
        prototype.physics = PhysicsComponent(Vector2f(1.0f, 2.0f), 0.0f, Vector2f(0.0f, 0.0f));
        auto id = system.newEntity(prototype);
    }

    void constructPosVis()
    {
        EntityPrototype prototype;
        prototype.physics = PhysicsComponent(Vector2f(1.0f, 0.0f), 0.0f, Vector2f(0.0f, 0.0f));
        prototype.visual = VisualComponent();
        auto id = system.newEntity(prototype);
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
    foreach(ref Entity e, ref VisualComponent v, ref PhysicsComponent p; system)
    {
        assert(p.position == Vector2f(1.0f, 0.0f));
        assert(e.visual  is &v);
        assert(e.physics is &p);
        assert(e.deathTimeout is null);
        ++posvis;
    }
    assert(posvis == 2);
    uint pos = 0;
    foreach(ref Entity e, ref PhysicsComponent p; system)
    {
        assert(p.position.x == 1.0f);
        assert(e.physics is &p);
        assert(e.deathTimeout is null);
        ++pos;
    }
    assert(pos == 6);
}
mixin registerTest!(unittestEntitySystem, "EntitySystem general");
