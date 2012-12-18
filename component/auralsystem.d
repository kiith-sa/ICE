//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

/// Plays sound effects of entities.
module component.auralsystem;


import audio.soundsystem;
import component.entitysystem;
import component.system;
import component.soundcomponent;
import math.rect;
import math.vector2;


/// Plays sound effects of entities.
class AuralSystem : System
{
private:
    /// Entity system whose data we're processing.
    EntitySystem entitySystem_;

    /// Sound system handling sound playback.
    SoundSystem soundSystem_;


    /// We can't hear sounds of objects outside this area 
    ///
    /// (entities without a position play sounds anyway)
    Rectf soundArea_;

public:
    /// Construct an AuralSystem.
    ///
    /// Params:  entitySystem = Entity system whose data we're processing.
    ///          soundSystem  = Sound system used to play sounds.
    ///          soundArea    = Area in which we can hear sounds.
    this(EntitySystem entitySystem, SoundSystem soundSystem, ref const Rectf soundArea)
    {
        entitySystem_ = entitySystem;
        soundSystem_  = soundSystem;
        soundArea_    = soundArea;
    }

    /// Check entities' sound playback conditions and play sounds.
    void update()
    {
        foreach(ref Entity e, ref SoundComponent sound; entitySystem_)
        {
            foreach(ref SoundComponent.PlayCondition condition; sound.playConditions)
            {
                processCondition(e, condition);
            }
        }
    }

    /// Process a sound playing condition for an entity, playing sound if needed.
    ///
    /// Params: e         = Entity with the play condition.
    ///         condition = Play condition to process.
    void processCondition(ref Entity e, ref SoundComponent.PlayCondition condition)
    {
        auto physics = e.physics;
        // Can't hear a sound outside the game area.
        if(physics !is null && !soundArea_.intersect(physics.position))
        {
            return;
        }
        final switch(condition.type) with(SoundComponent.PlayCondition.Type)
        {
            // Play sound if the entity has just been spawned.
            case Spawn:
                if(e.spawned)
                {
                    soundSystem_.playSound(condition.sound, condition.volume);
                }
                return;
            // Play sound if a particular weapon has fired.
            case Burst:
                auto weapon = e.weapon;
                // No WeaponComponent. Ignore.
                if(weapon is null){return;}
                if(weapon.burstStarted[condition.weaponIndex])
                {
                    soundSystem_.playSound(condition.sound, condition.volume);
                }
                return;
            // Play sound if the entity has been hit.
            case Hit:
                auto collidable = e.collidable;
                // No CollidableComponent. Ignore.
                if(collidable is null){return;}
                if(collidable.hasColliders)
                {
                    foreach(ref collider; collidable.colliders)
                    {
                        auto owner = collider.owner;
                        if(owner is null || owner.ownerID != e.id)
                        {
                            soundSystem_.playSound(condition.sound, condition.volume);
                            return;
                        }
                    }
                }
                return;
        }
    }
}
