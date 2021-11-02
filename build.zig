const std = @import("std");

const freetype_path = "./vendor/freetype/build/";
const glfw_lib = "./vendor/glfw/build/src";
const glfw_include = "./vendor/glfw/include";

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("nutty", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);

    // Find freetype
    exe.addIncludeDir(freetype_path ++ "include");
    exe.addLibPath(freetype_path ++ "lib");

    // Find GLFW
    exe.addIncludeDir(glfw_include);
    exe.addLibPath(glfw_lib);

    exe.linkSystemLibrary("freetype");
    exe.linkSysteLibrary("glfw");
    exe.linkLibC();

    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
