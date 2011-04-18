
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module memory.memorymonitor;


///Statistics passed by MemoryMonitorable to memory monitors.
package struct Statistics
{
    ///Total manually allocated memory at the moment, in MiB.
    real manual_MiB;
}
