const std = @import("std");
const c = @import("c.zig");
const window = @import("window.zig");
const Font = @import("font.zig").Font;
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
    const font = try Font.init("./fonts/mononoki.ttf", 16, 166, 0);
    const glyph_bitmap = try font.get_glyph('E');
    std.debug.print("Bitmap size: {d}\n", .{glyph_bitmap.len});
    std.debug.print("{any}\n", .{glyph_bitmap});

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
