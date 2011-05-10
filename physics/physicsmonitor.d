
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Monitor viewing physics engine.
module physics.physicsmonitor;
@safe


///Statistics data sent by PhysicsEngine to physics monitors.
package struct Statistics
{
    ///Physics bodies at the moment.
    uint bodies = 0;
    ///Physics bodies with collision volumes at the moment.
    uint col_bodies = 0;
    ///Contact tests this frame.
    uint tests;
    ///Contacts detected this frame.
    uint contacts;
    ///Penetration resolution iterations this frame.
    uint penetration;
    ///Collision response iterations this frame.
    uint response;

    ///Reset the statistics gathered for the next frame.
    void zero(){tests = contacts = penetration = response = 0;}
}
