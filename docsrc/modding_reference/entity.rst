.. _modding_reference/entity:

======
Entity
======

In ICE, there is no distinction between game objects of different types; i.e.
there's no "ship" or "projectile" object type. Instead, every object consists
of various *components* which can be combined to create different kinds of
objects. Game objects in ICE are called *entities*. An entity might be a ship,
a static obstacle, a projectile, an explosion fragment or something else; the
combination of components determines behavior and attributes of the entity.

Entities are defined in YAML files. An entity definition is a mapping of
component names and their contents. All entity data is in components; even data
such as the position (``physics``) or graphics (``visual``). Each component
type is optional. Under the hood, some components might cause different
components to be added; E.g. a weapon component adds a spawner component if
it's not already in the entity definition.


Example (a ship entity)::

   visual: visual/turtle.yaml
   engine:
     maxSpeed: 350
     acceleration: 5000  
   volume:
     aabbox: 
       min: [-4, 0]
       max: [4, 12]
   weapon:
     0: weapons/lightPlasma.yaml
   collidable:
   health: 15
   warhead:
     damage: 10
     killsEntity: true
   dumbScript: dumbscripts/zigzag.yaml
   score:
     exp: 30
   spawner:
     - entity: explosions/deathBase.yaml 
       condition: death
       components:
         visual: visual/turtle.yaml
         physics: 
           position: [0, 0]
     - entity: explosions/spiralSmall.yaml
       condition: death 
       components:
         physics: 
           position: [0, 0]
           rotation: 0.0

This entity has a number of components:

* :ref:`modding_reference/component_visual` specifying its graphics
* :ref:`modding_reference/component_engine` allowing the entity to move.
* :ref:`modding_reference/component_volume` used in collision detection.
* :ref:`modding_reference/component_weapon` with one weapon.
* :ref:`modding_reference/component_collidable` to use the entity in collision
  detection. Even if two entities have a *volume*, at least one of them must
  be *collidable* in order for a collision to happen.
* :ref:`modding_reference/component_health` giving the entity 15 health,
  allowing it to be killed.
* :ref:`modding_reference/component_warhead` causing damage to other entities
  at collision.
* :ref:`modding_reference/component_dumbscript` describing default behavior of
  the entity (usually overridden in levels).
* :ref:`modding_reference/component_score` to increase player score by 30 when
  they kill the entity.
* :ref:`modding_reference/component_spawner` spawning entities used in an
  explosion effect when the entity dies.

This is only a small subset of components in ICE. Other components might be
useful for entities representing different concepts (e.g. projectiles) or to
create ships with different abilities. Various combinations of components can
lead to interesting, sometimes unexpected results; experimenting might pay off.
In-depth documentation of each component type can be found in the modding
reference.
