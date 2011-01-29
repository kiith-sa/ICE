module actor.actorcontainer;


import actor.actor;


///Interface for classes that contain, or manage actor. Currently implemented by ActorManager.
interface ActorContainer
{
    /**
     * Add a new actor.
     * 
     * Params:  actor = Actor to add. Must not already be in the container.
     */
    void add_actor(Actor actor);

    /**
     * Remove an actor. 
     * 
     * Params:  actor = Actor to remove. Must be in the container.
     */
    void remove_actor(Actor actor);
}
