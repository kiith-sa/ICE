
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Component that provides weaponry to an entity.
module component.weaponcomponent;


import containers.lazyarray;
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
        ///Index to a lazy array in the weapon system storing weapon data.
        LazyArrayIndex dataIndex;

        ///Ammo used up since last reload.
        uint  ammoConsumed         = 0;
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

        ///Start a burst (called when we're not reloading and done with the previous burst).
        void startBurst() pure nothrow
        {
            shotsSoFarThisBurst = 0;
            timeSinceLastBurst  = 0.0;
        }

        ///End a burst (called when shotsSoFarThisBurst == shots in weapon burst).
        void finishBurst() pure nothrow
        {
            shotsSoFarThisBurst = uint.max;
        }
    }

    //Weapons owned by the entity.
    FixedArray!Weapon weapons;

    ///Load from a YAML node. Throws YAMLException on error.
    this(ref YAMLNode yaml)
    {
        //weapons.length = yaml.length;
        weapons = FixedArray!Weapon(yaml.length);
        size_t i = 0;
        foreach(ubyte slot, string resourceName; yaml)
        {
            weapons[i++] = Weapon(slot, LazyArrayIndex(resourceName));
        }
    }
}
