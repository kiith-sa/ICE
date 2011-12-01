//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Wall actor.
module pong.wall;
@safe


import pong.ball;
import scene.actor;
import scene.actorcontainer;
import physics.physicsbody;
import spatial.volumeaabbox;
import video.videodriver;
import math.vector2;
import math.rectangle;
import util.signal;
import util.factory;
import color;


/**
 * A rectangular wall in the game area.
 *
 * Signal:
 *     public mixin Signal!(BallBody) ball_hit
 *
 *     Emitted when a ball hits the wall. Will emit const BallBody after D2 move. 
 */
class Wall : Actor
{
    protected:
        ///Default color of the wall.
        Color default_color_ = Color(0, 0, 0, 0);
        ///Current color of the wall.
        Color color_;
        ///Default color of the wall border.
        Color default_color_border_ = Color(224, 224, 255, 224);
        ///Current color of the wall border.                 
        Color color_border_;
        ///Area taken up by the wall.
        Rectanglef box_;

    public:
        ///Emitted when a ball hits the wall. Will emit const BallBody after D2 move.
        mixin Signal!(BallBody) ball_hit;

        ///Set wall velocity.
        @property void velocity(in Vector2f v){physics_body_.velocity = v;}

        override void die(size_t frame)
        {
            ball_hit.disconnect_all();
            super.die(frame);
        }

    protected:
        /**
         * Construct a wall with specified parameters.
         *
         * Params:  container    = Actor container to manage the wall.
         *          physics_body = Physics body of the wall.
         *          box          = Rectangle used for graphical representation of the wall.
         */
        this(ActorContainer container, PhysicsBody physics_body, const ref Rectanglef box)
        {
            super(container, physics_body);
            box_ = box;
            color_ = default_color_;
            color_border_ = default_color_border_;
        }

        override void draw(VideoDriver driver)
        {
            const Vector2f position = physics_body_.position;
            driver.draw_rectangle(position + box_.min, position + box_.max, color_border_);
            driver.draw_filled_rectangle(position + box_.min, position + box_.max, color_);
        }

        override void update(in real time_step, in real game_time, in size_t frame)
        {
            foreach(collider; physics_body_.colliders)
            {
                if(collider.classinfo is BallBody.classinfo)
                {
                    ball_hit.emit(cast(BallBody)collider);
                }
            }
        }
}             

/**
 * Base class for factories constructing Wall and derived classes.
 *
 * Params:  box_min = Minimum extent of the wall relative to its position.
 *                    Default; Vector2f(0.0f, 0.0f)
 *          box_max = Maximum extent of the wall relative to its position.
 *                    Default; Vector2f(1.0f, 1.0f)
 */
abstract class WallFactoryBase(T) : ActorFactory!(T)
{
    mixin(generate_factory("Vector2f $ box_min $ Vector2f(0.0f, 0.0f)", 
                           "Vector2f $ box_max $ Vector2f(1.0f, 1.0f)"));
    package:
        ///Get a collision aabbox based on factory parameters. Used in produce().
        VolumeAABBox bbox(){return new VolumeAABBox(box_min_, box_max_ - box_min_);}
        ///Get a bounds rectangle based on factory parameters. Used in produce().
        Rectanglef rectangle(){return Rectanglef(box_min_, box_max_);}
}

///Factory used to construct walls.
class WallFactory : WallFactoryBase!(Wall)
{
    public override Wall produce(ActorContainer container)
    {
        auto physics_body = new PhysicsBody(bbox, position_, velocity_, real.infinity);
        auto rect = rectangle();
        return new Wall(container, physics_body, rect);
    }
}
