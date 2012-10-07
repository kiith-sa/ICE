================
Weapon component
================

Weapon component allows an entity to have weapons which can be used by scripts
or the player. An entity has 256 weapon *slots*, any of which can contain a
weapon. Weapons are referenced through these slots by scripts or internal
player logic.  Weapons themselves are specified in separate files, not directly
in the component.  To spawn entities (projectiles), weapons use the
:ref:`modding_reference/component_spawner`, which is added together with a
weapon component if not already present in an entity.

Example::

   weapon:
     0: weapons/player.yaml
     1: weapons/clusterBombBack.yaml
     2: weapons/circleOfDeath.yaml
     3: weapons/activeshield.yaml

An entity with this weapon component has 4 weapons (in slots 1-4).
Each of these is in its own YAML file.

----
Tags
----

============= ================================================================
``0``-``255`` Weapon slot. Specifies file name of the weapon to use in this
              slot. *String*. Default: none.
============= ================================================================


Weapons are in separate files to allow different entities to share weapons.  A
weapon file specifies things like how long it takes to fire, how many shots
(**bursts**) can be fired before reloading and how long reloading takes.  It
also specifies all entities (projectiles) to spawn in one burst. Any entities
can be spawned. For example, even ships or missiles with nontrivial behavior
(through dumbscripts).

Example weapon file::

  burstPeriod: 0.17
  ammo: 3
  reloadTime: 1.0
  burst:
    - entity: projectiles/rocket.yaml 
      components:
        physics:
          position: [-18, 15.0]
          speed: 25.0
          spawnAbsolute: [velocity]
    - entity: projectiles/rocket.yaml 
      components:
        physics:
          position: [18, 15.0]
          speed: 25.0
          spawnAbsolute: [velocity]

This weapon fires a burst every 0.17 seconds. It can fire 3 bursts before
reloading, which takes 1 second. Each burst spawns 2 "rocket" projectiles.
Position and speed of these is specified during spawning (see
:ref:`modding_reference/component_spawner`).

---------------------
Tags in a weapon file
---------------------

=========== ==================================================================
burstPeriod Period between bursts in seconds. Must be greater than 0. *Float*.
            This must be specified; there is no default.
ammo        Number of bursts that can be fired before the weapon needs to 
            reload. 0 means infinite ammo. *Integer*. Default: ``0``.
reloadTime  Time it takes to reload the weapon. *Float*. Default: ``0``.
burst       Entities to spawn at weapon bursts.
            This works exactly like :ref:`modding_reference/component_spawner`
            entries, but without spawning conditions (burst of this weapon 
            is the internally used spawning condition). *Sequence of entity 
            entries*. Must be specified; there is no default.
=========== ==================================================================
