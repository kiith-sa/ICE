
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Gives an entity an owner player that can control it.
module component.playercomponent;


import ice.player;

import util.yaml;


///Gives an entity an owner player that can control it.
struct PlayerComponent
{
    ///Player owning the entity.
    Player player;

    /**
     * Load from a YAML node. 
     *
     * PlayerComponent is not loadable, so this always throws YAMLException.
     */
    this(ref YAMLNode yaml)
    {
        throw new YAMLException("Can't specify PlayerComponent in YAML - it's run-time only");
    }

    ///Construct from a reference to the controlling player.
    this(Player player) pure nothrow
    {
        this.player = player;
    }
}

