module video.nodepacker;


import math.math;
import math.vector2;
import math.rectangle;
import allocator;


///Binary tree based texture packer. Handles allocation of texture page space.
package align(1) struct NodePacker
{
    private:
        //Single packer node.
        static align(1) struct Node
        {
            public:
                //Area belonging to the node.
                Rectangleu rectangle;
            private:
                //Children nodes.
                Node* child_a_;
                Node* child_b_;
                //True if this node's area is taken by a texture.
                bool full_ = false;

            public:
                ///Try to insert a texture with given size to this node.
                /**
                 * @return node with space for the texture on success.
                 * @return null on failure.
                */
                Node* insert(Vector2u size)
                in
                {
                    assert(size != Vector2u(0, 0), "Can't pack a zero sized texture");
                }
                body
                {
                    //if not a leaf
                    if(child_a_ !is null && child_b_ !is null)
                    {
                        //try inserting to first child
                        Node* new_node = child_a_.insert(size);
                        if(new_node !is null){return new_node;}
                        //no room, try the second 
                        //(which will return NULL if no room there either)
                        return child_b_.insert(size);
                    }
                    if(full_){return null;}

                    Vector2u rect_size = rectangle.size;
                    //if this node is too small
                    if(rect_size.x < size.x || rect_size.y < size.y){return null;}
                    //if exact fit
                    if(rect_size == size)
                    {
                        full_ = true;
                        return this;
                    }
                    child_a_ = alloc!(Node)();
                    child_b_ = alloc!(Node)();

                    //decide which way to split
                    Vector2u free_space = rect_size - size;
                    child_b_.rectangle = child_a_.rectangle = rectangle;
                    //split with a vertical cut if more free space on the right
                    if(free_space.x > free_space.y)
                    {
                        child_a_.rectangle.max.x = rectangle.min.x + size.x;// - 1;
                        child_b_.rectangle.min.x += size.x;
                    }
                    //split with a horizontal cut if more free space on the bottom
                    else
                    {
                        child_a_.rectangle.max.y = rectangle.min.y + size.y;// - 1;
                        child_b_.rectangle.min.y += size.y;
                    }
                    return child_a_.insert(size);
                }

                ///Try to remove a texture with specified area.
                /**
                 * @return true on success.
                 * @return false on failure.
                 * @note could be optimized using simple rectanlge intersection
                 * (probably not much gain, though).
                 */
                bool remove(ref Rectangleu rect)
                {
                    //exact fit, this is the area we want to free
                    if(rect == rectangle && full_)
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
                        child_a_.die();
                        free(child_a_);
                        child_a_ = null;
                    }
                    if(child_b_ !is null)
                    {
                        child_b_.die();
                        free(child_b_);
                        child_b_ = null;
                    }
                }
        }

        //Size of the area available to the packer, in pixels.
        Vector2u size_;

        //Root node of the packer tree.
        Node* root_;

    public:
        ///Fake constructor. Returns NodePacker with specified texture size.
        static NodePacker opCall(Vector2u size)
        {
            NodePacker packer;
            packer.ctor(size);
            return packer;
        }

        ///Destroy this NodePacker and its nodes.
        void die()
        {
            root_.die();
            free(root_);
        }

        ///Try to allocate space for a texture with given size.
        /**
         * @param size Size of the texture to allocate space for.
         * @param texcoords Texture coordinates of the texture will be output here.
         * @param offset Offset of the texture on the page will be output here.
         *
         * @return true on success.
         * @return false on failure.
         */
        bool allocate_space(Vector2u size, out Rectanglef texcoords, 
                            out Vector2u offset)
        {
            Node* node = root_.insert(size);
            if(node is null){return false;}

            Vector2f min = to!(float)(node.rectangle.min);
            Vector2f max = to!(float)(node.rectangle.max);

            texcoords.min = Vector2f(min.x / size_.x, min.y / size_.y);
            texcoords.max = Vector2f(max.x / size_.x, max.y / size_.y);
            offset = node.rectangle.min;
            return true;
        }

        ///Free space taken by a texture.
        void free_space(ref Rectangleu rectangle)
        {
            bool removed = root_.remove(rectangle);
            assert(removed, "Trying to remove unallocated space from NodePacker");
        }

        ///Determine if this NodePacker is empty.
        bool empty(){return root_.empty();}

    private:
        ///Initialization method used by the fake constructor.
        void ctor(Vector2u size)
        {
            size_ = size;
            root_ = alloc!(Node)();
            *root_ = Node(Rectangleu(Vector2u(0, 0), size), null, null, false);
        }
}   

