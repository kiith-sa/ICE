
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Static text widget.
module gui.guistatictext;
@safe


import std.algorithm;
import std.string;

import gui.guielement;
import video.videodriver;
import math.vector2;
import math.rectangle;
import color;
import util.factory;


///Horizontal alignments.
enum AlignX
{
    ///Align to right.
    Right,
    ///Align to center.
    Center,
    ///Align to left.
    Left
}

///Vertical alignments.
enum AlignY
{
    ///Align to top.
    Top,
    ///Align to center.
    Center,
    ///Align to bottom.
    Bottom
}

/**
 * Static text element. 
 *
 * Text is broken down into lines to fit width, but no fancy formatting is supported yet.
 */
class GUIStaticText : GUIElement
{
    private:
        ///Single line of text drawn on screen.
        struct TextLine
        {
            ///Position relative to element position.
            Vector2i offset;
            ///Text of the line.
            string text;
        }

        ///Text string. This is broken into TextLines according to width.
        string text_ = "";
        ///Text lines to draw.
        TextLine[] lines_;

        ///Horizontal alignment of the text.
        AlignX align_x_;
        ///Vertical alignment of the text.
        AlignY align_y_;
        ///Distance between the lines in pixels.
        uint line_gap_;
        
        ///Name of the font used.
        string font_;
        ///Font size in points.
        uint font_size_;
        ///Font color.
        Color font_color_;

    public:
        ///Set text color.
        @property void text_color(in Color color){font_color_ = color;}

        ///Return displayed text.
        @property string text() const {return text_;}

        ///Set text to display.
        @property void text(in string text)
        {
            if(text == text_){return;}
            text_ = expandtabs(text);
            aligned_ = false;
        }

        ///Get default font size of GUIStaticText instances.
        @property static uint default_font_size(){return 12;}

    protected:
        /**
         * Construct a static text with specified parameters.
         *
         * Params:  params      = Parameters for GUIElement constructor.
         *          text_color  = Text color.
         *          text        = Text to display.
         *          align_x     = Horizontal alignment of the text.
         *          align_y     = Vertical alignment of the text.
         *          font_size   = Font size.
         *          font        = Name of the font to use.
         */
        this(in GUIElementParams params, in Color text_color, in string text, 
             in AlignX align_x, in AlignY align_y, in uint font_size, in string font)
        {
            super(params);

            text_ = expandtabs(text);

            font_color_ = text_color;
            font_size_  = font_size;
            font_       = font;

            align_x_ = align_x;
            align_y_ = align_y;
            //pretty much arbitrary, something better might be needed in future
            line_gap_ = max(2u, font_size_ / 6);

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
                driver.draw_text(bounds_.min + line.offset, line.text, font_color_);
            }
        }

        override void realign(VideoDriver driver)
        {
            super.realign(driver);

            string text = text_.idup;

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
        //This code is pretty horrible. Need a serious, even if not feature-rich layout engine.
        /**
         * Add a TextLine from the text, and return rest of the text.
         *
         * Params:  driver       = VideoDriver used for text size measurement.
         *          text         = Text to get the line from.
         *          y_offset_in  = Y offset to use for this line.
         *          y_offset_out = Y offset to use for the next line will be written here.
         *
         * Returns: Remaining text that isn't part of the newly added line.
         */
        string add_line(VideoDriver driver, string text, in 
                        uint y_offset_in, out uint y_offset_out)
        {
            //get leading space, if any, and following word from text
            //also, break the line if (unix) newline found
            string get_word(out bool end_line)
            {
                end_line = false;
                uint end;
                //get leading space
                foreach(i, dchar c; text)
                {
                    if(!iswhite(c)){break;}
                    //break at newline
                    else if(c == '\n')
                    {
                        end_line = true;
                        return text[0 .. end];
                    }
                    ++end;
                }
                //get the word
                foreach(dchar c; text[end .. $])
                {
                    if(iswhite(c)){break;}
                    //break at newline
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
            const uint width = size.x;
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
            const text_width = driver.text_size(line.text).x;
            line.offset.x  = align_x_ == AlignX.Right  ? width - text_width :
                             align_x_ == AlignX.Center ? (width - text_width) / 2
                             : line.offset.x;
                                           
            lines_ ~= line;
            //strip leading space so the next line doesn't start with space
            return stripl(text);
        }
        
        ///Align lines verically.
        void align_vertical()
        {
            //if AlignY is Top, we're aligned as lines start at y == 0 by default
            if(lines_.length == 0 || align_y_ == AlignY.Top){return;}
            const text_height = font_size_ * lines_.length + line_gap_ * (lines_.length - 1);
            auto offset_y = size.y - text_height;
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
 * Params:  draw_border = Draw border of the element?
 *                        Default; false
 *          text_color  = Color of the text.
 *                        Default; Color.white
 *          text        = Text to display.
 *                        Default; ""
 *          align_x     = Horizontal alignment of the text.
 *                        Default; AlignX.Left
 *          align_y     = Vertical alignment of the text.
 *                        Default; AlignY.Top
 *          font_size   = Size of text font.
 *          font        = Name of the font to use.
 *                        Default; "default"
 */
final class GUIStaticTextFactory : GUIElementFactoryBase!GUIStaticText
{
    mixin(generate_factory(`Color  $ text_color $ Color.white`, 
                           `string $ text       $ ""`, 
                           `AlignX $ align_x    $ AlignX.Left`, 
                           `AlignY $ align_y    $ AlignY.Top`, 
                           `uint   $ font_size  $ GUIStaticText.default_font_size()`,
                           `string $ font       $ "default"`));

    ///Construct a GUIStaticTextFactory and initialize defaults.
    this(){draw_border_ = false;}

    public override GUIStaticText produce()
    {
        return new GUIStaticText(gui_element_params, text_color_, text_, 
                                 align_x_, align_y_, font_size_, font_);
    }
}
