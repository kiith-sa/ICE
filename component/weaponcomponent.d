
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Component that provides weaponry to an entity.
module component.weaponcomponent;


import containers.fixedarray;
import util.yaml;


///Component that provides weaponry to an entity.
struct WeaponComponent
{
    /**
     * Stores data about a specific weapon instance.
     *
     * Data about the weapon itself, such as ammo capacity, reload time and
     * burst data, is lazily loaded and stored by WeaponSystem.
     */
    align(4) struct Weapon
    {
        ///Weapon slot taken by the weapon (there are 256 slots).
        ubyte  weaponSlot;
        ///Name of the weapon resource.
        string weaponName;

        ///Ammo used up since last reload.
        uint  ammoConsumed        = 0;
        ///Time remaining before we're reloaded. Zero or negative means we're not reloading.
        double reloadTimeRemaining = 0.0f;
        ///Time since last burst. If greater than the weapon's burstPeriod, we can fire.
        double timeSinceLastBurst  = double.infinity;

        ///Number of shots fired so far in the current burst. uint.max means not in burst.
        uint shotsSoFarThisBurst  = uint.max;

        ///Are we currently in the middle of a burst?
        @property bool burstInProgress() const pure nothrow 
        {
            return shotsSoFarThisBurst != uint.max;
        }
    }

    //Weapons owned by the entity.
    Weapon[] weapons;

    ///Load from a YAML node. Throws YAMLException on error.
    this(ref YAMLNode yaml)
    {
        weapons = new Weapon[yaml.length];
        size_t i = 0;
        foreach(ubyte slot, string weaponName; yaml)
        {
            weapons[i++] = Weapon(slot, weaponName);
        }
    }
}

