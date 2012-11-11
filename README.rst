====
ICE 
====

------------
Introduction
------------

ICE is a top-down scrolling shooter in tradition of Raptor and Tyrian with 
vector style graphics written in the D programming language.

ICE is in early development and there is no release at this time.

--------
Gameplay
--------

You move your ship around the screen while shooting enemies that attack you.
A basic weapon allows you to shoot forward while, over the course of the 
campaign, you get more weapons that can be used only once in a while,
taking time to recharge (currently, these are always enabled).

^^^^^^^^
Controls
^^^^^^^^

================ ==============================================================
``W``, ``Up``    Move up
``A``, ``Left``  Move left
``S``, ``Down``  Move down
``D``, ``Right`` Move right
``Space``        Fire weapon 1.
``J``            Fire weapon 2.
``K``            Fire weapon 3.
``Scroll-Lock``  Take screenshot (in ``~/.ice/main/screenshots/`` if installed,
                 or ``user_data/main/screenshots/`` in the game directory)
================ ==============================================================


--------------------
Compiling/Installing
--------------------

^^^^^^^^^^^^^^^^^^^
Directory structure
^^^^^^^^^^^^^^^^^^^

================== ============================================================================
Directory          Description
================== ============================================================================
``./``             This README file, utility scripts, source code outside of any packages.
``./data``         Main game data directory, contains data that is never modified.
``./user_data``    User game data directory, contains modifiable data such as screenshots, etc.
``./dependencies`` Source code of libraries ICE depends on.
``./doc``          Documentation.
``./docsrc``       Documentation source code.
``./xxx``          Other directories: ICE source code.
================== ============================================================================

^^^^^^^^^^^^
Requirements
^^^^^^^^^^^^

ICE is written in D2, so it requires a working D2 compiler such as DMD or GDC.
It also depends on Derelict, D:GameVFS and D:YAML, which are included for 
convenience. SDL 1.2, FreeType and OpenGL are required through Derelict.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Compiling/Installing on Linux
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

First, ensure you have all dependencies, as specified above, installed.

ICE uses a D script, ``cdc.d`` for compilation. In order to compile, you first 
have to compile ``cdc.d`` by typing following commands, for dmd an gdc 
respectively::

   dmd cdc.d 

   gdc cdc.d -o cdc 


To compile ICE, use the following command, which will build the debug target.
This should take about a minute with dmd, or a few minutes with gdc::
    
   ./cdc

Alternatively, you can consult ``cdc --help`` for specific build targets - 
you need the release target if you want to install using the install.sh script.

If you don't want to install, you can run ICE from the package's top
level directory by launching ``./ice-debug`` binary or binary of any
other build target.

To install, run following command as root (e.g. by using ``sudo``)::

   ./install.sh

This will copy the release binary to ``/usr/bin/ice.bin`` , and a simple
launcher script to ``/usr/bin/ice``. Main game data will be copied
to ``/usr/local/share/ice`` and ICE will create a ``.ice/`` subdirectory in
your home directory.

-------
License
-------
ICE is released under the terms of the 
`Boost Software License <http://en.wikipedia.org/wiki/Boost_Software_License>`_.
This license allows you to use the source code in your own
projects, open source or proprietary, and to modify it to suit your needs. 
However, you have to preserve the license headers in the source code and the 
accompanying license file. This doesn't apply to binary distributions, 
but it wouldn't hurt you to at least mention what you're using.

Please note that these games are based in part on the work of the LodePNG library.
Any derived works, source code or binary, must preserve lodepng copyright notices,
which can be found in lodepng based files (e.g. ``./png/pngdecoder.d``).

Source distributions and repositiories of DGames also include source code
of the Derelict multimedia D bindings for convenience.
Derelict is also released under the Boost Software License.
Source distributions of any derived works must preserve derelict copyright notices,
which can be found in the ``./dependencies/`` directory.

Full text of the license can be found in file ``LICENSE_1_0.txt`` and is also
displayed here::

   Boost Software License - Version 1.0 - August 17th, 2003

   Permission is hereby granted, free of charge, to any person or organization
   obtaining a copy of the software and accompanying documentation covered by
   this license (the "Software") to use, reproduce, display, distribute,
   execute, and transmit the Software, and to prepare derivative works of the
   Software, and to permit third-parties to whom the Software is furnished to
   do so, all subject to the following:

   The copyright notices in the Software and this entire statement, including
   the above license grant, this restriction and the following disclaimer,
   must be included in all copies of the Software, in whole or in part, and
   all derivative works of the Software, unless such copies or derivative
   works are solely in the form of machine-executable object code generated by
   a source language processor.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
   SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
   FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
   ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
   DEALINGS IN THE SOFTWARE.

---------------
Contact/Credits
---------------

ICE was created by Ferdinand Majerech aka Kiith-Sa kiithsacmp[AT]gmail.com,
Libor Mališ, Dávid Horváth and Tomáš Nguyen.

Parts of code based on the D port of the LodePNG library.
