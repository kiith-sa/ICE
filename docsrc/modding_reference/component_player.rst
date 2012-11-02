.. _modding_reference/component_player:

================
Player component
================

A player component specifies which player controls an entity (if it also has
a :ref:`modding_reference/component_controller`).  While it can be declared in
YAML, there is currently only one hardcoded player (player ``0``), which
controls the player ship. In future, this might be used for multiple players,
and maybe AI players. The only parameter a player component takes is the player
index.

Example::

   player: 0

An entity with this PlayerComponent is controlled by player 0.
