//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Sound system API.
module audio.soundsystem;


import std.typecons;


/// Base class for sound related exceptions.
class SoundException : Exception 
{
    public this(string msg, string file = __FILE__, int line = __LINE__)
    {
        super(msg, file, line);
    }
}

/// Thrown when music fails to load.
class MusicInitException : SoundException 
{
    public this(string msg, string file = __FILE__, int line = __LINE__)
    {
        super(msg, file, line);
    }
}

/// Base class for all sound system classes.
///
/// A sound system handles sound and music playback, volume control, etc.
abstract class SoundSystem
{
public:
    /// Set music volume. Must be at from inverval <0.0, 1.0> .
    void setMusicVolume(const float volume);

    /// Start playing a music track.
    /// 
    /// Params:  name   = VFS file name of the music track to play.
    ///          repeat = Should the music track repeat infinitely?
    ///         
    /// Throws: MusicInitException if the music file was not found,
    ///         was corrupted, or in unsupported format.
    void playMusic(string name, Flag!"repeat" repeat = Yes.repeat);

    /// Halt the currently played music track, if any.
    void haltMusic();
}
