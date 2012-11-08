.. _modding_reference/level:

=====
Level
=====

ICE levels are YAML files specifying things like what entities are spawned
when, background effects, and so on. Currently a level consists of any number
of *wave definitions* and a *level script*. A wave definition describes a group
of entities that are spawned together. The level script determines when these
waves appear, and other things such as background effects.


---------------
Wave definition
---------------

A wave is really just an entity that uses its
:ref:`modding_reference/component_spawner` to spawn entities. A wave definition
starts by a "header" in format ``wave waveName:`` where waveName is name of the
wave. The wave then defines a spawner component, which works exactly the same
as in an entity. As wave is an entity, other components could be defined
as well if needed.

The spawner component can spawn entities with a delay and override their
components.  The most commonly overridden components are the physics component
to set position of the spawned entity, and dumbscript component to set entity
behavior.  However, any other components can be overridden as well, e.g.
weapons, health and so on.  For detauls, see
:ref:`modding_reference/component_spawner` documentation.


Example::

   wave turtlePawn:
     spawner:
       - entity: ships/turtle.yaml 
         components:
           physics: 
               position: [380, 0]
           dumbScript: dumbscripts/pawnLeft.yaml
       - entity: ships/turtle.yaml
         components:
           physics: 
               position: [420, 0]
           dumbScript: dumbscripts/pawnRight.yaml

This wave is called ``turtlePawn``. It will spawn two ``ships/turtle.yaml``
entities at positions ``[380, 0]`` and ``[420, 0]``. The first entity will use
the ``dumbscripts/pawnLeft.yaml`` dumbscript, the second
``dumbscripts/pawnRight.yaml``.


------------
Level script
------------

The level script is a YAML sequence of events that will occur during the 
course of the level. Like dumbscript, there is no contol flow; just a
series of instructions to execute.

Example::

   level:
     !!pairs
     - effect text:
         text: 42
         font: default 
         fontSize: 512
         color: rgbaFF000001
         time: 1.0
     - effect lines:
         minWidth: 0.225
         maxWidth: 0.9
         minLength: 3.0
         maxLength: 12.0
         verticalScrollingSpeed: 225.0
         linesPerPixel: 0.0015
         detailLevel: 6
         color: rgbaD0D0FF24
     - wait: 1.0
     - wave: turtlePawn
     - wait: 0.3
     - wave: turtlePawn
     - wait: 0.3
     - wave: turtlePawn
     - wait: 3
     - wave: turtlePawn
     - wait: 0.3
     - wave: turtlePawn
     - wait: 0.3
     - wave: turtlePawn
     - wait: 5
     - wave: [turtlePawn, [100.0,  0]]
     - wait: 0.3
     - wave: [turtlePawn, [200.0,  -20]]
     - wait: 0.3
     - wave: [turtlePawn, [300.0,  -40]]
     - wait: 3
     - wave: [turtlePawn, [-100.0,  0]]
     - wait: 0.3
     - wave: [turtlePawn, [-200.0,  -20]]
     - wait: 0.3
     - wave: [turtlePawn, [-300.0,  -40]]
     - wait: 4.0

This level starts with a barely visible ``text`` effect showing a large "42" in
the center of the screen for one second. It also uses a ``lines`` effect which
generates small scrolling lines, giving the impression of a starfield.

1 second after the level starts, a ``turtlePawn`` wave (defined above) is
spawned. More ``turtlePawn`` waves are spawned in 0.3 second intervals, with
a 3 second pause between the first three and the other three.

This is followed by a 5 second pause. After the pause, more ``turtlePawn``
waves are spawned, but this time with offsets altering positions of the spawned
units.  (This actually changes the position of the wave entity, which would be
``[0, 0]`` otherwise, and as entities are spawned relative to their spawner by
default, this changes their positions as well).


-------------------------
Level script instructions
-------------------------

======== =======================================================================
effect X Display specified type of effect. The effect itself is a mapping 
         describing parameters of the effect. X can be either ``text`` (show 
         text centered in the screen) or ``lines`` (generate random lines on 
         the background, useful for e.g. a starfield effect). Effect parameters
         are further described in tables below.
wave     Launch a wave, spawning its units. This spawns the wave entity.
         This instruction can be in one of multiple formats. These are described
         further below.
wait     Wait for specified time in seconds. *Float*.
text     Display specified text for 3 seconds. *String*.
         **This should not be used - it is deprecated and will be replaced.**
======== =======================================================================

------------------------
Wave instruction formats
------------------------

Launch the ``waveName`` wave at ``[0, 0]``::

  - wave: waveName

Launch the ``waveName`` wave at ``[X, Y]``::

  - wave: [waveName [X, Y]]

Launch the ``waveName`` wave, overriding wave entity components. This allows e.g.
to change components of the wave entity - for example giving it a visual 
component or allowing it to move while spawning::

  - wave:
      wave: waveName
      components:
        physics:
          position: [100, 300]

----------------
Text effect tags
----------------

======== =======================================================================
text     Text to display. This must be specified; there is no default. *String*.
font     Font to use (must be in a ``fonts`` subdirectory of a mod directory).
         ``default`` means the default font. *String*. Default: ``default``.
fontSize Size of the font. *Int*. Default: ``28``.
color    Color of the text. *RGB or RGBA color*. Default: ``rgbaFFFFFFFF``.
time     Time to show the text for in seconds. ``0`` means infinite. *Float*.
         Default: ``0``
======== =======================================================================

-----------------
Lines effect tags
-----------------

====================== =========================================================
lineDirection          Direction of generated lines. Allows to generate rotated
                       lines (but still moving in vertical direction). *Float*.
                       Default: ``0.0`` (``0deg``).
minWidth               Minimum width of a generated line. *Float*.
                       Default: ``1.0``
maxWidth               Maximum width of a generated line. *Float*.
                       Default: ``2.0``
minLength              Minimum length of a generated line. *Float*.
                       Default: ``1.0``
maxLength              Maximum length of a generated line. *Float*.
                       Default: ``10.0``
linesPerPixel          How many lines to generate per pixel by default.
                       "Pixel" might not correspond to a pixel on screen - 
                       it is a square 1 unit wide and  1 unit tall where the 
                       screen is always 800x600 units, regardless of the actual 
                       resolution. *Float*. Default: ``0.001``.
verticalScrollingSpeed Speed of vertical line movement in units per second. 
                       (there is no horizontal movement). *Float*.
                       Default: ``250.0``.
detailLevel            Effect detail level. Lower values will result in smoother
                       line movement but higher CPU/memory usage. ``0`` is
                       "full" detail. *Int*. Default: ``3``.
color                  Color of the lines.
time                   Time to show the effect for in seconds. ``0`` means 
                       infinite. *Float*. Default: ``0``.
====================== =========================================================
