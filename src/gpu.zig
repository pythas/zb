const std = @import("std");
const cpu = @import("cpu.zig");
const utils = @import("utils.zig");

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

    const Self = @This();

    pub fn init() Self {
        return .{};
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
            // Mode 2: OAM Scan
            2 => {
                if (self.dots >= 80) {
                    self.dots -= 80;
                    self.setMode(3);
                }
            },
            // Mode 3: Drawing Pixels
            3 => {
                if (self.dots >= 172) {
                    self.dots -= 172;
                    self.setMode(0);

                    // HBlank Interrupt (Bit 3)
                    if (utils.checkBit(self.stat, 3)) {
                        interrupt = .LCD;
                    }
                }
            },
            // Mode 0: HBlank
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
            // Mode 1: VBlank
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

    fn render(self: *Self) void {
        _ = self;
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
