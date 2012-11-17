//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Sound system backend based on SDL Mixer.
module audio.sdlmixersoundsystem;


import std.conv;
import std.stdio;
import std.string;
import std.typecons;

import derelict.sdl.mixer;
import derelict.sdl.sdl;
import derelict.util.exception;
import dgamevfs._;

import audio.soundsystem;
import memory.memory;


/// Sound system backend based on SDL Mixer.
class SDLMixerSoundSystem : SoundSystem
{
private:
    // Game directory to load sounds from.
    VFSDir gameDir_;

    // Is the sound system disabled? (Used if it failed to initialize).
    bool disabled_ = false;

    /// Currently played music track, if any.
    Mix_Music* music_   = null;
    /// Buffer holding currently played music track, if any.
    void[] musicBuffer_ = null;
    /// SDL_RWops providing SDL Mixer with access to currently played music track, if any.
    SDL_RWops* musicRW_ = null;

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
    }

    /// Destroy the SDLMixerSoundSystem, freeing resources.
    ~this()
    {
        if(disabled_){return;}
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
