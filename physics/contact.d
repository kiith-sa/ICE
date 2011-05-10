
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Physics body contact struct.
module physics.contact;
@safe


import std.algorithm;

import physics.physicsbody;
import math.vector2;
import math.math;


///Stores data about a contact between two physics bodies.
align(1) struct Contact
{
    public:
        ///First body involved in the contact.
        PhysicsBody body_a;
        ///Second body involved in the contact.
        PhysicsBody body_b;

        /**
         * Normal of the contact.
         * Contact normal is the direction we must move body_b (and opposite of the
         * direction we must move body_a) to resolve the contact.
         */
        Vector2f contact_normal;
        ///Greatest depth of interpenetration between the bodies.
        float penetration;

        ///If true, this contact is already resolved - do not resolve it further.
        bool resolved;

    package:
        ///Swap the bodies in the contact, and flip the direction of the contact normal.
        void swap_bodies()
        {
            contact_normal *= -1.0f;
            swap(body_a, body_b);
        }
        
        /**
         * Resolve penetration between the bodies by changing their positions.
         *
         * No resolution is done if both bodies have infinite mass.
         * This might change if bugs arise.
         *
         * Params:  change_a = Vector to write position change of the first body to.
         *          change_b = Vector to write position change of the second body to.
         */
        void resolve_penetration(out Vector2f change_a, out Vector2f change_b)
        in
        {
            assert(body_a !is null && body_b !is null,
                   "Can't resolve penetration of a contact with one or no body");
        }
        body
        {
            const real inv_mass_a = body_a.inverse_mass;
            const real inv_mass_b = body_b.inverse_mass;
            const real inv_mass_total = inv_mass_a + inv_mass_b;

            //if both inverse masses are 0 (masses are infinite),
            //don't move anything (degenerate case)
            //maybe handle this differently if bugs arise
            if(equals(inv_mass_total, cast(const real)0.0L)){return;}

            const real move_a = penetration * (inv_mass_a / inv_mass_total) * -1.0;
            const real move_b = penetration * (inv_mass_b / inv_mass_total) * 1.0;

            change_a = contact_normal * move_a;
            change_b = contact_normal * move_b;

            body_a.position = body_a.position + change_a;
            body_b.position = body_b.position + change_b;
        }

        ///Handle collision response to the contact (e.g. bodies bouncing away).
        void collision_response()
        in
        {
            assert(body_a !is null && body_b !is null,
                   "Can't process collision response of a contact with one or no body");
            assert(!resolved, "Trying to resolve collision response that was already fully resolved");
        }
        body
        {
            body_a.collision_response_contract(this);
            body_b.collision_response_contract(this);
        }

        ///Return desired change of velocity of the contact (total of both bodies) for collision response.
        @property float desired_delta_velocity() const
        {
            return resolved ? 0.0f : 2.0 * contact_velocity;
        }

        ///Return sum of inverse masses of bodies involved in this contact.
        @property real inverse_mass_total() const 
        {
            return body_a.inverse_mass + body_b.inverse_mass;
        }

    private:
        ///Return total velocity of the contact (both bodies) in the direction of contact normal.
        @property float contact_velocity() const
        {
            return contact_normal.dot_product(body_a.velocity - body_b.velocity);
        }
}        
