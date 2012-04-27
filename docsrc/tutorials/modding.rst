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

ICE has a modular directory system to allow for pluggable mods in future, 
howevever, this feature is not used at the moment.

For now, there is only one "mod" - ICE itself. This mod can be found in the
``data/main`` directory. These are main game data - they are not supposed to be
changed after installation. Any file in ``data/main`` can be overridden by a 
file in ``user_data/main`` with the same filename.

Note that ``user_data/main`` translates to ``~/.ice/main`` after installation on
Linux and similar systems.

---------------
Creating a ship
---------------

Ships are stored in the ``ships`` subdirectory of a mod directory. For the main 
game, that is ``data/main/ships``. Note that this is a convention - ships could
be stored elsewhere if needed.

In terms of ICE, a ship is an *entity* - a collection of *components* that 
specify properties to the ship. For example, a ship might have a *visual* 
component - which describes how it is drawn on screen.

To create your own ship, you can create a file with the contents of the 
following example in the ``ships`` directory.

Alternatively, you can try copying and modifying any ship that already exists
there.

Example ship::

   visual: visual/player.yaml
   engine:
     maxSpeed: 300
     acceleration: 2100  #-1 is instant
   volume:
     aabbox: 
       min: [-32, -32]
       max: [32,  0]
   weapon:
     0: weapons/default.yaml
   collidable:
   health: 500
   warhead:
     damage: 10
     killsEntity: false

Each entry in the ship code describes a component and the properties of that 
component. This ship has the following components:

* A *visual* component, pointing to the graphics file for the ship.
* An *engine* component that can move the ship at most 300 units per second and
  accelerate at 2100 units per second per second.
* A *volume* used for collision detection (for example with projectiles). 
  This volume is an *aabbox* - axis-aligned-bounding-box, or a rectangle that does 
  not rotate.
* A *weapon* component with one weapon at slot *0*. There are multiple (256) 
  weapon slots to allow a ship to have more than one weapon.
* A *collidable* component that s just that - it allows the ship to receive 
  collisions. Most projectiles, for example, have a volume but are not 
  collidable - they can't collide with each other, only with the *collidable*
  ships.
* A *health* component with 500 maximum health. Entities with a health component 
  die when they run out of health.
* A *warhead* component that causes 10 damage and doesn't kill the ship itself.
  Warheads are fired at collision with another entity. This means our ship 
  causes damage to other ships it collides with and doesn't immediately get 
  destroyed. Most projectiles, for example, are destroyed as soon as they 
  collide with something.

.. TODO add this after writing a component reference.
.. There are other components a ship can have. You can see the Component reference
.. for more detailed information.

Importantly, a ship needs other resources - In this example, a visual component
and any weapons it may use. Those are explained below.


------------------------------------
Creating graphics (visual component)
------------------------------------

Currently the only graphics format supported by ICE is a simple YAML based 
vector format that only supports straight lines, with variable colors and line 
widths.

Graphics are specified by *visual components*, defined in YAML files in the
``visual`` subdirectory of a mod directory.

To create your own visual component, you can create a file with the contents of 
the following example in the ``visual`` directory.

Alternatively, you can try copying and modifying any visual component that 
already exists there.

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
   
This visual component is an array of *lines*, which is currently the only 
supported visual component *type*.

Lines are specified by *vertices*, a sequence of pairs that can either specify
line *width*, vertex *color* and *vertex* itself.

Lines are formed by the 1st and 2nd vertex, the 3rd and 4rd, and so on.
The number of vertices must be divisible by 2.

A *color* or *width* entry affects all vertices drawn after it, until the next 
*color* or *width* entry. Default color is white and default width is 1.

Note that *width* affects only whole lines, while *color* can change colors of
each vertex (which blend in the line, so you can e.g. have a line that blends
from a red end to a blue end).


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

Alternatively, you can try copying and modifying any weapon that already exists
there.

Example weapon::

   burstPeriod: 0.06
   ammo: 2
   reloadTime: 0.2
   burst:
     - projectile: projectiles/defaultbullet.yaml 
       delay: 0.02
       position: [8.0, 8.0]
       direction: -0.1
     - projectile: projectiles/defaultbullet.yaml 
       delay: 0.0
       position: [0.0, -8.0] 
       direction: 0.0
       speed: 50.0
     - projectile: projectiles/defaultbullet.yaml 
       delay: 0.0
       position: [0.0, -8.0] 
       direction: 0.0
       speed: 50.0
     - projectile: projectiles/defaultbullet.yaml 
       delay: 0.02
       position: [-8.0, 8.0] 
       direction: 0.1

This weapon can fire 2 bursts, each taking 0.06 seconds, before reloading for 
0.2 seconds. Each burst consists of 4 projectiles shot at different positions
(relative to the ship) in different directions (in radians, relative to the 
ship).

Two of the projectiles are fired immediately, the other two 0.02 seconds
later. The projectiles fired immediately are fired at speed 50 and use their 
engine component (defined in the projectile) to accelerate to full speed.
If speed is not specified, the projectiles are fired at their maximum speed.

Note that each projectile in the burst specifies its own projectile file. One
burst can consist of projectiles of multiple types. Each projectile is an 
entity, just like a ship (in the engine, there is no difference between 
projectiles and ships).

---------------------
Creating a projectile
---------------------

Projectiles are found in the ``projectiles`` subdirectory of the mod directory.

Internally, there is no difference between a projectile and a ship - both are 
component based entities. Any component that can be used in a ship can be used 
in a projectile, and vice versa.

To create a new projectile, you can create a file with the contents of the 
following example in the ``projectiles`` directory.

Alternatively, you can try copying and modifying any projectile that already 
exists there.

Example projectile::

   deathTimeout: 1.1
   engine : 
     maxSpeed       : 2000
     acceleration   : 1000  #-1 is instant
   volume:
     aabbox:
       min: [-2, -12]
       max: [2,  0]
   visual:   visual/defaultbullet.yaml
   warhead:
     damage: 10

Most components of this projectile are the same as components used in a ship.

The main differences are: 

* *deathTimeout* component, which destroys the projectile 1.1 seconds after it's
  fired. It is important that projectiles that don't collide with anything have 
  a limited lifetime so they don't stay in memory forever.
* There is no *collidable* component. This means the projectiles can't collide 
  with other projectiles - only with collidable ships.
* The warhead has no ``killsEntity: false``, so the projectile is "killed" 
  after it hits its target.

Also, the projectile has no health or weapon. However, it could have health or
weapon, or any other component a ship can have. (For example, a collidable 
projectile with limited health could be a missile that can be shot down).


----------------
Creating a level
----------------

Levels are described in YAML files found in the ``levels`` subdirectory of a mod
directory.

Currently, there's only 1 level file, which the game is hardcoded to load: 
``level1.yaml``. This should be used for level development for now.

A level is composed of definitions of "waves" (groups of enemies
spawned simultaneously) and of a level script, which specifies when to 
spawn a wave.

Example::

   wave wave1:
     spawn:
       - unit: ships/enemy1.yaml
         physics: 
             position: [360, 32]
             rotation: 0
       - unit: ships/playership.yaml
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

There can be any number of wave definitions, but two waves must not have 
identical names.

Currently, the wave definition has one section, *spawn*, which is a 
sequence of units (entities) to be spawned. 

Each unit is a mapping with one required key, *unit*, which specifies filename
of the unit to spawn. The unit might contain more keys, which define components
to override components loaded from the unit definition. 

In this example, the first unit has its physics component overridden, spawning 
it at a particular position, and the second also overrides the *dumbScript*
component (explained below), specifying behavior of the spawned unit.

^^^^^^^^^^^^
Level script
^^^^^^^^^^^^

The level script starts with a mapping key named ``level``, and is composed of
pairs of instructions and their parameters. 

This level is very simple. First, we start a "lines" effect that draws a
scrolling starfield background composed of randomly generated lines.
After 2 seconds, we spawn a single wave and later we display some text.
Once the script is done, the level ends (the player wins the level).
The player loses if their ship gets destroyed before the level is over.


---------------------
Creating a DumbScript
---------------------

Normally when you spawn a unit, it just sits there and doesn't do anything.

Behavior of an entity can be controlled by a *dumbScript* component, which
can be set in the entity YAML file or in a wave definition in a level.

DumbScript is a simple YAML based script that specifies actions the unit 
should take. It's called DumbScript because there is no flow control - it just
dumbly executes instructions one after another. In future, there might be 
smarter scripts based on a real programming language, e.g. Lua.

DumbScripts are located in the ``dumbScripts`` subdirectory of a mod directory.

To create a new dumb script, you can create a file with the contents of the 
following example in the ``dumbScripts`` directory.

Alternatively, you can try copying and modifying any projectile that already 
exists there.

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

Similarly, it can be set in a wave definition in a level.
You can even use DumbScripts in projectiles. For example, you could use a 
DumbScript to create a projectile that fires more projectiles (or one that 
splits into multiple smaller projectiles).
