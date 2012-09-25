.. _modding_reference/component_volume:

================
Volume component
================

A volume component defines physical volume taken up by an entity.  This used
for collision detection. If volumes of two entities intersect, and at least one
of them is collidable (e.g. projectile(not collidable) and ship(collidable) or
ship and ship (both collidable)), collision response (such as a warhead) goes
into effect.

Example::

   volume:
     aabbox: 
       min: [-20, -30]
       max: [20, 7]

An entity with this volume component is, for purposes of collision detection, a
rectangle with X extents of -20 to 20 and Y extents of -30 to 7 relative to 
position of the entity.

----
Tags
----

====== =========================================================================
aabbox Defines an axis-aligned bounding box volume. This is the only volume type 
       supported at the moment. *Key-value mapping* This must always be 
       specified.
====== =========================================================================

------------------
Tags in ``aabbox``
------------------

=== ============================================================================
min Minimum extents of the AABBox relative to position of the entity. Both 
    coordinates' values must be lower than their values in max. 
    *Sequence of 2 floats*. This must be specified; there is no default.
max Maximum extents of the AABBox relative to position of the entity. Both 
    coordinates' values must be higher than their values in min. 
    *Sequence of 2 floats*. This must be specified; there is no default.
=== ============================================================================
