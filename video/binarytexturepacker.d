
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Binary tree based texture packer.
module video.binarytexturepacker;


import std.conv;

import math.math;
import math.vector2;
import math.rect;
import memory.memory;


/**
 * Binary tree based texture packer. Handles allocation of texture page space.
 *
 * To fit a texture, space is subdivided vertically/horizontally to create an area 
 * fitting texture width/height, try to fit the texture to that area, if it doesn't
 * fit, subdivide again, repeat.
 */
package struct BinaryTexturePacker
{
    private:
        ///Allocates and stores nodes.
        struct NodeStorage
        {
            import containers.segmentedvector;
            ///Node storage. Using a SegmentedVector to avoid pointer invalidion.
            SegmentedVector!(Node, 64) storage;

            ///Allocate a new node and return a pointer to it.
            Node* newNode(ref Rectu area)
            {
                storage ~= Node(area, this);
                return &storage[storage.length - 1];
            }
        }

        ///Node representing a rectangular area of space.
        struct Node
        {
            public:
                ///Area belonging to the node.
                Rectu area;

            private:
                ///Allocates and stores nodes.
                NodeStorage* storage_;
                ///First child.
                Node* childA_;
                ///Second child.
                Node* childB_;
                ///Is this node's area taken by a texture?
                bool full_ = false;

            public:
                /**
                 * Construct a Node representing specified area.
                 *
                 * Params:  area    = Area of the node.
                 *          storage = Allocates and stores nodes.
                 */
                this(const ref Rectu area, ref NodeStorage storage)
                {
                    this.area     = area;
                    this.storage_ = &storage;
                }

                /**
                 * Try to insert a texture with given size to this node.
                 *
                 * Params:  size = Size of space needed.
                 *
                 * Returns: Node with space for the texture on success, null on failure.
                 */
                Node* insert(const Vector2u size)
                in{assert(size != Vector2u(0, 0), "Can't pack a zero sized texture");}
                body
                {
                    //if not a leaf
                    if(childA_ !is null && childB_ !is null)
                    {
                        //try inserting to the first child
                        Node* newNode = childA_.insert(size);
                        if(newNode !is null){return newNode;}
                        //no room, try the second 
                        //(which will return null if no room there either)
                        return childB_.insert(size);
                    }
                    if(full_){return null;}

                    const Vector2u areaSize = area.size;
                    //if this node is too small
                    if(areaSize.x < size.x || areaSize.y < size.y){return null;}
                    //if exact fit
                    if(areaSize == size)
                    {
                        full_ = true;
                        return &this;
                    }

                    childA_ = storage_.newNode(area);
                    childB_ = storage_.newNode(area);

                    //decide which way to split
                    const Vector2u freeSpace = areaSize - size;
                    //split with a vertical cut if more free space on the right
                    if(freeSpace.x > freeSpace.y)
                    {
                        childA_.area.max.x = area.min.x + size.x;// - 1;
                        childB_.area.min.x += size.x;
                    }
                    //split with a horizontal cut if more free space on the bottom
                    else
                    {
                        childA_.area.max.y = area.min.y + size.y;// - 1;
                        childB_.area.min.y += size.y;
                    }
                    return childA_.insert(size);
                }

                //could be optimized using simple rectangle intersection
                //(probably not much gain, though).
                /**
                 * Try to remove a texture with specified area.
                 *
                 * Params:  rect = Area of texture to remove.
                 *
                 * Returns: True on success, false on failure.
                 */
                bool remove(const ref Rectu rect)
                {
                    //exact fit, this is the area we want to free
                    if(rect == area && full_)
                    {
                        full_ = false;
                        return true;
                    }
                    //try children
                    if(childA_ !is null && childA_.remove(rect)){return true;}
                    if(childB_ !is null && childB_.remove(rect)){return true;}
                    //can't remove from this node
                    return false;
                }

                ///Determine if this node and all its subnodes are empty.
                @property bool empty() const pure
                {
                    if(full_){return false;}
                    if(childA_ !is null && !childA_.empty()){return false;}
                    if(childB_ !is null && !childB_.empty()){return false;}
                    return true;
                }
        }

        ///Size of the area available to the packer in pixels.
        Vector2u size_;

        ///Root node of the packer tree.
        Node* root_ = null;

        ///Allocates and stores nodes.
        NodeStorage* nodeStorage_;

    public:
        /**
         * Construct BinaryTexturePacker.
         *
         * Params:  size = Size of texture area for the packer to manage.
         */
        this(const Vector2u size)
        {
            size_ = size;
            nodeStorage_ = alloc!NodeStorage;
            /* root_ = alloc!Node(Rectu(Vector2u(0, 0), size)); */
            root_ = nodeStorage_.newNode(Rectu(Vector2u(0, 0), size));
        }

        ///Destroy this BinaryTexturePacker and its nodes.
        ~this()
        {
            //NodeStorage destructor will destroy all nodes.
            free(nodeStorage_);
        }

        /**
         * Try to allocate space for a texture with given size.
         *
         * Params:  size    = Size of texture space to allocate.
         *          texArea = Area taken by the texture will be returned here. 
         *        
         * Returns: True if successful, false otherwise.
         */
        bool allocateSpace(const Vector2u size, out Rectu texArea)
        {
            const Node* node = root_.insert(size);
            if(node is null){return false;}
            texArea = node.area;
            return true;
        }

        /**
         * Free space taken by a texture.
         * 
         * Params:  area = Area of the texture to free.
         */
        void freeSpace(const ref Rectu area)
        {
            bool removed = root_.remove(area);
            assert(removed, "Trying to remove unallocated space from BinaryTexturePacker");
        }

        ///Determine if this BinaryTexturePacker is empty.
        @property bool empty() const pure {return root_.empty();}

        ///Return a string containing information about the packer.
        @property string info() const
        {
            uint nodes, leaves, full, fullArea;

            //crawl nodes and get info about them.
            void crawler(const Node* n)
            {
                ++nodes;
                if(n.childA_ !is null){crawler(n.childA_);}
                if(n.childB_ !is null){crawler(n.childB_);}
                if(n.childA_ is null && n.childB_ is null)
                {
                    ++leaves;
                    if(n.full_)
                    {
                        ++full;
                        fullArea += n.area.area;
                    }
                }
            }

            crawler(root_);

            const real totalArea = size_.x * size_.y;
            const real fullPercent = fullArea / totalArea * 100.0;
            const real emptyPercent = 100.0 - fullPercent;
            string output;
            output ~= "nodes: "  ~ to!string(nodes) ~ "\n";
            output ~= "leaves: " ~ to!string(leaves) ~ "\n";
            output ~= "full: "   ~ to!string(full) ~ "\n";
            output ~= "empty: "  ~ to!string(leaves - full) ~ "\n";
            output ~= "farea: "  ~ to!string(fullPercent) ~ "%\n";
            output ~= "earea: "  ~ to!string(emptyPercent) ~ "%\n";
            return output;
        }
}
