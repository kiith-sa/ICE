//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

/// Provides an entity with an ability to play sound effects.
module component.soundcomponent;


import std.conv;
import std.stdio;

import math.math;
import memory.allocator;
import containers.fixedarray;
import util.yaml;


/// Provides an entity with an ability to play sound effects.
struct SoundComponent
{
public:
    /// A condition determining when to play a particular sound.
    struct PlayCondition
    {
        /// Type of playback condition.
        enum Type : ubyte
        {
            /// Played when the entity is spawned.
            Spawn,
            /// Played at burst of weapon specified by weaponIndex.
            Burst,
            /// The entity is being hit by a warhead.
            ///
            /// Better than adding a SoundComponent to projectiles 
            /// even though that would be more powerful.
            ///
            /// We can add a tag to this; 
            /// i.e. only play this sound when hit by entity with tag X.
            Hit
        }

        /// Type of playback condition.
        Type type;

        /// Type-specific data.
        union
        {
            /// Index of the weapon used with Burst type.
            ubyte weaponIndex;
        }

        /// Sound to play when the condition is met.
        string sound;

        /// Volume of the sound. Must be between 0 and 1.
        float volume = 1.0f;
    }

    /// Use an allocator to reduce reallocation.
    alias FixedArray!(PlayCondition, BufferSwappingAllocator!(PlayCondition, 4)) PlayConditionArray;
    /// Used when there is more than one weapon.
    PlayConditionArray playConditions;

    /// Load from a YAML node. Throws YAMLException on error.
    this(ref YAMLNode yaml)
    {
        // Example SoundComponent:
        //   sound:
        //     - condition: spawn 
        //       sound:  someSound.ogg
        //     - condition: burst
        //       weapon: 0
        //       sound:  someOtherSound.ogg
        //       volume: 1.0
        playConditions = PlayConditionArray(yaml.length);
        uint index = 0;
        foreach(ref YAMLNode item; yaml)
        {
            PlayCondition condition;
            const conditionType = item["condition"].as!string;
            switch(conditionType)
            {
                case "spawn": condition.type = PlayCondition.Type.Spawn; break;
                case "burst": condition.type = PlayCondition.Type.Burst; break;
                case "hit":   condition.type = PlayCondition.Type.Hit;   break;
                default:
                    throw new YAMLException("Unknown sound play condition: " ~ conditionType);
            }
            if(condition.type == PlayCondition.Type.Burst)
            {
                condition.weaponIndex = item["weapon"].as!ubyte;
            }
            condition.sound = item["sound"].as!string;
            if(item.containsKey("volume"))
            {
                condition.volume = item["volume"].as!float;
                if(condition.volume < 0.0f || condition.volume > 1.0f)
                {
                    writeln("Sound effect volume must be between 0 and 1; ",
                            "invalid value ", condition.volume, "  will be clamped");
                    condition.volume = clamp(condition.volume, 0.0f, 1.0f);
                }
            }
            playConditions[index] = condition;
            ++index;
        }
    }
}
