
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Interface managing actors.
module scene.actorcontainer;
@safe


import scene.actor;


///Interface for classes that contain, or manage actors. Currently implemented by SceneManager.
interface ActorContainer
{
    /**
     * Add a new actor.
     * 
     * Params:  actor = Actor to add. Must not already be in the container.
     */
    void add_actor(Actor actor);
}
