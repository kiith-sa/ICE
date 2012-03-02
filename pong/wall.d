//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Wall actor.
module pong.wall;


import pong.ball;
import scene.actor;
import scene.scenemanager;
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
 *     public mixin Signal!(const BallBody) ballHit
 *
 *     Emitted when a ball hits the wall. 
 */
class Wall : Actor
{
    protected:
        ///Default color of the wall.
        Color defaultColor_ = rgba!"0000";
        ///Current color of the wall.
        Color color_;
        ///Default color of the wall border.
        Color defaultColorBorder_ = rgba!"E0E0FFE0";
        ///Current color of the wall border.                 
        Color colorBorder_;
        ///Area taken up by the wall.
        Rectanglef box_;

    public:
        ///Emitted when a ball hits the wall. Will emit const BallBody after D2 move.
        mixin Signal!(const BallBody) ballHit;

        override void onDie(SceneManager manager)
        {
            ballHit.disconnectAll();
        }

        ///Set wall velocity.
        @property void velocity(in Vector2f v){physicsBody_.velocity = v;}

    protected:
        /**
         * Construct a wall.
         *
         * Params:  physicsBody = Physics body of the wall.
         *          box          = Rectangle used for graphical representation of the wall.
         */
        this(PhysicsBody physicsBody, const ref Rectanglef box)
        {
            super(physicsBody);
            box_          = box;
            color_        = defaultColor_;
            colorBorder_ = defaultColorBorder_;
        }

        override void draw(VideoDriver driver)
        {
            const Vector2f position = physicsBody_.position;
            driver.drawRectangle(position + box_.min, position + box_.max, colorBorder_);
            driver.drawFilledRectangle(position + box_.min, position + box_.max, color_);
        }

        override void update(SceneManager manager)
        {
            foreach(collider; physicsBody_.colliders)
            {
                if(collider.classinfo is BallBody.classinfo)
                {
                    ballHit.emit(cast(BallBody)collider);
                }
            }
        }
}             

/**
 * Base class for factories constructing Wall and derived classes.
 *
 * Params:  boxMin = Minimum extent of the wall relative to its position.
 *                    Default; Vector2f(0.0f, 0.0f)
 *          boxMax = Maximum extent of the wall relative to its position.
 *                    Default; Vector2f(1.0f, 1.0f)
 */
abstract class WallFactoryBase(T) : ActorFactory!T
{
    mixin(generateFactory("Vector2f $ boxMin $ Vector2f(0.0f, 0.0f)", 
                           "Vector2f $ boxMax $ Vector2f(1.0f, 1.0f)"));
    package:
        ///Get a collision aabbox based on factory parameters. Used in produce().
        VolumeAABBox bbox(){return new VolumeAABBox(boxMin_, boxMax_ - boxMin_);}
        ///Get a bounds rectangle based on factory parameters. Used in produce().
        Rectanglef rectangle(){return Rectanglef(boxMin_, boxMax_);}
}

///Factory used to construct walls.
class WallFactory : WallFactoryBase!Wall
{
    public override Wall produce(SceneManager manager)
    {
        auto physicsBody = new PhysicsBody(bbox, position_, velocity_, real.infinity);
        auto rect = rectangle();
        return newActor(manager, new Wall(physicsBody, rect));
    }
}
