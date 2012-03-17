
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Comoponent that makes an entity controllable, as if through user input.
module component.controllercomponent;


import util.bits;
import util.yaml;


/**
 * Comoponent that makes an entity controllable, as if through user input.
 *
 * Logically emulates a controller with buttons used to control a ship.
 */
struct ControllerComponent
{
    ///Direction buttons. 
    bool up, down, left, right;

    ///Booleans specifying which weapons are currently being fired.
    Bits!256 firing;

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
}


