===========
Modding ICE
===========

------------
Introduction
------------

To simplify its development and to make its engine reusable, ICE is designed to 
be as moddable as possible. All entities in the game are loaded from human 
readable YAML files. Graphics and "scripts" are also loaded from YAML, although 
different formats might be supported in future.


^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
About the directory structure
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

ICE has a modular directory system to allow for pluggable mods in future.

Right now, there is only one "mod" - ICE itself. This mod can be found in the
``data/main`` and ``user_data/main`` directories.  Any file in ``data/main``
can be overridden by a file in ``user_data/main`` with the same filename.

Note that ``user_data/main`` translates to ``~/.ice/main`` after installation on
Linux and similar systems.

---------------
Creating a ship
---------------

Ships are stored in the ``ships`` subdirectory of a mod directory. For the main
game, that is ``user_data/main/ships``. This is a convention - ships could be
stored elsewhere if needed.

Ships are *entities* - collections of *components* that specify properties of
the ship. For example, a ship might have a *visual* component - which describes
how it is drawn.

To create your own ships, add a new file with contents of the following example
in the ``ships`` directory.

Alternatively, you can try copying and modifying any ship that already exists
there.

Example ship::

   visual: visual/player.yaml
   engine:
     maxSpeed: 300
     acceleration: 2100
   volume:
     aabbox: 
       min: [-32, -32]
       max: [32,  0]
   weapon:
     0: weapons/player.yaml
   collidable:
   health: 500
   warhead:
     damage: 500
     killsEntity: false

Each item describes a component and its properties. This ship has the following
components:

* A *visual* component, pointing to the graphics file of the ship.
* An *engine* component that can move the ship at most 300 units per second and
  accelerate at 2100 units per second per second.
* A *volume* used for collision detection (for example with projectiles). 
  This volume is an *aabbox* - axis-aligned-bounding-box, or a rectangle that does 
  not rotate.
* A *weapon* component with one weapon at slot *0*. There are multiple (256) 
  slots to allow a ship to have more than one weapon.
* A *collidable* component that allows the ship to receive collisions. Most 
  projectiles, for example, have a volume but are not collidable - they can't 
  collide with each other, only with the *collidable* ships.
* A *health* component with 500 maximum health. Entities with a health component 
  die when they run out of health.
* A *warhead* component that causes 500 damage and doesn't kill the ship itself.
  Warheads are fired at collision with another entity. This means our ship 
  causes damage to other ships it collides with but doesn't immediately get 
  destroyed. Most projectiles, for example, are destroyed as soon as they 
  collide with something.

There are other components a ship can have. You can see the modding reference
pages (linked from :ref:`index`) more detailed information.

Importantly, a ship needs other resources - In this example, a visual component
and any weapons it may use. Those are explained below.


------------------------------------
Creating graphics (visual component)
------------------------------------

Currently the only graphics format supported by ICE is a simple YAML based
vector format that stores straight lines with variable colors and line widths.

Graphics are specified by *visual components*, defined in YAML files in the
``visual`` subdirectory of a mod directory.

To create your own visual component, you can create a file with the contents of
the following example in the ``visual`` directory.

You could also try copying and modifying any visual component that already
exists there.

Example visual component::

   type: lines
   vertices:
     !!pairs
     - width: 2
     - color:  rgba40400000
     - vertex: [-7.0, -4.0]
     - color:  rgbA0A0FF
     - vertex: [-1.0, 12.0]
   
     - vertex: [1.0,  12.0]
     - color:  rgba40400000
     - vertex: [7.0,  -4.0]
   
     - color:  rgbA0A0FF
     - vertex: [0.0,  8.0]
     - color:  rgba40400000
     - vertex: [0.0,  13.0]
   
This visual component is a group of *lines*, currently the only supported
visual component *type*.

Lines are specified by the *vertices* tag, that allows setting line *width*,
vertex *color* and *vertex* itself.

Lines are formed by the 1st and 2nd vertex, the 3rd and 4rd, and so on.
The number of vertices must be even.

A *color* or *width* entry affects all vertices drawn after it, until the next 
*color* or *width* entry. Default color is white and default width is 1.

Note that *width* affects only whole lines, while *color* can change colors of
each vertex (which blend in the line, so you can e.g. have a line that blends
from a red end to a blue end).

**See also:** 

:ref:`modding_reference/component_visual`

-----------------
Creating a weapon
-----------------

Weapons are stored in the ``weapons`` subdirectory of the mod directory. A 
weapon fires *projectiles* (entities) in *bursts* of one or more projectiles. 
Each burst takes time to be fired and consumes 1 unit of ammo (which may be
finite or infinite). When a weapon runs out of ammo, it can't fire for a 
specified *reload* period.

To create a new weapon, you can create a file with the contents of the 
following example in the ``weapons`` directory.

Alternatively, you can copy and modify any weapon that already exists there.

Example weapon::

   burstPeriod: 0.06
   ammo: 3
   reloadTime: 0.2
   burst:
    - entity: projectiles/defaultBullet.yaml 
      delay: 0.0
      components:
        physics:
          position: [-1.0, 16.0]
          rotation: 0.5deg
          speed:    50.0
          spawnAbsolute: [velocity]
    - entity: projectiles/defaultBullet.yaml 
      delay: 0.0
      components:
        physics:
          position: [1.0, 16.0]
          rotation: -0.5deg
          speed:    50.0
          spawnAbsolute: [velocity]
    - entity: projectiles/defaultBullet.yaml 
      delay: 0.02
      components:
        physics:
          position: [-2.0, 12.0]
          rotation: 1deg
          speed:    50.0
          spawnAbsolute: [velocity]
    - entity: projectiles/defaultBullet.yaml 
      delay: 0.02
      components:
        physics:
          position: [2.0, 12.0]
          rotation: -1deg
          speed:    50.0
          spawnAbsolute: [velocity]


This weapon fires 3 bursts, each taking 0.06 seconds, before reloading for 0.2
seconds. Each burst consists of 4 projectiles shot at different positions
(relative to the ship) in different directions (specified in degrees here using
the *deg* suffix). Velocity of the fired (spawned) projectile is absolute, 
determined by ship's rotation and firing speed, unaffected by the ship's
own movement.

Two projectiles are fired immediately, the other two 0.02 seconds later. The
projectiles are fired at speed 50 and use their engine component (defined in
the projectile) to accelerate to full speed.

Each projectile in the burst specifies its own entity file. One burst can
consist of projectiles of multiple types. Each projectile is an entity, just
like a ship. In fact a weapon could fire ships.

In the engine, there is no difference between projectiles and ships.  When
we're firing the projectiles, we're setting their positions by overriding their
physics components. Any component can be overridden by specifying it in
*components*. You can use this, for example, to change projectiles' visual
appeareance or give them specific behaviors by dumbScripts (described below).

---------------------
Creating a projectile
---------------------

Projectiles are found in the ``projectiles`` subdirectory of the mod directory.

Both projectiles and ships are component based entities. Any component that can
be used in a ship can be used in a projectile, and vice versa.

To create a new projectile, create a file with the contents of the 
following example in the ``projectiles`` directory.

Alternatively, you could copy and modify any projectile that already exists
there.

Example projectile::

   deathTimeout: 1.1
   engine : 
     maxSpeed       : 2000
     acceleration   : 1000 
   volume:
     aabbox:
       min: [-2, -12]
       max: [2,  0]
   visual:   visual/defaultbullet.yaml
   warhead:
     damage: 10

Most components of this projectile are the same as ones used in the ship
example.

The main differences are: 

* *deathTimeout* component, which destroys the projectile 1.1 seconds after it's
  fired. It is important that projectiles that don't collide with anything have 
  a limited lifetime so they don't stay in memory forever.
* There is no *collidable* component. This means the projectiles can't collide 
  with other projectiles - only with collidable ships.
* The warhead has no ``killsEntity: false``, so the projectile is "killed" 
  after it hits its target.

This projectile has no health or weapons. However, it could have health or
weapons, or any other component a ship can have. (For example, a collidable
projectile with limited health could be a missile that can be shot down).

----------------
Creating a level
----------------

Levels are described in YAML files found in the ``levels`` subdirectory of a mod
directory.

To play a level, you must add it to a campaign. Campaign are YAML files in the 
``campaigns`` subdirectory of a mod directory. They are simple, sequential lists 
of levels in the campaign. A new campaign can be created by simply adding another 
campaign YAML file.

A level is composed of definitions of "waves" (groups of enemies
spawned simultaneously) and of a level script, which specifies when to 
spawn a wave.

Example::

   wave wave1:
     spawner:
       - entity: ships/enemy1.yaml 
         components:
           physics:
             position: [360, 32]
       - entity: ships/enemy1.yaml 
         delay: 0.1
         components:
           physics:
             position: [440, 64]
             rotation: 0
           dumbScript: dumbscripts/enemy1.yaml
   
   level:
     !!pairs
     - effect lines:
         minWidth: 0.3
         maxWidth: 1.0
         minLength: 4.0
         maxLength: 16.0
         verticalScrollingSpeed: 300.0
         linesPerPixel: 0.001
         detailLevel: 7
         color: rgbaC8C8FF30
     - wait: 2.0
     - wave: wave1
     - wait: 2.0
     - wave: [wave1, [50, 150]]
     - wait: 2.0
     - wave: 
         wave: wave1
         components:
           physics:
             position: [10, 30]
             rotation: 0.8
     - wait: 5.0
     - text: Lorem Ipsum  #at top or bottom of screen 
     - wait: 5.0
     - text: Level done!
     - wait: 2.0

^^^^^^^^^^^^^^^
Wave definition
^^^^^^^^^^^^^^^

A wave definition starts with a mapping key named ``wave xxx`` where xxx is the 
name of the wave. Wave names **must not contain spaces** .

There can be any number of wave definitions, but no two waves can have
identical names.

A wave is an entity, and a wave definition defines that entity. Waves are
generally used to spawn units by setting the *spawner* component.  Spawner is
a sequence of entities(units) to be spawned.

Each entity is a mapping with one required key, *entity*, which specifies filename
of the entity to spawn. Optional *delay* specifies delay to spawn after the wave, 
in seconds. 

Components of the entity can be overridden by *components*. At least the
physics component should be set here to position the entity. The second entity
overrides the *dumbScript* component (explained below), specifying behavior of
the spawned unit.

^^^^^^^^^^^^
Level script
^^^^^^^^^^^^

A level script starts with a mapping key named ``level``, and is composed of
instructions and their parameters. 

This level is very simple. First, we start a "lines" effect that draws
a scrolling starfield background composed of randomly generated lines.  After
2 seconds, we spawn a wave. We wait 2 more seconds, and spawn the same wave
using a different format, changing positions of its entities by ``[50, 150]``. 

Then we wait another 2 seconds and spawn the same wave again, demonstrating the
third wave instruction format. Here we make full use of the fact that a wave is
actually an entity, and can override any of its components.

Finally, we display some text.  Once the script is done, the level ends (the
player wins the level).  The player loses if their ship gets destroyed before
the level is over.


---------------------
Creating a DumbScript
---------------------

Normally when an entity is spawned, it just sits there and doesn't do anything.

Entity behavior can be controlled by a *dumbScript* component, which can be set
in the entity YAML file or anywhere the entity is spawned (e.g. a wave
definition in a level).

DumbScript is a simple YAML based "script" that specifies actions the unit
should take. It's called DumbScript because there is no flow control - it just
dumbly executes instructions one after another. In future, there might be
smarter scripts based on a real programming language, e.g. Lua.

DumbScripts are located in the ``dumbScripts`` subdirectory of a mod directory.

To create a new dumb script, you can create a file with the contents of the 
following example in the ``dumbScripts`` directory.

Alternatively, you could copy and modify any dumb script that already exists
there.

Example DumbScript::

   !!pairs
   - for 0.25:
       move-direction: 0.5
   - for 0.5:
       move-direction: -0.5
   - for 0.5:
       fire: [0, 1]
   - for 0.5:
       move-direction: 0.5
       move-speed: 0.5
       fire: [0]
   - for 0.5:
       move-direction: -0.5
       move-speed: 0.5
       fire: [0]
   - for 5.0:
       move-direction: 0
   - die:

This script moves the entity in a direction of 0.5 radians for 0.25 seconds,
then in -0.5 radians for another 0.25 seconds, then it fires weapons 0 and 1
for 0.5 seconds, then moves, at half-speed, in a direction of 0.5 radians
while firing weapon 0, and then does the same moving in -0.5 radians. 
In the end, it moves straight (0 radians) for 5 seconds, and kills the entity.

Note that DumbScripts can be used by any entity. If a dumbScript is in 
``dumbScripts/script.yaml``, it will be used by an entity if you add the 
following code to it::

   dumbScript: dumbScripts/script.yaml 

Similarly, it can be set in a wave definition in a level.  You can even use
DumbScripts in projectiles. For example, you could use a DumbScript to create
a projectile that moves in a complex fashion and even fires its own weapon.

**See also:** 

:ref:`modding_reference/component_dumbscript`
