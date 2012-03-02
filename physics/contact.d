
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Physics body contact struct.
module physics.contact;


import std.algorithm;

import physics.physicsbody;
import math.vector2;
import math.math;

///Stores data about a contact between two physics bodies.
struct Contact
{
    public:
        ///First body involved in the contact.
        PhysicsBody bodyA;
        ///Second body involved in the contact.
        PhysicsBody bodyB;

        /**
         * Normal of the contact.
         * Contact normal is the direction we must move bodyB (and opposite of the
         * direction we must move bodyA) to resolve the contact.
         */
        Vector2f contactNormal;
        ///Greatest depth of interpenetration between the bodies.
        float penetration;

        ///If true, this contact is already resolved - do not resolve it further.
        bool resolved;

    package:
        ///Swap the bodies in the contact, and flip the direction of the contact normal.
        void swapBodies()
        {
            contactNormal *= -1.0f;
            swap(bodyA, bodyB);
        }
        
        /**
         * Resolve penetration between the bodies by changing their positions.
         *
         * No resolution is done if both bodies have infinite mass.
         * This might change if bugs arise.
         *
         * Params:  changeA = Vector to write position change of the first body to.
         *          changeB = Vector to write position change of the second body to.
         */
        void resolvePenetration(out Vector2f changeA, out Vector2f changeB) pure
        in
        {
            assert(bodyA !is null && bodyB !is null,
                   "Can't resolve penetration of a contact with one or no body");
        }
        body
        {
            const invMassA = bodyA.inverseMass;
            const invMassB = bodyB.inverseMass;
            const invMassTotal = invMassA + invMassB;

            //if both inverse masses are 0 (masses are infinite),
            //don't move anything (degenerate case)
            //maybe handle this differently if bugs arise
            if(equals(invMassTotal, cast(const real)0.0L)){return;}

            const moveA = penetration * (invMassA / invMassTotal) * -1.0;
            const moveB = penetration * (invMassB / invMassTotal) * 1.0;

            changeA = contactNormal * moveA;
            changeB = contactNormal * moveB;

            bodyA.position = bodyA.position + changeA;
            bodyB.position = bodyB.position + changeB;
        }

        ///Handle collision response to the contact (e.g. bodies bouncing away).
        void collisionResponse()
        in
        {
            assert(bodyA !is null && bodyB !is null,
                   "Can't process collision response of a contact with one or no body");
            assert(!resolved, "Trying to resolve collision response that was already fully resolved");
        }
        body
        {
            bodyA.collisionResponseContract(this);
            bodyB.collisionResponseContract(this);
        }

        ///Return desired change of velocity of the contact (total of both bodies) for collision response.
        @property float desiredDeltaVelocity() const pure
        {
            return resolved ? 0.0f : 2.0 * contactVelocity;
        }

        ///Return sum of inverse masses of bodies involved in this contact.
        @property real inverseMassTotal() const pure
        {
            return bodyA.inverseMass + bodyB.inverseMass;
        }

    private:
        ///Return total velocity of the contact (both bodies) in the direction of contact normal.
        @property float contactVelocity() const pure
        {
            return contactNormal.dotProduct(bodyA.velocity - bodyB.velocity);
        }
}        
