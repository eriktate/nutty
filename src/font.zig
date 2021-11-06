const std = @import("std");
const print = std.debug.print;
const c = @import("c.zig");

const FontError = error{
    InitFailed,
    UnknownFaceFormat,
    FaceNotFound,
    InvalidSize,
    CharNotFound,
    LoadGlyphFailed,
    RenderGlyphFailed,
};

pub const Font = struct {
    lib: c.FT_Library,
    face: c.FT_Face,

    pub fn init(path: [:0]const u8, size: u32, dpi_width: u32, dpi_height: u32) FontError!Font {
        var font: Font = undefined;

        var err = c.FT_Init_FreeType(&font.lib);
        if (err != 0) {
            return FontError.InitFailed;
        }

        // TODO (etate): consider loading the font data
        // separately and running c.FT_New_Memory_Face
        err = c.FT_New_Face(font.lib, path, 0, &font.face);
        if (err == c.FT_Err_Unknown_File_Format) {
            return FontError.UnknownFaceFormat;
        } else if (err != 0) {
            return FontError.FaceNotFound;
        }

        err = c.FT_Set_Char_Size(font.face, 0, size * 64, dpi_width, dpi_height);
        if (err != 0) {
            return FontError.InvalidSize;
        }

        return font;
    }

    pub fn get_glyph(self: Font, char_code: u64) FontError![]u8 {
        var glyph_index = c.FT_Get_Char_Index(self.face, char_code);
        var err = c.FT_Load_Glyph(self.face, glyph_index, c.FT_LOAD_DEFAULT);
        if (err != 0) {
            return FontError.LoadGlyphFailed;
        }

        err = c.FT_Render_Glyph(self.face.*.glyph, c.FT_RENDER_MODE_NORMAL);
        if (err != 0) {
            return FontError.RenderGlyphFailed;
        }

        const bitmap = self.face.*.glyph.*.bitmap;
        print("Gray mode: {d}\n", .{c.FT_PIXEL_MODE_GRAY});
        print("Pixel mode: {d}\n", .{bitmap.pixel_mode});
        print("Pixel width: {d}\n", .{bitmap.width});
        print("Pixel height: {d}\n", .{bitmap.rows});
        print("Pixel count: {d}\n", .{bitmap.rows * bitmap.width});
        var idx: usize = 0;
        const byte_count = @intCast(c_uint, bitmap.pitch) * bitmap.rows;
        while (idx < byte_count) {
            print("{d}", .{bitmap.buffer[idx]});
            idx += 1;
            if (idx % bitmap.width == 0) {
                print("\n", .{});
            }
        }

        return bitmap.buffer[0..byte_count];
    }
};
