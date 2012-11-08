//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

/// Manages game players and player components.
module component.playersystem;


import ice.player;
import component.entitysystem;
import component.playercomponent;
import component.system;


/// Manages game players and player components.
class PlayerSystem: System
{
private:
    // Players in the game.
    Player[] players_;

    // Reference to the entity system.
    EntitySystem entitySystem_;

public:
    /// Construct a PlayerSystem working on entities from specified EntitySystem, 
    /// with specified players in game.
    this(EntitySystem entitySystem, Player[] players)
    {
        entitySystem_ = entitySystem;
        players_      = players;
    }

    /// Update the PlayerSystem.
    void update()
    {
        // Assign Players to PlayerComponents based on their player indices.
        foreach(ref Entity e, ref PlayerComponent player; entitySystem_)
        {
            if(player.player is null && players_.length > player.playerIndex)
            {
                player.player = players_[player.playerIndex];
            }
        }
    }
}
