====
ICE 
====

------------
Introduction
------------

ICE is a vertical shoot-em-up in tradition of Raptor and Tyrian with vector
style graphics written in the D programming language.

ICE is still in very early development and might see large changes.

--------
Gameplay
--------

You move your ship around the screen, shooting attacking enemies.  A basic
weapon allows you to shoot forward while, over the course of the campaign, you
get more weapons that can be used only once in a while, taking time to recharge
(currently, these are always enabled; the gradual ship improvements are not yet
implemented).

Each weapon is designed to require a bit of skill and timing as opposed to just
being a bigger, more powerful gun.

^^^^^^^^
Controls
^^^^^^^^

======================= =======================================================
``W``,     ``Up``       Move up
``A``,     ``Left``     Move left
``S``,     ``Down``     Move down
``D``,     ``Right``    Move right
``Space``, ``NumPad 5`` Fire weapon 1.
``J``,     ``NumPad 4`` Fire weapon 2.
``K``,     ``NumPad 2`` Fire weapon 3.
``Scroll Lock``         Take screenshot (in ``~/.ice/main/screenshots/`` if
                        installed, or ``user_data/main/screenshots/`` in the
                        game directory)
``Escape``              Exit the game while playing.
======================= =======================================================


------------------------
Download current version
------------------------

Downloads of the current version (Windows, Linux, source) can be found
found `here <http://icegame.nfshost.com/pages/downloads.html>`_.


---------------------------------
Compiling, installing from source
---------------------------------

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
Dependencies
^^^^^^^^^^^^

ICE is written in D, so for compilation it requires a D compiler such as DMD.
Currently, only DMD is supported; GDC will be supported once it becomes a part
of GCC. Due to linker problems, only DMD 2.058 works on Windows; this should
change in future.

ICE depends on Derelict, D:GameVFS and D:YAML, which are included for
convenience. SDL 1.2, SDL-Mixer, FreeType and OpenGL are required through
Derelict.

^^^^^^^^^^
Installing
^^^^^^^^^^

`From source code on Linux <https://github.com/kiith-sa/ICE/blob/master/docsrc/tutorials/install_source_linux.rst>`_
`From source code on Windows <https://github.com/kiith-sa/ICE/blob/master/docsrc/tutorials/install_source_windows.rst>`_

Installing tutorials can also be found in the `doc/html/tutorials` directory.

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

Main menu music by `Osmic <http://opengameart.org/users/osmic>`_.
Level music by `Alexandr Zhelanov <http://opengameart.org/users/alexandr-zhelanov>`_ 
and `FoxSynergy <http://opengameart.org/users/foxsynergy>`_.

Parts of code based on the D port of the LodePNG library.
