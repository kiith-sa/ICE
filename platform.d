module platform;


import std.string;
import derelict.sdl.sdl;

import singleton;
import signal;
import vector2;

enum KeyState
{
    Pressed,
    Released
}

///Key codes. Map directly to SDL 1.2 key codes.
enum Key
{
	Unknown	     = 0,
	First		 = 0,
                 
	Backspace  	 = 8,
	Tab		     = 9,
	Clear		 = 12,
	Return	     = 13,
	Pause		 = 19,
	Escape		 = 27,
	Space		 = 32,
	Exclaim	     = 33,
	Quotedbl	 = 34,
	Hash		 = 35,
	Dollar		 = 36,
	Ampersand	 = 38,
	Quote		 = 39,
	Leftparen	 = 40,
	Rightparen	 = 41,
	Asterisk	 = 42,
	Plus		 = 43,
	Comma		 = 44,
	Minus		 = 45,
	Period		 = 46,
	Slash		 = 47,

	K_0			 = 48,
	K_1			 = 49,
	K_2			 = 50,
	K_3		     = 51,
	K_4			 = 52,
	K_5		     = 53,
	K_6			 = 54,
	K_7			 = 55,
	K_8		     = 56,
	K_9		     = 57,

	Colon		 = 58,
	Semicolon	 = 59,
	Less		 = 60,
	Equals		 = 61,
	Greater	   	 = 62,
	Question	 = 63,
	At			 = 64,

	Leftbracket	 = 91,
	Backslash	 = 92,
	Rightbracket = 93,
	Caret		 = 94,
	Underscore	 = 95,
	Backquote	 = 96,

	K_A			 = 97,
	K_B			 = 98,
	K_C			 = 99,
	K_D			 = 100,
	K_E		     = 101,
	K_F		     = 102,
	K_G		     = 103,
	K_H		     = 104,
	K_I		     = 105,
	K_J		     = 106,
	K_K		     = 107,
	K_L		     = 108,
	K_M		     = 109,
	K_N		     = 110,
	K_O		     = 111,
	K_P		     = 112,
	K_Q		     = 113,
	K_R			 = 114,
	K_S		     = 115,
	K_T		     = 116,
	K_U		     = 117,
	K_V		     = 118,
	K_W		     = 119,
	K_X		     = 120,
	K_Y		     = 121,
	K_Z		     = 122,
	Delete	     = 127,

	Local_0      = 160,
	Local_1      = 161,
	Local_2      = 162,
	Local_3      = 163,
	Local_4      = 164,
	Local_5      = 165,
	Local_6      = 166,
	Local_7      = 167,
	Local_8      = 168,
	Local_9      = 169,
	Local_10	 = 170,
	Local_11	 = 171,
	Local_12	 = 172,
	Local_13	 = 173,
	Local_14	 = 174,
	Local_15	 = 175,
	Local_16	 = 176,
	Local_17	 = 177,
	Local_18	 = 178,
	Local_19	 = 179,
	Local_20	 = 180,
	Local_21	 = 181,
	Local_22	 = 182,
	Local_23	 = 183,
	Local_24	 = 184,
	Local_25	 = 185,
	Local_26	 = 186,
	Local_27	 = 187,
	Local_28	 = 188,
	Local_29	 = 189,
	Local_30	 = 190,
	Local_31	 = 191,
	Local_32	 = 192,
	Local_33	 = 193,
	Local_34	 = 194,
	Local_35	 = 195,
	Local_36	 = 196,
	Local_37	 = 197,
	Local_38	 = 198,
	Local_39	 = 199,
	Local_40	 = 200,
	Local_41	 = 201,
	Local_42	 = 202,
	Local_43	 = 203,
	Local_44	 = 204,
	Local_45	 = 205,
	Local_46	 = 206,
	Local_47	 = 207,
	Local_48	 = 208,
	Local_49	 = 209,
	Local_50	 = 210,
	Local_51	 = 211,
	Local_52	 = 212,
	Local_53	 = 213,
	Local_54	 = 214,
	Local_55	 = 215,
	Local_56	 = 216,
	Local_57	 = 217,
	Local_58	 = 218,
	Local_59	 = 219,
	Local_60	 = 220,
	Local_61	 = 221,
	Local_62	 = 222,
	Local_63	 = 223,
	Local_64	 = 224,
	Local_65	 = 225,
	Local_66	 = 226,
	Local_67	 = 227,
	Local_68	 = 228,
	Local_69	 = 229,
	Local_70	 = 230,
	Local_71	 = 231,
	Local_72	 = 232,
	Local_73	 = 233,
	Local_74	 = 234,
	Local_75	 = 235,
	Local_76	 = 236,
	Local_77	 = 237,
	Local_78	 = 238,
	Local_79	 = 239,
	Local_80	 = 240,
	Local_81	 = 241,
	Local_82	 = 242,
	Local_83	 = 243,
	Local_84	 = 244,
	Local_85	 = 245,
	Local_86	 = 246,
	Local_87	 = 247,
	Local_88	 = 248,
	Local_89	 = 249,
	Local_90	 = 250,
	Local_91	 = 251,
	Local_92	 = 252,
	Local_93	 = 253,
	Local_94	 = 254,
	Local_95	 = 255,

	NP_0	     = 256,
	NP_1	     = 257,
	NP_2	     = 258,
	NP_3	     = 259,
	NP_4	     = 260,
	NP_5	     = 261,
	NP_6		 = 262,
	NP_7		 = 263,
	NP_8	     = 264,
	NP_9		 = 265,

	NP_period	 = 266,
	NP_divide	 = 267,
	NP_multiply	 = 268,
	NP_minus	 = 269,
	NP_plus	     = 270,
	NP_enter	 = 271,
	NP_equals	 = 272,

	Up			 = 273,
	Down	     = 274,
	Right	     = 275,
	Left		 = 276,
	Insert		 = 277,
	Home	     = 278,
	End		     = 279,
	Pageup		 = 280,
	Pagedown	 = 281,

	F1			 = 282,
	F2		     = 283,
	F3		     = 284,
	F4		     = 285,
	F5		     = 286,
	F6		     = 287,
	F7		     = 288,
	F8		     = 289,
	F9		     = 290,
	F10		     = 291,
	F11		     = 292,
	F12	         = 293,
	F13		     = 294,
	F14	         = 295,
	F15	         = 296,

	Numlock	     = 300,
	Capslock	 = 301,
	Scrollock	 = 302,
	Rshift		 = 303,
	Lshift	     = 304,
	Rctrl	     = 305,
	Lctrl	     = 306,
	Ralt	     = 307,
	Lalt	     = 308,
	Rmeta	     = 309,
	Lmeta	     = 310,
	Lsuper	     = 311,
	Rsuper	     = 312,
	Mode		 = 313,
	Compose   	 = 314,

	Help		 = 315,
	Print		 = 316,
	Sysreq		 = 317,
	Break		 = 318,
	Menu		 = 319,
	Power		 = 320,
	Euro	     = 321,
	Undo	     = 322,

	Last
}

///Mouse buttons.
enum MouseKey
{
    Left,
    Middle,
    Right,
    WheelUp,
    WheelDown
}

///Handles platform specific functionality like input/output.
class Platform : Singleton
{
    mixin SingletonMixin;
    
    private:
        bool Run = true;

        bool[Key.max] keys_pressed;
                 
    public:
        ///Emitted when a key is pressed. Passes the key, its state and unicode value.
        mixin Signal!(KeyState, Key, dchar) key;

        ///Emitted when a mouse button is pressed. Passes the key, its state and mouse position.
        mixin Signal!(KeyState, MouseKey, Vector2u) mouse_key;
        ///Emitted when mouse is moved. Passes mouse position and position change.
        mixin Signal!(Vector2u, Vector2i) mouse_motion;

        void die()
        {
			SDL_Quit();
            DerelictSDL.unload();
        }
        
        ///Collect input and determine if the game should continue running.
        bool run()
        {
            SDL_Event event;

            while(SDL_PollEvent(&event))
            {
                switch(event.type)
                {
                    case SDL_QUIT:
                        quit();
                        break;
					case SDL_KEYDOWN:
					case SDL_KEYUP:
                        process_key(event.key);
                        break;
                    case SDL_MOUSEBUTTONDOWN:
                    case SDL_MOUSEBUTTONUP:
                        process_mouse_key(event.button);
                        break;
                    case SDL_MOUSEMOTION:
                        process_mouse_motion(event.motion);
                        break;
                    default:
                        break;
                }
            }
            return Run;
        }

        ///Quit the platform, i.e. the game.
        void quit()
        {
            Run = false;
        }

        ///Sets window caption string to str.
        void window_caption(string str)
        {
            SDL_WM_SetCaption(toStringz(str), null); 
        }

        ///Hide the mouse cursor.
        void hide_cursor()
        {
            SDL_ShowCursor(0);
        }

        ///Show the mouse cursor.
        void show_cursor()
        {
            SDL_ShowCursor(1);
        }

        ///Determine if specified key is pressed.
        bool is_key_pressed(Key key)
        {
            return keys_pressed[cast(uint)key];
        }
        
    protected:
        //Constructor - initializes SDL and throws Excetion on failure.
        this()
        {
            DerelictSDL.load();
			if(SDL_Init(SDL_INIT_VIDEO) < 0)
            {
                string error = std.string.toString(SDL_GetError());
				throw new Exception("Could not initialize SDL: " ~ error);
            }
            SDL_EnableUNICODE(SDL_ENABLE);
        }
        
        //Process a keyboard event
        void process_key(SDL_KeyboardEvent event)
        {
            KeyState state = KeyState.Pressed;
            keys_pressed[event.keysym.sym] = true;
            if(event.type == SDL_KEYUP)
            {
                state = KeyState.Released;
                keys_pressed[event.keysym.sym] = false;
            }
            key.emit(state, cast(Key)event.keysym.sym, 
                           event.keysym.unicode);
        }
        
        //Process a mouse button event
        void process_mouse_key(SDL_MouseButtonEvent event)
        {
            KeyState state = KeyState.Pressed;
            if(event.type == SDL_MOUSEBUTTONUP)
            {
                state = KeyState.Released;
            }

            MouseKey key;
            switch(event.button)
            {
                case(SDL_BUTTON_LEFT):
                    key = MouseKey.Left;
                    break;
                case(SDL_BUTTON_MIDDLE):
                    key = MouseKey.Middle;
                    break;
                case(SDL_BUTTON_RIGHT):
                    key = MouseKey.Right;
                    break;
                case(SDL_BUTTON_WHEELUP):
                    key = MouseKey.WheelUp;
                    break;
                case(SDL_BUTTON_WHEELDOWN):
                    key = MouseKey.WheelDown;
                    break;
            }

            Vector2u position = Vector2u(event.x, event.y);

            mouse_key.emit(state, key, position);
        }
        
        //Process a mouse motion event
        void process_mouse_motion(SDL_MouseMotionEvent event)
        {
            Vector2u position = Vector2u(event.x, event.y);
            Vector2i position_relative = Vector2i(event.xrel, event.yrel);
            mouse_motion.emit(position, position_relative);
        }
}
