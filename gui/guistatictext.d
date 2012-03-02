
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Static text widget.
module gui.guistatictext;


import std.algorithm;
import std.ascii;
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
        AlignX alignX_;
        ///Vertical alignment of the text.
        AlignY alignY_;
        ///Distance between the lines in pixels.
        uint lineGap_;
        
        ///Name of the font used.
        string font_;
        ///Font size in points.
        uint fontSize_;
        ///Font color.
        Color fontColor_;

    public:
        ///Set text color.
        @property void textColor(in Color color){fontColor_ = color;}

        ///Return displayed text.
        @property string text() const {return text_;}

        ///Set text to display.
        @property void text(in string text)
        {
            if(text == text_){return;}
            text_ = detab(text);
            aligned_ = false;
        }

        ///Get default font size of GUIStaticText instances.
        @property static uint defaultFontSize(){return 12;}

    protected:
        /**
         * Construct a static text with specified parameters.
         *
         * Params:  params      = Parameters for GUIElement constructor.
         *          textColor  = Text color.
         *          text        = Text to display.
         *          alignX     = Horizontal alignment of the text.
         *          alignY     = Vertical alignment of the text.
         *          fontSize   = Font size.
         *          font        = Name of the font to use.
         */
        this(in GUIElementParams params, in Color textColor, in string text, 
             in AlignX alignX, in AlignY alignY, in uint fontSize, in string font)
        {
            super(params);

            text_ = detab(text);

            fontColor_ = textColor;
            fontSize_  = fontSize;
            font_       = font;

            alignX_ = alignX;
            alignY_ = alignY;
            //pretty much arbitrary, something better might be needed in future
            lineGap_ = max(2u, fontSize_ / 6);

            aligned_ = false;
        }

        override void draw(VideoDriver driver)
        {
            if(!visible_){return;}

            super.draw(driver);

            driver.font = font_;
            driver.fontSize = fontSize_;
            foreach(ref line; lines_)
            {
                driver.drawText(bounds_.min + line.offset, line.text, fontColor_);
            }
        }

        override void realign(VideoDriver driver)
        {
            super.realign(driver);

            string text = text_.idup;

            //we need to set font to get information about drawn size of lines
            driver.font = font_;
            driver.fontSize = fontSize_;
            lines_ = [];
            uint yOffset;

            //break text to lines and align them horizontally, then align vertically
            while(text.length > 0){text = addLine(driver, text, yOffset, yOffset);}

            alignVertical();
        }

    private:
        //This code is pretty horrible. Need a serious, even if not feature-rich layout engine.
        /**
         * Add a TextLine from the text, and return rest of the text.
         *
         * Params:  driver       = VideoDriver used for text size measurement.
         *          text         = Text to get the line from.
         *          yOffsetIn  = Y offset to use for this line.
         *          yOffsetOut = Y offset to use for the next line will be written here.
         *
         * Returns: Remaining text that isn't part of the newly added line.
         */
        string addLine(VideoDriver driver, string text, in 
                        uint yOffsetIn, out uint yOffsetOut)
        {
            //get leading space, if any, and following word from text
            //also, break the line if (unix) newline found
            string getWord(out bool endLine)
            {
                endLine = false;
                uint end;
                //get leading space
                foreach(i, dchar c; text)
                {
                    if(!isWhite(c)){break;}
                    //break at newline
                    else if(c == '\n')
                    {
                        endLine = true;
                        return text[0 .. end];
                    }
                    ++end;
                }
                //get the word
                foreach(dchar c; text[end .. $])
                {
                    if(isWhite(c)){break;}
                    //break at newline
                    else if(c == '\n')
                    {
                        endLine = true;
                        return text[0 .. end];
                    }
                    ++end;
                }
                return text[0 .. end];
            }

            //line we're constructing
            TextLine line;
            const uint width = size.x;
            bool endLine = false;

            while(text.length > 0)
            {
                string word = getWord(endLine);

                //can we add word to the line without passing width?
                Vector2u lineSize = driver.textSize(line.text ~ word);
                if(lineSize.x > width || endLine)
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
                    yOffsetOut = yOffsetIn + lineSize.y + lineGap_;
                    break;
                }
                else
                {
                    line.text ~= word;
                    text = text[word.length .. $];
                }
            }

            //align the line horizontally
            line.offset = Vector2i(0, yOffsetIn);
            const textWidth = driver.textSize(line.text).x;
            line.offset.x  = alignX_ == AlignX.Right  ? width - textWidth :
                             alignX_ == AlignX.Center ? (width - textWidth) / 2
                             : line.offset.x;
                                           
            lines_ ~= line;
            //strip leading space so the next line doesn't start with space
            return stripLeft(text);
        }
        
        ///Align lines verically.
        void alignVertical()
        {
            //if AlignY is Top, we're aligned as lines start at y == 0 by default
            if(lines_.length == 0 || alignY_ == AlignY.Top){return;}
            const textHeight = fontSize_ * lines_.length + lineGap_ * (lines_.length - 1);
            auto offsetY = size.y - textHeight;
            if(alignY_ == AlignY.Center){offsetY /= 2;}
            //move lines according to the offset
            foreach(ref line; lines_){line.offset.y += offsetY;}
        }
}               

/**
 * Factory used for static text construction.
 *
 * See_Also: GUIElementFactoryBase
 *
 * Params:  drawBorder = Draw border of the element?
 *                        Default; false
 *          textColor  = Color of the text.
 *                        Default; Color.white
 *          text        = Text to display.
 *                        Default; ""
 *          alignX     = Horizontal alignment of the text.
 *                        Default; AlignX.Left
 *          alignY     = Vertical alignment of the text.
 *                        Default; AlignY.Top
 *          fontSize   = Size of text font.
 *          font        = Name of the font to use.
 *                        Default; "default"
 */
final class GUIStaticTextFactory : GUIElementFactoryBase!GUIStaticText
{
    mixin(generateFactory(`Color  $ textColor $ Color.white`, 
                           `string $ text       $ ""`, 
                           `AlignX $ alignX    $ AlignX.Left`, 
                           `AlignY $ alignY    $ AlignY.Top`, 
                           `uint   $ fontSize  $ GUIStaticText.defaultFontSize()`,
                           `string $ font       $ "default"`));

    ///Construct a GUIStaticTextFactory and initialize defaults.
    this(){drawBorder_ = false;}

    public override GUIStaticText produce()
    {
        return new GUIStaticText(guiElementParams, textColor_, text_, 
                                 alignX_, alignY_, fontSize_, font_);
    }
}
