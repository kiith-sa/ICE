
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Keeps track of spatial relations between objects with volumes.
module component.spatialsystem;


import std.algorithm;
import std.container;

import containers.array2d;
import containers.vector;
import math.math;
import math.rect;
import math.vector2;
import util.unittests;

import component.entitysystem;
import component.physicscomponent;
import component.system;
import component.volumecomponent;


/**
 * Keeps track of spatial relations between objects with volumes.
 *
 * Implemented as a simple grid that keeps track of which entities are in 
 * which cells.
 */
class SpatialSystem : System 
{
    private:
        ///Represents an entity in the spatial grid.
        struct SpatialEntity
        {
            ///Pointer to the entity.
            Entity* entity;
            ///Physics component of the entity. This is only valid for one update.
            PhysicsComponent* physics;
            ///Spatial volume of the entity. This is only valid for one update.
            VolumeComponent*  volume;
        }

        ///Entity system whose data we're processing.
        EntitySystem entitySystem_;

        alias Vector!SpatialEntity Cell;
        ///Cells of the spatial grid. This is rebuilt every frame.
        Array2D!Cell grid_;

        ///Cell representing the area outside the grid.
        Cell outer_;

        ///Size of a single cell (both x and y).
        const float cellSize_;

        /**
         * Size of the grid in cells (both x and y). 
         *
         * Must be <= 254 because max x and y coords in CellsAABBox are 
         * the actual max coord + 1.
         */
        const ubyte gridSize_;

        ///Origin of the grid (top-left corner) in world space.
        const Vector2f origin_;

        ///Used as a temporary buffer by neighbors iteration to check for duplicate neighbors.
        Vector!(Entity*) tempEntities_;

    public:
        /**
         * Construct a SpatialSystem.
         *
         * Params:  entitySystem = EntitySystem whose entities we're processing.
         *          center       = Center of the grid in world space.
         *          cellSize     = Size of a single cell of the grid (both x and y).
         *          gridSize     = Size of the grid in cells (both x and y).
         *                         Must be > 0 and <= 254 (yes, 254, not 255).
         */
        this(EntitySystem entitySystem, 
             const Vector2f center, const float cellSize, const ubyte gridSize)
        in
        {
            assert(cellSize > 0,
                   "Can't construct a SpatialSystem with a negative or zero cell size");
            assert(gridSize > 0 && gridSize < 255,
                   "Can't construct a SpatialSystem with a grid size of 0 or 255");
        }
        body
        {
            entitySystem_ = entitySystem;

            cellSize_ = cellSize;
            gridSize_ = gridSize;

            const halfSize_ = cellSize_ * gridSize_ * 0.5;
            origin_ = center - Vector2f(halfSize_, halfSize_);

            grid_ = Array2D!Cell(gridSize_, gridSize_);

            tempEntities_.reserve(256);
            foreach(ref cell; grid_)
            {
                cell.reserve(512);
            }
            outer_.reserve(1024);
        }

        ///Destroy the SpatialSystem, freeing all used memory.
        ~this()
        {
            //Grid, outer, tempEntities_ get destryed implicitly.
        }

        ///Determine spatial relations between entities.
        void update()
        {
            //Clear spatial data from the previous update.
            clear();

            static t = 0;
            foreach(ref Entity e,
                    ref PhysicsComponent physics,
                    ref VolumeComponent volume; 
                    entitySystem_)
            {
                //No preserving of spatial items between frames
                //For now, should be good enough to just zero all the cells 
                //and readd everything every frame.

                //Note that if we change this, we won't be able to store 
                //pointers to volume components in Cells - as volume components
                //maybe moved around in memory between frames.
                final switch(volume.type)
                {
                    case VolumeComponent.Type.AABBox:
                        foreach(x, y, ref cell; cells(physics.position, volume.aabbox))
                        {
                            cell ~= SpatialEntity(&e, &physics, &volume);
                        }
                        break;
                    case VolumeComponent.Type.Uninitialized:
                        assert(false, 
                               "Uninitialized VolumeComponent during SpatialSystem update");
                }
            }
        }

        /*
         * If this is too inefficient, users will have to iterate over cells 
         * and entities within instead of getting neihgbors of each entity.
         */

        /**
         * Iterate over all neighbors of entity with specified physics and volume component.
         *
         * This iterates over a ref Entity, ref PhysicsComponent and ref VolumeComponent.
         *
         * Note that if physics and volume belong to an entity, that entity will
         * be iterated as well.
         *
         * Examples:
         * --------------------
         * //spatial is our SpatialSystem
         * //ourPhysics is our PhysicsComponent
         * //ourVolume is our VolumeComponent
         * 
         * foreach(ref Entity entity, 
         *         ref PhysicsComponent physics,
         *         ref VolumeComponent volume;
         *         spatial.neighbors(ourPhysics, ourVolume))   
         * {
         *     //do stuff
         * }
         * --------------------
         */
        final auto neighbors(ref PhysicsComponent physics, ref VolumeComponent volume)
        {
            struct Foreach
            {
                @disable this(this);
                @disable void opAssign(ref Foreach);

                private:
                    union 
                    {
                        ///Cells within an AABBox.
                        CellsAABBox cellsAABBox_;
                    }
                    ///Type of the volume whose neighbors we're iterating.
                    VolumeComponent.Type type_;

                public:
                    ///Construct from CellsAABBox.
                    this(CellsAABBox cells)
                    {
                        cellsAABBox_ = cells;
                        type_ = VolumeComponent.Type.AABBox;
                    }

                    ///Foreach over neighbors.
                    int opApply(int delegate(ref Entity, ref PhysicsComponent, ref VolumeComponent) dg)
                    {
                        //Foreach result.
                        int result = 0;

                        with(cellsAABBox_) final switch(type_)
                        {
                            case VolumeComponent.Type.AABBox:
                                const bool oneCell = 1 == (cellXMax_ - cellXMin_) * (cellYMax_ - cellYMin_);

                                //Used to ensure we never iterate over the same neighbor twice.
                                //If too much overhead, we might have to remove 
                                //that guarantee.

                                //Vector has a bad complexity here (O(n^^2)), but is 
                                //faster than RBTree due to no GC usage.
                                //Binary heap in an array might be even better.
                                //static Vector!(Entity*) iterated;

                                auto iterated = &(spatial_.tempEntities_);
                                scope(exit) if(!oneCell) {iterated.length = 0;}

                                //Iterate over cells in the AABBox.
                                foreach(x, y, ref cell; cellsAABBox_) 
                                {
                                    //Iterate over entities in the cell.
                                    foreach(ref e; cell[])
                                    {
                                        //Only iterate over an entity once.
                                        if(!oneCell && (*iterated)[].canFind(e.entity)){continue;}
                                        result = dg(*e.entity, *e.physics, *e.volume);
                                        if(result){return result;}
                                        if(!oneCell){(*iterated) ~= e.entity;}
                                    }
                                }
                                break;
                            case VolumeComponent.Type.Uninitialized:
                                assert(false, 
                                       "Iterating over neighbors of an uninitialized VolumeComponent");
                        }
                        return result;
                    }
            }
            static assert(Foreach.sizeof <= 16);

            //So, even for any entity with volume that is in one cell only, we do this:
            //* Return a 16-byte struct.
            //* Call opApply on it.
            //* Call opApply on the internal Cells struct.
            //* For the one cell within, call opApply over SpatialEntity[].
            //
            //This is kinda heavyweight, but fast enough for now.
            //If benchmarks prove otherwise, we might need to change this.
            final switch(volume.type)
            {
                case VolumeComponent.Type.AABBox:
                    return Foreach(cells(physics.position, volume.aabbox));
                case VolumeComponent.Type.Uninitialized:
                    assert(false, 
                           "Trying to get neighbors of an uninitialized VolumeComponent");
            }
        }

    private:
        ///Clear spatial data. Called on each update.
        void clear() 
        {
            foreach(ref cell; grid_){cell.length = 0;}
            outer_.length = 0;
        }

        ///Struct that iterates over all cells intersecting with an AABBox.
        align(2) struct CellsAABBox
        {
            ///Spatial system we're iterating over.
            SpatialSystem spatial_;

            ///Minimum X cell to iterate.
            ubyte cellXMin_ = 0;
            ///Maximum X cell to iterate + 1.
            ubyte cellXMax_ = 0;
            ///Minimum Y cell to iterate.
            ubyte cellYMin_ = 0;
            ///Maximum Y cell to iterate + 1.
            ubyte cellYMax_ = 0;
            ///Iterate outer cell?
            bool outer_ = false;

            this(SpatialSystem spatial, ref const Rectf aabbox) 
            {
                spatial_ = spatial;

                const mult = 1.0 / spatial_.cellSize_;
                const gridSize   = spatial_.gridSize_;

                //Get minimum and maximum cells containing the rectangle.
                const xMin = floor!int(aabbox.min.x * mult);
                const xMax = floor!int(aabbox.max.x * mult);
                const yMin = floor!int(aabbox.min.y * mult);
                const yMax = floor!int(aabbox.max.y * mult);

                //Everything is within the grid.
                if(xMin >= 0 &&
                   yMin >= 0 &&
                   xMax < gridSize &&
                   yMax < gridSize)
                {
                    cellXMin_ = cast(ubyte)xMin;
                    cellXMax_ = cast(ubyte)(xMax + 1);
                    cellYMin_ = cast(ubyte)yMin;
                    cellYMax_ = cast(ubyte)(yMax + 1);
                    return;
                }

                //If outside the grid, iterate over outer.
                outer_ = true;

                //Completely outside the grid, so we're done.
                if(xMax < 0 || 
                   yMax < 0 ||
                   xMin >= gridSize ||
                   yMin >= gridSize)
                {
                    return;
                }

                cellXMin_ = cast(ubyte)max(0, xMin);
                cellXMax_ = cast(ubyte)(min(xMax, gridSize - 1) + 1);
                cellYMin_ = cast(ubyte)max(0, yMin);
                cellYMax_ = cast(ubyte)(min(yMax, gridSize - 1) + 1);
            }

            int opApply(int delegate(int x, int y, ref Cell) dg)
            {
                int result;
                if(outer_)
                {
                    result = dg(-1, -1, spatial_.outer_);
                    if(result){return result;}
                }
                //Iterate over all the cells that contain the rectangle.
                foreach(x; cellXMin_ .. cellXMax_) 
                {
                    foreach(y; cellYMin_ .. cellYMax_) 
                    {
                        result = dg(x, y, spatial_.grid_[x, y]);
                        if(result){break;}
                    }
                }
                return result;
            }
        }

        /**
         * Iterate over all cells that intersect with aabbox at specified position.
         *
         * Iterates over int (x coordinate), int (y coordinate) and ref Cell (celly coordinate) and ref Cell (cell).
         */
        auto cells(const Vector2f position, ref const Rectf aabbox)
        {
            //Translate relative to the grid.
            const translated = aabbox + (position - origin_);
            return CellsAABBox(this, translated);
        }
        private static void unittestCells()
        {
            import std.typecons;
            auto system = new SpatialSystem(null, Vector2f(0.0f, 0.0f), 128.0f, 8);
            scope(exit){.clear(system);}

            Tuple!(int, int)[] cells;
            foreach(x, y, cell; system.cells(Vector2f(-1.0f, 0.0f),
                                             Rectf(-128.0f, -128.0f, 128.5f, 127.0f)))
            {
                cells ~= tuple(x, y);
            }
            assert(cells == [tuple(2, 3), tuple(2, 4),
                             tuple(3, 3), tuple(3, 4),
                             tuple(4, 3), tuple(4, 4)]);
            .clear(cells);
            foreach(x, y, cell; system.cells(Vector2f(511.0f, 512.0f),
                                             Rectf(-128.0f, -128.0f, 128.5f, 127.0f)))
            {
                cells ~= tuple(x, y);
            }
            assert(cells == [tuple(-1, -1), tuple(6, 7), tuple(7, 7)]);
        }
        mixin registerTest!(unittestCells, "SpatialSystem.cells");
}

void unittestSpatial()
{
    auto eSystem = new EntitySystem;
    scope(exit){eSystem.destroy();}

    const velocity = Vector2f(5.0f, 0.0f);

    alias PhysicsComponent P;
    alias VolumeComponent V;

    EntityPrototype prototype;
    auto pos1 = P(Vector2f(-1.0f, 0.0f), 0.0f, velocity);
    prototype.physics = pos1;
    auto rect = V(Rectf(-128.0f, -128.0f, 128.5f, 127.0f));
    prototype.volume = rect;
    auto id1 = eSystem.newEntity(prototype);
    auto pos2 = P(Vector2f(511.0f, 512.0f), 0.0f, velocity);
    prototype.physics = pos2;
    auto id2 = eSystem.newEntity(prototype);
    auto spatial = new SpatialSystem(eSystem, Vector2f(0.0f, 0.0f), 128.0f, 8);
    scope(exit){.clear(spatial);}

    eSystem.update();
    spatial.update();

    EntityID[] ids;
    foreach(ref Entity entity, 
            ref PhysicsComponent physics, 
            ref VolumeComponent volume;
            spatial.neighbors(pos1, rect))
    {
        ids ~= entity.id;
    }
    assert(ids == [id1]);
    foreach(ref Entity entity, 
            ref PhysicsComponent physics, 
            ref VolumeComponent volume;
            spatial.neighbors(pos2, rect))
    {
        ids ~= entity.id;
    }
    assert(ids == [id1, id2]);
    clear(ids);

    foreach(ref Entity e; eSystem)
    {
        if(e.id == id1)
        {
            e.kill();
        }
    }
    eSystem.update();
    spatial.update();
    foreach(ref Entity entity, 
            ref PhysicsComponent physics, 
            ref VolumeComponent volume;
            spatial.neighbors(pos1, rect))
    {
        ids ~= entity.id;
    }
    foreach(ref Entity entity, 
            ref PhysicsComponent physics, 
            ref VolumeComponent volume;
            spatial.neighbors(pos2, rect))
    {
        ids ~= entity.id;
    }
    assert(ids == [id2]);
}
mixin registerTest!(unittestSpatial, "SpatialSystem general");
