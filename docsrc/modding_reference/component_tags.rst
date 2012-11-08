.. _modding_reference/component_tags:

==============
Tags component
==============

A tags component attaches any number of 4 character tags to an entity.
Currently, tags are used to identify special entities such as the player ship.
There might be more uses for them in future. Builtin ICE tags always start with
an undescore, e.g. the player ship tag, ``_PLR``. In future, when/if tags are
more general purpose, any custom tags used by mods should not start with
underscores.

The tags component is defined as a sequence of tag strings. These strings must
be **at most** 4 characters long.

Example::

   tags: [_PLR]

An entity with this tags component has the ``_PLR`` tag, which is a builtin tag
used to identify the player ship.
