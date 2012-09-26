.. _modding_reference/component_engine:

================
Engine component
================

Engine component allows an entity to change its movement(velocity) over time.
It behaves like an "engine" accelerating the entity in certain direction when
enabled. Whether the engine is enabled and the direction to apply acceleration
in is determined by :ref:`modding_reference/component_controller` which in turn
is controlled either by a :ref:`modding_reference/component_dumbscript` or by
a player.

Example::

   engine:
     maxSpeed: 450
     acceleration 250

An entity with this engine component will accelerate by 250 units/second every
second until it reaches a speed of 450 units/second.

----
Tags
----

============ ===================================================================
maxSpeed     Maximum speed the entity can move in units per second. When the 
             engine is active, acceleration is applied until this speed is 
             reached. If speed of the entity is any higher than this, it will be 
             lowered to this value. Must be greater or equal to 0.0. *Scalar 
             float*. This is required; there is no default value.
acceleration Acceleration applied when the engine is enabled in units per second 
             per second. Negative values represent instant acceleration; i.e. 
             the entity is instantly accelerated to full speed in the engine's 
             direction.
============ ===================================================================

