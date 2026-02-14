const ig = @import("cimgui_docking");

pub const WindowConfig = struct {
    pos: ig.ImVec2,
    size: ig.ImVec2,
    visible: bool = true,
};

pub const UiState = struct {
    emulator: WindowConfig,
    registers: WindowConfig,
    oam: WindowConfig,
    tiles: WindowConfig,

    pub fn init() UiState {
        return .{
            .emulator = .{
                .pos = .{ .x = 10, .y = 30 },
                .size = .{ .x = 340, .y = 340 },
                .visible = true,
            },
            .registers = .{
                .pos = .{ .x = 360, .y = 30 },
                .size = .{ .x = 220, .y = 250 },
                .visible = true,
            },
            .oam = .{
                .pos = .{ .x = 10, .y = 380 },
                .size = .{ .x = 570, .y = 400 },
                .visible = true,
            },
            .tiles = .{
                .pos = .{ .x = 590, .y = 30 },
                .size = .{ .x = 320, .y = 450 },
                .visible = true,
            },
        };
    }
};
