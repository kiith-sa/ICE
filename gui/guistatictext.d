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
        string Text;

        AlignX AlignmentX = AlignX.Left;
        AlignY AlignmentY = AlignY.Top;
        
        //Lines of text to draw.
        TextLine[] Lines;

        Color FontColor = Color(255, 255, 255, 255);

        //Name of the font used.
        string Font;

        uint FontSize;
        
        //Distance between lines, in pixels
        uint LineGap;

        //True if Lines are aligned according to current settings, false otherwise.
        //(used to determine whether or not Lines need realigning before drawing)
        bool Aligned;

    public:
        ///Construct a static text with specified parameters.
        this(GUIElement parent, Vector2i position, Vector2u size, string text, 
             string font, uint font_size)
        {
            super(parent, position, size);
            text = expandtabs(text);
            DrawBorder = false;
            Font = font;
            FontSize = font_size;
            LineGap = max(2u, FontSize / 6);
            Text = text;
            realign();
            Aligned = true;
        }

        ///Set text color.
        void text_color(Color color){FontColor = color;}

        ///Set size of this element in screen space.
        override void size(Vector2u size)
        {
            super.size(size);
            Aligned = false;
        }
        
        ///Set horizontal alignment.
        void alignment_x(AlignX alignment)
        {
            AlignmentX = alignment;
            Aligned = false;
        }

        ///Set vertical alignment.
        void alignment_y(AlignY alignment)
        {
            AlignmentY = alignment;
            Aligned = false;
        }

        ///Set distance between lines.
        void line_gap(uint gap)
        {
            LineGap = gap;
            Aligned = false;
        }

    protected:
        override void draw()
        {
            super.draw();
            //must realign if settings changed
            if(!Aligned){realign();}

            VideoDriver.get.font = Font;
            VideoDriver.get.font_size = FontSize;
            foreach(ref line; Lines)
            {
                Vector2i offset = Bounds.min + line.offset;
                VideoDriver.get.draw_text(offset, line.text, FontColor);
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
                    y_offset_out = y_offset_in + line_size.y + LineGap;
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
            if(AlignmentX == AlignX.Right)
            {
                line.offset.x = width - driver.text_size(line.text).x;
            }
            if(AlignmentX == AlignX.Center)
            {
                line.offset.x = (width - driver.text_size(line.text).x) / 2;
            }
            Lines ~= line;
            //strip leading space so the next line doesn't start with space
            return stripl(text);
        }
        
        //Align lines verically.
        void align_vertical()
        {
            //if AlignY is Top, we're aligned as lines start at y == 0 by default
            if(Lines.length == 0 || AlignmentY == AlignY.Top){return;}
            uint text_height = FontSize * Lines.length + LineGap * (Lines.length - 1);
            int offset_y = super.size.y - text_height;
            if(AlignmentY == AlignY.Center){offset_y /= 2;}
            //move lines according to the offset
            foreach(ref line; Lines){line.offset.y += offset_y;}
        }

        //Break text down to lines and realign it.
        void realign()
        {
            string text = Text;

            //we need to set font to get information about drawn size of lines
            VideoDriver.get.font = Font;
            VideoDriver.get.font_size = FontSize;
            Lines = [];
            uint y_offset;

            //break text to lines and align them horizontally, then align vertically
            while(text.length > 0){text = add_line(text, y_offset, y_offset);}
            align_vertical();

            Aligned = true;
        }
}               
