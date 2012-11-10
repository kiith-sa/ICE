
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Component that provides weaponry to an entity.
module component.weaponcomponent;


import std.array;
import std.conv;

import containers.lazyarray;
import containers.fixedarray;
import memory.allocator;
import util.bits;
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
    struct Weapon
    {
        ///Index to a lazy array in the weapon system storing weapon data.
        LazyArrayIndex dataIndex;

        ///Time remaining before we're reloaded. Zero or negative means we're not reloading.
        double reloadTimeRemaining = 0.0f;

        ///Time since last burst. If greater than the weapon's burstPeriod, we can fire.
        double timeSinceLastBurst  = double.infinity;

        ///Ammo used up since last reload.
        uint ammoConsumed          = 0;

        ///Weapon slot taken by the weapon (there are 256 slots).
        ubyte weaponSlot;

        ///Have the weapon's projectile spawns been added to the SpawnerComponent of the Entity?
        bool spawnsAdded = false;

        ///Construct a Weapon in specified slot defined in specified file.
        this(const ubyte weaponSlot, string weaponFileName) pure nothrow
        {
            this.weaponSlot = weaponSlot;
            dataIndex = LazyArrayIndex(weaponFileName);
        }
    }

private:
    ///Weapons owned by the entity.
    struct
    {
        alias FixedArray!(Weapon, BufferSwappingAllocator!(Weapon, 32)) WeaponArray;
        // Used when there is more than one weapon.
        WeaponArray weapons_;
        // Used when there is a single weapon (avoids allocation).
        Weapon singleWeapon_;
    }

    // Do we have more than 1 weapon?
    bool multipleWeapons_;

public:
    ///Weapons whose bursts started this frame.
    Bits!256 burstStarted;

    ///Load from a YAML node. Throws YAMLException on error.
    this(ref YAMLNode yaml)
    {
        const weaponCount = yaml.length;
        if(weaponCount == 1)
        {
            multipleWeapons_ = false;
        }
        else
        {
            multipleWeapons_ = true;
            weapons_ = WeaponArray(yaml.length);
        }
        size_t i = 0;
        foreach(ubyte slot, string resourceName; yaml)
        {
            weapons[i++] = Weapon(slot, resourceName);
        }
    }

    ///Get all weapons used by the entity.
    @property inout(Weapon[]) weapons() inout pure nothrow 
    {
        return multipleWeapons_ ? weapons_[] : (cast(inout(Weapon[]))(&singleWeapon_)[0 .. 1]);
    }

    ///Get a string representation of the WeaponComponent.
    string toString() const
    {
        string[] weaponStrings;
        foreach(w; 0 .. weapons.length)
        {
            weaponStrings ~= to!string(weapons[w]);
        }
        return "WeaponComponent(" ~ weaponStrings.join(", ") ~ ")";
    }
    pragma(msg, "Weapon size: ", Weapon.sizeof);
}
pragma(msg, "WeaponComponent size: ", WeaponComponent.sizeof);
