/*
 * Copyright (c) 2004-2009 Derelict Developers
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * * Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * * Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 *
 * * Neither the names 'Derelict', 'DerelictSDL', nor the names of its contributors
 *   may be used to endorse or promote products derived from this software
 *   without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
module derelict.sdl.sdlfuncs;

private
{
    import derelict.util.loader;
    import derelict.sdl.sdltypes;

    version(Tango)
    {
        import tango.stdc.stdio;
    }
    else
    {
        import std.c.stdio;
    }
}

private void load(SharedLib lib)
{
    // active.d
    bindFunc(SDL_GetAppState)("SDL_GetAppState", lib);
    // audio.d
    bindFunc(SDL_AudioInit)("SDL_AudioInit", lib);
    bindFunc(SDL_AudioQuit)("SDL_AudioQuit", lib);
    bindFunc(SDL_AudioDriverName)("SDL_AudioDriverName", lib);
    bindFunc(SDL_OpenAudio)("SDL_OpenAudio", lib);
    bindFunc(SDL_GetAudioStatus)("SDL_GetAudioStatus", lib);
    bindFunc(SDL_PauseAudio)("SDL_PauseAudio", lib);
    bindFunc(SDL_LoadWAV_RW)("SDL_LoadWAV_RW", lib);
    bindFunc(SDL_FreeWAV)("SDL_FreeWAV", lib);
    bindFunc(SDL_BuildAudioCVT)("SDL_BuildAudioCVT", lib);
    bindFunc(SDL_ConvertAudio)("SDL_ConvertAudio", lib);
    bindFunc(SDL_MixAudio)("SDL_MixAudio", lib);
    bindFunc(SDL_LockAudio)("SDL_LockAudio", lib);
    bindFunc(SDL_UnlockAudio)("SDL_UnlockAudio", lib);
    bindFunc(SDL_CloseAudio)("SDL_CloseAudio", lib);
    // cdrom.d
    bindFunc(SDL_CDNumDrives)("SDL_CDNumDrives", lib);
    bindFunc(SDL_CDName)("SDL_CDName", lib);
    bindFunc(SDL_CDOpen)("SDL_CDOpen", lib);
    bindFunc(SDL_CDStatus)("SDL_CDStatus", lib);
    bindFunc(SDL_CDPlayTracks)("SDL_CDPlayTracks", lib);
    bindFunc(SDL_CDPlay)("SDL_CDPlay", lib);
    bindFunc(SDL_CDPause)("SDL_CDPause", lib);
    bindFunc(SDL_CDResume)("SDL_CDResume", lib);
    bindFunc(SDL_CDStop)("SDL_CDStop", lib);
    bindFunc(SDL_CDEject)("SDL_CDEject", lib);
    bindFunc(SDL_CDClose)("SDL_CDClose", lib);
    // cpuinfo.d
    bindFunc(SDL_HasRDTSC)("SDL_HasRDTSC", lib);
    bindFunc(SDL_HasMMX)("SDL_HasMMX", lib);
    bindFunc(SDL_HasMMXExt)("SDL_HasMMXExt", lib);
    bindFunc(SDL_Has3DNow)("SDL_Has3DNow", lib);
    bindFunc(SDL_Has3DNowExt)("SDL_Has3DNowExt", lib);
    bindFunc(SDL_HasSSE)("SDL_HasSSE", lib);
    bindFunc(SDL_HasSSE2)("SDL_HasSSE2", lib);
    bindFunc(SDL_HasAltiVec)("SDL_HasAltiVec", lib);
    // error.d
    bindFunc(SDL_SetError)("SDL_SetError", lib);
    bindFunc(SDL_GetError)("SDL_GetError", lib);
    bindFunc(SDL_ClearError)("SDL_ClearError", lib);
    // events.d
    bindFunc(SDL_PumpEvents)("SDL_PumpEvents", lib);
    bindFunc(SDL_PeepEvents)("SDL_PeepEvents", lib);
    bindFunc(SDL_PollEvent)("SDL_PollEvent", lib);
    bindFunc(SDL_WaitEvent)("SDL_WaitEvent", lib);
    bindFunc(SDL_PushEvent)("SDL_PushEvent", lib);
    bindFunc(SDL_SetEventFilter)("SDL_SetEventFilter", lib);
    bindFunc(SDL_GetEventFilter)("SDL_GetEventFilter", lib);
    bindFunc(SDL_EventState)("SDL_EventState", lib);
    // joystick.d
    bindFunc(SDL_NumJoysticks)("SDL_NumJoysticks", lib);
    bindFunc(SDL_JoystickName)("SDL_JoystickName", lib);
    bindFunc(SDL_JoystickOpen)("SDL_JoystickOpen", lib);
    bindFunc(SDL_JoystickOpened)("SDL_JoystickOpened", lib);
    bindFunc(SDL_JoystickIndex)("SDL_JoystickIndex", lib);
    bindFunc(SDL_JoystickNumAxes)("SDL_JoystickNumAxes", lib);
    bindFunc(SDL_JoystickNumBalls)("SDL_JoystickNumBalls", lib);
    bindFunc(SDL_JoystickNumHats)("SDL_JoystickNumHats", lib);
    bindFunc(SDL_JoystickNumButtons)("SDL_JoystickNumButtons", lib);
    bindFunc(SDL_JoystickUpdate)("SDL_JoystickUpdate", lib);
    bindFunc(SDL_JoystickEventState)("SDL_JoystickEventState", lib);
    bindFunc(SDL_JoystickGetAxis)("SDL_JoystickGetAxis", lib);
    bindFunc(SDL_JoystickGetHat)("SDL_JoystickGetHat", lib);
    bindFunc(SDL_JoystickGetBall)("SDL_JoystickGetBall", lib);
    bindFunc(SDL_JoystickGetButton)("SDL_JoystickGetButton", lib);
    bindFunc(SDL_JoystickClose)("SDL_JoystickClose", lib);
    // keyboard.d
    bindFunc(SDL_EnableUNICODE)("SDL_EnableUNICODE", lib);
    bindFunc(SDL_EnableKeyRepeat)("SDL_EnableKeyRepeat", lib);
    bindFunc(SDL_GetKeyRepeat)("SDL_GetKeyRepeat", lib);
    bindFunc(SDL_GetKeyState)("SDL_GetKeyState", lib);
    bindFunc(SDL_GetModState)("SDL_GetModState", lib);
    bindFunc(SDL_SetModState)("SDL_SetModState", lib);
    bindFunc(SDL_GetKeyName)("SDL_GetKeyName", lib);
    // loadso.d
    bindFunc(SDL_LoadObject)("SDL_LoadObject", lib);
    bindFunc(SDL_LoadFunction)("SDL_LoadFunction", lib);
    bindFunc(SDL_UnloadObject)("SDL_UnloadObject", lib);
    // mouse.d
    bindFunc(SDL_GetMouseState)("SDL_GetMouseState", lib);
    bindFunc(SDL_GetRelativeMouseState)("SDL_GetRelativeMouseState", lib);
    bindFunc(SDL_WarpMouse)("SDL_WarpMouse", lib);
    bindFunc(SDL_CreateCursor)("SDL_CreateCursor", lib);
    bindFunc(SDL_SetCursor)("SDL_SetCursor", lib);
    bindFunc(SDL_GetCursor)("SDL_GetCursor", lib);
    bindFunc(SDL_FreeCursor)("SDL_FreeCursor", lib);
    bindFunc(SDL_ShowCursor)("SDL_ShowCursor", lib);
    // mutex.d
    bindFunc(SDL_CreateMutex)("SDL_CreateMutex", lib);
    bindFunc(SDL_mutexP)("SDL_mutexP", lib);
    bindFunc(SDL_mutexV)("SDL_mutexV", lib);
    bindFunc(SDL_DestroyMutex)("SDL_DestroyMutex", lib);
    bindFunc(SDL_CreateSemaphore)("SDL_CreateSemaphore", lib);
    bindFunc(SDL_DestroySemaphore)("SDL_DestroySemaphore", lib);
    bindFunc(SDL_SemWait)("SDL_SemWait", lib);
    bindFunc(SDL_SemTryWait)("SDL_SemTryWait", lib);
    bindFunc(SDL_SemWaitTimeout)("SDL_SemWaitTimeout", lib);
    bindFunc(SDL_SemPost)("SDL_SemPost", lib);
    bindFunc(SDL_SemValue)("SDL_SemValue", lib);
    bindFunc(SDL_CreateCond)("SDL_CreateCond", lib);
    bindFunc(SDL_DestroyCond)("SDL_DestroyCond", lib);
    bindFunc(SDL_CondSignal)("SDL_CondSignal", lib);
    bindFunc(SDL_CondBroadcast)("SDL_CondBroadcast", lib);
    bindFunc(SDL_CondWait)("SDL_CondWait", lib);
    bindFunc(SDL_CondWaitTimeout)("SDL_CondWaitTimeout", lib);
    // rwops.d
    bindFunc(SDL_RWFromFile)("SDL_RWFromFile", lib);
    bindFunc(SDL_RWFromFP)("SDL_RWFromFP", lib);
    bindFunc(SDL_RWFromMem)("SDL_RWFromMem", lib);
    bindFunc(SDL_RWFromConstMem)("SDL_RWFromConstMem", lib);
    bindFunc(SDL_AllocRW)("SDL_AllocRW", lib);
    bindFunc(SDL_FreeRW)("SDL_FreeRW", lib);
    bindFunc(SDL_ReadLE16)("SDL_ReadLE16", lib);
    bindFunc(SDL_ReadBE16)("SDL_ReadBE16", lib);
    bindFunc(SDL_ReadLE32)("SDL_ReadLE32", lib);
    bindFunc(SDL_ReadBE32)("SDL_ReadBE32", lib);
    bindFunc(SDL_ReadLE64)("SDL_ReadLE64", lib);
    bindFunc(SDL_ReadBE64)("SDL_ReadBE64", lib);
    bindFunc(SDL_WriteLE16)("SDL_WriteLE16", lib);
    bindFunc(SDL_WriteBE16)("SDL_WriteBE16", lib);
    bindFunc(SDL_WriteLE32)("SDL_WriteLE32", lib);
    bindFunc(SDL_WriteBE32)("SDL_WriteBE32", lib);
    bindFunc(SDL_WriteLE64)("SDL_WriteLE64", lib);
    bindFunc(SDL_WriteBE64)("SDL_WriteBE64", lib);
    // sdlversion.d
    bindFunc(SDL_Linked_Version)("SDL_Linked_Version", lib);
    // thread.d
    bindFunc(SDL_CreateThread)("SDL_CreateThread", lib);
    bindFunc(SDL_ThreadID)("SDL_ThreadID", lib);
    bindFunc(SDL_GetThreadID)("SDL_GetThreadID", lib);
    bindFunc(SDL_WaitThread)("SDL_WaitThread", lib);
    bindFunc(SDL_KillThread)("SDL_KillThread", lib);
    // timer.d
    bindFunc(SDL_GetTicks)("SDL_GetTicks", lib);
    bindFunc(SDL_Delay)("SDL_Delay", lib);
    bindFunc(SDL_SetTimer)("SDL_SetTimer", lib);
    bindFunc(SDL_AddTimer)("SDL_AddTimer", lib);
    bindFunc(SDL_RemoveTimer)("SDL_RemoveTimer", lib);
    // video.d
    bindFunc(SDL_VideoInit)("SDL_VideoInit", lib);
    bindFunc(SDL_VideoQuit)("SDL_VideoQuit", lib);
    bindFunc(SDL_VideoDriverName)("SDL_VideoDriverName", lib);
    bindFunc(SDL_GetVideoSurface)("SDL_GetVideoSurface", lib);
    bindFunc(SDL_GetVideoInfo)("SDL_GetVideoInfo", lib);
    bindFunc(SDL_VideoModeOK)("SDL_VideoModeOK", lib);
    bindFunc(SDL_ListModes)("SDL_ListModes", lib);
    bindFunc(SDL_SetVideoMode)("SDL_SetVideoMode", lib);
    bindFunc(SDL_UpdateRects)("SDL_UpdateRects", lib);
    bindFunc(SDL_UpdateRect)("SDL_UpdateRect", lib);
    bindFunc(SDL_Flip)("SDL_Flip", lib);
    bindFunc(SDL_SetGamma)("SDL_SetGamma", lib);
    bindFunc(SDL_SetGammaRamp)("SDL_SetGammaRamp", lib);
    bindFunc(SDL_GetGammaRamp)("SDL_GetGammaRamp", lib);
    bindFunc(SDL_SetColors)("SDL_SetColors", lib);
    bindFunc(SDL_SetPalette)("SDL_SetPalette", lib);
    bindFunc(SDL_MapRGB)("SDL_MapRGB", lib);
    bindFunc(SDL_MapRGBA)("SDL_MapRGBA", lib);
    bindFunc(SDL_GetRGB)("SDL_GetRGB", lib);
    bindFunc(SDL_GetRGBA)("SDL_GetRGBA", lib);
    bindFunc(SDL_CreateRGBSurface)("SDL_CreateRGBSurface", lib);
    bindFunc(SDL_CreateRGBSurfaceFrom)("SDL_CreateRGBSurfaceFrom", lib);
    bindFunc(SDL_FreeSurface)("SDL_FreeSurface", lib);
    bindFunc(SDL_LockSurface)("SDL_LockSurface", lib);
    bindFunc(SDL_UnlockSurface)("SDL_UnlockSurface", lib);
    bindFunc(SDL_LoadBMP_RW)("SDL_LoadBMP_RW", lib);
    bindFunc(SDL_SaveBMP_RW)("SDL_SaveBMP_RW", lib);
    bindFunc(SDL_SetColorKey)("SDL_SetColorKey", lib);
    bindFunc(SDL_SetAlpha)("SDL_SetAlpha", lib);
    bindFunc(SDL_SetClipRect)("SDL_SetClipRect", lib);
    bindFunc(SDL_GetClipRect)("SDL_GetClipRect", lib);
    bindFunc(SDL_ConvertSurface)("SDL_ConvertSurface", lib);
    bindFunc(SDL_UpperBlit)("SDL_UpperBlit", lib);
    bindFunc(SDL_LowerBlit)("SDL_LowerBlit", lib);
    bindFunc(SDL_FillRect)("SDL_FillRect", lib);
    bindFunc(SDL_DisplayFormat)("SDL_DisplayFormat", lib);
    bindFunc(SDL_DisplayFormatAlpha)("SDL_DisplayFormatAlpha", lib);
    bindFunc(SDL_CreateYUVOverlay)("SDL_CreateYUVOverlay", lib);
    bindFunc(SDL_LockYUVOverlay)("SDL_LockYUVOverlay", lib);
    bindFunc(SDL_UnlockYUVOverlay)("SDL_UnlockYUVOverlay", lib);
    bindFunc(SDL_DisplayYUVOverlay)("SDL_DisplayYUVOverlay", lib);
    bindFunc(SDL_FreeYUVOverlay)("SDL_FreeYUVOverlay", lib);
    bindFunc(SDL_GL_LoadLibrary)("SDL_GL_LoadLibrary", lib);
    bindFunc(SDL_GL_GetProcAddress)("SDL_GL_GetProcAddress", lib);
    bindFunc(SDL_GL_SetAttribute)("SDL_GL_SetAttribute", lib);
    bindFunc(SDL_GL_GetAttribute)("SDL_GL_GetAttribute", lib);
    bindFunc(SDL_GL_SwapBuffers)("SDL_GL_SwapBuffers", lib);
    bindFunc(SDL_GL_UpdateRects)("SDL_GL_UpdateRects", lib);
    bindFunc(SDL_GL_Lock)("SDL_GL_Lock", lib);
    bindFunc(SDL_GL_Unlock)("SDL_GL_Unlock", lib);
    bindFunc(SDL_WM_SetCaption)("SDL_WM_SetCaption", lib);
    bindFunc(SDL_WM_GetCaption)("SDL_WM_GetCaption", lib);
    bindFunc(SDL_WM_SetIcon)("SDL_WM_SetIcon", lib);
    bindFunc(SDL_WM_IconifyWindow)("SDL_WM_IconifyWindow", lib);
    bindFunc(SDL_WM_ToggleFullScreen)("SDL_WM_ToggleFullScreen", lib);
    bindFunc(SDL_WM_GrabInput)("SDL_WM_GrabInput", lib);
    // sdl.d
    bindFunc(SDL_Init)("SDL_Init", lib);
    bindFunc(SDL_InitSubSystem)("SDL_InitSubSystem", lib);
    bindFunc(SDL_QuitSubSystem)("SDL_QuitSubSystem", lib);
    bindFunc(SDL_WasInit)("SDL_WasInit", lib);
    bindFunc(SDL_Quit)("SDL_Quit", lib);

    // syswm.d
    version(Windows)
        bindFunc(SDL_GetWMInfo)("SDL_GetWMInfo", lib);
}

GenericLoader DerelictSDL;
static this() {
    DerelictSDL.setup(
        "sdl.dll",
        "libSDL.so, libSDL.so.0, libSDL-1.2.so, libSDL-1.2.so.0",
        "../Frameworks/SDL.framework/SDL, /Library/Frameworks/SDL.framework/SDL, /System/Library/Frameworks/SDL.framework/SDL",
        &load
    );
}

extern(C)
{
    // SDL.h
    int function(Uint32) SDL_Init;
    int function(Uint32) SDL_InitSubSystem;
    void function(Uint32) SDL_QuitSubSystem;
    Uint32 function(Uint32) SDL_WasInit;
    void function() SDL_Quit;

    // SDL_active.h
    Uint8 function() SDL_GetAppState;

    // SDL_audio.h
    int function(char*) SDL_AudioInit;
    void function() SDL_AudioQuit;
    char* function(char*,int) SDL_AudioDriverName;
    int function(SDL_AudioSpec*,SDL_AudioSpec*) SDL_OpenAudio;
    SDL_audiostatus function() SDL_GetAudioStatus;
    void function(int) SDL_PauseAudio;
    SDL_AudioSpec* function(SDL_RWops*,int,SDL_AudioSpec*,Uint8**,Uint32*) SDL_LoadWAV_RW;
    void function(Uint8*) SDL_FreeWAV;
    int function(SDL_AudioCVT*,Uint16,Uint8,int,Uint16,Uint8,int) SDL_BuildAudioCVT;
    int function(SDL_AudioCVT*) SDL_ConvertAudio;
    void function(Uint8*,Uint8*,Uint32,int) SDL_MixAudio;
    void function() SDL_LockAudio;
    void function() SDL_UnlockAudio;
    void function() SDL_CloseAudio;

    SDL_AudioSpec* SDL_LoadWAV(char *file, SDL_AudioSpec *spec, Uint8 **buf, Uint32 *len)
    {
        return SDL_LoadWAV_RW(SDL_RWFromFile(file, "rb"), 1, spec, buf, len);
    }

    // SDL_cdrom.h
    int function() SDL_CDNumDrives;
    char* function(int) SDL_CDName;
    SDL_CD* function(int) SDL_CDOpen;
    CDstatus function(SDL_CD*) SDL_CDStatus;
    int function(SDL_CD*,int,int,int,int) SDL_CDPlayTracks;
    int function(SDL_CD*,int,int) SDL_CDPlay;
    int function(SDL_CD*) SDL_CDPause;
    int function(SDL_CD*) SDL_CDResume;
    int function(SDL_CD*) SDL_CDStop;
    int function(SDL_CD*) SDL_CDEject;
    int function(SDL_CD*) SDL_CDClose;

    // SDL_cpuinfo.h
    SDL_bool function() SDL_HasRDTSC;
    SDL_bool function() SDL_HasMMX;
    SDL_bool function() SDL_HasMMXExt;
    SDL_bool function() SDL_Has3DNow;
    SDL_bool function() SDL_Has3DNowExt;
    SDL_bool function() SDL_HasSSE;
    SDL_bool function() SDL_HasSSE2;
    SDL_bool function() SDL_HasAltiVec;

    // SDL_error.h
    void function(char*,...) SDL_SetError;
    char* function() SDL_GetError;
    void function() SDL_ClearError;

    // SDL_events.h
    void function() SDL_PumpEvents;
    int function(SDL_Event*,int,SDL_eventaction,Uint32) SDL_PeepEvents;
    int function(SDL_Event*) SDL_PollEvent;
    int function(SDL_Event*) SDL_WaitEvent;
    int function(SDL_Event*) SDL_PushEvent;
    void function(SDL_EventFilter) SDL_SetEventFilter;
    SDL_EventFilter function() SDL_GetEventFilter;
    Uint8 function(Uint8,int) SDL_EventState;


    int SDL_QuitRequested()
    {
        SDL_PumpEvents();
        return SDL_PeepEvents(null, 0, SDL_PEEKEVENT, SDL_QUITMASK);
    }

    // SDL_joystick.h
    int function() SDL_NumJoysticks;
    char* function(int) SDL_JoystickName;
    SDL_Joystick* function(int) SDL_JoystickOpen;
    int function(int) SDL_JoystickOpened;
    int function(SDL_Joystick*) SDL_JoystickIndex;
    int function(SDL_Joystick*) SDL_JoystickNumAxes;
    int function(SDL_Joystick*) SDL_JoystickNumBalls;
    int function(SDL_Joystick*) SDL_JoystickNumHats;
    int function(SDL_Joystick*) SDL_JoystickNumButtons;
    void function() SDL_JoystickUpdate;
    int function(int) SDL_JoystickEventState;
    Sint16 function(SDL_Joystick*,int) SDL_JoystickGetAxis;
    Uint8 function(SDL_Joystick*,int) SDL_JoystickGetHat;
    int function(SDL_Joystick*,int,int*,int*) SDL_JoystickGetBall;
    Uint8 function(SDL_Joystick*,int) SDL_JoystickGetButton;
    void function(SDL_Joystick*) SDL_JoystickClose;

    // SDL_keyboard.h
    int function(int) SDL_EnableUNICODE;
    int function(int,int) SDL_EnableKeyRepeat;
    void function(int*,int*) SDL_GetKeyRepeat;
    Uint8* function(int*) SDL_GetKeyState;
    SDLMod function() SDL_GetModState;
    void function(SDLMod) SDL_SetModState;
    char* function(SDLKey key) SDL_GetKeyName;

    // SDL_loadso.h
    void* function(char*) SDL_LoadObject;
    void* function(void*,char*) SDL_LoadFunction;
    void function(void*) SDL_UnloadObject;

    // SDL_mouse.h
    Uint8 function(int*,int*) SDL_GetMouseState;
    Uint8 function(int*,int*) SDL_GetRelativeMouseState;
    void function(Uint16,Uint16) SDL_WarpMouse;
    SDL_Cursor* function(Uint8*,Uint8*,int,int,int,int) SDL_CreateCursor;
    void function(SDL_Cursor*) SDL_SetCursor;
    SDL_Cursor* function() SDL_GetCursor;
    void function(SDL_Cursor*) SDL_FreeCursor;
    int function(int) SDL_ShowCursor;

    // SDL_mutex.h
    SDL_mutex* function() SDL_CreateMutex;
    int function(SDL_mutex*) SDL_mutexP;
    int function(SDL_mutex*) SDL_mutexV;
    void function(SDL_mutex*) SDL_DestroyMutex;
    SDL_sem* function(Uint32) SDL_CreateSemaphore;
    void function(SDL_sem*) SDL_DestroySemaphore;
    int function(SDL_sem*) SDL_SemWait;
    int function(SDL_sem*) SDL_SemTryWait;
    int function(SDL_sem*,Uint32) SDL_SemWaitTimeout;
    int function(SDL_sem*) SDL_SemPost;
    Uint32 function(SDL_sem*) SDL_SemValue;
    SDL_cond* function() SDL_CreateCond;
    void function(SDL_cond*) SDL_DestroyCond;
    int function(SDL_cond*) SDL_CondSignal;
    int function(SDL_cond*) SDL_CondBroadcast;
    int function(SDL_cond*,SDL_mutex*) SDL_CondWait;
    int function(SDL_cond*,SDL_mutex*,Uint32) SDL_CondWaitTimeout;

    int SDL_LockMutex(SDL_mutex *mutex)
    {
        return SDL_mutexP(mutex);
    }

    int SDL_UnlockMutex(SDL_mutex *mutex)
    {
        return SDL_mutexV(mutex);
    }

    // SDL_rwops.h
    SDL_RWops* function(char*,char*) SDL_RWFromFile;
    SDL_RWops* function(FILE*,int) SDL_RWFromFP;
    SDL_RWops* function(void*,int) SDL_RWFromMem;
    SDL_RWops* function(void*,int) SDL_RWFromConstMem;
    SDL_RWops* function() SDL_AllocRW;
    void function(SDL_RWops*) SDL_FreeRW;
    Uint16 function(SDL_RWops*) SDL_ReadLE16;
    Uint16 function(SDL_RWops*) SDL_ReadBE16;
    Uint32 function(SDL_RWops*) SDL_ReadLE32;
    Uint32 function(SDL_RWops*) SDL_ReadBE32;
    Uint64 function(SDL_RWops*) SDL_ReadLE64;
    Uint64 function(SDL_RWops*) SDL_ReadBE64;
    Uint16 function(SDL_RWops*,Uint16) SDL_WriteLE16;
    Uint16 function(SDL_RWops*,Uint16) SDL_WriteBE16;
    Uint32 function(SDL_RWops*,Uint32) SDL_WriteLE32;
    Uint32 function(SDL_RWops*,Uint32) SDL_WriteBE32;
    Uint64 function(SDL_RWops*,Uint64) SDL_WriteLE64;
    Uint64 function(SDL_RWops*,Uint64) SDL_WriteBE64;

    // SDL_version.h
    SDL_version* function() SDL_Linked_Version;

    // SDL_syswm.h
    int function(SDL_SysWMinfo*) SDL_GetWMInfo;

    // SDL_thread.h
    SDL_Thread* function(int (*fm)(void*), void*) SDL_CreateThread;
    Uint32 function() SDL_ThreadID;
    Uint32 function(SDL_Thread*) SDL_GetThreadID;
    void function(SDL_Thread*,int*) SDL_WaitThread;
    void function(SDL_Thread*) SDL_KillThread;

    // SDL_timer.h
    Uint32 function() SDL_GetTicks;
    void function(Uint32) SDL_Delay;
    int function(Uint32,SDL_TimerCallback) SDL_SetTimer;
    SDL_TimerID function(Uint32,SDL_NewTimerCallback,void*) SDL_AddTimer;
    SDL_bool function(SDL_TimerID) SDL_RemoveTimer;

    // SDL_video.h
    int function(char*,Uint32) SDL_VideoInit;
    void function() SDL_VideoQuit;
    char* function(char*,int) SDL_VideoDriverName;
    SDL_Surface* function() SDL_GetVideoSurface;
    SDL_VideoInfo* function() SDL_GetVideoInfo;
    int function(int,int,int,Uint32) SDL_VideoModeOK;
    SDL_Rect** function(SDL_PixelFormat*,Uint32) SDL_ListModes;
    SDL_Surface* function(int,int,int,Uint32) SDL_SetVideoMode;
    void function(SDL_Surface*,int,SDL_Rect*) SDL_UpdateRects;
    void function(SDL_Surface*,Sint32,Sint32,Uint32,Uint32) SDL_UpdateRect;
    int function(SDL_Surface*) SDL_Flip;
    int function(float,float,float) SDL_SetGamma;
    int function(Uint16*,Uint16*,Uint16*) SDL_SetGammaRamp;
    int function(Uint16*,Uint16*,Uint16*) SDL_GetGammaRamp;
    int function(SDL_Surface*,SDL_Color*,int,int) SDL_SetColors;
    int function(SDL_Surface*,int,SDL_Color*,int,int) SDL_SetPalette;
    Uint32 function(SDL_PixelFormat*,Uint8,Uint8,Uint8) SDL_MapRGB;
    Uint32 function(SDL_PixelFormat*,Uint8,Uint8,Uint8,Uint8) SDL_MapRGBA;
    void function(Uint32,SDL_PixelFormat*,Uint8*,Uint8*,Uint8*) SDL_GetRGB;
    void function(Uint32,SDL_PixelFormat*,Uint8*,Uint8*,Uint8*,Uint8*) SDL_GetRGBA;
    SDL_Surface* function(Uint32,int,int,int,Uint32,Uint32,Uint32,Uint32) SDL_CreateRGBSurface;
    SDL_Surface* function(void*,int,int,int,int,Uint32,Uint32,Uint32,Uint32) SDL_CreateRGBSurfaceFrom;
    void function(SDL_Surface*) SDL_FreeSurface;
    int function(SDL_Surface*) SDL_LockSurface;
    void function(SDL_Surface*) SDL_UnlockSurface;
    SDL_Surface* function(SDL_RWops*,int) SDL_LoadBMP_RW;
    int function(SDL_Surface*,SDL_RWops*,int) SDL_SaveBMP_RW;
    int function(SDL_Surface*,Uint32,Uint32) SDL_SetColorKey;
    int function(SDL_Surface*,Uint32,Uint8) SDL_SetAlpha;
    SDL_bool function(SDL_Surface*,SDL_Rect*) SDL_SetClipRect;
    void function(SDL_Surface*,SDL_Rect*) SDL_GetClipRect;
    SDL_Surface* function(SDL_Surface*,SDL_PixelFormat*,Uint32) SDL_ConvertSurface;
    int function(SDL_Surface*,SDL_Rect*,SDL_Surface*,SDL_Rect*) SDL_UpperBlit;
    int function(SDL_Surface*,SDL_Rect*,SDL_Surface*,SDL_Rect*) SDL_LowerBlit;
    int function(SDL_Surface*,SDL_Rect*,Uint32) SDL_FillRect;
    SDL_Surface* function(SDL_Surface*) SDL_DisplayFormat;
    SDL_Surface* function(SDL_Surface*) SDL_DisplayFormatAlpha;
    SDL_Overlay* function(int,int,Uint32,SDL_Surface*) SDL_CreateYUVOverlay;
    int function(SDL_Overlay*) SDL_LockYUVOverlay;
    void function(SDL_Overlay*) SDL_UnlockYUVOverlay;
    int function(SDL_Overlay*,SDL_Rect*) SDL_DisplayYUVOverlay;
    void function(SDL_Overlay*) SDL_FreeYUVOverlay;
    int function(char*) SDL_GL_LoadLibrary;
    void* function(char*) SDL_GL_GetProcAddress;
    int function(SDL_GLattr,int) SDL_GL_SetAttribute;
    int function(SDL_GLattr,int*) SDL_GL_GetAttribute;
    void function() SDL_GL_SwapBuffers;
    void function(int,SDL_Rect*) SDL_GL_UpdateRects;
    void function() SDL_GL_Lock;
    void function() SDL_GL_Unlock;
    void function(char*,char*) SDL_WM_SetCaption;
    void function(char**,char**) SDL_WM_GetCaption;
    void function(SDL_Surface*,Uint8*) SDL_WM_SetIcon;
    int function() SDL_WM_IconifyWindow;
    int function(SDL_Surface*) SDL_WM_ToggleFullScreen;
    SDL_GrabMode function(SDL_GrabMode) SDL_WM_GrabInput;

    alias SDL_CreateRGBSurface SDL_AllocSurface;
    alias SDL_UpperBlit SDL_BlitSurface;

    SDL_Surface* SDL_LoadBMP(char *file)
    {
        return SDL_LoadBMP_RW(SDL_RWFromFile(file, "rb"), 1);
    }

    int SDL_SaveBMP(SDL_Surface *surface, char *file)
    {
        return SDL_SaveBMP_RW(surface, SDL_RWFromFile(file,"wb"), 1);
    }
}