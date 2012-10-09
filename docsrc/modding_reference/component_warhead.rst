.. _modding_reference/component_warhead:

=================
Warhead component
=================

Warhead component allows an entity to damage other entities on collision.  Note
that in order for any collision to happen, the entity also must have
a :ref:`modding_reference/component_collidable` and
a :ref:`modding_reference/component_volume`.  This can be used for projectiles
to damage ships and for damage in ship-ship collisions.

Example::

   warhead:
     damage: 6

An entity with this warhead component will, at collision, damage the entity it 
collided with by 6 damage. After that, it will die (This can be prevented using
``killsEntity: false``: see below.).

----
Tags
----

=========== ====================================================================
damage      Damage caused to the entity we collided with. Negative damage can be
            used for healing effects. *Integer*. Must be specified; there is no 
            default.
killsEntity If true(default), the entity with the warhead component dies when 
            the warhead is activated. For example, projectiles should die when 
            they hit their target. However, ships should not die when they 
            collide with something; this can be acheved by setting this 
            to ``false``. *Bool*. Default: ``true``.
=========== ====================================================================

