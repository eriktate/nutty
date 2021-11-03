const std = @import("std");
const c = @import("c.zig");
const window = @import("window.zig");
const fs = std.fs;
const os = std.os;

const Pty = struct {
    fd: fs.File,
};

const TermError = error{
    PseudoTerminalInitFailed,
    InvalidFd,
};

const shell = "/bin/bash";

fn create_pty() anyerror!Pty {
    var pty = Pty{ .fd = fs.File{ .handle = 0 } };
    var args_ptr = [2:null]?[*:0]u8{
        shell,
        null,
    };

    var name: [128]u8 = undefined;
    const p = c.forkpty(&pty.fd.handle, &name, null, null);
    if (p > 0) {
        return pty;
    }

    return os.execvpeZ(args_ptr[0].?, &args_ptr, std.c.environ);
}

pub fn main() anyerror!void {
    var ft: c.FT_Library = undefined;
    var face: c.FT_Face = undefined;

    // var font: c.FT_Face = undefined;
    var err = c.FT_Init_FreeType(&ft);
    if (err != 0) {
        std.log.err("failed to init freetype: {d}", .{err});
    }

    err = c.FT_New_Face(ft, "./fonts/mononoki.ttf", 0, &face);
    if (err == c.FT_Err_Unknown_File_Format) {
        std.log.err("unknown font format: {d}", .{err});
    } else if (err != 0) {
        std.log.err("could not read font: {d}", .{err});
    }

    std.log.info("Number of glyphs in font: {d}", .{face.*.num_glyphs});

    err = c.FT_Set_Char_Size(face, 0, 16 * 64, 1920, 1080);
    if (err != 0) {
        std.log.err("failed to set the font size: {d}", .{err});
    }

    const glyph_index = c.FT_Get_Char_Index(face, 'E');
    err = c.FT_Load_Glyph(
        face,
        glyph_index,
        c.FT_LOAD_DEFAULT,
    );
    if (err != 0) {
        std.log.err("failed to load glyph: {d}", .{err});
    }

    err = c.FT_Load_Glyph(face, glyph_index, c.FT_LOAD_DEFAULT);
    if (err != 0) {
        std.log.err("failed to load glyph: {d}", .{err});
    }

    err = c.FT_Render_Glyph(face.*.glyph, c.FT_RENDER_MODE_NORMAL);
    if (err != 0) {
        std.log.err("failed to render glyph: {d}", .{err});
    }

    const glyph_bitmap = face.*.glyph.*.bitmap;
    std.log.info("Glyph bitmap data: {d}", .{glyph_bitmap.buffer[0]});
    var idx: usize = 0;
    var bitmap_byte_count = @intCast(c_uint, glyph_bitmap.pitch) * glyph_bitmap.rows;
    while (idx < bitmap_byte_count) {
        std.debug.print("{d}", .{glyph_bitmap.buffer[idx]});
        idx += 1;
    }

    const win = try window.Window.init(540, 480, "nutty - float");
    defer win.close();

    const pty = try create_pty();
    defer pty.fd.close();

    // pty fd has to be a TTY
    if (!pty.fd.isTty()) {
        return TermError.InvalidFd;
    }

    std.log.info("Starting TTY", .{});
    var buf: [1024 * 2]u8 = undefined;

    try pty.fd.writeAll("ls\r");
    // try pty.fd.writeAll("cat test.txt\r");
    std.time.sleep(2 * 1000 * 1000 * 1000);
    _ = try pty.fd.read(buf[0..]);
    std.debug.print("{s}", .{buf});
    std.debug.print("\n\n", .{});

    std.log.info("Again:", .{});

    try pty.fd.writeAll("ls -al\r");
    std.time.sleep(2 * 1000 * 1000 * 1000);
    _ = try pty.fd.read(buf[0..]);
    std.debug.print("{s}", .{buf});
    std.debug.print("\n\n", .{});
}
