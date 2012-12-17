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
    /// Set sound effects volume. Must be from inverval <0.0, 1.0> .
    void setSoundVolume(const float volume);

    /// Start playing a sound effect.
    ///
    /// Params:  name   = VFS file name of the sound to play.
    ///                   Only OGG vorbis and WAV files are guaranteed to be supported.
    ///          volume = Relative volume of the sound effect. 
    ///                   Must be from interval <0.0, 1.0>.
    ///
    /// If the sound could not be played (e.g. because it couldn't be loaded)
    /// it will be silently ignored.
    void playSound(string name, const float volume);

    /// Set music volume. Must be from inverval <0.0, 1.0> .
    void setMusicVolume(const float volume);

    /// Start playing a music track.
    /// 
    /// Params:  name   = VFS file name of the music track to play.
    ///                   Only OGG vorbis files are guaranteed to be supported.
    ///          repeat = Should the music track repeat infinitely?
    ///         
    /// Throws: MusicInitException if the music file was not found,
    ///         was corrupted, or in unsupported format.
    void playMusic(string name, Flag!"repeat" repeat = Yes.repeat);

    /// Halt the currently played music track, if any.
    void haltMusic();
}
