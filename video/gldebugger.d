module video.gldebugger;


import test.subdebugger;
import gui.guibutton;
import math.vector2;


package class PagesDebugger : SubDebugger
{
    private:
        
        //TODO:
        //0: display, selection of pages, info about current page (color format, node count, etc.)
        //1: scrolling pages
        //2: zooming pages
        //3: keyboard control
        //4: display of page nodes, colors specifying if free or not 
        //   (slight, transparent rectangles)
    public:
        this()
        {
        }
}

package class GLDebugger : SubDebugger
{
    private:
        GUIButton pages_button_;
        SubDebugger current_debugger_ = null;
        
    public:
        this()
        {
            pages_button_ = new GUIButton(this, Vector2i(4, 4),
                                          Vector2u(40, 12), "Pages");
            pages_button_.font_size = 8;
            pages_button_.pressed.connect(&pages);
            super();
        }

        override void size(Vector2u size)
        {
            super.size(size);
        }

        void pages()
        {
            disconnect_current();
            current_debugger_ = new PagesDebugger;
            add_child(current_debugger_);
            current_debugger_.position_local = Vector2i(48, 4);
            current_debugger_.size = Vector2u(super.size.x - 52, super.size.y - 8);
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
