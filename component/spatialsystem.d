
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Keeps track of spatial relations between objects with volumes.
module component.spatialsystem;


import std.algorithm;

import containers.array2d;
import containers.fixedarray;
import math.math;
import math.rect;
import math.vector2;

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
            ///ID of the entity.
            EntityID id;
            ///Physics component of the entity. This is only valid for one update.
            PhysicsComponent* physics;
            ///Spatial volume of the entity. This is only valid for one update.
            VolumeComponent*  volume;
        }

        ///A cell in the spatial grid.
        struct Cell
        {
            private:
                ///Storage of entities in this cell.
                FixedArray!SpatialEntity data_;

                ///Number of entities in the cell.
                uint used_;

            public:
                ///Clear all entities from the cell.
                void clear() pure nothrow
                {
                    used_ = 0;
                }

                ///Add an entity to the cell.
                void add(ref SpatialEntity entity)
                {
                    //Reallocate if needed.
                    if(used_ == data_.length)
                    {
                        auto newData_ = FixedArray!SpatialEntity(data_.length * 2 + 1);
                        newData_[0 .. used_] = data_[0 .. used_];
                        data_ = move(newData_);
                    }
                    data_[used_] = entity;
                    ++used_;
                }

                ///Get a slice to all entities in this cell.
                const(SpatialEntity[]) get()
                {
                    return data_[0 .. used_];
                }
        }

        ///Entity system whose data we're processing.
        EntitySystem entitySystem_;

        ///Cells of the spatial grid. This is rebuilt every frame.
        Array2D!Cell grid_;

        ///Cell representing the area outside the grid.
        Cell outer_;

        ///Size of a single cell (both x and y).
        const float cellSize_;

        ///Size of the grid in cells (both x and y).
        const uint gridSize_;

        ///Origin of the grid (top-left corner) in world space.
        const Vector2f origin_;

    public:
        this(EntitySystem entitySystem, 
             const Vector2f center, const float cellSize, const uint gridSize)
        {
            entitySystem_ = entitySystem;

            cellSize_ = cellSize;
            gridSize_ = gridSize;

            const halfSize_ = cellSize_ * gridSize_ * 0.5;
            origin_ = center - Vector2f(halfSize_, halfSize_);

            grid_ = Array2D!Cell(gridSize_, gridSize_);
        }

        ///Destroy the SpatialSystem, freeing all used memory.
        ~this()
        {
            .clear(grid_);
            .clear(outer_);
        }

        ///Determine spatial relations between entities.
        void update()
        {
            //Clear spatial data from the previous update.
            clear();

            foreach(Entity e,
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
                        foreach(ref cell; cells(physics.position, volume.aabbox))
                        {
                            cell.add(SpatialEntity(e.id, &physics, &volume));
                        }
                        break;
                    case VolumeComponent.Type.Uninitialized:
                        assert(false, 
                               "Uninitialized VolumeComponent during SpatialSystem update");
                        break;
                }
            }
        }

    private:
        ///Clear spatial data. Called on each update.
        void clear() 
        {
            foreach(ref cell; grid_){cell.clear();}
            outer_.clear();
        }

        ///Iterate over all cells that intersect with aabbox at specified position.
        auto cells(const Vector2f position, ref const Rectf aabbox)
        {
            struct Foreach
            {
                SpatialSystem spatial_;

                //AABBox relative to origin of spatial_.
                Rectf aabbox_;

                int opApply(int delegate(ref Cell) dg)
                {    
                    const float mult = 1.0f / spatial_.cellSize_;
                    const gridSize   = spatial_.gridSize_;

                    //Foreach result.
                    int result = 0;

                    //Get minimum and maximum cells containing the rectangle.
                    int cellXMin = floor!int(aabbox_.min.x * mult);
                    int cellXMax = floor!int(aabbox_.max.x * mult);
                    int cellYMin = floor!int(aabbox_.min.y * mult);
                    int cellYMax = floor!int(aabbox_.max.y * mult);

                    //If outside the grid, iterate over outer.
                    if(cellXMin < 0 || 
                       cellYMin < 0 || 
                       cellXMax >= gridSize || 
                       cellYMax >= gridSize)
                    {
                        result = dg(spatial_.outer_);
                        if(result){return result;}
                    }

                    //Now that we handled outer we can clamp to grid.
                    cellXMin = clamp(cellXMin, 0, cast(int)gridSize - 1);
                    cellYMin = clamp(cellYMin, 0, cast(int)gridSize - 1);
                    cellXMax = clamp(cellXMax, 0, cast(int)gridSize - 1);
                    cellYMax = clamp(cellYMax, 0, cast(int)gridSize - 1);

                    //Iterate over the cells that contain the rectangle and add all of them.
                    foreach(x; cellXMin .. cellXMax + 1) foreach(y; cellYMin .. cellYMax + 1)
                    {
                        result = dg(spatial_.grid_[x, y]);
                        if(result){break;}
                    }
                    return result;
                }
            }

            //Translate relative to the grid.
            return Foreach(this, aabbox + (position - origin_));
        }
}
