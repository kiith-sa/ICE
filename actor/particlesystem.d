module actor.particlesystem;


import actor.actor;
import actor.actormanager;
import math.vector2;


///Base class for particle systems.
abstract class ParticleSystem : Actor
{
    protected:
        //Time left for this system to live. 
        //If negative, particle system can exist indefinitely.
        real LifeTime = -1.0;

        Actor Owner = null;

    public:
        ///Set time left for this LineTrail to live. Negative means infinite.
        void life_time(real time){LifeTime = time;}

        void update()
        {
            real frame_length = ActorManager.get.frame_length;
            //If LifeTime reaches zero, destroy this 
            if(LifeTime >= 0.0 && LifeTime - frame_length <= 0.0)
            {
                die();
            }
            LifeTime -= frame_length;
        }

        void detach()
        {
            Owner = null;
        }

    protected:
        //Construct Actor with specified properties.
        this(Vector2f position, Vector2f velocity = Vector2f(0.0, 0.0),
             Actor owner = null,
             real life_time = -1.0) 
        {
            super(position, velocity);
            LifeTime = life_time;
            Owner = owner;
        }
}
