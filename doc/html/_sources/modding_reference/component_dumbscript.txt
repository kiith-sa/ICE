.. _modding_reference/component_dumbscript:

====================
DumbScript component
====================

A dumbscript defines behavior of an entity, such as moving and firing. Unless
an entity is player controlled, without a dumbscript, it will not use its
engine or weapons (if any). A dumbscript controls
a :ref:`modding_reference/component_controller`, which is added to an entity by
default with the dumbscript component.

A dumbscript component is specified by filename of a separate dumbscript file.

Example::

   dumbscript: dumbscripts/script.yaml

The script itself is in this file. A dumbscript is a YAML sequence of
instructions. It is just a simple series of tasks to carry out, there is no
flow control.

Example::

   !!pairs
   - for 0.2:
       fire: [0, 1]
   - for 0.3:
       move-direction: 0.3
       move-speed: 0.3
   - for 0.3:
       move-direction: -0.2
       move-speed: 0.45
       fire: [1]
   - die:

An entity with this script will first fire weapons in slots ``0`` and ``1`` for
0.2 seconds, then move in direction of 0.3 radians (degrees can be used as
well) at 0.3 times its full speed for 0.3 seconds. Then, it will move in
direction of -0.2 radians with 0.45 of its full speed, firing weapon ``1``.
After that, the entity will die.


------------
Instructions
------------

===== ==========================================================================
for X Carry out an action for the duration of X seconds. The action is 
      determined by parameters specified as key:value pairs. These are 
      described in the table below. This can be used to e.g. move or fire for a 
      certain duration, and even to move *and* fire simultaneously.
die   When this instruction is reached, the entity dies. This is important for 
      example for enemy ships that must cease to exist after leaving the screen
      to free CPU and memory resources.
===== ==========================================================================


-------------------------------------
Parameters of the ``for`` instruction
-------------------------------------

============== =================================================================
move-direction Move in the direction specified in radians. Degrees can be 
               specified using the ``deg`` suffix. Movement direction follows
               the same rules as rotation of a 
               :ref:`modding_reference/component_physics`. *Float scalar*. 
               Default: no direction (i.e. don't move)
move-speed     Movement speed as a multiple of the entity's max speed determined 
               by its engine component. *Float scalar*. Default: ``1.0``.
fire           Fire weapons in specified slots. If there is no weapon in any 
               specified slot, it is ignored. *Sequence of integers*. 
               Default: ``[]``.
============== =================================================================
