const std = @import("std");

const ig = @import("cimgui_docking");
const sokol = @import("sokol");
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const simgui = sokol.imgui;
const sgimgui = sokol.sgimgui;

const Cpu = @import("cpu.zig").Cpu;
const Bus = @import("bus.zig").Bus;

// const state = struct {
//     var pass_action: sg.PassAction = .{};
//     var show_first_window: bool = true;
//     var show_second_window: bool = true;
// };
//
// export fn init() void {
//     sg.setup(.{
//         .environment = sglue.environment(),
//         .logger = .{ .func = slog.func },
//     });
//     sgimgui.setup(.{});
//     simgui.setup(.{
//         .logger = .{ .func = slog.func },
//     });
//
//     ig.igGetIO().*.ConfigFlags |= ig.ImGuiConfigFlags_DockingEnable;
//
//     state.pass_action.colors[0] = .{
//         .load_action = .CLEAR,
//         .clear_value = .{ .r = 0.0, .g = 0.5, .b = 1.0, .a = 1.0 },
//     };
// }
//
// export fn frame() void {
//     simgui.newFrame(.{
//         .width = sapp.width(),
//         .height = sapp.height(),
//         .delta_time = sapp.frameDuration(),
//         .dpi_scale = sapp.dpiScale(),
//     });
//
//     const backendName: [*c]const u8 = switch (sg.queryBackend()) {
//         .D3D11 => "Direct3D11",
//         .GLCORE => "OpenGL",
//         .GLES3 => "OpenGLES3",
//         .METAL_IOS => "Metal iOS",
//         .METAL_MACOS => "Metal macOS",
//         .METAL_SIMULATOR => "Metal Simulator",
//         .WGPU => "WebGPU",
//         .VULKAN => "Vulkan",
//         .DUMMY => "Dummy",
//     };
//
//     //=== UI CODE STARTS HERE
//     ig.igSetNextWindowPos(.{ .x = 10, .y = 30 }, ig.ImGuiCond_Once);
//     ig.igSetNextWindowSize(.{ .x = 400, .y = 100 }, ig.ImGuiCond_Once);
//     if (ig.igBegin("Hello Dear ImGui!", &state.show_first_window, ig.ImGuiWindowFlags_None)) {
//         _ = ig.igColorEdit3("Background", &state.pass_action.colors[0].clear_value.r, ig.ImGuiColorEditFlags_None);
//         _ = ig.igText("Dear ImGui Version: %s", ig.IMGUI_VERSION);
//     }
//     ig.igEnd();
//
//     ig.igSetNextWindowPos(.{ .x = 50, .y = 150 }, ig.ImGuiCond_Once);
//     ig.igSetNextWindowSize(.{ .x = 400, .y = 100 }, ig.ImGuiCond_Once);
//     if (ig.igBegin("Another Window", &state.show_second_window, ig.ImGuiWindowFlags_None)) {
//         _ = ig.igText("Sokol Backend: %s", backendName);
//     }
//     ig.igEnd();
//
//     if (ig.igBeginMainMenuBar()) {
//         sgimgui.drawMenu("sokol-gfx");
//         ig.igEndMainMenuBar();
//     }
//     sgimgui.draw();
//     //=== UI CODE ENDS HERE
//
//     sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });
//     simgui.render();
//     sg.endPass();
//     sg.commit();
// }
//
// export fn cleanup() void {
//     simgui.shutdown();
//     sgimgui.shutdown();
//     sg.shutdown();
// }
//
// export fn event(ev: [*c]const sapp.Event) void {
//     _ = simgui.handleEvent(ev.*);
// }

pub fn main() !void {
    var bus = Bus.init();
    var cpu = Cpu.init(&bus);
    cpu.setAf(0xaaff);
    const af = cpu.getAf();
    std.debug.print("{}", .{af});

    // sapp.run(.{
    //     .init_cb = init,
    //     .frame_cb = frame,
    //     .cleanup_cb = cleanup,
    //     .event_cb = event,
    //     .window_title = "sokol-zig + Dear Imgui",
    //     .width = 800,
    //     .height = 600,
    //     .icon = .{ .sokol_default = true },
    //     .logger = .{ .func = slog.func },
    // });
}

test {
    _ = @import("cpu.zig");
    _ = @import("bus.zig");
}
