const std = @import("std");

pub const Gpu = struct {
    // clock: u32,
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

    const Self = @This();

    pub fn init() Self {
        return .{};
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
            else => std.debug.panic("gpu: invalid read adress: 0x{x}\n", .{address}),
        };
    }

    pub fn write(self: *Self, address: u16, value: u8) void {
        switch (address) {
            0x8000...0x9fff => self.vram[address - 0x8000] = value,
            0xfe00...0xfe9f => self.oam[address - 0xfe00] = value,
            0xff40 => {
                // if self.lcdc & (1 << 7) > 0 && value & (1 << 7) == 0 {
                //     self.stat = 0x80;
                //     self.ly = 0x00;
                // }
                // println!("LCDC W: {:08b}", value);
                // self.lcdc = value;
            },
            0xff41 => {
                self.stat = value;
            },
            0xff42 => self.scy = value,
            0xff43 => self.scx = value,
            0xff44 => self.ly = 0x00,
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
