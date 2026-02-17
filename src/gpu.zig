const std = @import("std");
const cpu = @import("cpu.zig");
const utils = @import("utils.zig");

pub const Sprite = struct {
    x: i16,
    y: i16,
    tile: u8,
    palette: bool,
    x_flip: bool,
    y_flip: bool,
    priority: bool,

    const Self = @This();

    pub fn init(data: [4]u8) Self {
        return .{
            .y = @as(i16, data[0]) - 16,
            .x = @as(i16, data[1]) - 8,
            .tile = data[2],
            .palette = (data[3] & 0x10) != 0,
            .x_flip = (data[3] & 0x20) != 0,
            .y_flip = (data[3] & 0x40) != 0,
            .priority = (data[3] & 0x80) != 0,
        };
    }
};

pub const Gpu = struct {
    dots: u32 = 0,
    lcdc: u8 = 0,
    stat: u8 = 0,
    scy: u8 = 0,
    scx: u8 = 0,
    ly: u8 = 0,
    lyc: u8 = 0,
    bgp: u8 = 0,
    obp0: u8 = 0,
    obp1: u8 = 0,
    wy: u8 = 0,
    wx: u8 = 0,
    vram: [0x2000]u8 = [_]u8{0} ** 0x2000,
    oam: [0xA0]u8 = [_]u8{0} ** 0xA0,

    frame_ready: bool = false,
    video_buffer: [160 * 144]u32 = undefined,

    const Self = @This();
    const Palette: [4]u32 = .{
        0xFF9BBC0F,
        0xFF8BAC0F,
        0xFF306230,
        0xFF0F380F,
    };

    pub fn init() Self {
        return .{};
    }

    pub fn reset(self: *Self) void {
        self.* = .{};
    }

    pub inline fn getMode(self: Self) u8 {
        return self.stat & 0b11;
    }

    pub inline fn setMode(self: *Self, mode: u8) void {
        self.stat = (self.stat & 0xf8) | mode & 0x03;
    }

    fn updateLyc(self: *Self) ?cpu.Interrupt {
        if (self.ly == self.lyc) {
            // LYC=LY flag
            self.stat = utils.setBit(self.stat, 2);

            if (utils.checkBit(self.stat, 6)) {
                return .LCD;
            }
        } else {
            // clear LYC=LY
            self.stat = utils.clearBit(self.stat, 2);
        }

        return null;
    }

    pub fn cycle(self: *Self, cycles: u8) ?cpu.Interrupt {
        self.dots += cycles;

        if (!utils.checkBit(self.lcdc, 7)) {
            return null;
        }

        const mode = self.getMode();
        var interrupt: ?cpu.Interrupt = null;

        switch (mode) {
            // OAM scan
            2 => {
                if (self.dots >= 80) {
                    self.dots -= 80;
                    self.setMode(3);
                }
            },
            // Drawing pixels
            3 => {
                if (self.dots >= 172) {
                    self.dots -= 172;
                    self.setMode(0);

                    self.renderScanline();

                    // HBlank interrupt
                    if (utils.checkBit(self.stat, 3)) {
                        interrupt = .LCD;
                    }
                }
            },
            // HBlank
            0 => {
                if (self.dots >= 204) {
                    self.dots -= 204;
                    self.ly += 1;

                    // Check LYC for the new line
                    const lyc_intr = self.updateLyc();

                    if (self.ly == 144) {
                        self.setMode(1);
                        self.frame_ready = true;
                        interrupt = .VBlank;

                        if (utils.checkBit(self.stat, 4)) {}
                    } else {
                        self.setMode(2);
                        if (utils.checkBit(self.stat, 5)) {
                            interrupt = .LCD;
                        }
                    }

                    if (interrupt == null) interrupt = lyc_intr;
                }
            },
            // VBlank
            1 => {
                if (self.dots >= 456) {
                    self.dots -= 456;
                    self.ly += 1;

                    {
                        const lyc_interrupt = self.updateLyc();
                        if (interrupt == null) {
                            interrupt = lyc_interrupt;
                        }
                    }

                    if (self.ly > 153) {
                        self.ly = 0;
                        self.setMode(2);
                        self.frame_ready = false;

                        const lyc_interrupt = self.updateLyc();
                        if (interrupt == null) {
                            interrupt = lyc_interrupt;
                        }

                        if (utils.checkBit(self.stat, 5)) {
                            interrupt = .LCD;
                        }
                    }
                }
            },
            else => unreachable,
        }

        return interrupt;
    }

    fn renderScanline(self: *Self) void {
        const screen_y: u16 = self.ly;
        var bg_pixels = [_]u8{0} ** 160;

        const bg_enabled = utils.checkBit(self.lcdc, 0);
        const window_enabled = utils.checkBit(self.lcdc, 5) and self.ly >= self.wy;

        for (0..160) |i| {
            const screen_x: u16 = @intCast(i);
            var color_idx: u8 = 0;
            var palette_idx: u8 = 0;
            var is_window = false;

            if (window_enabled and screen_x + 7 >= self.wx) {
                is_window = true;
            }

            if (is_window) {
                const x = screen_x + 7 - self.wx;
                const y = screen_y - self.wy;

                const tile_x = x / 8;
                const tile_y = y / 8;

                const tile_fine_x: u3 = @truncate(x % 8);
                const tile_fine_y: u3 = @truncate(y % 8);

                const tile_map_base: u16 = if (utils.checkBit(self.lcdc, 6)) 0x9c00 else 0x9800;
                const map_address = tile_map_base + (tile_y * 32) + tile_x;
                const tile_id = self.vram[map_address - 0x8000];

                var tile_address: u16 = 0;
                if (utils.checkBit(self.lcdc, 4)) {
                    tile_address = 0x8000 + (@as(u16, tile_id) * 16);
                } else {
                    const signed_id = @as(i8, @bitCast(tile_id));
                    const offset = @as(i32, signed_id) * 16;
                    tile_address = @as(u16, @intCast(@as(i32, 0x9000) + offset));
                }

                tile_address += (@as(u16, tile_fine_y) * 2);

                const byte1 = self.vram[tile_address - 0x8000];
                const byte2 = self.vram[(tile_address + 1) - 0x8000];

                color_idx = utils.getTilePixelColor(byte1, byte2, tile_fine_x);
                palette_idx = utils.getPaletteColor(self.bgp, color_idx);
            } else if (bg_enabled) {
                const x = screen_x +% @as(u16, self.scx);
                const y = screen_y +% @as(u16, self.scy);

                const tile_x = (x / 8) % 32;
                const tile_y = (y / 8) % 32;

                const tile_fine_x: u3 = @truncate(x % 8);
                const tile_fine_y: u3 = @truncate(y % 8);

                const tile_map_base: u16 = if (utils.checkBit(self.lcdc, 3)) 0x9c00 else 0x9800;
                const map_address = tile_map_base + (tile_y * 32) + tile_x;
                const tile_id = self.vram[map_address - 0x8000];

                var tile_address: u16 = 0;
                if (utils.checkBit(self.lcdc, 4)) {
                    tile_address = 0x8000 + (@as(u16, tile_id) * 16);
                } else {
                    const signed_id = @as(i8, @bitCast(tile_id));
                    const offset = @as(i32, signed_id) * 16;
                    tile_address = @as(u16, @intCast(@as(i32, 0x9000) + offset));
                }

                tile_address += (@as(u16, tile_fine_y) * 2);

                const byte1 = self.vram[tile_address - 0x8000];
                const byte2 = self.vram[(tile_address + 1) - 0x8000];

                color_idx = utils.getTilePixelColor(byte1, byte2, tile_fine_x);
                palette_idx = utils.getPaletteColor(self.bgp, color_idx);
            } else {
                color_idx = 0;
                palette_idx = 0;
            }

            bg_pixels[i] = color_idx;
            const buffer_idx = (@as(usize, screen_y) * 160) + i;
            self.video_buffer[buffer_idx] = Palette[palette_idx];
        }

        if (utils.checkBit(self.lcdc, 1)) {
            const sprite_height: i16 = if (utils.checkBit(self.lcdc, 2)) 16 else 8;
            var sprite_count: u8 = 0;
            var sprites_on_line = [_]Sprite{undefined} ** 10;

            for (0..40) |j| {
                const sprite = Sprite.init(self.oam[j * 4 ..][0..4].*);
                if (@as(i16, @intCast(screen_y)) >= sprite.y and @as(i16, @intCast(screen_y)) < sprite.y + sprite_height) {
                    sprites_on_line[sprite_count] = sprite;
                    sprite_count += 1;
                    if (sprite_count == 10) break;
                }
            }

            if (sprite_count > 0) {
                // sort by x coordinate
                for (0..sprite_count) |j| {
                    for (j + 1..sprite_count) |k| {
                        if (sprites_on_line[j].x > sprites_on_line[k].x) {
                            const tmp = sprites_on_line[j];
                            sprites_on_line[j] = sprites_on_line[k];
                            sprites_on_line[k] = tmp;
                        }
                    }
                }

                var j: usize = sprite_count;
                while (j > 0) {
                    j -= 1;
                    const sprite = sprites_on_line[j];

                    var tile_y = @as(u16, @intCast(@as(i16, @intCast(screen_y)) - sprite.y));
                    if (sprite.y_flip) {
                        tile_y = @as(u16, @intCast(sprite_height)) - 1 - tile_y;
                    }

                    const tile_id = if (sprite_height == 16) sprite.tile & 0xFE else sprite.tile;
                    const tile_address = 0x8000 + (@as(u16, tile_id) * 16) + (tile_y * 2);

                    const byte1 = self.vram[tile_address - 0x8000];
                    const byte2 = self.vram[(tile_address + 1) - 0x8000];

                    for (0..8) |x_offset| {
                        const screen_x = sprite.x + @as(i16, @intCast(x_offset));
                        if (screen_x < 0 or screen_x >= 160) continue;

                        var tile_x = @as(u3, @intCast(x_offset));
                        if (sprite.x_flip) {
                            tile_x = 7 - tile_x;
                        }

                        const color_idx = utils.getTilePixelColor(byte1, byte2, tile_x);

                        if (color_idx == 0 or (sprite.priority and bg_pixels[@as(usize, @intCast(screen_x))] != 0)) {
                            continue;
                        }

                        const palette = if (sprite.palette) self.obp1 else self.obp0;
                        const palette_color = utils.getPaletteColor(palette, color_idx);

                        const buffer_idx = (@as(usize, screen_y) * 160) + @as(usize, @intCast(screen_x));
                        self.video_buffer[buffer_idx] = Palette[palette_color];
                    }
                }
            }
        }
    }

    pub fn read(self: *const Self, address: u16) u8 {
        return switch (address) {
            0x8000...0x9fff => self.vram[address - 0x8000],
            0xfe00...0xfe9f => self.oam[address - 0xfe00],
            0xff40 => self.lcdc,
            0xff41 => self.stat,
            0xff42 => self.scy,
            0xff43 => self.scx,
            0xff44 => self.ly,
            0xff45 => self.lyc,
            0xff47 => self.bgp,
            0xff48 => self.obp0,
            0xff49 => self.obp1,
            0xff4a => self.wy,
            0xff4b => self.wx,
            else => std.debug.panic("gpu: invalid read address: 0x{x}\n", .{address}),
        };
    }

    pub fn write(self: *Self, address: u16, value: u8) void {
        switch (address) {
            0x8000...0x9fff => self.vram[address - 0x8000] = value,
            0xfe00...0xfe9f => self.oam[address - 0xfe00] = value,
            0xff40 => {
                self.lcdc = value;

                if (!utils.checkBit(value, 7)) {
                    self.ly = 0;
                    self.stat &= 0xFC;
                    self.dots = 0;
                }
            },
            0xff41 => {
                self.stat = (value & 0xF8) | (self.stat & 0x07);
            },
            0xff42 => self.scy = value,
            0xff43 => self.scx = value,
            0xff44 => {},
            0xff45 => self.lyc = value,
            0xff47 => self.bgp = value,
            0xff48 => self.obp0 = value,
            0xff49 => self.obp1 = value,
            0xff4a => self.wy = value,
            0xff4b => self.wx = value,
            else => std.debug.panic("gpu: invalid write address: 0x{x}\n", .{address}),
        }
    }
};
