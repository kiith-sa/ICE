//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Sound system backend based on SDL Mixer.
module audio.sdlmixersoundsystem;


import std.conv;
import std.math;
import std.stdio;
import std.string;
import std.typecons;

import derelict.sdl.mixer;
import derelict.sdl.sdl;
import derelict.util.exception;
import dgamevfs._;

import audio.soundsystem;
import containers.vector;
import memory.memory;


/// Sound system backend based on SDL Mixer.
class SDLMixerSoundSystem : SoundSystem
{
private:
    // Game directory to load sounds from.
    VFSDir gameDir_;

    // Is the sound system disabled? (Used if it failed to initialize).
    bool disabled_ = false;

    // Currently played music track, if any.
    Mix_Music* music_   = null;
    // Buffer holding currently played music track, if any.
    void[] musicBuffer_ = null;
    // SDL_RWops providing SDL Mixer with access to currently played music track, if any.
    SDL_RWops* musicRW_ = null;

    // Currently loaded sounds.
    Vector!Sound sounds_;

public:
    /// Construct a SDLMixerSoundSystem loading sounds from specified library.
    this(VFSDir gameDir)
    {
        gameDir_ = gameDir;
        // Load the library.
        try
        {
            DerelictSDLMixer.load();
        }
        catch(DerelictException e)
        {
            writeln("SDL Mixer libary could not be loaded: ", e.msg);
            writeln("Sound will be disabled");
            disabled_ = true;
        }
        // Initialize SDL Mixer audio.
        if(Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 4096) == -1) 
        {
            writeln("SDLMixerSoundSystem failed to initialize: ",
                    Mix_GetError());
            writeln("Sound will be disabled");
            disabled_ = true;
        }
        // It might be useful to set this in a config file.
        Mix_AllocateChannels(80);
    }

    /// Destroy the SDLMixerSoundSystem, freeing resources.
    ~this()
    {
        if(disabled_){return;}
        // Stop all sound effects, then delete them.
        Mix_HaltChannel(-1);
        foreach(ref sound; sounds_)
        {
            sound.destroy();
        }
        // Free currently playing track, if any.
        if(music_ !is null)
        {
            free(musicBuffer_);
            SDL_FreeRW(musicRW_);
            Mix_HaltMusic();
            Mix_FreeMusic(music_);
            music_ = null;
        }
        // Deinitialize SDL Mixer, and unload it.
        Mix_CloseAudio();
        DerelictSDLMixer.unload();
    }

    override void setSoundVolume(const float volume)
    {
        if(disabled_){return;}
        assert(volume >= 0.0f && volume <= 1.0f, 
               "Can't set sound volume outside the 0.0-1.0 range");
        Mix_Volume(-1, cast(int)(volume * MIX_MAX_VOLUME));
    }

    override void playSound(string name, const float volume)
    {
        if(disabled_){return;}
        assert(volume >= 0.0f && volume <= 1.0f, 
               "Can't play sound with volume outside the 0.0-1.0 range");
        // Look if we've already loaded this sound, and play if found.
        foreach(ref sound; sounds_) if(sound.name == name)
        {
            sound.setVolume(volume);
            sound.play();
            return;
        }
        // The sound is being played for the first time. Load it and play.
        sounds_ ~= Sound(gameDir_, name);
        sounds_[sounds_.length - 1].setVolume(volume);
        sounds_[sounds_.length - 1].play();
    }

    override void setMusicVolume(const float volume)
    {
        if(disabled_){return;}
        assert(volume >= 0.0f && volume <= 1.0f, 
               "Can't set music volume outside the 0.0-1.0 range");
        Mix_VolumeMusic(cast(int)(volume * MIX_MAX_VOLUME));
    }

    override void playMusic(string name, Flag!"repeat" repeat)
    {
        if(disabled_){return;}
        // If a music track is already being played, delete it.
        if(music_ !is null)
        {
            free(musicBuffer_);
            SDL_FreeRW(musicRW_);
            Mix_HaltMusic();
            Mix_FreeMusic(music_);
            music_ = null;
        }
        try
        {
            // Load the new track from file.
            auto musicFile = gameDir_.file(name);
            if(!musicFile.exists)
            {
                throw new MusicInitException("Music file does not exist: " ~ name);
            }
            const bytes = musicFile.bytes;
            musicBuffer_ = cast(void[])allocArray!ubyte(cast(uint)bytes);
            scope(failure) {free(musicBuffer_);}
            const bytesRead = musicFile.input.read(musicBuffer_).length;
            if(bytesRead != bytes)
            {
                const msg = "Could not load music " ~ name ~
                            ": couldn't read the entire file";
                throw new MusicInitException(msg);
            }

            // Provide SDL Mixer with access to the track.
            musicRW_ = SDL_RWFromMem(musicBuffer_.ptr, cast(int)bytes);
            scope(failure) {SDL_FreeRW(musicRW_);}
            music_ = Mix_LoadMUS_RW(musicRW_);

            if(music_ is null)
            {
                const msg = "Failed to load music " ~ name ~ ": " ~ to!string(Mix_GetError());
                throw new MusicInitException(msg);
            }
            Mix_PlayMusic(music_, repeat ? -1 : 0);
        }
        catch(VFSException e)
        {
            throw new MusicInitException
                ("Could not load music " ~ name ~ ": " ~ e.msg);
        }
    }

    override void haltMusic()
    {
        if(disabled_){return;}
        Mix_HaltMusic();
    }
}

/// Handles storage and playing of a single sound sample.
private struct Sound
{
private:
    // Name of the sample (VFS address of the file).
    string name_;

    // SDL_Mixer sound chunk storing the sample.
    Mix_Chunk* soundChunk_;

    // Currently set volume of this sample.
    float currentVolume_ = -1.0f;

    // Buffer storing the (undecoded) sound data loaded from a file.
    void[] soundBuffer_ = null;

    // SDL_RWops providing SDL Mixer with access to the sound.
    SDL_RWops* soundRW_ = null;

public:
    /// Construct a Sound.
    ///
    /// Params:  gameDir = Game data directory.
    ///          name    = VFS name of the sound file.
    ///
    /// If there is an error, it will be printed to stdout and a dummy sound 
    /// object that will not play anything will be loaded.
    this(VFSDir gameDir, const string name)
    {
        name_ = name;
        // If the sound fails to load, the sound struct will 
        // exist, it just won't play anything.
        void fallback(const string msg)
        {
            writeln("Failed to load sound: ", name);
            writeln("Cause: ", msg);
            writeln("The sound will be disabled");
            if(soundBuffer_ !is null) 
            {
                free(soundBuffer_);
                soundBuffer_ = null;
            }
            if(soundRW_ !is null)
            {
                SDL_FreeRW(soundRW_);
                soundRW_ = null;
            }
            return;
        }

        // Load sound data from a file.
        auto soundFile = gameDir.file(name);
        if(!soundFile.exists)
        {
            fallback("Sound file does not exist");
            return;
        }
        const bytes = soundFile.bytes;
        soundBuffer_ = cast(void[])allocArray!ubyte(cast(uint)bytes);
        const bytesRead = soundFile.input.read(soundBuffer_).length;
        if(bytesRead != bytes)
        {
            fallback("Couldn't read the entire file");
            return;
        }

        // Provide SDL Mixer with access to the data.
        soundRW_    = SDL_RWFromMem(soundBuffer_.ptr, cast(int)bytes);
        soundChunk_ = Mix_LoadWAV_RW(soundRW_, 0);

        if(soundChunk_ is null)
        {
            fallback(to!string(Mix_GetError()));
            return;
        }
        setVolume(1.0f);
    }

    /// Set volume of the sample. Must be from inverval <0.0, 1.0> .
    void setVolume(const float volume)
    {
        // Don't call SDL mixer for changes too small to notice, or if the 
        // sound wasn't loaded successfully.
        if(soundChunk_ is null || abs(currentVolume_ - volume) < 1.0f / MIX_MAX_VOLUME)
        {
            return;
        }
        Mix_VolumeChunk(soundChunk_, cast(int)(MIX_MAX_VOLUME * volume));
        currentVolume_ = volume;
    }

    /// Play the sample once.
    void play()
    {
        if(soundChunk_ is null){return;}
        // -1: first free channel, 0: play once
        if(Mix_PlayChannel(-1, soundChunk_, 0) == -1)
        {
            writeln("Error playing sound: ", name_);
        }
    }

    /// Destroy this sound. Must be called to deallocate sound data.
    ///
    /// The sound must not be playing when this is called.
    /// (Use Mix_HaltChannel(-1) to halt all sound.)
    void destroy()
    {
        // Don't destroy if the sound failed to load.
        if(soundChunk_ is null){return;}
        free(soundBuffer_);
        SDL_FreeRW(soundRW_);
        Mix_FreeChunk(soundChunk_);
    }

    /// Get the name of the sound sample.
    @property const(string) name() const pure nothrow {return name_;}
}
