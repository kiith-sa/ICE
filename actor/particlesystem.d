module actor.particlesystem;


import actor.actor;
import actor.actormanager;
import math.vector2;


///Base class for particle systems.
abstract class ParticleSystem : Actor
{
    private:
        //Time left for this system to live. 
        //If negative, particle system can exist indefinitely.
        real life_time_ = -1.0;

    protected:
        Actor owner_ = null;

    public:
        ///Set time left for this LineTrail to live. Negative means infinite.
        final void life_time(real time){life_time_ = time;}

        void update()
        {
            real frame_length = ActorManager.get.time_step;
            //If life_time_ reaches zero, destroy this 
            if(life_time_ >= 0.0 && life_time_ - frame_length <= 0.0){die();}
            life_time_ -= frame_length;
        }

        final void detach(){owner_ = null;}

    protected:
        //Construct Actor with specified properties.
        this(Vector2f position, Vector2f velocity = Vector2f(0.0, 0.0),
             Actor owner = null, real life_time = -1.0) 
        {
            super(position, velocity);
            life_time_ = life_time;
            owner_ = owner;
        }
}
