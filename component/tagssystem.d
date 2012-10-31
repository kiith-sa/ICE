
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// System that allows the engine to asynchronically access entities based on tags.
module component.tagssystem;


import std.typecons;

import component.entitysystem;
import component.system;
import component.tagscomponent;


/// System that allows the engine to asynchronically access entities based on tags.
class TagsSystem : System
{
    private:
        /// Entity system whose data we're processing.
        EntitySystem entitySystem_;

        /// Pairs of tags to act on and delegates to call if a tag is found.
        Tuple!(string, void delegate(const EntityID))[] tagDelegates_;

    public:
        /// Construct a TagsSystem working on entities from specified EntitySystem.
        this(EntitySystem entitySystem)
        {
            entitySystem_ = entitySystem;
        }

        /// Call registered delegates providing IDs of tagged entities.
        void update()
        {
            foreach(ref Entity e, ref TagsComponent tags; entitySystem_)
            {
                foreach(pair; tagDelegates_) if(tags.hasTag(pair[0]))
                {
                    pair[1](e.id);
                }
            }
        }

        /// Calls the specified function when specified tag is detected.
        ///
        /// Calls the function for every entity with specified tag,
        /// every frame it exists.
        ///
        /// Params: tag    = Tag to look for.
        ///         toCall = Function to call. ID of the tagged entity is passed.
        void callOnTag(string tag, void delegate(const EntityID) toCall)
        {
            tagDelegates_ ~= tuple(tag, toCall);
        }
}
