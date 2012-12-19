//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

/// Plays sound effects of entities.
module component.auralsystem;


import std.algorithm;

import audio.soundsystem;
import component.entitysystem;
import component.system;
import component.soundcomponent;
import containers.vector;
import math.rect;
import math.vector2;
import time.gametime;


/// Plays sound effects of entities.
class AuralSystem : System
{
private:
    /// Entity system whose data we're processing.
    EntitySystem entitySystem_;

    /// Game time subsystem (used for delayed sounds).
    GameTime gameTime_;

    /// Sound system handling sound playback.
    SoundSystem soundSystem_;

    /// We can't hear sounds of objects outside this area 
    ///
    /// (entities without a position play sounds anyway)
    Rectf soundArea_;

    /// Sound with delayed playback.
    struct DelayedSound
    {
        /// Sound to play.
        string sound;
        /// Relative volume of the sound (0.0 to 1.0).
        float volume;
        /// Time when the sound should be played.
        real time;
    }

    /// Stores sounds whose play conditions have been met but have a delay.
    /// 
    /// delayedSounds_[0 .. delayedSoundsUsed_] are sounds to be played. Other 
    /// entries are preallocated and ready to be reused.
    /// 
    /// Possible optimizations:
    /// 1) Binary heap, sorted array, or sorted array of indices to this array.
    Vector!DelayedSound delayedSounds_;

    /// Number of used items in delayedSounds_.
    size_t delayedSoundsUsed_;

public:
    /// Construct an AuralSystem.
    ///
    /// Params:  entitySystem = Entity system whose data we're processing.
    ///          gameTime     = Game time subsystem.
    ///          soundSystem  = Sound system used to play sounds.
    ///          soundArea    = Area in which we can hear sounds.
    this(EntitySystem entitySystem, GameTime gameTime, SoundSystem soundSystem,
         ref const Rectf soundArea)
    {
        delayedSounds_.reserve(1024);
        entitySystem_ = entitySystem;
        gameTime_     = gameTime;
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

        const time = gameTime_.gameTime;
        // Play any sounds that have reached their play time.
        for(size_t s = 0; s < delayedSoundsUsed_; ++s)
        {
            if(delayedSounds_[s].time > time){continue;}

            //Play.
            soundSystem_.playSound(delayedSounds_[s].sound, delayedSounds_[s].volume);
            //Remove from delayedSounds_ (it's unsorted, so removing can be fast).
            --delayedSoundsUsed_;
            swap(delayedSounds_[s], delayedSounds_[delayedSoundsUsed_]);
        }
    }

private:
    // Process a sound playing condition for an entity, playing sound if needed.
    //
    // Params: e         = Entity with the play condition.
    //         condition = Play condition to process.
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
                    playSound(condition);
                }
                return;
            // Play sound if a particular weapon has fired.
            case Burst:
                auto weapon = e.weapon;
                // No WeaponComponent. Ignore.
                if(weapon is null){return;}
                if(weapon.burstStarted[condition.weaponIndex])
                {
                    playSound(condition);
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
                            playSound(condition);
                            return;
                        }
                    }
                }
                return;
        }
    }

    // Play sound of specified play condition (with delay if needed). 
    void playSound(SoundComponent.PlayCondition condition)
    {
        if(condition.delay < 0.001)
        {
            soundSystem_.playSound(condition.sound, condition.volume);
            return;
        }
        DelayedSound* sound = getFreeDelayedSound();
        *sound = DelayedSound(condition.sound, condition.volume, 
                              gameTime_.gameTime + condition.delay);
    }

    // Get unused delayed sound from delayedSounds_, adding new one if needed.
    DelayedSound* getFreeDelayedSound()
    in
    {
        assert(delayedSoundsUsed_ <= delayedSounds_.length, 
               "more delayed sounds used than delayedSounds_ holds");
    }
    body
    {
        if(delayedSoundsUsed_ == delayedSounds_.length)
        {
            delayedSounds_.length = delayedSounds_.length + 1;
            delayedSounds_.back = DelayedSound();
        }

        return &delayedSounds_[delayedSoundsUsed_++];
    }
}
