
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
import util.resourcemanager;
import util.yaml;
import video.videodriver;

import component.entitysystem;
import component.exceptions;
import component.physicscomponent;
import component.visualcomponent;
import component.system;


///System that displays (with VideoDriver) visual representations of entities.
class VisualSystem : System
{
    private:
        /// Entity system whose data we're processing.
        EntitySystem entitySystem_;

        /// Game data directory.
        VFSDir gameDir_;

        /// VideoDriver to draw VisualComponents with.
        VideoDriver videoDriver_;

        /// Reference to the resource manager handling YAML loading.
        ResourceManager!YAMLNode yamlManager_;

        /// Lazily loads and stores visual data.
        LazyArray!VisualData visualData_;

        /// Visual data used when visual data of an entity fails to load.
        VisualData placeholderVisualData_;

        /// Draw volume components of objects? (debugging)
        bool drawVolumeComponents_;

    public:
        /// Construct a VisualSystem.
        ///
        /// Params:  entitySystem = Entity system whose entities we're processing.
        ///          gameDir      = Game data directory.
        this(EntitySystem entitySystem, VFSDir gameDir)
        {
            entitySystem_ = entitySystem;
            gameDir_      = gameDir;
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


        /// Provide a reference to the YAML resource manager. 
        /// 
        /// Must be called at least once after construction.
        ///
        /// Throws:  SystemInitException on failure.
        @property void yamlManager(ResourceManager!YAMLNode rhs)
        {
            yamlManager_ = rhs;
            //Load visual system configuration.
            try
            {
                YAMLNode* yaml = yamlManager_.getResource("visualsystem.yaml");
                if(yaml is null)
                {
                    yaml = writeDefaultConfig();
                    // Writing default VisualSystem config might fail, but is not fatal.
                    if(yaml is null){return;}
                }

                if((*yaml).containsKey("drawVolumeComponents"))
                {
                    drawVolumeComponents_ = (*yaml)["drawVolumeComponents"].as!bool;
                }
            }
            catch(YAMLException e)
            {
                writeln("WARNING: Could not load VisualSystem configuration: ", e.msg);
            }
            if(!loadVisualData("placeholder/visual.yaml", placeholderVisualData_))
            {
                throw new SystemInitException("Failed to load placeholder visual data");
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
                VisualData* data = visual.placeholder 
                    ? &placeholderVisualData_
                    : visualData_[visual.dataIndex];
                if(data is null)
                {
                    writeln("WARNING: Could not load visual data ", visual.dataIndex);
                    writeln("Falling back to placeholder visual data...");
                    data = &placeholderVisualData_;
                    visual.placeholder = true;
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
        /// Write the default visualsystem.yaml config file.
        ///
        /// Returns: Pointer to the YAMLNode storing the default configuration.
        YAMLNode* writeDefaultConfig()
        {
            auto configFile = gameDir_.file("visualsystem.yaml");
            YAMLNode defaultConfig = loadYAML("drawVolumeComponents: false\n");
            try
            {
                saveYAML(configFile, defaultConfig);
            }
            catch(YAMLException e)
            {
                assert(false, 
                       "YAML error saving default VisualSystem config; this shouldn't happen");
            }
            catch(VFSException e)
            {
                writeln("WARNING: could not write default VisualSystem config file; ignoring.");
            }

            return yamlManager_.getResource("visualsystem.yaml");
        }

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
                assert(yamlManager_ !is null, 
                       "Trying to load a visual component but YAML resource manager has not been set");

                YAMLNode* yamlSourcePtr = yamlManager_.getResource(name);
                if(yamlSourcePtr is null)
                {
                    writeln(fail() ~ "Couldn't load YAML file " ~ name);
                    return false;
                }
                auto yamlSource = *yamlSourcePtr;
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
            return true;
        }
}

