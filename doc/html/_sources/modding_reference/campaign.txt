.. _modding_reference/campaign:

========
Campaign
========

ICE gameplay is based on singleplayer campaigns. A campaign is nothing more
than a linear sequence of levels. In future, there might be branching
campaigns, but it's not an immediate priority. ICE supports any number of
campaigns. At launch, ICE looks in the ``campaigns`` subdirectory of mounted
mod directories, and attempts to load every YAML file there as a campaign.
This is different from levels or entities; while those can be stored in any
directory, the campaigns directory is hardcoded.

Example::

   name: ICE demo
   levels:
     - levels/level1.yaml 
     - levels/level2.yaml
     - levels/level3.yaml
     - levels/level4.yaml
   credits:
     ICE demo campaign:
       - name: Dávid Horváth
       - name: Libor Mališ
       - name: Tomáš Nguyen

This campaign is called ``ICE demo`` in game, and it is 4 levels long,
specifying filename of each level. It also specifies one credits section,
``ICE demo campaign``, with names of authors of the campaign. This credits
section is displayed with game credits when the player clears the campaign.


----
Tags
----

======= ========================================================================
name    Name of the campaign displayed on the campaign selection screen.
        Also used by player profiles to track campaign progress; renaming the 
        campaign will result in players losing progress. *String*. There is no
        default; this must be specified.
levels  File names of levels in the campaign, in order they are played.
        *Sequence of strings*. There is no default; this must be specified.
credits One or more credits sections. These will be displayed when the player 
        clears the campaign. *Mapping of credits section names and contents*.
        There is no default; this must be specified.
======= ========================================================================

---------------
Credits section
---------------

A credits section is a mapping where keys are credits section headers (e.g.
*Graphics* or *Programming*), and values are sequences of author credits. Each
credit is a mapping, usually only specifying name of the person credited, but
more data can be specified, as described below.

-----------
Credit tags
-----------

==== ===========================================================================
name Name of the person credited.
link A link to the website, gallery, etc. of the credited person. Useful when
     an author of work under the CC-BY license when wants to be credited with a
     link to their work.
==== ===========================================================================


**See also:** 

:ref:`modding_reference/level`
