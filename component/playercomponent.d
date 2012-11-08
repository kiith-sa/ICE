
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Gives an entity an owner player that can control it.
module component.playercomponent;


import ice.player;
import util.yaml;


/// Gives an entity an owner player that can control it.
struct PlayerComponent
{
    /// Player owning the entity. null until the PlayerSystem sets it.
    Player player;

    /// Index of the player owning the entity. Used by PlayerSystem to set the player.
    uint playerIndex;

    /// Load from a YAML node. 
    this(ref YAMLNode yaml)
    {
        playerIndex = yaml.as!uint;
    }
}
