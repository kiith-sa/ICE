
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Base interface of all component processing systems.
module component.system;


///Base interface of all component processing systems.
interface System
{
    ///Update the system, processing related components.
    void update();
}


