
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
import containers.lazyarray;
import containers.fixedarray;
import math.vector2;
import memory.memory;
import util.frameprofiler;
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

            /// Vertex with a position and a color. 
            /// 
            /// Used for line start/end.
            struct ColoredVertex
            {
                /// Position of the vertex.
                Vector2f position;
                /// Color of the vertex.
                Color color;

                /// Construct a ColoredVertex.
                this(const Vector2f position, const Color color) @safe pure nothrow
                {
                    this.position = position;
                    this.color = color;
                }
            }
            union
            {
                ///Visual data stored for the Lines type.
                struct
                {
                    ///Vertices (in pairs).
                    FixedArray!ColoredVertex vertices;
                    ///Line widths (each for a pair of vertices)
                    FixedArray!float widths;
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

        ///Draw volume components of objects? (debugging)
        bool drawVolumeComponents_;

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
                    clear(data.widths);
                    break;
                default:
                    assert(false, "Unknown visual component type: " ~ to!string(data.type));
            }
            clear(visualData_);
        }

        ///Set VideoDriver to draw VisualComponents with.
        @property void videoDriver(VideoDriver rhs) pure nothrow {videoDriver_ = rhs;}

        ///Set the game directory to load video data from.
        @property void gameDir(VFSDir rhs) 
        {
            gameDir_ = rhs;

            import std.stdio;
            //Load configuration from the game directory.
            try
            {
                YAMLNode yaml = loadYAML(gameDir_.file("visualsystem.yaml"));
                if(yaml.containsKey("drawVolumeComponents"))
                {
                    drawVolumeComponents_ = yaml["drawVolumeComponents"].as!bool;
                }
            }
            catch(VFSException e)
            {
                writeln("WARNING: Could not load VisualSystem configuration: ", e.msg);
            }
            catch(YAMLException e)
            {
                writeln("WARNING: Could not load VisualSystem configuration: ", e.msg);
            }
        }

        ///Render entities' visual representations.
        void update()
        {
            assert(videoDriver_ !is null, "Updating VisualSystem with no VideoDriver");
            foreach(ref Entity e, 
                    ref PhysicsComponent physics, 
                    ref VisualComponent  visual; 
                    entitySystem_)
            {
                if(drawVolumeComponents_)
                {
                    import component.volumecomponent;
                    auto volume = e.volume;
                    if(volume !is null) final switch(volume.type)
                    {
                        case VolumeComponent.Type.AABBox:
                            videoDriver_.drawRect(physics.position + volume.aabbox.min, 
                                                  physics.position + volume.aabbox.max,
                                                  Color.red);
                            break;
                        case VolumeComponent.Type.Uninitialized:
                            assert(false, "Uninitialized VolumeComponent");
                    }
                }

                ///Loads visual data if not yet loaded.
                VisualData* data = visualData_[visual.dataIndex];
                if(data is null)
                {
                    writeln("WARNING: Could not load visual data ", visual.dataIndex.id);
                    writeln("Falling back to placeholder visual data...");
                    assert(false, "TODO - Placeholder visual data not implemented");
                }

                const pos = physics.position;
                if(data.type == VisualData.Type.Lines)
                {
                    const vertices    = &data.vertices;
                    const widths      = &data.widths;
                    const vertexCount = vertices.length;

                    videoDriver_.lineAA = true;

                    assert(vertexCount % 2 == 0, 
                           "Uneven number of vertices in a lines visual component");
                    assert(widths.length == vertexCount / 2, 
                           "Vertex and width counts don't match in a lines visual component");

                    //Draw lines pairing vertices together.
                    for(size_t line = 0, lineStart = 0; 
                        lineStart < vertexCount; 
                        lineStart += 2, ++line)
                    {
                        videoDriver_.lineWidth = (*widths)[line];
                        videoDriver_.drawLine
                            (pos + (*vertices)[lineStart].position,
                             pos + (*vertices)[lineStart + 1].position,
                             (*vertices)[lineStart].color,
                             (*vertices)[lineStart + 1].color);
                    }
                    videoDriver_.lineWidth = 1.0f;
                    videoDriver_.lineAA = false;
                }
                else
                {
                    assert(false, "Unknown visual data type: " ~ 
                                  to!string(data.type));
                }
            }
        }

    private:
        /**
         * Load visual data from a YAML file with specified name to output. 
         *
         * Params:  name   = Name of the visual data YAML file in the game directory.
         *          output = Loaded data will be written here.
         *
         * Returns: true on success, false on failure.
         */
        bool loadVisualData(string name, out VisualData output)
        {
            string fail(){return "Failed to load visual data " ~ name ~ ": ";}
            try
            {
                YAMLNode yamlSource;
                {
                    auto zone = Zone("Visual component file reading & YAML parsing");
                    yamlSource = loadYAML(gameDir_.file(name));
                }
                const type = yamlSource["type"].as!string;
                if(type == "lines")
                {
                    auto vertices = yamlSource["vertices"];

                    Color currentColor = Color.white;
                    float currentWidth = 1.0f;

                    scope(failure)
                    {
                        clear(output.vertices);
                        clear(output.widths);
                    }

                    // First determine the vertex count so we can allocate 
                    // the arrays once without reallocating.
                    size_t vertexCount = 0;
                    foreach(string key, ref YAMLNode value; vertices) switch(key)
                    {
                        case "vertex": ++vertexCount; break;
                        default:       continue;
                    }

                    if(vertexCount % 2 != 0)
                    {
                        writeln(fail() ~ "Lines must have an even number of vertices.");
                        return false;
                    }

                    {
                        auto zone = Zone("VisualData vertices/widths allocation");
                        output.vertices = FixedArray!(VisualData.ColoredVertex)(vertexCount);
                        output.widths   = FixedArray!float(vertexCount / 2);
                    }

                    size_t vertex = 0;
                    foreach(string key, ref YAMLNode value; vertices) switch(key)
                    {
                        case "color":
                            currentColor = value.as!Color;
                            break;
                        case "width":
                            currentWidth = fromYAML!(float, "a > 0.0f")(value , "width");
                            break;
                        case "vertex":
                            //Width is specified only once per line (vertex pair)
                            //not per vertex.
                            if(vertex % 2 == 0)
                            {
                                output.widths[vertex / 2] = currentWidth;
                            }
                            output.vertices[vertex] = 
                                VisualData.ColoredVertex(fromYAML!Vector2f(value, "vertex"),
                                                         currentColor);
                            ++vertex;
                            break;
                        default:
                            writeln(fail() ~ "Unrecognized key in a \"lines\" "
                                    "visual component: \"" ~ key ~ "\"");
                            return false;
                    }

                    assert(output.vertices.length == output.widths.length * 2,
                           "Lines' vertex and weight counts don't match");

                    output.type = VisualData.Type.Lines;
                }
                else
                {
                    writeln(fail(), "Unknown visual component type: ", type);
                    return false;
                }
            }
            catch(YAMLException e){writeln(fail(), e.msg); return false;}
            catch(VFSException e) {writeln(fail(), e.msg); return false;}
            return true;
        }
}

