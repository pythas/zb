const std = @import("std");
const cpu = @import("cpu.zig");

pub const Timer = struct {
    div: u8 = 0,
    tima: u8 = 0,
    tma: u8 = 0,
    tac: u8 = 0,

    div_cycle: u16 = 0,
    tima_cycle: u32 = 0,

    const Self = @This();

    pub fn init() Self {
        return .{};
    }

    pub fn reset(self: *Self) void {
        self.* = .{};
    }

    pub fn cycle(self: *Self, cycles: u8) ?cpu.Interrupt {
        var interrupt: ?cpu.Interrupt = null;

        // DIV increments every 256 T-cycles (16384Hz)
        self.div_cycle += cycles;
        if (self.div_cycle >= 256) {
            self.div_cycle -= 256;
            self.div +%= 1;
        }

        // TIMA increments at rate specified by TAC
        if ((self.tac & 0x04) != 0) {
            self.tima_cycle += cycles;

            const threshold: u32 = switch (self.tac & 0x03) {
                0x00 => 1024, // 4096Hz
                0x01 => 16, // 262144Hz
                0x02 => 64, // 65536Hz
                0x03 => 256, // 16384Hz
                else => unreachable,
            };

            if (self.tima_cycle >= threshold) {
                self.tima_cycle -= threshold;

                if (self.tima == 0xFF) {
                    self.tima = self.tma;
                    interrupt = .Timer;
                } else {
                    self.tima += 1;
                }
            }
        }

        return interrupt;
    }

    pub fn read(self: *const Self, address: u16) u8 {
        return switch (address) {
            0xff04 => self.div,
            0xff05 => self.tima,
            0xff06 => self.tma,
            0xff07 => self.tac,
            else => std.debug.panic("timer: invalid read address: 0x{x}\n", .{address}),
        };
    }

    pub fn write(self: *Self, address: u16, value: u8) void {
        switch (address) {
            0xff04 => self.div = 0,
            0xff05 => self.tima = value,
            0xff06 => self.tma = value,
            0xff07 => self.tac = value & 0x07,
            else => std.debug.panic("timer: invalid write address: 0x{x}\n", .{address}),
        }
    }
};
