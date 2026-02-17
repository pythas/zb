const std = @import("std");

pub const Joypad = struct {
    state: u8 = 0xff,
    joyp: u8 = 0,

    pub const Button = enum(u3) {
        A = 0,
        B = 1,
        Select = 2,
        Start = 3,
        Right = 4,
        Left = 5,
        Up = 6,
        Down = 7,
    };

    const Self = @This();

    pub fn init() Self {
        return .{};
    }

    pub fn reset(self: *Self) void {
        self.* = .{};
    }

    pub fn setButton(self: *Self, button: Button, pressed: bool) void {
        const bit = @intFromEnum(button);
        if (pressed) {
            self.state &= ~(@as(u8, 1) << bit);
        } else {
            self.state |= (@as(u8, 1) << bit);
        }
    }

    pub fn read(self: *const Self, address: u16) u8 {
        return switch (address) {
            0xff00 => {
                var res: u8 = 0xcf | self.joyp;
                if (self.joyp & 0x10 == 0) {
                    res &= (self.state >> 4) | 0xf0;
                }
                if (self.joyp & 0x20 == 0) {
                    res &= (self.state & 0x0f) | 0xf0;
                }
                return res;
            },
            else => std.debug.panic("joypad: invalid read address: 0x{x}\n", .{address}),
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
