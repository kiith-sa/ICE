.. _modding_reference/component_physics:

=================
Physics component
=================

A physics component manages physics state of an entity, such as its position,
rotation and velocity. Any entity that is located at some position must have 
a physics component.

Example::

   physics:
     position: [0, 45]
     rotation: 90deg
     speed: 50
     spawnAbsolute: [velocity]

Entities with this physics component will be located at ``[0, 45]`` relative to
their spawn point, rotated ``90deg`` (that is, directed to right), and moving
forward at 50 units per second. The velocity/speed will be the same regardless
of velocity of the spawner entity.


----
Tags
----

============= ==================================================================
position      2D position of the entity. The left-top corner of the screen is 
              position ``[0, 0]``. The right-bottom corner is ``[800, 600]``. 
              This is always the same regardless of window resolution. By 
              default, this is relative to whichever entity spawns this entity.
              ``spawnAbsolute`` can be used to change that. *Sequence of 2 
              floats*. Default: ``[0, 0]``.
rotation      Rotation of the entity. Specified in radians by default. Suffix
              ``deg`` can be used to specify rotation in degrees. For example:
              ``rotation: 45.5deg``. Rotation of 0 points down; 90deg or about
              1.57 (half PI) points right, 180/3.14 up, 270/4.71 left. By 
              default, rotation is relative to rotation of whichever entity 
              spawns this entity. ``spawnAbsolute`` can be used to change that. 
              *Float scalar*. Default: ``0``.
velocity      2D Velocity of the entity when it is spawned. This is completely 
              independent of rotation - e.g. a velocity of ``[1, 0]`` moves the 
              entity right regardless of whether it's rotated to the right or 
              left. Velocity is measured in units per second. For eample, an 
              entity with velocity of ``[200, 300]`` will move 200 units right 
              and 300 units down each second. By default, velocity is relative 
              to velocity of whichever entity spawns this entity. 
              ``spawnAbsolute`` can be used to change that. *Sequence of 2 
              floats*. Default: ``[0, 0]``.
speed         A convenience way of specifying velocity in direction the entity 
              is rotated to. For example, a speed of ``200`` translates to 
              movement of 200 units per second to the front. This is an 
              alternative way of specifying velocity; **specifying both velocity
              and speed is an error**. *Float scalar*.
PRS           A shorthand specifying position, rotation and speed. For example,
              ``PRS: [[50, 100], 90deg, 100]`` is the same as specifying 
              position ``[50, 100]``, rotation ``90deg`` and speed ``100``. This
              is useful e.g. when spawning many entities at once. **When PRS is 
              specified, specifying either one of position, rotation, velocity 
              or speed is an error**. *Sequence of position, rotation and 
              speed, with the same types as used with respective tags*.
spawnAbsolute Normally, when an entity spawns another entity (e.g. firing a 
              projectile or exploding), position, rotation and velocity of the 
              newly spawned entity are added up to the spawner's position, 
              rotation and velocity. That is, they are relative. This ensures 
              that a rotated ship shoots projetiles in the rotated projectiles, 
              and, for that matter, that projectiles are spawned near the ship 
              instead of some fixed position. Sometimes, this is not desirable 
              and we want an entity to be spawned with fixed position, rotation
              or velocity. ``spawnAbsolute`` is a sequence that can contain one 
              or more of the following named values: ``position``, ``rotation``,
              ``velocity``. These specify that the particular physics attribute 
              is absolute when spawning. For example: 
              ``spawnAbsolute: [rotation, velocity]`` specifies that the entity
              will be spawned with fixed rotation and velocity regardless of its 
              spawner. In this example, the position is still relative.
              *Sequence of named values*. Default: ``[]``.
============= ==================================================================
