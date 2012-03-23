===============================
Installing from source on Linux
===============================

-----------------------------------
Using DMD (Digital Mars D Compiler)
-----------------------------------


1. Install DMD dependencies

   DMD depends on ``gcc-multilib``.
   On Debian/Ubuntu, you can install it with::

      sudo apt-get install gcc-multilib


2. Download and install DMD

   Get the newest DMD 2 binary package for your distro from
   `here <http://dlang.org/download.html>`_, and install it.

   
3. Install ICE dependencies

   ICE needs SDL 1.2 and FreeType to run, so install them with your package 
   manager. It's possible that you already have them, as many projects depend 
   on them. On Debian/Ubuntu::
   
      sudo apt-get install libsdl1.2debian libfreetype6


4. Get ICE 

   You can download and extract ICE source tarball from its 
   `GitHub page <https://github.com/kiith-sa/ICE>`_.
   
   Or you can download the source repository using git::
   
      git clone git://github.com/kiith-sa/ICE.git


5. Compile and install ICE

   Move to to the directory where you downloaded ICE source (this is the 
   directory that contains the ``cdc.d`` file).
   
   First, compile the CDC build script::
   
       dmd cdc.d
   
   Now, you need to compile ICE::
   
       ./cdc
    
   This will compile a debug build. A release build can be compiled as well.
   For more info about ICE build targets, type ``./cdc --help``.
   
   Now you can install ICE::
   
       sudo ./install.sh
   
   The release build will be copied to ``/usr/bin/ice.bin`` and a launcher 
   script to ``/usr/bin/ice`` so you can now launch ICE by typing ``ice``
   into the console. Game data files will be copied to ``usr/local/share/ice``.
   ICE will store user settings and similar data in 
   ``/home/YOUR_USER_NAME/.ice``.

