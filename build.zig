const std = @import("std");
const sokol = @import("sokol");
const cimgui = @import("cimgui");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const cimgui_conf = cimgui.getConfig(true);

    const dep_sokol = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
        .with_sokol_imgui = true,
        .with_tracing = true,
    });
    const dep_cimgui = b.dependency("cimgui", .{
        .target = target,
        .optimize = optimize,
    });

    dep_sokol.artifact("sokol_clib").root_module.addIncludePath(dep_cimgui.path(cimgui_conf.include_dir));

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
            .{ .name = cimgui_conf.module_name, .module = dep_cimgui.module(cimgui_conf.module_name) },
        },
    });

    const exe = b.addExecutable(.{
        .name = "zb",
        .root_module = exe_mod,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_dir = b.option([]const u8, "test-dir", "Path to GameboyCPUTests v2 directory");
    const test_filter = b.option([]const u8, "test-filter", "Filter for test files (e.g. 00.json)");
    const options = b.addOptions();
    options.addOption(?[]const u8, "test_dir", test_dir);
    options.addOption(?[]const u8, "test_filter", test_filter);
    exe_unit_tests.root_module.addOptions("config", options);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
