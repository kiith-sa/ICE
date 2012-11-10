
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Comoponent that makes an entity controllable, as if through user input.
module component.controllercomponent;


import math.vector2;
import util.bits;
import util.yaml;


/*
 *
 * Possible improvement:
 *
 * Don't implicitly add a ControllerComponent with a DumbScriptComponent or 
 * the player ship. Let it be specified manually, like this:
 *
 * controller: controlled-by: player 1 #2, etc could also be used
 *
 * dumbscript: dumbscripts/script.yaml
 * controller: controlled-by: dumbscript 1 #2, etc could also be used
 *
 * This will especially be useful when many components might affect a 
 * ControllerComponent. We can explicitly specify which one controls
 * the entity, and eventually maybe even change it. E.g. a (dumb?)script 
 * instruction might give control to player and player action to 
 * (dumb?)script, implementing stuff like special moves, macros, "autopilot".
 */

/**
 * Component that makes an entity controllable, as if through user input.
 *
 * Logically emulates a controller with buttons used to control a ship.
 */
struct ControllerComponent
{
    public:
        ///Booleans specifying which weapons are currently being fired.
        Bits!256 firing;

        ///Should the entity kill itself?
        bool die;

    private:
        static bool DO_NOT_DESTROY_AT_ENTITY_DEATH;
         
        ///Direction of movement.
        Vector2f movementDirection_;

    public:
        /**
         * Load from a YAML node. 
         *
         * Right now YAML can only specify existence of a ControllerComponent,
         * not load anything from it.
         */
        this(ref YAMLNode yaml)
        {
            //Nothing so far.
        }

        ///Set the movement direction. Length of the vector must be <= 1.0 .
        @property void movementDirection(Vector2f rhs) pure nothrow 
        in
        {
            //A small epsilon for floating-point errors.
            assert(rhs.length < 1.000001,
                   "Movement direction vector's length must be at most 1");
        }
        body
        {
            movementDirection_ = rhs;
        }

        ///Get the movement direction.
        @property Vector2f movementDirection() const pure nothrow 
        {
            return movementDirection_;
        }
}
