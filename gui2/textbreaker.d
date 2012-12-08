//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// A struct handling breaking of text into lines.
module gui2.textbreaker;

import std.algorithm;
import std.array;
import std.conv;
import std.string;
import std.traits;
import std.uni;

import math.vector2;


/// Breaks up a text into lines of specified width.
struct TextBreaker(S) if(isSomeString!S)
{
private:
    // Text being parsed/broken into lines.
    //
    // One code point is always one character.
    S text_;
    // Lines the text has been broken into.
    S[] lines_;
    // Sizes of lines from lines_ in pixels.
    Vector2u[] lineSizes_;
    // Maximum line width in pixels. Single-word lines might end up being wider.
    uint maxLineWidthPixels_;

    // Line currently being built, not yet added to lines_.
    //
    // This is a slice into text_, and might have leading and/or trailing spaces.
    S line_;
    // Size of line_ in pixels.
    Vector2u lineSize_;
    // Index of the first character in line_.
    size_t lineStart_ = 0;
    // Number of words in line_.
    uint wordCount_ = 0;
    // Current candidate for the index of the last character in line_.
    //
    // Also the currently parsed character.
    size_t candidateLineEnd_ = 0;

    // Current parsing function.
    void delegate(const dchar) state_;
    // Returns size of a string in pixels.
    Vector2u delegate(S) getTextSize_;

public:
    /// Access lines of broken text.
    @property const(S[]) lines() const pure nothrow {return lines_;}

    /// Access line sizes (in pixels) of lines from the "lines" property.
    @property const(Vector2u[]) lineSizes() const pure nothrow {return lineSizes_;}

    /// Parse and break text into lines.
    ///
    /// Params:  text        = Text to break. The user must ensure that each
    ///                        code point in this string corresponds exactly to
    ///                        1 character. This is required to avoid allocations
    ///                        using slicing.
    ///          width       = Maximum width of a line in pixels.
    ///                        Note that if a single word in text is wider
    ///                        than this, it will not be broken and result
    ///                        in a wider line.
    ///          getTextSize = Delegate that takes a string and returns its
    ///                        size in pixels.
    void parse(const S text, const uint width, Vector2u delegate(S) getTextSize)
    {
        text_               = text.strip;
        maxLineWidthPixels_ = width;
        state_              = &parseWord;

        // We've stripped the text, so if there is anything at all to parse,
        // it starts with a word.
        getTextSize_        = getTextSize;

        // Clean up state remaining from previous parse() calls.
        lines_.length = lineSizes_.length = lineStart_ = wordCount_ = 0;

        // Parse.
        for (candidateLineEnd_ = 0; candidateLineEnd_ < text.length;)
        {
            const c = cast(dchar)text[candidateLineEnd_];
            ++ candidateLineEnd_;
            state_(c);
        }
        // If we did break before the last word, we still need to draw
        // the last word. (addLine ignores if there is no text left).
        lineSize_ = getTextSize_(line_.strip);
        addLine();

        // Allow GC to reuse the arrays.
        lines_.assumeSafeAppend();
        lineSizes_.assumeSafeAppend();
    }

private:
    // Add another line to the text.
    void addLine()
    {
        if(line_.empty){return;}
        lines_     ~= line_.strip;
        lineSizes_ ~= lineSize_;
        // Prevent GC from reallocating the arrays next time we add something.
        lines_.assumeSafeAppend();
        lineSizes_.assumeSafeAppend();
        lineStart_ += line_.length;
    }

    // Called at the end of a word to break text if the current line is too wide.
    void breakTextIfNeeded()
    {
        const testLine = text_[lineStart_ .. candidateLineEnd_];
        const testSize = getTextSize_(testLine.strip);
        // Too wide, need to break.
        if(testSize.x > maxLineWidthPixels_)
        {
            // 1 word is wider than maxLineWidthPixels_, 
            // can't break it further, so draw anyway.
            if(wordCount_ == 1)
            {
                lineSize_  = testSize;
                line_      = testLine;
                addLine();
                wordCount_ = 0;
                line_      = cast(S)"";
                return;
            }

            // We added a word, testLine too wide, so break before the word
            // and it will remain for the next line.
            addLine();
            wordCount_ = 1;
            line_ = text_[lineStart_ .. candidateLineEnd_];
            lineSize_ = getTextSize_(line_.strip);
            return;
        }
        // We still fit into the line, update line and size.
        lineSize_ = testSize;
        line_     = testLine;
    }

    // Parses a word character, breaking text after encountering whitespace.
    void parseWord(const dchar c)
    {
        // If we reach a space or end of text, break a line.
        if(!isWhite(c) && candidateLineEnd_ != text_.length) {return;}
        state_ = &parseGap;
        ++ wordCount_;
        breakTextIfNeeded();
    }

    // Parses a character in a gap between words.
    void parseGap(const dchar c)
    {
        if(!isWhite(c) && candidateLineEnd_ != text_.length) {state_ = &parseWord;}
    }
}
