//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Prototype of a game entity.
module component.entityprototype;


import std.algorithm;
import std.conv;
import std.traits;
import std.typecons;

import component.entityutil;
import util.yaml;

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
                result ~= "Nullable!" ~ c ~ " " ~ nameCamelCased(c) ~ ";\n";
            }
            return result;
        }

        @disable this(this);

        @disable void opAssign(ref EntityPrototype);

    public:
        mixin(ctfeComponents());

        /**
         * Load an EntityPrototype from a YAML mapping.
         *
         * Keys in the mapping must be camelCased component type names.
         * E.g. physics for PhysicsComponent or deathTimeout for 
         * DeathTimeoutComponent.
         * 
         * Params:  name = Name of the prototype (used for debugging).
         *          yaml = YAML node to load from.
         *
         * Throws:  YAMLException if the EntityPrototype could not be loaded.
         */
        this(string name, YAMLNode yaml)
        {
            scope(failure)
            {
                import std.stdio;
                writeln("Construction of entity prototype \"", name, "\" failed");
            }
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

        ///Turn this prototype into a clone of rhs (i.e. copy rhs's components).
        void clone(ref EntityPrototype rhs)
        {
            foreach(c; componentTypes)
            {
                if(rhs.componentConst!c.isNull)
                {
                    component!c.nullify();
                }
                else
                {
                    component!c = rhs.component!c.get();
                }
            }
        }

        /**
         * Override components of this prototype from specified YAML mapping.
         *
         * Any keys in the mapping that don't match a component name will be ignored.
         */
        void overrideComponents(ref YAMLNode yaml)
        {
            foreach(string key, ref YAMLNode value; yaml)
            {
                if(isCamelCasedComponentName(key))
                {
                    loadComponent(key, value);
                }
            }
        }

        ///Return a string represenation of the prototype.
        string toString() const
        {
            string result = "EntityPrototype:\n";
            foreach(c; componentTypes)
            {
                mixin("enum hasToString = hasMember!(" ~ c ~ ", \"toString\");");
                mixin("const isNull = " ~ c.nameCamelCased ~ ".isNull;");
                if(!isNull)
                {
                    static if(hasToString)
                    {
                        result ~= "  " ~ c ~ ":\n" ~
                                  "    " ~ this.componentConst!(c).toString() ~ "\n";
                    }
                    else 
                    {
                        result ~= "  " ~ c ~ ":\n" ~
                                  "    " ~ to!string(this.componentConst!(c)()) ~ "\n";
                    }
                }
            }
            return result;
        }

    package:
        ///Does this prototype have a component of specified type?
        @property bool hasComponent(string componentType)() const
        {
            mixin("return !" ~ componentType.nameCamelCased ~ ".isNull;");
        }

        ///Get a reference to the component of specified type.
        @property ref auto component(string componentType)()
        {
            mixin("return " ~ componentType.nameCamelCased ~ ";");
        }

        ///Get a const reference to the component of specified type.
        @property ref const auto componentConst(string componentType)() const
        {
            mixin("return " ~ componentType.nameCamelCased ~ ";");
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

        ///Get a bit mask specifying which components this prototype has.
        @property ulong componentMask() const 
        {
            ulong mask = 0;
            foreach(type; componentTypes) if(hasComponent!type)
            {
                mask |= componentType!type();
            }

            return mask;
        }
}
pragma(msg, "EntityPrototype size is " ~ to!string(EntityPrototype.sizeof));

