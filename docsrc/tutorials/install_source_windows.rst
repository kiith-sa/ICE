=================================
Installing from source on Windows
=================================

-----------------------------------
Using DMD (Digital Mars D Compiler)
-----------------------------------


1. Download and install DMD

   Get the newest DMD 2 zip archive from
   `here <http://dlang.org/download.html>`_, and unpack it.

2. Set the ``PATH`` environment variable

   You need to add DMD to the ``PATH`` environment variable so you can use it
   directly. 

   To do this on Windows XP:

   - Right-click *My Computer*
   - Click *Properties*
   - Go to the *Advanced* tab
   - Click the *Environment Variables* button
   - From *System Variables*, select *Path*, and click *Edit*
   - Assuming you unpacked DMD to ``C:\dmd2``, add this to the end of *Variable value*::
  
        ;C:\dmd2\windows\bin

   On Windows 7:

   - Right-click *Computer*
   - Click *Properties*
   - Go to the *Advanced system settings* tab
   - Click the *Environment Variables* button
   - From *System Variables*, select *Path*, and click *Edit*
   - Assuming you installed Python to ``C:\dmd2``, add this to the end of *Variable value*::
   
        ;C:\dmd2\windows\bin
   
3. Get ICE 

   You can download and extract ICE source tarball from its 
   `GitHub page <https://github.com/kiith-sa/ICE>`_.
   
   Or you can download the source repository using git::
   
      git clone git://github.com/kiith-sa/ICE.git

4. Get ICE dependencies

   ICE requires DLLs of SDL, FreeType, SDL-Mixer (and its dependencies) to run 
   on Windows. Download the zip archive from 
   `here <https://github.com/downloads/kiith-sa/ICE/ice_win32_dependencies.zip>`_ 
   and extract it to the folder folder you downloaded ICE source into (this is the
   folder that contains the ``cdc.d`` file).

5. Compile and install ICE

   Launch the command line (``Start -> Run -> cmd`` on both WinXP and Win7 or 
   Powershell on Win7). Move to to the folder where you downloaded ICE source.
   
   First, compile the CDC build script::
   
       dmd cdc.d
   
   Now, you need to compile ICE::
   
       cdc.exe
    
   This will compile a debug build, called ``ice-debug.exe``. A release build 
   can be compiled as well. For more info about ICE build targets, type 
   ``cdc.exe --help``.

   You can now run ICE by clicking the compiled .exe .


