const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;
const ig = @import("cimgui_docking");

const Bus = @import("../bus.zig").Bus;
const WindowConfig = @import("state.zig").WindowConfig;

pub const MapWindow = struct {
    image: sg.Image,
    view: sg.View,
    sampler: sg.Sampler,
    pixels: [256 * 256 * 4]u8,

    show_window_layer: bool = false,

    const Self = @This();

    pub fn init() Self {
        const image = sg.makeImage(.{
            .width = 256,
            .height = 256,
            .pixel_format = .RGBA8,
            .usage = .{ .stream_update = true },
            .label = "bg-map-texture",
        });

        return .{
            .image = image,
            .view = sg.makeView(.{ .texture = .{ .image = image } }),
            .sampler = sg.makeSampler(.{ .min_filter = .NEAREST, .mag_filter = .NEAREST }),
            .pixels = undefined,
        };
    }

    pub fn deinit(self: *Self) void {
        sg.destroySampler(self.sampler);
        sg.destroyView(self.view);
        sg.destroyImage(self.image);
    }

    pub fn draw(self: *Self, config: *WindowConfig, bus: *Bus) void {
        if (!config.visible) return;

        ig.igSetNextWindowPos(config.pos, ig.ImGuiCond_FirstUseEver);
        ig.igSetNextWindowSize(config.size, ig.ImGuiCond_FirstUseEver);

        if (ig.igBegin("Map Viewer", &config.visible, 0)) {
            ig.igText("Layer:");
            ig.igSameLineEx(0, -1);

            if (ig.igRadioButton("Background", !self.show_window_layer)) {
                self.show_window_layer = false;
            }
            ig.igSameLineEx(0, -1);
            if (ig.igRadioButton("Window", self.show_window_layer)) {
                self.show_window_layer = true;
            }

            self.updateTexture(bus);

            const cursor_pos = ig.igGetCursorScreenPos();

            ig.igImage(.{ ._TexID = sokol.imgui.imtextureidWithSampler(self.view, self.sampler) }, .{ .x = 256, .y = 256 });

            if (!self.show_window_layer) {
                self.drawViewportRect(bus, cursor_pos);
            }
        }
        ig.igEnd();
    }

    fn updateTexture(self: *Self, bus: *Bus) void {
        const lcdc = bus.read(0xFF40);

        var map_base: u16 = 0;

        if (self.show_window_layer) {
            map_base = if ((lcdc & 0x40) != 0) 0x9C00 else 0x9800;
        } else {
            map_base = if ((lcdc & 0x08) != 0) 0x9C00 else 0x9800;
        }

        const use_8000_method = (lcdc & 0x10) != 0;
        const palette = [_]u32{ 0xFFFFFFFF, 0xFFAAAAAA, 0xFF555555, 0xFF000000 };

        var map_idx: usize = 0;
        while (map_idx < 1024) : (map_idx += 1) {
            const tile_id = bus.read(map_base + @as(u16, @intCast(map_idx)));

            var tile_addr: u16 = 0;
            if (use_8000_method) {
                tile_addr = 0x8000 + (@as(u16, tile_id) * 16);
            } else {
                const signed_id = @as(i8, @bitCast(tile_id));
                tile_addr = 0x9000 + (@as(u16, @bitCast(@as(i16, signed_id))) * 16);
            }

            const tile_y = map_idx / 32;
            const tile_x = map_idx % 32;

            var y: usize = 0;
            while (y < 8) : (y += 1) {
                const b1 = bus.read(tile_addr + @as(u16, @intCast(y * 2)));
                const b2 = bus.read(tile_addr + @as(u16, @intCast(y * 2)) + 1);

                var x: usize = 0;
                while (x < 8) : (x += 1) {
                    const bit = @as(u3, @intCast(7 - x));
                    const lo = (b1 >> bit) & 1;
                    const hi = (b2 >> bit) & 1;
                    const color = palette[(hi << 1) | lo];

                    const dest_x = (tile_x * 8) + x;
                    const dest_y = (tile_y * 8) + y;
                    const dest_idx = (dest_y * 256 + dest_x) * 4;

                    self.pixels[dest_idx + 0] = @as(u8, @intCast((color >> 0) & 0xFF));
                    self.pixels[dest_idx + 1] = @as(u8, @intCast((color >> 8) & 0xFF));
                    self.pixels[dest_idx + 2] = @as(u8, @intCast((color >> 16) & 0xFF));
                    self.pixels[dest_idx + 3] = 0xFF;
                }
            }
        }

        var data = sg.ImageData{};
        data.mip_levels[0] = sg.asRange(&self.pixels);
        sg.updateImage(self.image, data);
    }

    fn drawViewportRect(_: *Self, bus: *Bus, image_start_pos: ig.ImVec2) void {
        const scx = bus.read(0xFF43);
        const scy = bus.read(0xFF42);

        const draw_list = ig.igGetWindowDrawList();
        const color = ig.igGetColorU32ImVec4(.{ .x = 1, .y = 0, .z = 0, .w = 1 });

        const clip_min = image_start_pos;
        const clip_max = ig.ImVec2{ .x = image_start_pos.x + 256, .y = image_start_pos.y + 256 };
        ig.ImDrawList_PushClipRect(draw_list, clip_min, clip_max, true);
        defer ig.ImDrawList_PopClipRect(draw_list);

        const x = image_start_pos.x + @as(f32, @floatFromInt(scx));
        const y = image_start_pos.y + @as(f32, @floatFromInt(scy));

        ig.ImDrawList_AddRectEx(draw_list, .{ .x = x, .y = y }, .{ .x = x + 160, .y = y + 144 }, color, 0.0, 0, 2.0);

        ig.ImDrawList_AddRectEx(draw_list, .{ .x = x - 256, .y = y }, .{ .x = x - 256 + 160, .y = y + 144 }, color, 0.0, 0, 2.0);
        ig.ImDrawList_AddRectEx(draw_list, .{ .x = x, .y = y - 256 }, .{ .x = x + 160, .y = y - 256 + 144 }, color, 0.0, 0, 2.0);
        ig.ImDrawList_AddRectEx(draw_list, .{ .x = x - 256, .y = y - 256 }, .{ .x = x - 256 + 160, .y = y - 256 + 144 }, color, 0.0, 0, 2.0);
    }
};
