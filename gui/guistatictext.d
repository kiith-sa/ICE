module gui.guistatictext;


import std.string;

import gui.guielement;
import video.videodriver;
import math.math;
import math.vector2;
import math.rectangle;
import color;


///Horizontal alignments.
enum AlignX
{
    Right,
    Center,
    Left
}

///Vertical alignments.
enum AlignY
{
    Top,
    Center,
    Bottom
}

///Static text element. Text is broken down into lines to fit width.
class GUIStaticText : GUIElement
{
    private:
        //Single line of text drawn on screen.
        struct TextLine
        {
            //position relative to element position.
            Vector2i offset;
            //text of the line.
            string text;
        }

        //Text of the element. This is broken into TextLines according to width.
        string text_;

        AlignX align_x_ = AlignX.Left;
        AlignY align_y_ = AlignY.Top;
        
        //Lines of text to draw.
        TextLine[] lines_;

        //Name of the font used.
        string font_;

        uint font_size_;
        
        Color font_color_ = Color(255, 255, 255, 255);

        //Distance between lines, in pixels
        uint line_gap_;

        //True if lines_ are aligned according to current settings, false otherwise.
        //(used to determine whether or not lines_ need realigning before drawing)
        bool aligned_;

    public:
        ///Construct a static text with specified parameters.
        this(GUIElement parent, Vector2i position, Vector2u size, string text, 
             string font, uint font_size)
        {
            super(parent, position, size);
            text = expandtabs(text);
            draw_border_ = false;
            font_ = font;
            font_size_ = font_size;
            line_gap_ = max(2u, font_size_ / 6);
            text_ = text;
            realign();
            aligned_ = true;
        }

        ///Set text color.
        void text_color(Color color){font_color_ = color;}

        ///Set size of this element in screen space.
        override void size(Vector2u size)
        {
            super.size(size);
            aligned_ = false;
        }
        
        ///Set horizontal alignment.
        void alignment_x(AlignX alignment)
        {
            align_x_ = alignment;
            aligned_ = false;
        }

        ///Set vertical alignment.
        void alignment_y(AlignY alignment)
        {
            align_y_ = alignment;
            aligned_ = false;
        }

        ///Set distance between lines.
        void line_gap(uint gap)
        {
            line_gap_ = gap;
            aligned_ = false;
        }

        ///Set font size of the text.
        void font_size(uint size)
        {
            font_size_ = size;
            aligned_ = false;
        }

    protected:
        override void draw()
        {
            super.draw();
            //must realign if settings changed
            if(!aligned_){realign();}

            VideoDriver.get.font = font_;
            VideoDriver.get.font_size = font_size_;
            foreach(ref line; lines_)
            {
                Vector2i offset = bounds_.min + line.offset;
                VideoDriver.get.draw_text(offset, line.text, font_color_);
            }
        }

    private:
        //Add a TextLine from the text, and return rest of the text.
        string add_line(string text, uint y_offset_in, out uint y_offset_out)
        {
            //get leading space, if any, and following word from text
            string get_word()
            {
                uint end;
                foreach(i, dchar c; text){if(!iswhite(c)){end = i; break;}}
                foreach(dchar c; text[end .. $]){if(iswhite(c)){break;}++end;}
                return text[0 .. end];
            }

            //line we're constructing
            TextLine line;
            VideoDriver driver = VideoDriver.get;
            uint width = super.size.x;

            while(text.length > 0)
            {
                string word = get_word();

                //can we add word to the line without passing width?
                Vector2u line_size = driver.text_size(line.text ~ word);
                if(line_size.x > width)
                {
                    //line too wide, don't add the word and break
                    if(line.text.length == 0)
                    {
                        //word is too huge for a single line, 
                        //so add a line with only that word
                        line.text = word; 
                        text = text[word.length .. $];
                    }
                    //update y position to below this line
                    y_offset_out = y_offset_in + line_size.y + line_gap_;
                    break;
                }
                else
                {
                    line.text ~= word;
                    text = text[word.length .. $];
                }
            }

            //align the line horizontally
            line.offset = Vector2i(0, y_offset_in);
            if(align_x_ == AlignX.Right)
            {
                line.offset.x = width - driver.text_size(line.text).x;
            }
            if(align_x_ == AlignX.Center)
            {
                line.offset.x = (width - driver.text_size(line.text).x) / 2;
            }
            lines_ ~= line;
            //strip leading space so the next line doesn't start with space
            return stripl(text);
        }
        
        //Align lines verically.
        void align_vertical()
        {
            //if AlignY is Top, we're aligned as lines start at y == 0 by default
            if(lines_.length == 0 || align_y_ == AlignY.Top){return;}
            uint text_height = font_size_ * lines_.length + line_gap_ * (lines_.length - 1);
            int offset_y = super.size.y - text_height;
            if(align_y_ == AlignY.Center){offset_y /= 2;}
            //move lines according to the offset
            foreach(ref line; lines_){line.offset.y += offset_y;}
        }

        //Break text down to lines and realign it.
        void realign()
        {
            string text = text_;

            //we need to set font to get information about drawn size of lines
            VideoDriver.get.font = font_;
            VideoDriver.get.font_size = font_size_;
            lines_ = [];
            uint y_offset;

            //break text to lines and align them horizontally, then align vertically
            while(text.length > 0){text = add_line(text, y_offset, y_offset);}
            align_vertical();

            aligned_ = true;
        }
}               
