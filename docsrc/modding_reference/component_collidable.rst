.. _modding_reference/component_collidable:

====================
Collidable component
====================

A collidable component tells the engine that the entity should be used in
collision detection. This is used e.g. in ships, but not in projectiles (unless
they should collide with other projectiles).  For example, if volumes of
a collidable ship and non-collidable projectile intersect, collision is
detected - the projectile hits the ship. Same for two collidable ships. But if
volumes of two non-collidable projectiles intersect, there is no collision; the
projectiles just continue moving as before.

Example::

   collidable:

Currently, this component has no parameters, but some collision detection
parameters might be added in future.
A :ref:`modding_reference/component_volume` is needed to actually have a volume
to detect collision with.
