.. _modding_reference/component_deathtimeout:

======================
DeathTimeout component
======================

A deathtimeout component specifies the maximum time an entity might live - when
this time (started when the entity is spawned) passes, the entity is destroyed.
This is mainly used for projectiles which need to cease to exist after leaving
the screen to free CPU/memory resources. It is also useful for entities that
spawn other entities at their destruction, e.g cluster bombs.


Example::

   deathTimeout: 0.3

An entity with this deathtimeout component will die 0.3 seconds after spawning
(unless killed earlier).
