.. _modding_reference/component_visual:

================
Visual component
================

A visual component determines how an entity is displayed. Without a visual
component, an entity is invisible.

A visual component is specified by filename of a separate visual component
file.  Visual data is quite complex so it would be unwieldy to specify it
directly.

Example::

   visual: visual/visualfile.yaml

All graphics data is in this file. Currently, a visual component can only be
drawn as a series of lines with varying widths (per-line) and colors
(per-vertex).

Example visual component file::

   type: lines
   vertices:
     !!pairs
   
     #Main
     - width: 0.5
     - color:  rgbaFFFFFF40
     - vertex: [-32.0, 16.0]
     - color:  rgbaFFFFFF90
     - vertex: [0.0, -16.0]
     - vertex: [0.0, -16.0]
     - color:  rgbaFFFFFF40
     - vertex: [32.0, 16.0]

     #Halo
     - width: 1.8
     - color:  rgba8080FF50
     - vertex: [-32.0, 16.0]
     - color:  rgbaB0B0FF60
     - vertex: [0.0, -16.0]
   
     - vertex: [0.0, -16.0]
     - color:  rgba8080FF50
     - vertex: [32.0, 16.0]
   

This draws a simple arrow shape. The main shape is made of 2 lines fading from
a very transparent white to more opague white and back.

Two more lines form a wider, more transparent "halo" aroud the shape.


--------------
Top-level tags
--------------

======== =====================================================================
type     Type of graphics data. Currently, only ``lines`` is supported.
vertices Vertices specifying lines. Lines are drawn between pairs of vertices:
         first and second is one line, third and fourth is another, and so on.
         There **must** be an even number of vertices.
         Vertex color and line width can be chaged between vertices.
         Value of this tag must be of the ``pairs`` type.
======== =====================================================================


--------------------
Tags in ``vertices``
--------------------

====== ========================================================================
vertex Vertex of a line. *Sequence of 2 floats*.
width  Width of following *lines*. Applied per line (vertex pair), not per 
       vertex. *Float*. There is no width limit but widths lower than 1 
       might not get draw precisely due to aliasing. Default: ``1``.
color  Color of following *vertices*. Colors are interpolated between vertices,
       so a line can e.g. fade from black to white. *RGB or RGBA color*. 
       Default: ``rgbaFFFFFFFF`` (fully opague white).
====== ========================================================================
