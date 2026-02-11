const std = @import("std");

pub const Joypad = struct {
    state: u8 = 0xff,
    joyp: u8 = 0,

    const Self = @This();

    pub fn init() Self {
        return .{};
    }

    pub fn read(self: *const Self, address: u16) u8 {
        return switch (address) {
            0xff00 => {
                return if (self.joyp == 0x10)
                    0xf0 | self.state & 0x0f
                else if (self.joyp == 0x20)
                    0xf0 | (self.state & 0xf0) >> 4
                else
                    0xff;
            },
            else => std.debug.panic("joypad: invalid read adress: 0x{x}\n", .{address}),
        };
    }

    pub fn write(self: *Self, address: u16, value: u8) void {
        switch (address) {
            0xff00 => {
                self.joyp = value & 0x30;
            },
            else => std.debug.panic("joypad: invalid write address: 0x{x}\n", .{address}),
        }
    }
};
