
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///System that displays (with VideoDriver) visual representations of entities.
module component.visualsystem;


import std.algorithm;
import std.conv;
import std.stdio;

import dgamevfs._;

import color;
import containers.fixedarray;
import containers.lazyarray;
import math.vector2;
import memory.memory;
import util.yaml;
import video.videodriver;

import component.entitysystem;
import component.physicscomponent;
import component.visualcomponent;
import component.system;


///System that displays (with VideoDriver) visual representations of entities.
class VisualSystem : System
{
    private:
        ///Visual data referenced by a VisualComponent.
        struct VisualData
        {
            ///Type of visual data used.
            enum Type 
            {
                Lines
            }
            Type type = Type.Lines;
            
            union
            {
                ///Visual data stored for the Lines type.
                struct
                {
                    ///Vertices (in pairs).
                    FixedArray!Vector2f vertices;
                    ///Vertex colors (in pairs).
                    FixedArray!Color    colors;
                }
            }
        }

        ///Entity system whose data we're processing.
        EntitySystem entitySystem_;

        ///VideoDriver to draw VisualComponents with.
        VideoDriver videoDriver_;

        ///Game directory to load video data from.
        VFSDir gameDir_;

        ///Lazily loads and stores visual data.
        LazyArray!VisualData visualData_;

    public:
        ///Construct a VisualSystem working on entities from specified EntitySystem.
        this(EntitySystem entitySystem)
        {
            entitySystem_ = entitySystem;
            visualData_.loaderDelegate(&loadVisualData);
        }

        ///Destroy the VisualSystem, freeing all loaded visual data.
        ~this()
        {
            foreach(ref data; visualData_) switch(data.type)
            {
                case VisualData.Type.Lines:
                    clear(data.vertices);
                    clear(data.colors);
                    break;
                default:
                    assert(false, "Unknown visual component type: " ~ to!string(data.type));
            }
            clear(visualData_);
        }

        ///Set VideoDriver to draw VisualComponents with.
        @property void videoDriver(VideoDriver rhs) pure nothrow {videoDriver_ = rhs;}

        ///Set the game directory to load video data from.
        @property void gameDir(VFSDir rhs) pure nothrow {gameDir_ = rhs;}

        ///Render entities' visual representations.
        void update()
        {
            assert(videoDriver_ !is null, "Updating VisualSystem with no VideoDriver");
            foreach(ref Entity e, 
                    ref PhysicsComponent physics, 
                    ref VisualComponent  visual; 
                    entitySystem_)
            {
                ///Loads visual data if not yet loaded.
                VisualData* data = visualData_[visual.dataIndex];
                if(data == null)
                {
                    writeln("WARNING: Could not load visual data ", visual.dataIndex.id);
                    writeln("Falling back to placeholder visual data...");
                    assert(false, "TODO - Placeholder visual data not implemented");
                }

                const pos = physics.position;
                if(data.type == VisualData.Type.Lines)
                {
                    const vertices    = &data.vertices;
                    const colors      = &data.colors;
                    const vertexCount = vertices.length;
                    assert(vertexCount % 2 == 0, 
                           "Uneven number of vertices in a lines visual component");
                    assert(vertexCount == colors.length, 
                           "Vertex and color counts don't match in a lines visual component");

                    //Draw lines pairing vertices together.
                    for(size_t lineStart = 0; lineStart < vertexCount; lineStart += 2)
                    {
                        videoDriver_.drawLine(pos + (*vertices)[lineStart],
                                              pos + (*vertices)[lineStart + 1],
                                              (*colors)[lineStart],
                                              (*colors)[lineStart + 1]);
                    }
                }
                else
                {
                    assert(false, "Unknown visual data type: " ~ 
                                  to!string(data.type));
                }
            }
        }

    private:
        ///Load visual data from a YAML file with specified name to output.
        bool loadVisualData(string name, out VisualData output)
        {
            string fail(){return "Failed to load visual data " ~ name ~ ": ";}
            try
            {
                YAMLNode yaml = loadYAML(gameDir_.file(name));
                const type = yaml["type"].as!string;
                if(type == "lines")
                {
                    auto vertices     = yaml["vertices"];
                    const vertexCount = vertices.length;
                    if(vertexCount % 2 != 0)
                    {
                        writeln(fail() ~ "Lines must have an even number of verices.");
                        return false;
                    }

                    scope(failure)
                    {
                        clear(output.vertices);
                        clear(output.colors);
                    }

                    //Load vertex data.
                    output.vertices = FixedArray!Vector2f(vertexCount);
                    output.colors   = FixedArray!Color(vertexCount);
                    size_t i = 0;
                    foreach(ref YAMLNode v; vertices)
                    {
                        output.vertices[i] = Vector2f(fromYAML!float(v["x"], "x"),
                                                      fromYAML!float(v["y"], "y"));
                        output.colors[i]   = v["color"].as!Color;
                        ++i;
                    }
                    output.type = VisualData.Type.Lines;
                }   
                else
                {
                    writeln(fail() ~ "Unknown visual component type: " ~ type);
                    return false;
                }
            }
            catch(YAMLException e)
            {
                writeln(fail() ~ e.msg);
                return false;
            }
            catch(VFSException e)
            {
                writeln(fail() ~ e.msg);
                return false;
            }
            return true;
        }
}

