
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module video.nodepacker;


import std.string;

import math.math;
import math.vector2;
import math.rectangle;
import memory.memory;


/**
 * Binary tree based texture packer. Handles allocation of texture page space.
 *
 * To fit a texture, space is subdivided vertically/horizontally to create an area 
 * fitting texture width/height, try to fit the texture to that area, if it doesn't
 * fit, subdivide again, repeat.
 */
package align(1) struct NodePacker
{
    alias std.string.toString to_string;
    private:
        ///Node representing a rectangular area of space.
        static align(1) struct Node
        {
            public:
                ///Area belonging to the node.
                Rectangleu area;
            private:
                ///First child.
                Node* child_a_;
                ///Second child.
                Node* child_b_;
                ///Is this node's area taken by a texture?
                bool full_ = false;

            public:
                /**
                 * Construct a Node representing specified area.
                 *
                 * Params:  area = Area of the node.
                 *
                 * Returns: Node with specified area.
                 */
                static Node opCall(ref Rectangleu area)
                {
                    Node result;
                    result.area = area;
                    return result;
                }

                /**
                 * Try to insert a texture with given size to this node.
                 *
                 * Params:  size = Size of space needed.
                 *
                 * Returns: Node with space for the texture on success, null on failure.
                 */
                Node* insert(Vector2u size)
                in{assert(size != Vector2u(0, 0), "Can't pack a zero sized texture");}
                body
                {
                    //if not a leaf
                    if(child_a_ !is null && child_b_ !is null)
                    {
                        //try inserting to the first child
                        Node* new_node = child_a_.insert(size);
                        if(new_node !is null){return new_node;}
                        //no room, try the second 
                        //(which will return null if no room there either)
                        return child_b_.insert(size);
                    }
                    if(full_){return null;}

                    Vector2u area_size = area.size;
                    //if this node is too small
                    if(area_size.x < size.x || area_size.y < size.y){return null;}
                    //if exact fit
                    if(area_size == size)
                    {
                        full_ = true;
                        return this;
                    }
                    child_a_ = alloc_struct!(Node)(area);
                    child_b_ = alloc_struct!(Node)(area);

                    //decide which way to split
                    Vector2u free_space = area_size - size;
                    //split with a vertical cut if more free space on the right
                    if(free_space.x > free_space.y)
                    {
                        child_a_.area.max.x = area.min.x + size.x;// - 1;
                        child_b_.area.min.x += size.x;
                    }
                    //split with a horizontal cut if more free space on the bottom
                    else
                    {
                        child_a_.area.max.y = area.min.y + size.y;// - 1;
                        child_b_.area.min.y += size.y;
                    }
                    return child_a_.insert(size);
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
                bool remove(ref Rectangleu rect)
                {
                    //exact fit, this is the area we want to free
                    if(rect == area && full_)
                    {
                        full_ = false;
                        return true;
                    }
                    //try children
                    if(child_a_ !is null && child_a_.remove(rect)){return true;}
                    if(child_b_ !is null && child_b_.remove(rect)){return true;}
                    //can't remove from this node
                    return false;
                }
                
                ///Determine if this node and all its subnodes are empty.
                bool empty()
                {
                    if(full_){return false;}
                    if(child_a_ !is null && !child_a_.empty()){return false;}
                    if(child_b_ !is null && !child_b_.empty()){return false;}
                    return true;
                }

                ///Destroy this node and its children.
                void die()
                {
                    if(child_a_ !is null)
                    {
                        free(child_a_);
                        child_a_ = null;
                    }
                    if(child_b_ !is null)
                    {
                        free(child_b_);
                        child_b_ = null;
                    }
                }
        }

        ///Size of the area available to the packer in pixels.
        Vector2u size_;

        ///Root node of the packer tree.
        Node* root_;

    public:
        /**
         * Construct NodePacker.
         *
         * Params:  size = Size of texture area for the packer to manage.
         * 
         * Returns: NodePacker with specified size.
         */
        static NodePacker opCall(Vector2u size)
        {
            NodePacker packer;
            packer.size_ = size;
            packer.root_ = alloc_struct!(Node)(Rectangleu(Vector2u(0, 0), size));
            return packer;
        }

        ///Destroy this NodePacker and its nodes.
        void die(){free(root_);}

        /**
         * Try to allocate space for a texture with given size.
         *
         * Params:  size      = Size of texture space to allocate.
         *          texcoords = Texture coords of the texture on the page will be written here.
         *          offset    = Offset of the texture on the page will be written here.
         *        
         * Returns: True if successful, false otherwise.
         */
        bool allocate_space(Vector2u size, out Rectanglef texcoords, out Vector2u offset)
        {
            Node* node = root_.insert(size);
            if(node is null){return false;}

            Vector2f min = to!(float)(node.area.min);
            Vector2f max = to!(float)(node.area.max);

            texcoords.min = Vector2f(min.x / size_.x, min.y / size_.y);
            texcoords.max = Vector2f(max.x / size_.x, max.y / size_.y);
            offset = node.area.min;
            return true;
        }

        /**
         * Free space taken by a texture.
         * 
         * Params:  area = Area of the texture to free.
         */
        void free_space(ref Rectangleu area)
        {
            bool removed = root_.remove(area);
            assert(removed, "Trying to remove unallocated space from NodePacker");
        }

        ///Determine if this NodePacker is empty.
        bool empty(){return root_.empty();}

        ///Return a string containing information about the packer.
        string info()
        {
            uint nodes, leaves, full, full_area;

            //crawl nodes and get info about them.
            void crawler(Node* n)
            {
                ++nodes;
                if(n.child_a_ !is null){crawler(n.child_a_);}
                if(n.child_b_ !is null){crawler(n.child_b_);}
                if(n.child_a_ is null && n.child_b_ is null)
                {
                    ++leaves;
                    if(n.full_)
                    {
                        ++full;
                        full_area += n.area.area;
                    }
                }
            }

            crawler(root_);

            real total_area = size_.x * size_.y;
            real full_percent = full_area / total_area * 100.0;
            real empty_percent = 100.0 - full_percent;
            string output;
            output ~= "nodes: " ~ to_string(nodes) ~ "\n";
            output ~= "leaves: " ~ to_string(leaves) ~ "\n";
            output ~= "full: " ~ to_string(full) ~ "\n";
            output ~= "empty: " ~ to_string(leaves - full) ~ "\n";
            output ~= "farea: " ~ to_string(full_percent) ~ "%\n";
            output ~= "earea: " ~ to_string(empty_percent) ~ "%\n";
            return output;
        }
}   

