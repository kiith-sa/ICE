.. _modding_reference/component_health:

================
Health component
================

Entities with a health component have limited health (hitpoints, whatever) 
that can be decreased by effects such as warheads. An entity with a health
component dies when its health reaches zero. A health component only specifies
maximum health (which is also starting health).

Example::

   health: 30

An entity with this health component will have a maximum of 30 health, and
spawn with 30 health. It will die when its health drops to zero.
