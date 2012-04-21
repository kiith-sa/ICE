
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Provides statistics to an entity, such as how many entities it has killed.
module component.statisticscomponent;


import util.yaml;


///Provides statistics to an entity, such as how many entities it has killed.
struct StatisticsComponent
{
    ///How many entities have we killed?
    uint entitiesKilled;
    ///How many bursts have we fired?
    uint burstsFired;

    ///Load from a YAML node. Throws YAMLException on error.
    this(ref YAMLNode yaml)
    {
        throw new YAMLException("Can't specify StatisticsComponent in YAML - it's run-time only");
    }
}
