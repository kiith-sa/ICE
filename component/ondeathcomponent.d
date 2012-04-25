
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Comoponent that calls a function when the entity dies.
module component.ondeathcomponent;


import component.entitysystem;

import util.yaml;


/**
 * Comoponent that calls a function when the entity dies. 
 */
struct OnDeathComponent
{
    public:
        ///Function to be called when the entity dies.
        void delegate(ref Entity) onDeath;

    public:
        /**
         * Load from a YAML node. 
         *
         * Right now YAML can only specify existence of a ControllerComponent,
         * not load anything from it.
         */
        this(ref YAMLNode yaml)
        {
            throw new YAMLException("Can't specify OnDeathComponent in YAML "
                                    "- it's run-time only");
        }

        ///Construct an OnDeathComponent that will call specified function on death.
        this(void delegate(ref Entity) onDeath)
        {
            this.onDeath = onDeath;
        }
}
