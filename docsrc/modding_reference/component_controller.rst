.. _modding_reference/component_controller:

====================
Controller component
====================

A controller component simulates "buttons" by which an entity can be
controlled.  It is used by the player ship and dumbscripts. A controller
component is automatically added to an entity if it has a dumbscript component.
It can be specified explicitly, but currently, without a dumbscript, it won't
do anything anyway. This might change in future if there are more ways to
control an entity.

Example::

   controller:

Currently, controller component has no parameters.
