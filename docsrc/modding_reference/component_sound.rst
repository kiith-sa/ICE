.. _modding_reference/component_sound:

================
Sound component
================

A sound component allows an entity to play sounds when certain conditions are
met (e.g. firing a weapon, being hit). In YAML, a sound component is a sequence
of sound playing conditions. Each condition might have various tags, at least
specifying the condition and file name of the sound to play.  Two sound formats
are supported: WAV and Ogg Vorbis.

Example::

   sound:
     - condition: hit
       sound:     sound/firing/hit.ogg
       volume:    0.3
     - condition: burst
       weapon:    0
       sound:     sound/firing/laser.ogg
     - condition: spawn
       sound:     sound/spawn/created.ogg
       delay:     0.5

An entity with this sound component has three sounds it might play. The first
is played when it's being hit, with 30% volume. The second is played when the
weapon in weapon slot 0 is fired, with full volume, and the last is played 0.5
seconds after the entity is spawned.

.. note::

   Sound effects will only play for entities inside or very close to game area,
   or entities without a position (no physics component). This is to prevent
   entities that are not dead yet but have left the screen from playing sounds.
   (As of time of this writing, the "sound area" is the game area with a margin
   of 64 units in all directions).

----
Tags
----

========= ======================================================================
condition When this condition is met, the sound is played. The value can be one 
          of *spawn*, met when the entity is created, *hit*, when the entity 
          collides (e.g. with a projectile), and *burst*, when the entity fires 
          a weapon (which must be specified by the *weapon* tag in that case).
          This must be specified; there is no default.
delay     Delay between meeting the condition and playing the sound.
          *Float, at least 0.0*. Default: ``0.0``
weapon    When the *burst* condition is used, the sound is played if the weapon 
          in this slot (if any) starts a burst (fires). *Integer*. This must be
          specified (when *burst* condition is used); there is no default.
sound     File name of the sound to play when the condition is met. *String*.
          This must be specified; there is no default.
volume    Volume of the sound (relative to the global sound volume).
          *Float, at least 0.0 and at most 1.0*. Default: ``1.0``.
========= ======================================================================
