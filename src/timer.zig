const std = @import("std");
const cpu = @import("cpu.zig");

pub const Timer = struct {
    div: u8 = 0,
    tima: u8 = 0,
    tma: u8 = 0,
    tac: u8 = 0,

    const Self = @This();

    pub fn init() Self {
        return .{};
    }

    pub fn cycle(self: *Self, cycles: u8) ?cpu.Interrupt {
        _ = self;
        _ = cycles;
        const interrupt: cpu.Interrupt = undefined;
        return interrupt;
    }

    pub fn read(self: *const Self, address: u16) u8 {
        return switch (address) {
            0xff04 => self.div,
            0xff05 => self.tima,
            0xff06 => self.tma,
            0xff07 => self.tac,
            else => std.debug.panic("timer: invalid read adress: 0x{x}\n", .{address}),
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
