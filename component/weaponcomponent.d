
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Component that provides weaponry to an entity.
module component.weaponcomponent;


import std.array;
import std.conv;

import component.spawnercomponent;
import containers.lazyarray;
import containers.fixedarray;
import memory.allocator;
import util.bits;
import util.frameprofiler;
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
        alias LazyArrayIndex!(WeaponData) WeaponDataIndex;

        ///Index to a lazy array in the weapon system storing weapon data.
        WeaponDataIndex dataIndex;

        ///Ratio of the time remaining before we're reloaded.
        ///
        ///Zero or negative means we're not reloading. 1 means we've just 
        ///started reloading.
        double reloadTimeRemainingRatio = 0.0f;

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
            dataIndex = WeaponDataIndex(weaponFileName);
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

package:
///Weapon "class", containing data shared by all instances of a weapon.
struct WeaponData
{
    alias SpawnerComponent.Spawn Spawn;

    ///Time period between bursts.
    double burstPeriod;
    ///Number of bursts before we need to reload. 0 means no ammo limit.
    uint ammo         = 0;
    ///Time it takes to reload after running out of ammo.
    double reloadTime = 1.0f;

    ///Spawns to spawn weapon's projectiles, once added to a SpawnerComponent of an Entity.
    FixedArray!Spawn spawns;

    /**
     * Initialize from YAML.
     *
     * Params:  name = Name of the weapon, for debugging.
     *          yaml = YAML node to load from.
     *
     * Returns: true on success, false on failure.
     *
     * Throws:  YAMLException if the weapon could not be loaded (e.g. not enough data).
     */
    void initialize(string name, ref YAMLNode yaml)
    {
        burstPeriod = fromYAML!(double, "a > 0.0")(yaml["burstPeriod"], "burstPeriod");

        //0 means unlimited ammo.
        ammo = yaml.containsKey("ammo") ? yaml["ammo"].as!uint : 0;
        reloadTime = yaml.containsKey("reloadTime")
                   ? fromYAML!(double, "a > 0.0")(yaml["reloadTime"], "reloadTime") 
                   : 0;

        auto burst = yaml["burst"];

        {
            auto zone = Zone("WeaponData spawns allocation");
            spawns = FixedArray!(Spawn)(burst.length);
        }
        uint i = 0;
        foreach(ref YAMLNode shot; burst)
        {
            spawns[i] = loadProjectileSpawn(shot);
            ++i;
        }
    }

    /**
     * Specialized function to load a projectile spawn from YAML.
     *
     * The major difference is that accelerateForward is set to true.
     *
     * There is also code to support legacy projectile syntax. This will be removed.
     *
     * Params:  yaml = YAML node to load fromYAML
     */
    static Spawn loadProjectileSpawn(ref YAMLNode yaml)
    {
        auto result = Spawn(yaml);
        with(result)
        {
            accelerateForward = true;
        }

        return result;
    }
}

