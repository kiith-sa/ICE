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
 * * Neither the names 'Derelict', 'DerelictFT', nor the names of its contributors
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
/** This module is a collection of all functions defined in the freetype 2 header files, plus
 * library loading/binding code, as of version 2.3.5.
 *
 * Comments show which files the definitions are from; brackets show which C macros include the
 * file (excluding the inclusion of freetype.h in most files).
 */
module derelict.freetype.ftfuncs;

private
{
    import derelict.freetype.fttypes;
    import derelict.util.loader;
}

package void loadFT(SharedLib lib)
{
    // freetype.h (FT_FREETYPE_H)
    bindFunc(FT_Init_FreeType)("FT_Init_FreeType", lib);
    bindFunc(FT_Done_FreeType)("FT_Done_FreeType", lib);
    bindFunc(FT_New_Face)("FT_New_Face", lib);
    bindFunc(FT_New_Memory_Face)("FT_New_Memory_Face", lib);
    bindFunc(FT_Open_Face)("FT_Open_Face", lib);
    bindFunc(FT_Attach_File)("FT_Attach_File", lib);
    bindFunc(FT_Attach_Stream)("FT_Attach_Stream", lib);
    bindFunc(FT_Done_Face)("FT_Done_Face", lib);
    bindFunc(FT_Select_Size)("FT_Select_Size", lib);
    bindFunc(FT_Request_Size)("FT_Request_Size", lib);
    bindFunc(FT_Set_Char_Size)("FT_Set_Char_Size", lib);
    bindFunc(FT_Set_Pixel_Sizes)("FT_Set_Pixel_Sizes", lib);
    bindFunc(FT_Load_Glyph)("FT_Load_Glyph", lib);
    bindFunc(FT_Load_Char)("FT_Load_Char", lib);
    bindFunc(FT_Set_Transform)("FT_Set_Transform", lib);
    bindFunc(FT_Render_Glyph)("FT_Render_Glyph", lib);
    bindFunc(FT_Get_Kerning)("FT_Get_Kerning", lib);
    bindFunc(FT_Get_Track_Kerning)("FT_Get_Track_Kerning", lib);
    bindFunc(FT_Get_Glyph_Name)("FT_Get_Glyph_Name", lib);
    bindFunc(FT_Get_Postscript_Name)("FT_Get_Postscript_Name", lib);
    bindFunc(FT_Select_Charmap)("FT_Select_Charmap", lib);
    bindFunc(FT_Set_Charmap)("FT_Set_Charmap", lib);
    bindFunc(FT_Get_Charmap_Index)("FT_Get_Charmap_Index", lib);
    bindFunc(FT_Get_Char_Index)("FT_Get_Char_Index", lib);
    bindFunc(FT_Get_First_Char)("FT_Get_First_Char", lib);
    bindFunc(FT_Get_Next_Char)("FT_Get_Next_Char", lib);
    bindFunc(FT_Get_Name_Index)("FT_Get_Name_Index", lib);
    bindFunc(FT_MulDiv)("FT_MulDiv", lib);
    bindFunc(FT_MulFix)("FT_MulFix", lib);
    bindFunc(FT_DivFix)("FT_DivFix", lib);
    bindFunc(FT_RoundFix)("FT_RoundFix", lib);
    bindFunc(FT_CeilFix)("FT_CeilFix", lib);
    bindFunc(FT_FloorFix)("FT_FloorFix", lib);
    bindFunc(FT_Vector_Transform)("FT_Vector_Transform", lib);
    bindFunc(FT_Library_Version)("FT_Library_Version", lib);
    bindFunc(FT_Face_CheckTrueTypePatents)("FT_Face_CheckTrueTypePatents", lib);
    bindFunc(FT_Face_SetUnpatentedHinting)("FT_Face_SetUnpatentedHinting", lib);

    // ftlist.h (FT_LIST_H)
    bindFunc(FT_List_Find)("FT_List_Find", lib);
    bindFunc(FT_List_Add)("FT_List_Add", lib);
    bindFunc(FT_List_Insert)("FT_List_Insert", lib);
    bindFunc(FT_List_Remove)("FT_List_Remove", lib);
    bindFunc(FT_List_Up)("FT_List_Up", lib);
    bindFunc(FT_List_Iterate)("FT_List_Iterate", lib);
    bindFunc(FT_List_Finalize)("FT_List_Finalize", lib);

    // ftoutln (FT_OUTLINE_H, FT_STROKER_H)
    bindFunc(FT_Outline_Decompose)("FT_Outline_Decompose", lib);
    bindFunc(FT_Outline_New)("FT_Outline_New", lib);
    bindFunc(FT_Outline_New_Internal)("FT_Outline_New_Internal", lib);
    bindFunc(FT_Outline_Done)("FT_Outline_Done", lib);
    bindFunc(FT_Outline_Done_Internal)("FT_Outline_Done_Internal", lib);
    bindFunc(FT_Outline_Check)("FT_Outline_Check", lib);
    bindFunc(FT_Outline_Get_CBox)("FT_Outline_Get_CBox", lib);
    bindFunc(FT_Outline_Translate)("FT_Outline_Translate", lib);
    bindFunc(FT_Outline_Copy)("FT_Outline_Copy", lib);
    bindFunc(FT_Outline_Transform)("FT_Outline_Transform", lib);
    bindFunc(FT_Outline_Embolden)("FT_Outline_Embolden", lib);
    bindFunc(FT_Outline_Reverse)("FT_Outline_Reverse", lib);
    bindFunc(FT_Outline_Get_Bitmap)("FT_Outline_Get_Bitmap", lib);
    bindFunc(FT_Outline_Render)("FT_Outline_Render", lib);
    bindFunc(FT_Outline_Get_Orientation)("FT_Outline_Get_Orientation", lib);

    // ftsizes.h (FT_SIZES_H)
    bindFunc(FT_New_Size)("FT_New_Size", lib);
    bindFunc(FT_Done_Size)("FT_Done_Size", lib);
    bindFunc(FT_Activate_Size)("FT_Activate_Size", lib);

    // ftmodapi.h (FT_MODULE_H, FT_RENDER_H)
    bindFunc(FT_Add_Module)("FT_Add_Module", lib);
    bindFunc(FT_Get_Module)("FT_Get_Module", lib);
    bindFunc(FT_Remove_Module)("FT_Remove_Module", lib);
    bindFunc(FT_New_Library)("FT_New_Library", lib);
    bindFunc(FT_Done_Library)("FT_Done_Library", lib);
    bindFunc(FT_Set_Debug_Hook)("FT_Set_Debug_Hook", lib);
    bindFunc(FT_Add_Default_Modules)("FT_Add_Default_Modules", lib);
    bindFunc(FT_Get_TrueType_Engine_Type)("FT_Get_TrueType_Engine_Type", lib);

    // ftrender.h (FT_RENDER_H)
    bindFunc(FT_Get_Renderer)("FT_Get_Renderer", lib);
    bindFunc(FT_Set_Renderer)("FT_Set_Renderer", lib);

    // t1tables.h (FT_TYPE1_TABLES_H)
    bindFunc(FT_Has_PS_Glyph_Names)("FT_Has_PS_Glyph_Names", lib);
    bindFunc(FT_Get_PS_Font_Info)("FT_Get_PS_Font_Info", lib);
    bindFunc(FT_Get_PS_Font_Private)("FT_Get_PS_Font_Private", lib);

    // tttables.h (FT_TRUETYPE_TABLES_H)
    bindFunc(FT_Get_Sfnt_Table)("FT_Get_Sfnt_Table", lib);
    bindFunc(FT_Load_Sfnt_Table)("FT_Load_Sfnt_Table", lib);
    bindFunc(FT_Sfnt_Table_Info)("FT_Sfnt_Table_Info", lib);
    bindFunc(FT_Get_CMap_Language_ID)("FT_Get_CMap_Language_ID", lib);
    bindFunc(FT_Get_CMap_Format)("FT_Get_CMap_Format", lib);

    // ftbdf.h (FT_BDF_H)
    bindFunc(FT_Get_BDF_Charset_ID)("FT_Get_BDF_Charset_ID", lib);
    bindFunc(FT_Get_BDF_Property)("FT_Get_BDF_Property", lib);

    // ftgzip.h (FT_GZIP_H)
    bindFunc(FT_Stream_OpenGzip)("FT_Stream_OpenGzip", lib);

    // ftlzw.h (FT_LZW_H)
    bindFunc(FT_Stream_OpenLZW)("FT_Stream_OpenLZW", lib);

    // ftwinfnt.h (FT_WINFONTS_H)
    bindFunc(FT_Get_WinFNT_Header)("FT_Get_WinFNT_Header", lib);

    // ftglyph.h (FT_GLYPH_H, FT_CACHE_H, FT_STROKER_H)
    bindFunc(FT_Get_Glyph)("FT_Get_Glyph", lib);
    bindFunc(FT_Glyph_Copy)("FT_Glyph_Copy", lib);
    bindFunc(FT_Glyph_Transform)("FT_Glyph_Transform", lib);
    bindFunc(FT_Glyph_Get_CBox)("FT_Glyph_Get_CBox", lib);
    bindFunc(FT_Glyph_To_Bitmap)("FT_Glyph_To_Bitmap", lib);
    bindFunc(FT_Done_Glyph)("FT_Done_Glyph", lib);
    bindFunc(FT_Matrix_Multiply)("FT_Matrix_Multiply", lib);
    bindFunc(FT_Matrix_Invert)("FT_Matrix_Invert", lib);

    // ftbitmap.h (FT_BITMAP_H)
    bindFunc(FT_Bitmap_New)("FT_Bitmap_New", lib);
    bindFunc(FT_Bitmap_Copy)("FT_Bitmap_Copy", lib);
    bindFunc(FT_Bitmap_Embolden)("FT_Bitmap_Embolden", lib);
    bindFunc(FT_Bitmap_Convert)("FT_Bitmap_Convert", lib);
    bindFunc(FT_Bitmap_Done)("FT_Bitmap_Done", lib);

    // ftbbox.h (FT_BBOX_H)
    bindFunc(FT_Outline_Get_BBox)("FT_Outline_Get_BBox", lib);

    // ftcache.h (FT_CACHE_H)
    bindFunc(FTC_Manager_New)("FTC_Manager_New", lib);
    bindFunc(FTC_Manager_Reset)("FTC_Manager_Reset", lib);
    bindFunc(FTC_Manager_Done)("FTC_Manager_Done", lib);
    bindFunc(FTC_Manager_LookupFace)("FTC_Manager_LookupFace", lib);
    bindFunc(FTC_Manager_LookupSize)("FTC_Manager_LookupSize", lib);
    bindFunc(FTC_Node_Unref)("FTC_Node_Unref", lib);
    bindFunc(FTC_Manager_RemoveFaceID)("FTC_Manager_RemoveFaceID", lib);
    bindFunc(FTC_CMapCache_New)("FTC_CMapCache_New", lib);
    bindFunc(FTC_CMapCache_Lookup)("FTC_CMapCache_Lookup", lib);
    bindFunc(FTC_ImageCache_New)("FTC_ImageCache_New", lib);
    bindFunc(FTC_ImageCache_Lookup)("FTC_ImageCache_Lookup", lib);
    bindFunc(FTC_ImageCache_LookupScaler)("FTC_ImageCache_LookupScaler", lib);
    bindFunc(FTC_SBitCache_New)("FTC_SBitCache_New", lib);
    bindFunc(FTC_SBitCache_Lookup)("FTC_SBitCache_Lookup", lib);
    bindFunc(FTC_SBitCache_LookupScaler)("FTC_SBitCache_LookupScaler", lib);

    // ftmm.h (FT_MULTIPLE_MASTERS_H)
    bindFunc(FT_Get_Multi_Master)("FT_Get_Multi_Master", lib);
    bindFunc(FT_Get_MM_Var)("FT_Get_MM_Var", lib);
    bindFunc(FT_Set_MM_Design_Coordinates)("FT_Set_MM_Design_Coordinates", lib);
    bindFunc(FT_Set_Var_Design_Coordinates)("FT_Set_Var_Design_Coordinates", lib);
    bindFunc(FT_Set_MM_Blend_Coordinates)("FT_Set_MM_Blend_Coordinates", lib);
    bindFunc(FT_Set_Var_Blend_Coordinates)("FT_Set_Var_Blend_Coordinates", lib);

    // ftsnames.h (FT_SFNT_NAMES_H)
    bindFunc(FT_Get_Sfnt_Name_Count)("FT_Get_Sfnt_Name_Count", lib);
    bindFunc(FT_Get_Sfnt_Name)("FT_Get_Sfnt_Name", lib);

    // ftotval.h (FT_OPENTYPE_VALIDATE_H)
    bindFunc(FT_OpenType_Validate)("FT_OpenType_Validate", lib);
    bindFunc(FT_OpenType_Free)("FT_OpenType_Free", lib);

    // ftgxval.h (FT_GX_VALIDATE_H)
    bindFunc(FT_TrueTypeGX_Validate)("FT_TrueTypeGX_Validate", lib);
    bindFunc(FT_TrueTypeGX_Free)("FT_TrueTypeGX_Free", lib);
    bindFunc(FT_ClassicKern_Validate)("FT_ClassicKern_Validate", lib);
    bindFunc(FT_ClassicKern_Free)("FT_ClassicKern_Free", lib);

    // ftpfr (FT_PFR_H)
    bindFunc(FT_Get_PFR_Metrics)("FT_Get_PFR_Metrics", lib);
    bindFunc(FT_Get_PFR_Kerning)("FT_Get_PFR_Kerning", lib);
    bindFunc(FT_Get_PFR_Advance)("FT_Get_PFR_Advance", lib);

    // ftstroke.h (FT_STROKER_H)
    bindFunc(FT_Outline_GetInsideBorder)("FT_Outline_GetInsideBorder", lib);
    bindFunc(FT_Outline_GetOutsideBorder)("FT_Outline_GetOutsideBorder", lib);
    bindFunc(FT_Stroker_New)("FT_Stroker_New", lib);
    bindFunc(FT_Stroker_Set)("FT_Stroker_Set", lib);
    bindFunc(FT_Stroker_Rewind)("FT_Stroker_Rewind", lib);
    bindFunc(FT_Stroker_ParseOutline)("FT_Stroker_ParseOutline", lib);
    bindFunc(FT_Stroker_BeginSubPath)("FT_Stroker_BeginSubPath", lib);
    bindFunc(FT_Stroker_EndSubPath)("FT_Stroker_EndSubPath", lib);
    bindFunc(FT_Stroker_LineTo)("FT_Stroker_LineTo", lib);
    bindFunc(FT_Stroker_ConicTo)("FT_Stroker_ConicTo", lib);
    bindFunc(FT_Stroker_CubicTo)("FT_Stroker_CubicTo", lib);
    bindFunc(FT_Stroker_GetBorderCounts)("FT_Stroker_GetBorderCounts", lib);
    bindFunc(FT_Stroker_ExportBorder)("FT_Stroker_ExportBorder", lib);
    bindFunc(FT_Stroker_GetCounts)("FT_Stroker_GetCounts", lib);
    bindFunc(FT_Stroker_Export)("FT_Stroker_Export", lib);
    bindFunc(FT_Stroker_Done)("FT_Stroker_Done", lib);
    bindFunc(FT_Glyph_Stroke)("FT_Glyph_Stroke", lib);
    bindFunc(FT_Glyph_StrokeBorder)("FT_Glyph_StrokeBorder", lib);

    // ftsynth.h (FT_SYNTHESIS_H) (WARNING: ALPHA CODE)
    bindFunc(FT_GlyphSlot_Own_Bitmap)("FT_GlyphSlot_Own_Bitmap", lib);
    bindFunc(FT_GlyphSlot_Embolden)("FT_GlyphSlot_Embolden", lib);
    bindFunc(FT_GlyphSlot_Oblique)("FT_GlyphSlot_Oblique", lib);

    // ftxf86.h (FT_XFREE86_H)
    bindFunc(FT_Get_X11_Font_Format)("FT_Get_X11_Font_Format", lib);

    // fttrigon.h (FT_TRIGONOMETRY_H)
    bindFunc(FT_Sin)("FT_Sin", lib);
    bindFunc(FT_Cos)("FT_Cos", lib);
    bindFunc(FT_Tan)("FT_Tan", lib);
    bindFunc(FT_Atan2)("FT_Atan2", lib);
    bindFunc(FT_Angle_Diff)("FT_Angle_Diff", lib);
    bindFunc(FT_Vector_Unit)("FT_Vector_Unit", lib);
    bindFunc(FT_Vector_Rotate)("FT_Vector_Rotate", lib);
    bindFunc(FT_Vector_Length)("FT_Vector_Length", lib);
    bindFunc(FT_Vector_Polarize)("FT_Vector_Polarize", lib);
    bindFunc(FT_Vector_From_Polar)("FT_Vector_From_Polar", lib);

    // ftlcdfil.h (FT_LCD_FILTER_H)
    bindFunc(FT_Library_SetLcdFilter)("FT_Library_SetLcdFilter", lib);

    // ftgasp.h (FT_GASP_H)
    bindFunc(FT_Get_Gasp)("FT_Get_Gasp", lib);

    /+ other
    //bindFunc(ftc_node_destroy)("ftc_node_destroy", lib);
    bindFunc(FT_Alloc)("FT_Alloc", lib);
    bindFunc(FT_QAlloc)("FT_QAlloc", lib);
    bindFunc(FT_Realloc)("FT_Realloc", lib);
    bindFunc(FT_QRealloc)("FT_QRealloc", lib);
    bindFunc(FT_Free)("FT_Free", lib);
    bindFunc(FT_GlyphLoader_New)("FT_GlyphLoader_New", lib);
    bindFunc(FT_GlyphLoader_CreateExtra)("FT_GlyphLoader_CreateExtra", lib);
    bindFunc(FT_GlyphLoader_Done)("FT_GlyphLoader_Done", lib);
    bindFunc(FT_GlyphLoader_Reset)("FT_GlyphLoader_Reset", lib);
    bindFunc(FT_GlyphLoader_Rewind)("FT_GlyphLoader_Rewind", lib);
    bindFunc(FT_GlyphLoader_CheckPoints)("FT_GlyphLoader_CheckPoints", lib);
    bindFunc(FT_GlyphLoader_CheckSubGlyphs)("FT_GlyphLoader_CheckSubGlyphs", lib);
    bindFunc(FT_GlyphLoader_Prepare)("FT_GlyphLoader_Prepare", lib);
    bindFunc(FT_GlyphLoader_Add)("FT_GlyphLoader_Add", lib);
    bindFunc(FT_GlyphLoader_CopyPoints)("FT_GlyphLoader_CopyPoints", lib);
    bindFunc(ft_service_list_lookup)("ft_service_list_lookup", lib);
    bindFunc(FT_CMap_New)("FT_CMap_New", lib);
    bindFunc(FT_CMap_Done)("FT_CMap_Done", lib);
    bindFunc(FT_Get_Module_Interface)("FT_Get_Module_Interface", lib);
    bindFunc(ft_module_get_service)("ft_module_get_service", lib);
    bindFunc(FT_New_GlyphSlot)("FT_New_GlyphSlot", lib);
    bindFunc(FT_Done_GlyphSlot)("FT_Done_GlyphSlot", lib);
    bindFunc(ft_glyphslot_free_bitmap)("ft_glyphslot_free_bitmap", lib);
    bindFunc(ft_glyphslot_alloc_bitmap)("ft_glyphslot_alloc_bitmap", lib);
    bindFunc(ft_glyphslot_set_bitmap)("ft_glyphslot_set_bitmap", lib);
    bindFunc(FT_Lookup_Renderer)("FT_Lookup_Renderer", lib);
    bindFunc(FT_Render_Glyph_Internal)("FT_Render_Glyph_Internal", lib);
    bindFunc(FT_New_Memory)("FT_New_Memory", lib);
    bindFunc(FT_Done_Memory)("FT_Done_Memory", lib);
    bindFunc(FT_Stream_Open)("FT_Stream_Open", lib);
    bindFunc(FT_Stream_New)("FT_Stream_New", lib);
    bindFunc(FT_Stream_Free)("FT_Stream_Free", lib);
    bindFunc(FT_Stream_OpenMemory)("FT_Stream_OpenMemory", lib);
    bindFunc(FT_Stream_Close)("FT_Stream_Close", lib);
    bindFunc(FT_Stream_Seek)("FT_Stream_Seek", lib);
    bindFunc(FT_Stream_Skip)("FT_Stream_Skip", lib);
    bindFunc(FT_Stream_Pos)("FT_Stream_Pos", lib);
    bindFunc(FT_Stream_Read)("FT_Stream_Read", lib);
    bindFunc(FT_Stream_ReadAt)("FT_Stream_ReadAt", lib);
    bindFunc(FT_Stream_TryRead)("FT_Stream_TryRead", lib);
    bindFunc(FT_Stream_EnterFrame)("FT_Stream_EnterFrame", lib);
    bindFunc(FT_Stream_ExitFrame)("FT_Stream_ExitFrame", lib);
    bindFunc(FT_Stream_ExtractFrame)("FT_Stream_ExtractFrame", lib);
    bindFunc(FT_Stream_ReleaseFrame)("FT_Stream_ReleaseFrame", lib);
    bindFunc(FT_Stream_GetChar)("FT_Stream_GetChar", lib);
    bindFunc(FT_Stream_GetShort)("FT_Stream_GetShort", lib);
    bindFunc(FT_Stream_GetOffset)("FT_Stream_GetOffset", lib);
    bindFunc(FT_Stream_GetLong)("FT_Stream_GetLong", lib);
    bindFunc(FT_Stream_GetShortLE)("FT_Stream_GetShortLE", lib);
    bindFunc(FT_Stream_GetLongLE)("FT_Stream_GetLongLE", lib);
    bindFunc(FT_Stream_ReadChar)("FT_Stream_ReadChar", lib);
    bindFunc(FT_Stream_ReadShort)("FT_Stream_ReadShort", lib);
    bindFunc(FT_Stream_ReadOffset)("FT_Stream_ReadOffset", lib);
    bindFunc(FT_Stream_ReadLong)("FT_Stream_ReadLong", lib);
    bindFunc(FT_Stream_ReadShortLE)("FT_Stream_ReadShortLE", lib);
    bindFunc(FT_Stream_ReadLongLE)("FT_Stream_ReadLongLE", lib);
    bindFunc(FT_Stream_ReadFields)("FT_Stream_ReadFields", lib);
    bindFunc(FT_Trace_Get_Count)("FT_Trace_Get_Count", lib);
    bindFunc(FT_Trace_Get_Name)("FT_Trace_Get_Name", lib);
    bindFunc(ft_debug_init)("ft_debug_init", lib);
    bindFunc(FT_SqrtFixed)("FT_SqrtFixed", lib);
    bindFunc(FT_Raccess_Guess)("FT_Raccess_Guess", lib);
    bindFunc(FT_Raccess_Get_HeaderInfo)("FT_Raccess_Get_HeaderInfo", lib);
    bindFunc(FT_Raccess_Get_DataOffsets)("FT_Raccess_Get_DataOffsets", lib);
    bindFunc(ft_validator_init)("ft_validator_init", lib);
    bindFunc(ft_validator_run)("ft_validator_run", lib);
    bindFunc(ft_validator_error)("ft_validator_error", lib);
    +/
}

GenericLoader DerelictFT;
static this() {
    DerelictFT.setup(
        "freetype.dll",
        "libfreetype.so.6,libfreetype.so",
        "libfreetype.dylib,libfreetype.6.dylib,libfreetype.6.3.16.dylib,/usr/X11/lib/libfreetype.dylib,/usr/X11/lib/libfreetype.6.dylib,/usr/X11/lib/libfreetype.6.3.16.dylib",
        &loadFT,
        "2.1.10"
    );
}

extern(C)
{
    // freetype.h (FT_FREETYPE_H)
    FT_Error function( FT_Library *alibrary ) FT_Init_FreeType;
    FT_Error function( FT_Library library ) FT_Done_FreeType;
    FT_Error function( FT_Library library, char* filepathname, FT_Long face_index, FT_Face *aface ) FT_New_Face;
    FT_Error function( FT_Library library, FT_Byte* file_base, FT_Long file_size, FT_Long face_index, FT_Face *aface ) FT_New_Memory_Face;
    FT_Error function( FT_Library library, FT_Open_Args* args, FT_Long face_index, FT_Face *aface ) FT_Open_Face;
    FT_Error function( FT_Face face, char* filepathname ) FT_Attach_File;
    FT_Error function( FT_Face face, FT_Open_Args* parameters ) FT_Attach_Stream;
    FT_Error function( FT_Face face ) FT_Done_Face;
    FT_Error function( FT_Face face, FT_Int strike_index ) FT_Select_Size;
    FT_Error function( FT_Face face, FT_Size_Request req ) FT_Request_Size;
    FT_Error function( FT_Face face, FT_F26Dot6 char_width, FT_F26Dot6 char_height, FT_UInt horz_resolution, FT_UInt vert_resolution ) FT_Set_Char_Size;
    FT_Error function( FT_Face face, FT_UInt pixel_width, FT_UInt pixel_height ) FT_Set_Pixel_Sizes;
    FT_Error function( FT_Face face, FT_UInt glyph_index, FT_Int32 load_flags ) FT_Load_Glyph;
    FT_Error function( FT_Face face, FT_ULong char_code, FT_Int32 load_flags ) FT_Load_Char;
    void function( FT_Face face, FT_Matrix* matrix, FT_Vector* delta ) FT_Set_Transform;
    FT_Error function( FT_GlyphSlot slot, FT_Render_Mode render_mode ) FT_Render_Glyph;
    FT_Error function( FT_Face face, FT_UInt left_glyph, FT_UInt right_glyph, FT_UInt kern_mode, FT_Vector *akerning ) FT_Get_Kerning;
    FT_Error function( FT_Face face, FT_Fixed point_size, FT_Int degree, FT_Fixed* akerning ) FT_Get_Track_Kerning;
    FT_Error function( FT_Face face, FT_UInt glyph_index, FT_Pointer buffer, FT_UInt buffer_max ) FT_Get_Glyph_Name;
    char* function( FT_Face face ) FT_Get_Postscript_Name;
    FT_Error function( FT_Face face, FT_Encoding encoding ) FT_Select_Charmap;
    FT_Error function( FT_Face face, FT_CharMap charmap ) FT_Set_Charmap;
    FT_Int function( FT_CharMap charmap ) FT_Get_Charmap_Index;
    FT_UInt function( FT_Face face, FT_ULong charcode ) FT_Get_Char_Index;
    FT_ULong function( FT_Face face, FT_UInt *agindex ) FT_Get_First_Char;
    FT_ULong function( FT_Face face, FT_ULong char_code, FT_UInt *agindex ) FT_Get_Next_Char;
    FT_UInt function( FT_Face face, FT_String* glyph_name ) FT_Get_Name_Index;
    FT_Long function( FT_Long a, FT_Long b, FT_Long c ) FT_MulDiv;
    FT_Long function( FT_Long a, FT_Long b ) FT_MulFix;
    FT_Long function( FT_Long a, FT_Long b ) FT_DivFix;
    FT_Fixed function( FT_Fixed a ) FT_RoundFix;
    FT_Fixed function( FT_Fixed a ) FT_CeilFix;
    FT_Fixed function( FT_Fixed a ) FT_FloorFix;
    void function( FT_Vector* vec, FT_Matrix* matrix ) FT_Vector_Transform;
    void function( FT_Library library, FT_Int *amajor, FT_Int *aminor, FT_Int *apatch ) FT_Library_Version;
    FT_Bool function( FT_Face face ) FT_Face_CheckTrueTypePatents;
    FT_Bool function( FT_Face face, FT_Bool value ) FT_Face_SetUnpatentedHinting;

    // ftlist.h (FT_LIST_H)
    FT_ListNode function( FT_List list, void* data ) FT_List_Find;
    void function( FT_List list, FT_ListNode node ) FT_List_Add;
    void function( FT_List list, FT_ListNode node ) FT_List_Insert;
    void function( FT_List list, FT_ListNode node ) FT_List_Remove;
    void function( FT_List list, FT_ListNode node ) FT_List_Up;
    FT_Error function( FT_List list, FT_List_Iterator iterator, void* user ) FT_List_Iterate;
    void function( FT_List list, FT_List_Destructor destroy, FT_Memory memory, void* user ) FT_List_Finalize;

    // ftoutln.h (FT_OUTLINE_H, FT_STROKER_H)
    FT_Error function( FT_Outline* outline, FT_Outline_Funcs* func_interface, void* user ) FT_Outline_Decompose;
    FT_Error function( FT_Library library, FT_UInt numPoints, FT_Int numContours, FT_Outline *anoutline ) FT_Outline_New;
    FT_Error function( FT_Memory memory, FT_UInt numPoints, FT_Int numContours, FT_Outline *anoutline ) FT_Outline_New_Internal;
    FT_Error function( FT_Library library, FT_Outline* outline ) FT_Outline_Done;
    FT_Error function( FT_Memory memory, FT_Outline* outline ) FT_Outline_Done_Internal;
    FT_Error function( FT_Outline* outline ) FT_Outline_Check;
    void function( FT_Outline* outline, FT_BBox *acbox ) FT_Outline_Get_CBox;
    void function( FT_Outline* outline, FT_Pos xOffset, FT_Pos yOffset ) FT_Outline_Translate;
    FT_Error function( FT_Outline* source, FT_Outline *target ) FT_Outline_Copy;
    void function( FT_Outline* outline, FT_Matrix* matrix ) FT_Outline_Transform;
    FT_Error function( FT_Outline* outline, FT_Pos strength ) FT_Outline_Embolden;
    void function( FT_Outline* outline ) FT_Outline_Reverse;
    FT_Error function( FT_Library library, FT_Outline* outline, FT_Bitmap *abitmap ) FT_Outline_Get_Bitmap;
    FT_Error function( FT_Library library, FT_Outline* outline, FT_Raster_Params* params ) FT_Outline_Render;
    FT_Orientation function( FT_Outline* outline ) FT_Outline_Get_Orientation;

    // ftsizes.h (FT_SIZES_H)
    FT_Error function( FT_Face face, FT_Size* size ) FT_New_Size;
    FT_Error function( FT_Size size ) FT_Done_Size;
    FT_Error function( FT_Size size ) FT_Activate_Size;

    // ftmodapi.h (FT_MODULE_H, FT_RENDER_H)
    FT_Error function( FT_Library library, FT_Module_Class* clazz ) FT_Add_Module;
    FT_Module function( FT_Library library, char* module_name ) FT_Get_Module;
    FT_Error function( FT_Library library, FT_Module mod ) FT_Remove_Module;
    FT_Error function( FT_Memory memory, FT_Library *alibrary ) FT_New_Library;
    FT_Error function( FT_Library library ) FT_Done_Library;
    void function( FT_Library library, FT_UInt hook_index, FT_DebugHook_Func debug_hook ) FT_Set_Debug_Hook;
    void function( FT_Library library ) FT_Add_Default_Modules;
    FT_TrueTypeEngineType function( FT_Library library ) FT_Get_TrueType_Engine_Type;

    // ftrender.h (FT_RENDER_H)
    FT_Renderer function( FT_Library library, FT_Glyph_Format format ) FT_Get_Renderer;
    FT_Error function( FT_Library library, FT_Renderer renderer, FT_UInt num_params, FT_Parameter* parameters ) FT_Set_Renderer;

    // t1tables.h (FT_TYPE1_TABLES_H)
    FT_Int function( FT_Face face ) FT_Has_PS_Glyph_Names;
    FT_Error function( FT_Face face, PS_FontInfoRec *afont_info ) FT_Get_PS_Font_Info;
    FT_Error function( FT_Face face, PS_PrivateRec *afont_private ) FT_Get_PS_Font_Private;

    // tttables.h (FT_TRUETYPE_TABLES_H)
    void* function( FT_Face face, FT_Sfnt_Tag tag ) FT_Get_Sfnt_Table;
    FT_Error function( FT_Face face, FT_ULong tag, FT_Long offset, FT_Byte* buffer, FT_ULong* length ) FT_Load_Sfnt_Table;
    FT_Error function( FT_Face face, FT_UInt table_index, FT_ULong *tag, FT_ULong *length ) FT_Sfnt_Table_Info;
    FT_ULong function( FT_CharMap charmap ) FT_Get_CMap_Language_ID;
    FT_ULong function( FT_CharMap charmap ) FT_Get_CMap_Format;

    // ftbdf.h (FT_BDF_H)
    FT_Error function( FT_Face face, char* *acharset_encoding, char* *acharset_registry ) FT_Get_BDF_Charset_ID;
    FT_Error function( FT_Face face, char* prop_name, BDF_PropertyRec *aproperty ) FT_Get_BDF_Property;

    // ftgzip.h (FT_GZIP_H)
    FT_Error function( FT_Stream stream, FT_Stream source ) FT_Stream_OpenGzip;

    // ftlzw.h (FT_LZW_H)
    FT_Error function( FT_Stream stream, FT_Stream source ) FT_Stream_OpenLZW;

    // ftwinfnt.h (FT_WINFONTS_H)
    FT_Error function( FT_Face face, FT_WinFNT_HeaderRec *aheader ) FT_Get_WinFNT_Header;

    // ftglyph.h (FT_GLYPH_H, FT_CACHE_H, FT_STROKER_H)
    FT_Error function( FT_GlyphSlot slot, FT_Glyph *aglyph ) FT_Get_Glyph;
    FT_Error function( FT_Glyph source, FT_Glyph *target ) FT_Glyph_Copy;
    FT_Error function( FT_Glyph glyph, FT_Matrix* matrix, FT_Vector* delta ) FT_Glyph_Transform;
    void function( FT_Glyph glyph, FT_UInt bbox_mode, FT_BBox *acbox ) FT_Glyph_Get_CBox;
    FT_Error function( FT_Glyph* the_glyph, FT_Render_Mode render_mode, FT_Vector* origin, FT_Bool destroy ) FT_Glyph_To_Bitmap;
    void function( FT_Glyph glyph ) FT_Done_Glyph;
    void function( FT_Matrix* a, FT_Matrix* b ) FT_Matrix_Multiply;
    FT_Error function( FT_Matrix* matrix ) FT_Matrix_Invert;

    // ftbitmap.h (FT_BITMAP_H)
    void function( FT_Bitmap *abitmap ) FT_Bitmap_New;
    FT_Error function( FT_Library library, FT_Bitmap *source, FT_Bitmap *target) FT_Bitmap_Copy;
    FT_Error function( FT_Library library, FT_Bitmap* bitmap, FT_Pos xStrength, FT_Pos yStrength ) FT_Bitmap_Embolden;
    FT_Error function( FT_Library library, FT_Bitmap *source, FT_Bitmap *target, FT_Int alignment ) FT_Bitmap_Convert;
    FT_Error function( FT_Library library, FT_Bitmap *bitmap ) FT_Bitmap_Done;

    // ftbbox.h (FT_BBOX_H)
    FT_Error function( FT_Outline* outline, FT_BBox *abbox ) FT_Outline_Get_BBox;

    // ftcache.h (FT_CACHE_H)
    FT_Error function( FT_Library library, FT_UInt max_faces, FT_UInt max_sizes, FT_ULong max_bytes, FTC_Face_Requester requester, FT_Pointer req_data, FTC_Manager *amanager ) FTC_Manager_New;
    void function( FTC_Manager manager ) FTC_Manager_Reset;
    void function( FTC_Manager manager ) FTC_Manager_Done;
    FT_Error function( FTC_Manager manager, FTC_FaceID face_id, FT_Face *aface ) FTC_Manager_LookupFace;
    FT_Error function( FTC_Manager manager, FTC_Scaler scaler, FT_Size *asize ) FTC_Manager_LookupSize;
    void function( FTC_Node node, FTC_Manager manager ) FTC_Node_Unref;
    void function( FTC_Manager manager, FTC_FaceID face_id ) FTC_Manager_RemoveFaceID;
    FT_Error function( FTC_Manager manager, FTC_CMapCache *acache ) FTC_CMapCache_New;
    FT_UInt function( FTC_CMapCache cache, FTC_FaceID face_id, FT_Int cmap_index, FT_UInt32 char_code ) FTC_CMapCache_Lookup;
    FT_Error function( FTC_Manager manager, FTC_ImageCache *acache ) FTC_ImageCache_New;
    FT_Error function( FTC_ImageCache cache, FTC_ImageType type, FT_UInt gindex, FT_Glyph *aglyph, FTC_Node *anode ) FTC_ImageCache_Lookup;
    FT_Error function( FTC_ImageCache cache, FTC_Scaler scaler, FT_ULong load_flags, FT_UInt gindex, FT_Glyph *aglyph, FTC_Node *anode ) FTC_ImageCache_LookupScaler;
    FT_Error function( FTC_Manager manager, FTC_SBitCache *acache ) FTC_SBitCache_New;
    FT_Error function( FTC_SBitCache cache, FTC_ImageType type, FT_UInt gindex, FTC_SBit *sbit, FTC_Node *anode ) FTC_SBitCache_Lookup;
    FT_Error function( FTC_SBitCache cache, FTC_Scaler scaler, FT_ULong load_flags, FT_UInt gindex, FTC_SBit *sbit,FTC_Node *anode ) FTC_SBitCache_LookupScaler;

    // ftmm.h (FT_MULTIPLE_MASTERS_H)
    FT_Error function( FT_Face face, FT_Multi_Master *amaster ) FT_Get_Multi_Master;
    FT_Error function( FT_Face face, FT_MM_Var* *amaster ) FT_Get_MM_Var;
    FT_Error function( FT_Face face, FT_UInt num_coords, FT_Long* coords ) FT_Set_MM_Design_Coordinates;
    FT_Error function( FT_Face face, FT_UInt num_coords, FT_Fixed* coords ) FT_Set_Var_Design_Coordinates;
    FT_Error function( FT_Face face, FT_UInt num_coords, FT_Fixed* coords ) FT_Set_MM_Blend_Coordinates;
    FT_Error function( FT_Face face, FT_UInt num_coords, FT_Fixed* coords ) FT_Set_Var_Blend_Coordinates;

    // ftsnames.h (FT_SFNT_NAMES_H)
    FT_UInt function( FT_Face face ) FT_Get_Sfnt_Name_Count;
    FT_Error function( FT_Face face, FT_UInt idx, FT_SfntName *aname ) FT_Get_Sfnt_Name;

    // ftotval.h (FT_OPENTYPE_VALIDATE_H)
    FT_Error function( FT_Face face, FT_UInt validation_flags, FT_Bytes *BASE_table, FT_Bytes *GDEF_table, FT_Bytes *GPOS_table, FT_Bytes *GSUB_table, FT_Bytes *JSTF_table ) FT_OpenType_Validate;
    void function ( FT_Face face, FT_Bytes table ) FT_OpenType_Free;
    // ftotval.h (FT_OPENTYPE_VALIDATE_H)

    // ftgxval.h (FT_GX_VALIDATE_H)
    FT_Error function( FT_Face face, FT_UInt validation_flags, FT_Bytes tables[FT_VALIDATE_GX_LENGTH], FT_UInt table_length ) FT_TrueTypeGX_Validate;
    void function( FT_Face face, FT_Bytes table ) FT_TrueTypeGX_Free;
    FT_Error function( FT_Face face, FT_UInt validation_flags, FT_Bytes *ckern_table ) FT_ClassicKern_Validate;
    void function( FT_Face face, FT_Bytes table ) FT_ClassicKern_Free;

    // ftpfr (FT_PFR_H)
    FT_Error function( FT_Face face, FT_UInt *aoutline_resolution, FT_UInt *ametrics_resolution, FT_Fixed *ametrics_x_scale, FT_Fixed *ametrics_y_scale ) FT_Get_PFR_Metrics;
    FT_Error function( FT_Face face, FT_UInt left, FT_UInt right, FT_Vector *avector ) FT_Get_PFR_Kerning;
    FT_Error function( FT_Face face, FT_UInt gindex, FT_Pos *aadvance ) FT_Get_PFR_Advance;

    // ftstroke.h (FT_STROKER_H)
    FT_StrokerBorder function( FT_Outline* outline ) FT_Outline_GetInsideBorder;
    FT_StrokerBorder function( FT_Outline* outline ) FT_Outline_GetOutsideBorder;
    FT_Error function( FT_Memory memory, FT_Stroker *astroker ) FT_Stroker_New;
    void function( FT_Stroker stroker, FT_Fixed radius, FT_Stroker_LineCap line_cap, FT_Stroker_LineJoin line_join, FT_Fixed miter_limit ) FT_Stroker_Set;
    void function( FT_Stroker stroker ) FT_Stroker_Rewind;
    FT_Error function( FT_Stroker stroker, FT_Outline* outline, FT_Bool opened ) FT_Stroker_ParseOutline;
    FT_Error function( FT_Stroker stroker, FT_Vector* to, FT_Bool open ) FT_Stroker_BeginSubPath;
    FT_Error function( FT_Stroker stroker ) FT_Stroker_EndSubPath;
    FT_Error function( FT_Stroker stroker, FT_Vector* to ) FT_Stroker_LineTo;
    FT_Error function( FT_Stroker stroker, FT_Vector* control, FT_Vector* to ) FT_Stroker_ConicTo;
    FT_Error function( FT_Stroker stroker, FT_Vector* control1, FT_Vector* control2, FT_Vector* to ) FT_Stroker_CubicTo;
    FT_Error function( FT_Stroker stroker, FT_StrokerBorder border, FT_UInt *anum_points, FT_UInt *anum_contours ) FT_Stroker_GetBorderCounts;
    void function( FT_Stroker stroker, FT_StrokerBorder border, FT_Outline* outline ) FT_Stroker_ExportBorder;
    FT_Error function( FT_Stroker stroker, FT_UInt *anum_points, FT_UInt *anum_contours ) FT_Stroker_GetCounts;
    void function( FT_Stroker stroker, FT_Outline* outline ) FT_Stroker_Export;
    void function( FT_Stroker stroker ) FT_Stroker_Done;
    FT_Error function( FT_Glyph *pglyph, FT_Stroker stroker, FT_Bool destroy ) FT_Glyph_Stroke;
    FT_Error function( FT_Glyph *pglyph, FT_Stroker stroker, FT_Bool inside, FT_Bool destroy ) FT_Glyph_StrokeBorder;

    // ftsynth.h (FT_SYNTHESIS_H) (WARNING: ALPHA CODE)
    FT_Error function( FT_GlyphSlot slot ) FT_GlyphSlot_Own_Bitmap;
    void function( FT_GlyphSlot slot ) FT_GlyphSlot_Embolden;
    void function( FT_GlyphSlot slot ) FT_GlyphSlot_Oblique;

    // ftxf86.h (FT_XFREE86_H)
    char* function( FT_Face face ) FT_Get_X11_Font_Format;

    // fttrigon.h (FT_TRIGONOMETRY_H)
    FT_Fixed function( FT_Angle angle ) FT_Sin;
    FT_Fixed function( FT_Angle angle ) FT_Cos;
    FT_Fixed function( FT_Angle angle ) FT_Tan;
    FT_Angle function( FT_Fixed x,FT_Fixed y ) FT_Atan2;
    FT_Angle function( FT_Angle angle1, FT_Angle angle2 ) FT_Angle_Diff;
    void function( FT_Vector* vec, FT_Angle angle ) FT_Vector_Unit;
    void function( FT_Vector* vec, FT_Angle angle ) FT_Vector_Rotate;
    FT_Fixed function( FT_Vector* vec ) FT_Vector_Length;
    void function( FT_Vector* vec, FT_Fixed *length, FT_Angle *angle ) FT_Vector_Polarize;
    void function( FT_Vector* vec, FT_Fixed length, FT_Angle angle ) FT_Vector_From_Polar;

    // ftlcdfil.h (FT_LCD_FILTER_H)
    FT_Error function( FT_Library library, FT_LcdFilter filter) FT_Library_SetLcdFilter;

    // ftgasp.h (FT_GASP_H)
    FT_Int function( FT_Face face, FT_UInt ppem ) FT_Get_Gasp;

    /+ other
    FT_Error function( FT_Memory memory, FT_Long size, void* *P ) FT_Alloc;
    FT_Error function( FT_Memory memory, FT_Long size, void* *p ) FT_QAlloc;
    FT_Error function( FT_Memory memory, FT_Long current, FT_Long size, void* *P ) FT_Realloc;
    FT_Error function( FT_Memory memory, FT_Long current, FT_Long size, void* *p ) FT_QRealloc;
    void function( FT_Memory memory, void* *P ) FT_Free;
    FT_Error function( FT_Memory memory, FT_GlyphLoader *aloader ) FT_GlyphLoader_New;
    FT_Error function( FT_GlyphLoader loader ) FT_GlyphLoader_CreateExtra;
    void function( FT_GlyphLoader loader ) FT_GlyphLoader_Done;
    void function( FT_GlyphLoader loader ) FT_GlyphLoader_Reset;
    void function( FT_GlyphLoader loader ) FT_GlyphLoader_Rewind;
    FT_Error function( FT_GlyphLoader loader, FT_UInt n_points, FT_UInt n_contours ) FT_GlyphLoader_CheckPoints;
    FT_Error function( FT_GlyphLoader loader, FT_UInt n_subs ) FT_GlyphLoader_CheckSubGlyphs;
    void function( FT_GlyphLoader loader ) FT_GlyphLoader_Prepare;
    void function( FT_GlyphLoader loader ) FT_GlyphLoader_Add;
    FT_Error function( FT_GlyphLoader target, FT_GlyphLoader source ) FT_GlyphLoader_CopyPoints;
    FT_Pointer function( FT_ServiceDesc service_descriptors, char* service_id ) FT_service_list_lookup;
    FT_Error function( FT_CMap_Class clazz, FT_Pointer init_data, FT_CharMap charmap, FT_CMap *acmap ) FT_CMap_New;
    void function( FT_CMap cmap ) FT_CMap_Done;
    void* function( FT_Library library, char* mod_name ) FT_Get_Module_Interface;
    FT_Pointer function( FT_Module mod, char* service_id ) FT_module_get_service;
    FT_Error function( FT_Face face, FT_GlyphSlot *aslot ) FT_New_GlyphSlot;
    void function( FT_GlyphSlot slot ) FT_Done_GlyphSlot;
    void function( FT_GlyphSlot slot ) FT_glyphslot_free_bitmap;
    FT_Error function( FT_GlyphSlot slot, FT_ULong size ) FT_glyphslot_alloc_bitmap;
    void function( FT_GlyphSlot slot, FT_Byte* buffer ) FT_glyphslot_set_bitmap;
    FT_Renderer function( FT_Library library, FT_Glyph_Format format, FT_ListNode* node ) FT_Lookup_Renderer;
    FT_Error function( FT_Library library, FT_GlyphSlot slot, FT_Render_Mode render_mode ) FT_Render_Glyph_Internal;
    FT_Memory function() FT_New_Memory;
    void function( FT_Memory memory ) FT_Done_Memory;
    FT_Error function( FT_Stream stream, char* filepathname ) FT_Stream_Open;
    FT_Error function( FT_Library library, FT_Open_Args* args, FT_Stream *astream ) FT_Stream_New;
    void function( FT_Stream stream, FT_Int external ) FT_Stream_Free;
    void function( FT_Stream stream, FT_Byte* base, FT_ULong size ) FT_Stream_OpenMemory;
    void function( FT_Stream stream ) FT_Stream_Close;
    FT_Error function( FT_Stream stream, FT_ULong pos ) FT_Stream_Seek;
    FT_Error function( FT_Stream stream, FT_Long distance ) FT_Stream_Skip;
    FT_Long function( FT_Stream stream ) FT_Stream_Pos;
    FT_Error function( FT_Stream stream, FT_Byte* buffer, FT_ULong count ) FT_Stream_Read;
    FT_Error function( FT_Stream stream, FT_ULong pos, FT_Byte* buffer, FT_ULong count ) FT_Stream_ReadAt;
    FT_ULong function( FT_Stream stream, FT_Byte* buffer, FT_ULong count ) FT_Stream_TryRead;
    FT_Error function( FT_Stream stream, FT_ULong count ) FT_Stream_EnterFrame;
    void function( FT_Stream stream ) FT_Stream_ExitFrame;
    FT_Error function( FT_Stream stream, FT_ULong count, FT_Byte** pbytes ) FT_Stream_ExtractFrame;
    void function( FT_Stream stream, FT_Byte** pbytes ) FT_Stream_ReleaseFrame;
    FT_Char function( FT_Stream stream ) FT_Stream_GetChar;
    FT_Short function( FT_Stream stream ) FT_Stream_GetShort;
    FT_Long function( FT_Stream stream ) FT_Stream_GetOffset;
    FT_Long function( FT_Stream stream ) FT_Stream_GetLong;
    FT_Short function( FT_Stream stream ) FT_Stream_GetShortLE;
    FT_Long function( FT_Stream stream ) FT_Stream_GetLongLE;
    FT_Char function( FT_Stream stream, FT_Error* error ) FT_Stream_ReadChar;
    FT_Short function( FT_Stream stream, FT_Error* error ) FT_Stream_ReadShort;
    FT_Long function( FT_Stream stream, FT_Error* error ) FT_Stream_ReadOffset;
    FT_Long function( FT_Stream stream, FT_Error* error ) FT_Stream_ReadLong;
    FT_Short function( FT_Stream stream, FT_Error* error ) FT_Stream_ReadShortLE;
    FT_Long function( FT_Stream stream, FT_Error* error ) FT_Stream_ReadLongLE;
    FT_Error function( FT_Stream stream, FT_Frame_Field* fields, void* structure ) FT_Stream_ReadFields;
    FT_Int function() FT_Trace_Get_Count;
    char* function( FT_Int idx ) FT_Trace_Get_Name;
    void function() FT_debug_init;
    FT_Int32 function( FT_Int32 x ) FT_SqrtFixed;
    void function( FT_Library library, FT_Stream stream, char* base_name, char** new_names, FT_Long* offsets, FT_Error* errors ) FT_Raccess_Guess;
    FT_Error function( FT_Library library, FT_Stream stream, FT_Long rfork_offset, FT_Long *map_offset, FT_Long *rdata_pos ) FT_Raccess_Get_HeaderInfo;
    FT_Error function( FT_Library library, FT_Stream stream, FT_Long map_offset, FT_Long rdata_pos, FT_Long tag, FT_Long **offsets, FT_Long *count ) FT_Raccess_Get_DataOffsets;
    void function( FT_Validator valid, FT_Byte* base, FT_Byte* limit, FT_ValidationLevel level ) FT_validator_init;
    FT_Int function( FT_Validator valid ) FT_validator_run;
    void function( FT_Validator valid, FT_Error error ) FT_validator_error;
    +/
}