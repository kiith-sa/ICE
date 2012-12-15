.. _modding_reference/component_spawner:

=================
Spawner component
=================

Entities with a spawner component can spawn (create) new entities when certain
conditions are met. This is a very powerful mechanism that can be used to
create various effects. An example is spawning explosion effects when a ship
dies.  As any entity can be spawned, it can be used to duplicate a projectile,
create projectiles like cluster bombs that split into smaller projectiles,
making a ship spawn other ships and so on. Under the hood, weapons also use
a spawner component to fire projectiles.

A spawner component can override components of spawned entities.  This allows
to give spawned entities different scripts, modify their health, and so on.
Usually at least the physics component is overridden to set position and
velocity of a spawned entity.

Components can only be overridden whole. If you override a physics component,
and only specify position, it won't override only the position and keep other
attributes' values; it will override the physics component with a new component
with specified position and other attributes with their default values.

The spawner component is a sequence of entities to spawn.  For each entity, its
file can be specified, as well as the condition to spawn at, components to
override and so on.

Example::

   spawner:
     - entity: explosions/player.yaml
       condition: death 
       components:
         physics: 
           position: [0, 0]
     - entity: explosions/deathbase.yaml 
       condition: death 
       components:
         visual: visual/player.yaml
         physics: 
           position: [0, 0]

An entity with this spawner component will spawn two entities when it dies.
Both will be spawned exactly at the spawner's position. The first one is 
an explosion; the other is a dummy entity that will continue displaying 
the same visual as the spawner for a while.

-----------------------
Tags in an entity entry
-----------------------

============== ================================================================
entity         File name of the entity to spawn. *String*. This must be
               specified; there is no default.
condition      When this condition is met, the entity is spawned. A condition
               might have parameters, such as a period for periodic. Supported
               conditions are described in a table below. This must be
               specified; there is no default.
components     Components specified here will override components from
               specified entity. Components are specified in the same way as
               in an entity file. Even components that are not present in the
               specified entity can be used. Usually, at least the physics 
               component should be overridden to specify position, velocity 
               and/or rotation.
spawnerIsOwner When true, the spawner entity will own the spawned entity. This
               can be useful for movement constraints and weapons.
               *Bool*. Default: ``true``.
delay          Delay between the condition is met and the entity is spawned in
               seconds. Must be greater or equal to zero. *Float*. 
               Default: ``0.0``.
============== ================================================================

----------
Conditions
----------

============= =================================================================
death         Spawn when the spawner dies. Useful for explosions, splitting
              ships, and so on.
spawn         Spawn together with the spawner.
weaponBurst A Spawn when burst of weapon in slot A starts. If there is no
              weapon in the slot, nothing happens. A is *integer* and must be
              at least ``0`` and at most ``255``.
periodic A    Spawn periodically, as long as the spawner exists. A is a *float*
              parameter specifying the period in seconds. The period must be
              greater than zero.
============= =================================================================
