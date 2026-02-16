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

const OamWindow = @import("ui/oam.zig").OamWindow;
const EmulatorWindow = @import("ui/emulator.zig").EmulatorWindow;
const RegisterWindow = @import("ui/register.zig").RegisterWindow;
const TileWindow = @import("ui/map.zig").MapWindow;
const UiState = @import("ui/state.zig").UiState;

const AppState = struct {
    allocator: std.mem.Allocator,

    gpu: Gpu,
    apu: Apu,
    joypad: Joypad,
    timer: Timer,
    bus: Bus,
    cpu: Cpu(Bus),

    ui: UiState,
    emulator_window: EmulatorWindow,
    register_window: RegisterWindow,
    oam_window: OamWindow,
    tile_window: TileWindow,

    pass_action: sg.PassAction,

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

            .ui = UiState.init(),
            .pass_action = .{},

            .emulator_window = EmulatorWindow.init(),
            .register_window = RegisterWindow.init(),
            .oam_window = OamWindow.init(),
            .tile_window = TileWindow.init(),
        };

        ptr.bus = Bus.init(&ptr.gpu, &ptr.apu, &ptr.joypad, &ptr.timer);

        ptr.cpu = Cpu(Bus).init(&ptr.bus);

        const bootrom = try readBinaryFile(allocator, "roms/DMG_ROM.bin");
        ptr.bus.loadBootrom(bootrom);
        allocator.free(bootrom);

        const rom = try readBinaryFile(allocator, "roms/tetris.gb");
        ptr.bus.loadRom(rom);
        allocator.free(rom);

        return ptr;
    }

    fn reset(self: *AppState) !void {
        self.bus.reset();
        self.cpu.reset();
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

    simgui.newFrame(.{
        .width = @intFromFloat(width),
        .height = @intFromFloat(height),
        .delta_time = sapp.frameDuration(),
        .dpi_scale = sapp.dpiScale(),
    });

    drawMainMenu();
    state.emulator_window.draw(&state.ui.emulator, &state.bus);
    state.register_window.draw(&state.ui.registers, &state.cpu);
    state.oam_window.draw(&state.ui.oam, &state.bus);
    state.tile_window.draw(&state.ui.tiles, &state.bus);

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

    state.emulator_window.deinit();
    state.tile_window.deinit();
}

fn drawMainMenu() void {
    if (ig.igBeginMainMenuBar()) {
        if (ig.igBeginMenu("System")) {
            if (ig.igMenuItem("Reset")) {
                state.reset() catch |err| {
                    std.debug.print("Failed to reset emulator: {}\n", .{err});
                };
            }
            ig.igEndMenu();
        }
        if (ig.igBeginMenu("View")) {
            _ = ig.igMenuItemBoolPtr("Emulator", "", &state.ui.emulator.visible, true);
            _ = ig.igMenuItemBoolPtr("Registers", "", &state.ui.registers.visible, true);
            _ = ig.igMenuItemBoolPtr("OAM Viewer", "", &state.ui.oam.visible, true);
            _ = ig.igMenuItemBoolPtr("Background Map", "", &state.ui.tiles.visible, true);
            ig.igEndMenu();
        }
        ig.igEndMainMenuBar();
    }
}

pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = event,
        .window_title = "zb",
        .width = 1000,
        .height = 600,
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = slog.func },
    });
}
