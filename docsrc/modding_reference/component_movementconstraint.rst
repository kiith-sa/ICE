.. _modding_reference/component_movementconstraint:

============================
MovementConstraint component
============================

A MovementConstraint component limits movement of an entity to an area. An 
example of this is the player ship which is limited to obly move within the 
screen. The area can also be specified relatively; for example, projectiles 
might be constrained to a particular area around the entity that fired them.

Example::

   movementConstraint:
     aabbox: [-1024, -80, 1024, 800]
     constrainedToOwner: true

An entity with this movement constraint component will only be able to move in
rectangle area with min coordinates of ``[-1024, -80]`` and max coordinates of
``[1024, 800]`` relative to the *owner* entity. Owner is most often whichever
entity spawned this entity.


----
Tags
----

================== =============================================================
aabbox             Constrain movement to an axis aligned bounding box 
                   (aka rectangle) area. By default, this is an absolute area 
                   in screen coordinates. *constrainedToOwner* can be used to 
                   change that. *Sequence of 4 floats*. Must be specified; 
                   there is no default.
constrainedToOwner If this is true, the constraint area is relative to owner's
                   position. Usually, owner is the entity that spawned this 
                   entity. After the owner dies, the constraint is relative to 
                   its last position. If the entity has no owner, the constraint 
                   is absolute (relative to ``[0, 0]``). *Bool*. 
                   Default: ``false``.
================== =============================================================
