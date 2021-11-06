const std = @import("std");
const c = @import("c.zig");
const window = @import("window.zig");
const Font = @import("font.zig").Font;
const Shader = @import("shader.zig").Shader;
const fs = std.fs;
const os = std.os;
const print = std.debug.print;

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
    const font = try Font.init("./fonts/mononoki.ttf", 16, 166, 0);
    const glyph_bitmap = try font.get_glyph('E');
    std.debug.print("Bitmap size: {d}\n", .{glyph_bitmap.len});
    // std.debug.print("{any}\n", .{glyph_bitmap});

    const win = try window.Window.init(640, 480, "nutty - float");
    defer win.close();

    const vert_src = @embedFile("../vertex.glsl");
    const frag_src = @embedFile("../fragment.glsl");
    const shader = try Shader.init(vert_src, frag_src);
    shader.use();

    const vertices = [_]f32{
        -1.0, 1.0,
        1.0,  1.0,
        -1.0, -1.0,
        1.0,  -1.0,
    };

    var vao: u32 = 0;
    c.glGenVertexArrays(1, &vao);
    c.glBindVertexArray(vao);

    var vbo: u32 = 0;
    c.glGenBuffers(1, &vbo);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(f32) * vertices.len, &vertices, c.GL_STATIC_DRAW);
    c.glVertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 2 * @sizeOf(f32), @intToPtr(?*const c_void, 0));
    c.glEnableVertexAttribArray(0);

    var garbage_texture: [16 * 26 * 3]f32 = undefined;
    for (garbage_texture) |_, idx| {
        garbage_texture[idx] = 0.5;
    }

    // load texture
    var texture: c_uint = 0;
    c.glGenTextures(1, &texture);
    c.glActiveTexture(c.GL_TEXTURE0);
    c.glBindTexture(c.GL_TEXTURE_2D, texture);
    // c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_REPEAT);
    // c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_NEAREST);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_NEAREST);
    c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RED, 16, 26, 0, c.GL_RED, c.GL_UNSIGNED_BYTE, &glyph_bitmap);
    // c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGB, 16, 26, 0, c.GL_RGB, c.GL_FLOAT, &garbage_texture);
    c.glGenerateMipmap(c.GL_TEXTURE_2D);

    c.glClearColor(1, 1, 1, 1);
    shader.setInt("tex", 0);

    print("Before while\n", .{});
    while (!win.shouldClose()) {
        c.glClear(c.GL_COLOR_BUFFER_BIT);
        c.glBindVertexArray(vao);
        c.glDrawArrays(c.GL_TRIANGLE_STRIP, 0, 4);
        c.glBindVertexArray(0);
        win.tick();
    }

    // const pty = try create_pty();
    // defer pty.fd.close();

    // // pty fd has to be a TTY
    // if (!pty.fd.isTty()) {
    //     return TermError.InvalidFd;
    // }

    // std.log.info("Starting TTY", .{});
    // var buf: [1024 * 2]u8 = undefined;

    // try pty.fd.writeAll("ls\r");
    // // try pty.fd.writeAll("cat test.txt\r");
    // std.time.sleep(2 * 1000 * 1000 * 1000);
    // _ = try pty.fd.read(buf[0..]);
    // std.debug.print("{s}", .{buf});
    // std.debug.print("\n\n", .{});

    // std.log.info("Again:", .{});

    // try pty.fd.writeAll("ls -al\r");
    // std.time.sleep(2 * 1000 * 1000 * 1000);
    // _ = try pty.fd.read(buf[0..]);
    // std.debug.print("{s}", .{buf});
    // std.debug.print("\n\n", .{});
}
