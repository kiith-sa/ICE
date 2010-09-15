module test.debugger;


import test.subdebugger;
import video.videodriver;
import gui.guielement;
import gui.guibutton;
import math.vector2;
import math.math;


///Displays various debugging/profiling information about engine subsystems.
class Debugger : GUIElement
{
    private:
        GUIButton video_button_;
        SubDebugger current_debugger_ = null;

    public:
        ///Construct a new debugger with specified parameters.
        this(GUIElement parent, Vector2i position, Vector2u size)
        {

            size.x = max(size.x, 320u);
            size.y = max(size.y, 200u);
            super(parent, position, size);
            video_button_ = new GUIButton(this, Vector2i(4, 4),
                                          Vector2u(48, 14), "Video");
            video_button_.font_size = 8;
            video_button_.pressed.connect(&video);
        }

    private:
        //display videodriver debugger.
        void video()
        {
            disconnect_current();
            current_debugger_ = VideoDriver.get.debugger;
            if(current_debugger_ is null){current_debugger_ = new SubDebugger;}
            add_child(current_debugger_);
            current_debugger_.position_local = Vector2i(4, 22);
            current_debugger_.size = Vector2u(size.x - 8, size.y - 26);
        }

        void disconnect_current()
        {
            if(current_debugger_ !is null)
            {
                remove_child(current_debugger_);
                current_debugger_.die();
                current_debugger_ = null;
            }
        }
}
