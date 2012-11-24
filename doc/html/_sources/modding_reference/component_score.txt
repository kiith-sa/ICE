.. _modding_reference/component_score:

===============
Score component
===============

A Score component assigns one or more score values to an entity. These values
increase the score statistics of other entities that kill this entity (if they
have a statistics component). This can be used for scoring and RPG statistics
improvement.

Example::

   score:
     exp: 30

When an entity with this score component is killed, experience of the entity 
that killed it will increase by 30 points.


----
Tags
----

================== =============================================================
exp                Experience value of the entity. *Unsigned integer*. Must be
                   specified; there is no default.
================== =============================================================

