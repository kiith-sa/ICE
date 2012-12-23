.. _modding_reference/component_health:

================
Health component
================

Entities with a health component have limited health (hitpoints, whatever) that
can be decreased by effects such as warheads. An entity with a health component
dies when its health reaches zero. A health component can be specified in two
formats; a more basic format that only specifies maximum health (which is also
starting health), and a detailed format which also allows to specify a shield.

Example::

   health: 30

An entity with this health component will have a maximum of 30 health.  It will
die when its health drops to zero.

Example::

   health:
     health: 150
     shield: 75
     shieldReloadRate: 25

An entity with this health component will have a maximum of 150 health.  It
will also have a shield capable of withstanding 75 damage. The shield will
reload at 25 per second; the health will not reload.

----
Tags
----

================ ===============================================================
health           Maximum heatlth the entity can have. This is the health the 
                 entity will have when it's spawned. *Unsigned integer*.
                 There is no default; this must be specified.
shield           Maximum shield the entity can have. The entity will also be 
                 spawned with this shield. *Unsigned integer*. Default: ``0``.
shieldReloadRate Reload rate of the shield in units per second. E.g. if shield
                 is ``75`` and this is ``25``, it will take 3 seconds for the 
                 shield to fully reload from zero. *Unsigned integer*. 
                 Default: ``50``.
================ ===============================================================
