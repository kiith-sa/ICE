
//          Copyright Ferdinand Majerech 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

/**
 * Composes nodes from YAML events provided by parser.
 * Code based on PyYAML: http://www.pyyaml.org
 */
module dyaml.composer;

import core.memory;

import std.array;
import std.conv;
import std.exception;
import std.typecons;

import dyaml.anchor;
import dyaml.constructor;
import dyaml.event;
import dyaml.exception;
import dyaml.node;
import dyaml.parser;
import dyaml.resolver;


package:
/**
 * Exception thrown at composer errors.
 *
 * See_Also: MarkedYAMLException
 */
class ComposerException : MarkedYAMLException
{
    mixin MarkedExceptionCtors;
}

///Composes YAML documents from events provided by a Parser.
final class Composer
{
    private:
        ///Parser providing YAML events.
        Parser parser_;
        ///Resolver resolving tags (data types).
        Resolver resolver_;
        ///Constructor constructing YAML values.
        Constructor constructor_;
        ///Nodes associated with anchors. Used by YAML aliases.
        Node[Anchor] anchors_;

        ///Used to reduce allocations when creating pair arrays.
        Appender!(Node.Pair[], Node.Pair) pairAppender_;
        ///Used to reduce allocations when creating node arrays.
        Appender!(Node[], Node) nodeAppender_;

    public:
        /**
         * Construct a composer.
         *
         * Params:  parser      = Parser to provide YAML events.
         *          resolver    = Resolver to resolve tags (data types).
         *          constructor = Constructor to construct nodes.
         */
        this(Parser parser, Resolver resolver, Constructor constructor) @trusted nothrow
        {
            parser_ = parser;
            resolver_ = resolver;
            constructor_ = constructor;

            pairAppender_ = appender!(Node.Pair[])();
            nodeAppender_ = appender!(Node[])();
        }

        ///Destroy the composer.
        pure @safe nothrow ~this()
        {
            parser_ = null;
            resolver_ = null;
            constructor_ = null;
            clear(anchors_);
            anchors_ = null;
        }

        /**
         * Determine if there are any nodes left.
         *
         * Must be called before loading as it handles the stream start event.
         */
        bool checkNode() @safe
        {
            //Drop the STREAM-START event.
            if(parser_.checkEvent(EventID.StreamStart))
            {
                parser_.getEvent();
            }

            //True if there are more documents available.
            return !parser_.checkEvent(EventID.StreamEnd);
        }

        ///Get a YAML document as a node (the root of the document).
        Node getNode() @safe
        {
            //Get the root node of the next document.
            assert(!parser_.checkEvent(EventID.StreamEnd), 
                   "Trying to get a node from Composer when there is no node to "
                   "get. use checkNode() to determine if there is a node.");

            return composeDocument();
        }

        ///Get single YAML document, throwing if there is more than one document.
        Node getSingleNode() @trusted
        {
            assert(!parser_.checkEvent(EventID.StreamEnd), 
                   "Trying to get a node from Composer when there is no node to "
                   "get. use checkNode() to determine if there is a node.");

            Node document = composeDocument();
            
            //Ensure that the stream contains no more documents.
            enforce(parser_.checkEvent(EventID.StreamEnd),
                    new ComposerException("Expected single document in the stream, "
                                          "but found another document.",
                                          parser_.getEvent().startMark));

            //Drop the STREAM-END event.
            parser_.getEvent();

            return document;
        }

    private:
        ///Compose a YAML document and return its root node.
        Node composeDocument() @trusted
        {
            //Drop the DOCUMENT-START event.
            parser_.getEvent();

            //Compose the root node.
            Node node = composeNode();

            //Drop the DOCUMENT-END event.
            parser_.getEvent();

            clear(anchors_);
            return node;
        }

        ///Compose a node.
        Node composeNode() @system
        {
            if(parser_.checkEvent(EventID.Alias))
            {
                immutable event = parser_.getEvent();
                const anchor = event.anchor;
                enforce((anchor in anchors_) !is null,
                        new ComposerException("Found undefined alias: " ~ anchor.get,
                                              event.startMark));

                //If the node referenced by the anchor is uninitialized,
                //it's not finished, i.e. we're currently composing it
                //and trying to use it recursively here.
                enforce(anchors_[anchor] != Node(),
                        new ComposerException("Found recursive alias: " ~ anchor.get,
                                              event.startMark));

                return anchors_[anchor];
            }

            immutable event = parser_.peekEvent();
            const anchor = event.anchor;
            if(!anchor.isNull() && (anchor in anchors_) !is null)
            {
                throw new ComposerException("Found duplicate anchor: " ~ anchor.get, 
                                            event.startMark);
            }

            Node result;
            //Associate the anchor, if any, with an uninitialized node.
            //used to detect duplicate and recursive anchors.
            if(!anchor.isNull())
            {
                anchors_[anchor] = Node();
            }

            if(parser_.checkEvent(EventID.Scalar))
            {
                result = composeScalarNode();
            }
            else if(parser_.checkEvent(EventID.SequenceStart))
            {
                result = composeSequenceNode();
            }
            else if(parser_.checkEvent(EventID.MappingStart))
            {
                result = composeMappingNode();
            }
            else{assert(false, "This code should never be reached");}

            if(!anchor.isNull())
            {
                anchors_[anchor] = result;
            }
            return result;
        }

        ///Compose a scalar node.
        Node composeScalarNode() @system
        {
            immutable event = parser_.getEvent();
            const tag = resolver_.resolve(NodeID.Scalar, event.tag, event.value, 
                                          event.implicit);

            Node node = constructor_.node(event.startMark, event.endMark, tag, 
                                          event.value, event.scalarStyle);

            return node;
        }

        ///Compose a sequence node.
        Node composeSequenceNode() @system
        {
            immutable startEvent = parser_.getEvent();
            const tag = resolver_.resolve(NodeID.Sequence, startEvent.tag, null, 
                                          startEvent.implicit);

            while(!parser_.checkEvent(EventID.SequenceEnd))
            {
                nodeAppender_.put(composeNode());
            }

            core.memory.GC.disable();
            scope(exit){core.memory.GC.enable();}
            Node node = constructor_.node(startEvent.startMark, parser_.getEvent().endMark, 
                                          tag, nodeAppender_.data.dup, startEvent.collectionStyle);
            nodeAppender_.clear();

            return node;
        }

        /**
         * Flatten a node, merging it with nodes referenced through YAMLMerge data type.
         *
         * Node must be a mapping or a sequence of mappings.
         *
         * Params:  root      = Node to flatten.
         *          startMark = Start position of the node.
         *          endMark   = End position of the node.
         *
         * Returns: Flattened mapping as pairs.
         */
        Node.Pair[] flatten(ref Node root, const Mark startMark, const Mark endMark) @system
        {
            void error(Node node)
            {
                //this is Composer, but the code is related to Constructor.
                throw new ConstructorException("While constructing a mapping, "
                                               "expected a mapping or a list of "
                                               "mappings for merging, but found: " 
                                               ~ node.type.toString() ~
                                               " NOTE: line/column shows topmost parent "
                                               "to which the content is being merged",
                                               startMark, endMark);
            }


            if(root.isMapping)
            {
                Node[] toMerge;
                foreach(ref Node key, ref Node value; root)
                {
                    if(key.isType!YAMLMerge){toMerge ~= value;}
                    else
                    {
                        auto temp = Node.Pair(key, value);
                        merge(pairAppender_, temp);
                    }
                }
                foreach(node; toMerge)
                {
                    merge(pairAppender_, flatten(node, startMark, endMark));
                }
            }
            //Must be a sequence of mappings.
            else if(root.isSequence) foreach(ref Node node; root)
            {
                if(!node.isType!(Node.Pair[])){error(node);}
                merge(pairAppender_, flatten(node, startMark, endMark));
            }
            else
            {
                error(root);
            }

            core.memory.GC.disable();
            scope(exit){core.memory.GC.enable();}
            auto flattened = pairAppender_.data.dup;
            pairAppender_.clear();

            return flattened;
        }

        ///Compose a mapping node.
        Node composeMappingNode() @system
        {
            immutable startEvent = parser_.getEvent();
            const tag = resolver_.resolve(NodeID.Mapping, startEvent.tag, null, 
                                          startEvent.implicit);

            Tuple!(Node, Mark)[] toMerge;
            while(!parser_.checkEvent(EventID.MappingEnd))
            {
                auto pair = Node.Pair(composeNode(), composeNode());

                //Need to flatten and merge the node referred by YAMLMerge.
                if(pair.key.isType!YAMLMerge)
                {
                    toMerge ~= tuple(pair.value, cast(Mark)parser_.peekEvent().endMark);
                }
                //Not YAMLMerge, just add the pair.
                else
                {
                    merge(pairAppender_, pair);
                }
            }
            foreach(node; toMerge)
            {
                merge(pairAppender_, flatten(node[0], startEvent.startMark, node[1]));
            }

            core.memory.GC.disable();
            scope(exit){core.memory.GC.enable();}
            Node node = constructor_.node(startEvent.startMark, parser_.getEvent().endMark, 
                                          tag, pairAppender_.data.dup, startEvent.collectionStyle);

            pairAppender_.clear();
            return node;
        }
}
