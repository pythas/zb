const std = @import("std");

const ig = @import("cimgui_docking");
const sokol = @import("sokol");
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const simgui = sokol.imgui;
const sgimgui = sokol.sgimgui;

const Gpu = @import("gpu.zig").Gpu;
const Apu = @import("apu.zig").Apu;
const Joypad = @import("joypad.zig").Joypad;
const Timer = @import("timer.zig").Timer;
const Cpu = @import("cpu.zig").Cpu;
const Bus = @import("bus.zig").Bus;

const AppState = struct {
    allocator: std.mem.Allocator,

    gpu: Gpu,
    apu: Apu,
    joypad: Joypad,
    timer: Timer,
    bus: Bus,
    cpu: Cpu(Bus),

    pass_action: sg.PassAction,
    display_image: sg.Image,
    display_view: sg.View,
    display_sampler: sg.Sampler,

    show_gameboy: bool = true,
    show_registers: bool = true,

    fn init(allocator: std.mem.Allocator) !*AppState {
        const ptr = try allocator.create(AppState);
        ptr.* = .{
            .allocator = allocator,
            .gpu = Gpu.init(),
            .apu = Apu.init(),
            .joypad = Joypad.init(),
            .timer = Timer.init(),
            .bus = undefined,
            .cpu = undefined,
            .pass_action = .{},
            .display_image = .{},
            .display_view = .{},
            .display_sampler = .{},
        };

        ptr.bus = Bus.init(&ptr.gpu, &ptr.apu, &ptr.joypad, &ptr.timer);

        ptr.cpu = Cpu(Bus).init(&ptr.bus);

        const bootrom = try readBinaryFile(allocator, "roms/DMG_ROM.bin");
        ptr.bus.loadBootrom(bootrom);
        allocator.free(bootrom);

        return ptr;
    }
};

var state: *AppState = undefined;

fn readBinaryFile(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    var dir = std.fs.cwd();
    const file = try dir.openFile(path, .{ .mode = .read_only });
    defer file.close();
    return try file.readToEndAlloc(allocator, 1024 * 1024);
}

export fn init() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    simgui.setup(.{
        .logger = .{ .func = slog.func },
    });

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    state = AppState.init(gpa.allocator()) catch |err| {
        std.debug.panic("Failed to init emulator: {}", .{err});
    };

    const img_desc = sg.ImageDesc{
        .width = 160,
        .height = 144,
        .pixel_format = .RGBA8,
        .usage = .{ .stream_update = true },
        .label = "gb-screen",
    };
    state.display_image = sg.makeImage(img_desc);

    state.display_view = sg.makeView(.{
        .texture = .{ .image = state.display_image },
    });

    const smp_desc = sg.SamplerDesc{
        .min_filter = .NEAREST,
        .mag_filter = .NEAREST,
    };
    state.display_sampler = sg.makeSampler(smp_desc);

    state.pass_action = .{};
    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.2, .g = 0.2, .b = 0.25, .a = 1.0 },
    };
}

export fn frame() void {
    const width = sapp.widthf();
    const height = sapp.heightf();

    var cycles_run: usize = 0;
    while (!state.gpu.frame_ready and cycles_run < 70224 * 2) {
        state.cpu.cycle();
        cycles_run += 4;
    }
    state.gpu.frame_ready = false;

    var data_desc = sg.ImageData{};
    data_desc.mip_levels[0] = sg.asRange(&state.gpu.video_buffer);
    sg.updateImage(state.display_image, data_desc);

    simgui.newFrame(.{
        .width = @intFromFloat(width),
        .height = @intFromFloat(height),
        .delta_time = sapp.frameDuration(),
        .dpi_scale = sapp.dpiScale(),
    });

    if (ig.igBeginMainMenuBar()) {
        if (ig.igBeginMenu("View")) {
            _ = ig.igMenuItemBoolPtr("GameBoy", "", &state.show_gameboy, true);
            _ = ig.igMenuItemBoolPtr("Registers", "", &state.show_registers, true);
            ig.igEndMenu();
        }
        ig.igEndMainMenuBar();
    }

    if (state.show_gameboy) {
        ig.igSetNextWindowSize(.{ .x = 340, .y = 340 }, ig.ImGuiCond_FirstUseEver);
        if (ig.igBegin("GameBoy", &state.show_gameboy, ig.ImGuiWindowFlags_NoScrollbar)) {
            const w_size = ig.igGetContentRegionAvail();
            const aspect = 160.0 / 144.0;
            var draw_w = w_size.x;
            var draw_h = w_size.x / aspect;
            if (draw_h > w_size.y) {
                draw_h = w_size.y;
                draw_w = w_size.y * aspect;
            }
            ig.igSetCursorPosX((w_size.x - draw_w) * 0.5 + ig.igGetCursorPosX());
            ig.igSetCursorPosY((w_size.y - draw_h) * 0.5 + ig.igGetCursorPosY());

            ig.igImage(.{ ._TexID = simgui.imtextureidWithSampler(state.display_view, state.display_sampler) }, .{ .x = draw_w, .y = draw_h });
        }
        ig.igEnd();
    }

    if (state.show_registers) {
        ig.igSetNextWindowPos(.{ .x = 10, .y = 30 }, ig.ImGuiCond_FirstUseEver);
        ig.igSetNextWindowSize(.{ .x = 200, .y = 250 }, ig.ImGuiCond_FirstUseEver);
        if (ig.igBegin("Registers", &state.show_registers, 0)) {
            ig.igText("PC: 0x%04X", state.cpu.pc);
            ig.igText("SP: 0x%04X", state.cpu.sp);
            ig.igSeparator();
            ig.igText("A: 0x%02X F: 0x%02X", state.cpu.a, state.cpu.f);
            ig.igText("B: 0x%02X C: 0x%02X", state.cpu.b, state.cpu.c);
            ig.igText("D: 0x%02X E: 0x%02X", state.cpu.d, state.cpu.e);
            ig.igText("H: 0x%02X L: 0x%02X", state.cpu.h, state.cpu.l);
            ig.igSeparator();
            ig.igText("Flags: %s%s%s%s", if (state.cpu.getFlag(.Z)) "Z" else "-", if (state.cpu.getFlag(.N)) "N" else "-", if (state.cpu.getFlag(.H)) "H" else "-", if (state.cpu.getFlag(.C)) "C" else "-");
        }
        ig.igEnd();
    }

    sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });
    simgui.render();
    sg.endPass();
    sg.commit();
}

export fn event(ev: [*c]const sapp.Event) void {
    _ = simgui.handleEvent(ev.*);
}

export fn cleanup() void {
    simgui.shutdown();
    sg.shutdown();
}

pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = event,
        .window_title = "zb",
        .width = 800,
        .height = 600,
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = slog.func },
    });
}
