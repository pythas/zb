const ig = @import("cimgui_docking");

const Bus = @import("../bus.zig").Bus;
const WindowConfig = @import("state.zig").WindowConfig;

pub const OamWindow = struct {
    const Self = @This();

    pub fn init() Self {
        return .{};
    }

    pub fn draw(_: *Self, config: *WindowConfig, bus: *Bus) void {
        if (!config.visible) {
            return;
        }

        ig.igSetNextWindowPos(config.pos, ig.ImGuiCond_FirstUseEver);
        ig.igSetNextWindowSize(config.size, ig.ImGuiCond_FirstUseEver);

        if (ig.igBegin("OAM Viewer", &config.visible, 0)) {

            // Setup a table with 6 columns
            // flags: RowBg | Borders | Resizable | ScrollY
            const flags = ig.ImGuiTableFlags_RowBg | ig.ImGuiTableFlags_Borders | ig.ImGuiTableFlags_Resizable | ig.ImGuiTableFlags_ScrollY;

            if (ig.igBeginTable("OAMTable", 6, flags)) {

                // Headers
                ig.igTableSetupColumn("Idx", ig.ImGuiTableColumnFlags_WidthFixed);
                ig.igTableSetupColumn("Y", ig.ImGuiTableColumnFlags_WidthFixed);
                ig.igTableSetupColumn("X", ig.ImGuiTableColumnFlags_WidthFixed);
                ig.igTableSetupColumn("Tile", ig.ImGuiTableColumnFlags_WidthFixed);
                ig.igTableSetupColumn("Flags", ig.ImGuiTableColumnFlags_WidthFixed);
                ig.igTableSetupColumn("Attributes Decoded", ig.ImGuiTableColumnFlags_None);
                ig.igTableHeadersRow();

                var i: usize = 0;
                // Iterate through 40 sprites
                while (i < 40) : (i += 1) {
                    const offset = i * 4;

                    // Read OAM bytes.
                    // ASSUMPTION: state.gpu.oam is accessible as [160]u8.
                    // If not, use state.bus.read(0xFE00 + @as(u16, @intCast(offset)))
                    const raw_y = bus.gpu.oam[offset];
                    const raw_x = bus.gpu.oam[offset + 1];
                    const tile = bus.gpu.oam[offset + 2];
                    const attr = bus.gpu.oam[offset + 3];

                    ig.igTableNextRow();

                    // Column 0: Index
                    _ = ig.igTableSetColumnIndex(0);
                    ig.igText("%d", i);

                    // Column 1: Y Position
                    _ = ig.igTableSetColumnIndex(1);
                    // Highlight off-screen sprites in grey
                    if (raw_y == 0 or raw_y >= 160) ig.igPushStyleColorImVec4(ig.ImGuiCol_Text, .{ .x = 0.5, .y = 0.5, .z = 0.5, .w = 1.0 });
                    ig.igText("%d", raw_y);
                    if (raw_y == 0 or raw_y >= 160) ig.igPopStyleColor();

                    // Column 2: X Position
                    _ = ig.igTableSetColumnIndex(2);
                    if (raw_x == 0 or raw_x >= 168) ig.igPushStyleColorImVec4(ig.ImGuiCol_Text, .{ .x = 0.5, .y = 0.5, .z = 0.5, .w = 1.0 });
                    ig.igText("%d", raw_x);
                    if (raw_x == 0 or raw_x >= 168) ig.igPopStyleColor();

                    // Column 3: Tile Index
                    _ = ig.igTableSetColumnIndex(3);
                    ig.igText("0x%02X", tile);

                    // Column 4: Raw Flags
                    _ = ig.igTableSetColumnIndex(4);
                    ig.igText("0x%02X", attr);

                    // Column 5: Decoded Attributes
                    _ = ig.igTableSetColumnIndex(5);

                    // Bit 7: Priority (0=OBJ Above BG, 1=OBJ Behind BG)
                    const prio = (attr & 0x80) != 0;
                    // Bit 6: Y Flip
                    const y_flip = (attr & 0x40) != 0;
                    // Bit 5: X Flip
                    const x_flip = (attr & 0x20) != 0;
                    // Bit 4: Palette (Non-CGB)
                    const pal = (attr & 0x10) != 0;

                    ig.igText("%s %s %s Pal:%d", (if (prio) "BG" else "FG").ptr, (if (y_flip) "Y-Flip" else "").ptr, (if (x_flip) "X-Flip" else "").ptr, if (pal) @as(c_int, 1) else @as(c_int, 0));
                }
                ig.igEndTable();
            }
        }
        ig.igEnd();
    }
};
