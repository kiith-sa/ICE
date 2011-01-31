module gui.guistatictext;


import std.string;

import gui.guielement;
import video.videodriver;
import math.math;
import math.vector2;
import math.rectangle;
import color;
import factory;


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
        string text_ = "";

        AlignX align_x_;
        AlignY align_y_;
        
        //Lines of text to draw.
        TextLine[] lines_;

        //Name of the font used.
        string font_;

        //Size of the font in points.
        uint font_size_;
        
        Color font_color_;

        //Distance between lines, in pixels
        uint line_gap_;

    public:
        ///Set text color.
        void text_color(Color color){font_color_ = color;}

        ///Return displayed text.
        string text(){return text_;}

        ///Set displayed text.
        void text(string text)
        {
            text_ = expandtabs(text);
            aligned_ = false;
        }

        ///Get default font size of GUIStaticText instances.
        static uint default_font_size(){return 12;}

    protected:
        /*
         * Construct a static text with specified parameters.
         *
         * See_Also: GUIElement.this 
         *
         * Params:  x           = X position math expression.
         *          y           = Y position math expression. 
         *          width       = Width math expression. 
         *          height      = Height math expression. 
         *          text_color  = Color of the text.
         *          text        = Text to display.
         *          align_x     = Horizontal alignment of the text.
         *          align_y     = Vertical alignment of the text.
         *          line_gap    = Spacing between lines of the text.
         *          font_size   = Size of text font.
         *          font        = Name of the font to use.
         */
        this(string x, string y, string width, string height, 
             Color text_color, string text, 
             AlignX align_x, AlignY align_y, uint line_gap,
             uint font_size, string font)
        {
            super(x, y, width, height);

            draw_border_ = false;
            font_color_ = text_color;
            text_ = expandtabs(text);
            align_x_ = align_x;
            align_y_ = align_y;
            line_gap_ = line_gap;
            font_size_ = font_size;
            font_ = font;
            aligned_ = false;
        }

        override void draw(VideoDriver driver)
        {
            if(!visible_){return;}

            super.draw(driver);

            driver.font = font_;
            driver.font_size = font_size_;
            foreach(ref line; lines_)
            {
                Vector2i offset = bounds_.min + line.offset;
                driver.draw_text(offset, line.text, font_color_);
            }
        }

        //Break text down to lines and realign it.
        override void realign(VideoDriver driver)
        {
            super.realign(driver);

            line_gap_ = max(2u, font_size_ / 6);

            string text = text_;

            //we need to set font to get information about drawn size of lines
            driver.font = font_;
            driver.font_size = font_size_;
            lines_ = [];
            uint y_offset;

            //break text to lines and align them horizontally, then align vertically
            while(text.length > 0){text = add_line(driver, text, y_offset, y_offset);}
            align_vertical();
        }

    private:
        //Add a TextLine from the text, and return rest of the text.
        string add_line(VideoDriver driver, string text, 
                        uint y_offset_in, out uint y_offset_out)
        {
            //get leading space, if any, and following word from text
            //also, break the line if (unix) newline found
            string get_word(out bool end_line)
            {
                end_line = false;
                uint end;
                foreach(i, dchar c; text)
                {
                    if(!iswhite(c)){break;}
                    else if(c == '\n')
                    {
                        end_line = true;
                        return text[0 .. end];
                    }
                    ++end;
                }
                foreach(dchar c; text[end .. $])
                {
                    if(iswhite(c)){break;}
                    else if(c == '\n')
                    {
                        end_line = true;
                        return text[0 .. end];
                    }
                    ++end;
                }
                return text[0 .. end];
            }

            //line we're constructing
            TextLine line;
            uint width = size.x;
            bool end_line = false;

            while(text.length > 0)
            {
                string word = get_word(end_line);

                //can we add word to the line without passing width?
                Vector2u line_size = driver.text_size(line.text ~ word);
                if(line_size.x > width || end_line)
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
            return text;
        }
        
        //Align lines verically.
        void align_vertical()
        {
            //if AlignY is Top, we're aligned as lines start at y == 0 by default
            if(lines_.length == 0 || align_y_ == AlignY.Top){return;}
            uint text_height = font_size_ * lines_.length + line_gap_ * (lines_.length - 1);
            int offset_y = size.y - text_height;
            if(align_y_ == AlignY.Center){offset_y /= 2;}
            //move lines according to the offset
            foreach(ref line; lines_){line.offset.y += offset_y;}
        }
}               

/**
 * Factory used for static text construction.
 *
 * See_Also: GUIElementFactoryBase
 *
 * Params:  text_color  = Color of the text.
 *                        Default: Color.white
 *          text        = Text to display.
 *                        Default: ""
 *          align_x     = Horizontal alignment of the text.
 *                        Default: AlignX.Left
 *          align_y     = Vertical alignment of the text.
 *                        Default: AlignY.Top
 *          line_gap    = Spacing between lines of the text.
 *                        Default: 0
 *          font_size   = Size of text font.
 *          font        = Name of the font to use.
 *                        Default: "default"
 */
final class GUIStaticTextFactory : GUIElementFactoryBase!(GUIStaticText)
{
    mixin(generate_factory("Color $ text_color $ Color.white", 
                           "string $ text $ \"\"", 
                           "AlignX $ align_x $ AlignX.Left", 
                           "AlignY $ align_y $ AlignY.Top", 
                           "uint $ line_gap $ 0",
                           "uint $ font_size $ GUIStaticText.default_font_size()",
                           "string $ font $ \"default\""));
    public override GUIStaticText produce()
    {
        return new GUIStaticText(x_, y_, width_, height_, text_color_, text_, 
                                 align_x_, align_y_, line_gap_, font_size_, font_);
    }
}
