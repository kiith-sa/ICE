
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Records which parts of a frame took how much time.
module util.frameprofiler;

import std.algorithm;
import std.conv;
import std.stdio;

import time.time;


/**
 * Pause recording of profiling data.
 *
 * Frames after this call won't be recorded - but their IDs (frame numbers) will
 * still be incremented.
 * 
 * This can only be called outside of a frame. 
 */
void frameProfilerPause()
{
    assert(currentZoneLevel_ == 0, "Can't pause frame profiler while recording a frame");
    // Already stopped, or, not even profiling - don't bother pausing.
    if(state_ == FrameProfilerState.Stopped || 
       state_ == FrameProfilerState.Uninitialized)
    {
        return;
    }
    state_ = FrameProfilerState.Paused;
}

/**
 * Resume recording of profiling data.
 * 
 * This can only be called outside of a frame.
 */
void frameProfilerResume()
{
    assert(currentZoneLevel_ == 0, "Can't resume frame profiler while recording a frame");
    // Already stopped, or, not even profiling - don't bother resuming.
    if(state_ == FrameProfilerState.Stopped || 
       state_ == FrameProfilerState.Uninitialized)
    {
        return;
    }
    state_ = FrameProfilerState.Recording;
}

/**
 * Single frame during a game run. Records time at construction and destruction.
 * Keeps track of all zones within a frame, and frame number.
 */
struct Frame
{
    /**
     * Construct a frame, recording its start time, ID, etc.
     *
     * If frameProfilerInit has not been called, this is a noop.
     *
     * Params:  frameInfo = String with information (e.g. name) about the frame.
     *                      This is useful when parsing profile dumps later.
     */
    this(string frameInfo)
    {
        ++frameID_;

        // Frame skipping.
        if(state_ == FrameProfilerState.Recording || 
           state_ == FrameProfilerState.SkippedFrame)
        {
            state_ = (frameID_ % (1 + frameSkip_) != 0) ? FrameProfilerState.SkippedFrame
                                                        : FrameProfilerState.Recording;
        }

        if(unableToRecord()) {return;}

        assert(currentZoneLevel_ == 0, "Starting a frame when we're already in a frame'");
        ++currentZoneLevel_;

        // Initialize frame in storage.
        with(frames_[recordedFrameCount_])
        {
            start = getTime();
            zoneOffset = recordedZoneCount_;
            frameID = frameID_;
            const charCount = min(frameInfo.length, info.length);
            info[0 .. charCount] = frameInfo[0 .. charCount];
            infoBytes = cast(ubyte)charCount;
        }
    }

    /// Destroy/exit the frame, recording time when it ends.
    ~this()
    {
        if(unableToRecord()) {return;}
        assert(currentZoneLevel_ == 1, "Ending a frame before exiting all zones");
        frames_[recordedFrameCount_].end = getTime();
        --currentZoneLevel_;
        ++recordedFrameCount_;
    }
}

/**
 * Zone in profiled code. Records high precision time at construction
 * and destruction. Zones can also be nested.
 *
 * A zone must be fully contained within either a frame or a parent zone.
 * I.e. it must be destroyed before its parent is destroyed.
 */
struct Zone
{
    private:
        /// Index of the stored zone in the zones_ array.
        ///
        /// That is where recorded data is stored.
        uint zoneIndex_;

    public:
        /**
         * Construct a zone, recording its start time.
         *
         * If frameProfilerInit has not been called this is a noop.
         *
         * Params:  zoneInfo = String with information (e.g. name) about the zone.
         *                     This is useful when parsing profile dumps later.
         */
        this(string zoneInfo)
        {
            if(unableToRecord()) {return;}
            assert(currentZoneLevel_ >= 1, "Zone outside of a frame");

            ++currentZoneLevel_;
            zoneIndex_ = recordedZoneCount_;
            assert(currentZoneLevel_ < zoneStack_.length, "Too deep zone nesting");
            zoneStack_[currentZoneLevel_] = zoneIndex_;

            // Initialize zone in storage.
            with(zones_[zoneIndex_])
            {
                start = getTime();
                // zoneStack_[1] is uint.max - topmost zones in a frame 
                // don't have a parent
                parent = zoneStack_[currentZoneLevel_ - 1];
                const charCount = min(zoneInfo.length, info.length);
                info[0 .. charCount] = zoneInfo[0 .. charCount];
                infoBytes = cast(ubyte)charCount;
            }
            ++recordedZoneCount_;
            ++frames_[recordedFrameCount_].zoneCount;
        }

        /// Destroy a zone, recording its end time and exiting it.
        ~this()
        {
            if(unableToRecord()) {return;}
            zones_[zoneIndex_].end = getTime();
            assert(zones_[zoneIndex_].parent == zoneStack_[currentZoneLevel_ - 1],
                   "A child zone (" ~ zones_[zoneIndex_].info ~ 
                   ") appears not to be entirely contained in its parent zone");
            --currentZoneLevel_;
        }
}

/**
 * Initialize/enable frame profiler, provifing memory to store profile data.
 * 
 * If this is not called, any Zones/Frames and other frame profiler calls 
 * are noops, except for frameProfilerDump(), which must not be called.
 *
 * Params: storage   = Memory for the profiler to use to accumulate profile 
 *                     data. This must NOT be deallocated for as long as any 
 *                     FrameProfiler functions/classes are being used.
 *                     When FrameProfiler runs out of this space, it stops
 *                     recording profile data.
 *         frameSkip = Number of frames to skip between each recorded frame.
 *                     For example, frameSkip 1 will result in every second 
 *                     frame being recorded. Can be used to limit profiler 
 *                     overhead and memory usage.
 */
void frameProfilerInit(ubyte[] storage, const uint frameSkip = 0)
{
    assert(state_ == FrameProfilerState.Uninitialized, 
           "Frame profiler is already initialized");
    state_ = FrameProfilerState.Recording;
    // Frames take ~5% of storage, zones ~95%.
    // We use a bit less and align thanks to integer division.
    const size_t frameCap = (storage.length / 20 * 1) / FrameStorage.sizeof;
    const size_t zoneCap  = (storage.length / 20 * 19) / ZoneStorage.sizeof;

    const size_t frameBytes = frameCap * FrameStorage.sizeof;
    const size_t zoneBytes  = zoneCap  * ZoneStorage.sizeof;

    frames_    = cast(FrameStorage[])(storage[0 .. frameBytes]);
    zones_     = cast(ZoneStorage[])(storage[frameBytes .. frameBytes + zoneBytes]);
    frameSkip_ = frameSkip;
}

/**
 * Dump recorded profile data.
 *
 * This will dump in a human-readable YAML based format.
 *
 * Can only be called if frameProfilerInit was called before.
 *
 * Params: dumpLine = This is called once for every output line. The passed
 *                    string will NOT end with a newline - the function will 
 *                    have to add it itself, if needed.
 *
 * Example:
 * --------------------
 * // Dump into stdout
 * frameProfilerDump(void(string str){writeln(str);});
 * --------------------
 */
void frameProfilerDump(void delegate(string) dumpLine)
{
    assert(state_ != FrameProfilerState.Uninitialized, 
           "Frame profiler is not initialized");
    dumpLine("frames:");
    char [4 * zoneStack_.length + 256] spaceStorage;
    spaceStorage[] = ' ';
    string spaces = cast(string)spaceStorage[0 .. $];

    foreach(ref frame; frames_[0 .. recordedFrameCount_])
    {
        dumpLine(spaces[0 .. 2] ~ "- id: "     ~ to!string(frame.frameID));
        dumpLine(spaces[0 .. 4] ~ "start: "    ~ to!string(frame.start));
        dumpLine(spaces[0 .. 4] ~ "end: "      ~ to!string(frame.end));
        dumpLine(spaces[0 .. 4] ~ "duration: " ~ 
                 to!string((frame.end - frame.start) * 1000.0) ~ "ms");
        dumpLine(spaces[0 .. 4] ~ "frame: "    ~ 
                 cast(string)(frame.info[0 .. frame.infoBytes]));
        //dumpLine(spaces[0 .. 2] ~ "zones:");

        if(frame.zoneCount == 0)
        {
            continue;
        }

        // Zones of this frame.
        const zones = zones_[frame.zoneOffset .. frame.zoneOffset + frame.zoneCount];

        // This is _extremely_ inefficient.
        // If profile dumping is too slow, use a better algorithm.
        void dumpZones(const size_t parent, const size_t indent)
        {
            bool found = false;

            // Find all zones with specified parent.
            // If any zones at all are found, we start the "zones: " sequence.
            // Then we dump the found zones, and recursively look for their children.
            foreach(z, ref zone; zones)
            {
                if(zone.parent != parent) {continue;}
                if(!found)
                {
                    found = true;
                    dumpLine(spaces[0 .. indent] ~ "zones:");
                }
                dumpLine(spaces[0 .. indent + 2] ~ "- zone: "   ~
                         cast(string)zone.info[0 .. zone.infoBytes]);
                dumpLine(spaces[0 .. indent + 4] ~ "start: "    ~ to!string(zone.start));
                dumpLine(spaces[0 .. indent + 4] ~ "end: "      ~ to!string(zone.end));
                dumpLine(spaces[0 .. indent + 4] ~ "duration: " ~ 
                         to!string((zone.end - zone.start) * 1000.0) ~ "ms");

                dumpZones(frame.zoneOffset + z, indent + 4);
            }
        }

        dumpZones(uint.max, 4);
    }
}

/// End frame profiler execution, returning it to state before frameProfilerInit().
///
/// The user is responsible for deleting any storage it passed 
/// to the frame profiler.
void frameProfilerEnd()
{
    frameSkip_          = 0;
    currentZoneLevel_   = 0;
    state_              = FrameProfilerState.Uninitialized;
    zoneStack_[]        = uint.max;
    frameID_            = 0;
    recordedFrameCount_ = 0;
    recordedZoneCount_  = 0;
    frames_             = null;
    zones_              = null;
}

private:

//64 bytes
struct ZoneStorage
{
    double start;
    double end;
    uint  parent;
    char[43] info;
    ubyte infoBytes;
    static assert(ZoneStorage.sizeof == 64, "Unexpected size of ZoneStorage");
}

//64 bytes
struct FrameStorage
{
    double start;
    double end;
    //first zone in zones array
    uint zoneOffset;
    //number of zones in frame
    uint zoneCount;


    //First frame is 0, second 1, etc...
    //This might not be consecutive if frame skipping is enabled.
    uint frameID;

    char[35] info;
    ubyte infoBytes;
    static assert(FrameStorage.sizeof == 64, "Unexpected size of FrameStorage");
}

// How many frames are skipped between each recorded frame?
//
// If 0, each frame is recorded. If 1, every second frame is recorded, etc.
uint frameSkip_ = 0;

// Nesting level of the current zone.
//
// When not in a frame, this is 0. When in a frame, but not yet in any zone, it
// is 1.  In the first zone it is 2, etc. .
uint currentZoneLevel_ = 0;

// Stack of all zones we currently are in.
//
// uint.max means that there is no zone on this level;
// for instance; level 0 is nothing and level 1 is the frame.
//
// This is used to keep track of parents of the current zone.
// With that, we can verify that zones are correctly nested.
uint[256] zoneStack_ = uint.max;

// ID (number) of the current frame. 
//
// 1 for the first frame, 2 for the second, etc. .
// This is correct even if frames are skipped, 
uint frameID_ = 0;

// Possible states the frame profiler might be in.
enum FrameProfilerState
{
    // frameProfilerInit() has not yet been caled. 
    //
    // Any frame profiler calls are noops at this point.
    Uninitialized,
    // Recording profile data.
    //
    // We're in this state after a call to frameProfilerInit() 
    // and any subsequent calls to frameProfilerResume().
    Recording,
    // In a skipped frame while recording profile data.
    //
    // We're in this state when frameSkip_ is nonzero and we're skipping the
    // current frame.
    SkippedFrame,
    // Paused recording. 
    //
    // We're in this state after frameProfilerPause() is called 
    // (unless we were Uninitialized/Stopped before the call - then
    // frameProfilerPause() has no effect).
    Paused,
    // Recording stopped permanently.
    //
    // We're in this state after we run out of memory provided by the 
    // frameProfilerInit() call.
    Stopped
}

// Current state of the frame profiler.
FrameProfilerState state_ = FrameProfilerState.Uninitialized;

// Number of frames recorded so far.
uint recordedFrameCount_ = 0;

// Number of zones recorded so far.
uint recordedZoneCount_ = 0;

// Storage for recorded frames. Provided by the user in frameProfilerInit().
FrameStorage[] frames_ = null;
// Storage for recorded zones. Provided by the user in frameProfilerInit().
ZoneStorage[] zones_   = null;

// Are we unable to record at the moment?
//
// We are only able to record when we're in the Recording state and have enough 
// space to store new frames/zones.
bool unableToRecord()
{
    // Not initialized, paused, stopped or skipping a frame - either way, not recording.
    if(state_ != FrameProfilerState.Recording) {return true;}
    // Ran out of space.
    if(recordedFrameCount_ >= frames_.length || recordedZoneCount_ >= zones_.length)
    {
        writeln("FrameProfiler stopped; out of allocated memory");
        state_ = FrameProfilerState.Stopped;
        return true;
    }
    assert(frames_ !is null && zones_ !is null, 
           "Frame profiler is running but frames_ and/or zones_ are not initialized");
    return false;
}
