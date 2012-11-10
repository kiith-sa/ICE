
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Component that constraints an entity's movement, e.g. to another entity or an area.
module component.movementconstraintcomponent;


import component.entitysystem;

import math.vector2;
import math.rect;
import util.yaml;


/**
 * Component that constraints an entity's movement, e.g. to another entity or an area.
 *
 * This is used e.g. to limit player ship movement.
 */
struct MovementConstraintComponent
{
    private static bool DO_NOT_DESTROY_AT_ENTITY_DEATH;
    public:
        /**
         * If true, we're constrained to an owner determined by OwnerComponent.
         *
         * Otherwise, the constraint is in world space.
         */
        bool constrainedToOwner;

        ///Constraint types.
        enum Type
        {
            ///Used when uninitialized to detect errors.
            Uninitialized,
            ///Axis-aligned bounding box.
            AABBox
        }

        /**
         * Position we're constrained to. 
         *
         * If we're constrained to an owner, this is changed each update.
         */
        Vector2f position = Vector2f(0.0f, 0.0f);

    private:
        ///Type of this constraint.
        Type type_ = Type.Uninitialized;

        union 
        {
            ///Axis-aligned bounding box.
            Rectf aabbox_;
        }

    public:
        /**
         * Load from a YAML node. 
         *
         * Throws YAMLException on error.
         */
        this(ref YAMLNode yaml)
        {
            constrainedToOwner = yaml.containsKey("constrainedToOwner")
                               ? yaml["constrainedToOwner"].as!bool
                               : false;
            type_ = Type.AABBox;
            aabbox_ = fromYAML!Rectf(yaml["aabbox"], 
                                     "MovementConstraintComponent constructor");
        }

        ///Get the constraint as an AABBox
        @property ref inout(Rectf) aabbox() inout pure nothrow 
        in
        {
            assert(type_ == Type.AABBox,
                   "Trying to read a constraint that is not AABBox as AABBox.");
        }
        body
        {
            return aabbox_;
        }

        ///Get constraint type.
        @property Type type() const pure nothrow {return type_;}
}

