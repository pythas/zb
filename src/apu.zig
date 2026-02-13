const std = @import("std");

const SquareChannel = struct {
    nr0: u8 = 0,
    nr1: u8 = 0,
    nr2: u8 = 0,
    nr3: u8 = 0,
    nr4: u8 = 0,

    dac_enabled: bool = false,
    enabled: bool = false,
    timer: u16 = 0,
    frequency: u16 = 0,
    sequence: u8 = 0,
    volume: u8 = 0,
    output_volume: u8 = 0,
    duty_cycle: u8 = 0,
    duty_cycles: [4][8]u8 = .{
        .{ 0, 1, 1, 1, 1, 1, 1, 1 },
        .{ 0, 0, 1, 1, 1, 1, 1, 1 },
        .{ 0, 0, 0, 0, 1, 1, 1, 1 },
        .{ 0, 0, 0, 0, 0, 0, 1, 1 },
    },

    length: u8 = 0,
    length_timer: u8 = 0,

    const Self = @This();

    pub fn read(self: Self, nr: u8) u8 {
        return switch (nr) {
            0 => self.nr0 | 0x80,
            1 => self.nr1 | 0x3f,
            2 => self.nr2 | 0x00,
            3 => self.nr3 | 0xff,
            4 => self.nr4 | 0xbf,
            else => std.debug.panic("apu sq: invalid register read: 0x{x}\n", .{nr}),
        };
    }
    pub fn write(self: *Self, nr: u8, value: u8) void {
        switch (nr) {
            0 => self.nr0 = value,
            1 => self.nr1 = value,
            2 => self.nr2 = value,
            3 => self.nr3 = value,
            4 => self.nr4 = value,
            else => std.debug.panic("apu sq: invalid register write: 0x{x}\n", .{nr}),
        }
    }
};

pub const Apu = struct {
    channels: [2]SquareChannel = [_]SquareChannel{.{}} ** 2,

    nr30: u8 = 0,
    nr31: u8 = 0,
    nr32: u8 = 0,
    nr33: u8 = 0,
    nr34: u8 = 0,
    nr41: u8 = 0,
    nr42: u8 = 0,
    nr43: u8 = 0,
    nr44: u8 = 0,
    nr50: u8 = 0,
    nr51: u8 = 0,
    nr52: u8 = 0,
    wave_pattern: [0x10]u8 = [_]u8{0} ** 0x10,

    const Self = @This();

    pub fn init() Self {
        return .{};
    }

    pub fn read(self: *const Self, address: u16) u8 {
        return switch (address) {
            0xff10...0xff14 => self.channels[0].read(@truncate(address - 0xff10)),
            0xff15 => 0xff,
            0xff16...0xff19 => self.channels[1].read(@truncate(address - 0xff15)),

            // channel 3
            0xff1a => self.nr30,
            0xff1b => self.nr31,
            0xff1c => self.nr32,
            0xff1d => self.nr33,
            0xff1e => self.nr34,
            0xff30...0xff3f => self.wave_pattern[address - 0xff30],

            // channel 4
            0xff1f => 0xff,
            0xff20 => self.nr41,
            0xff21 => self.nr42,
            0xff22 => self.nr43,
            0xff23 => self.nr44,

            // control
            0xff24 => self.nr50,
            0xff25 => self.nr51,
            0xff26 => self.nr52,

            0xff27...0xff2f => 0xff,

            else => std.debug.panic("apu: invalid read address: 0x{x}\n", .{address}),
        };
    }

    pub fn write(self: *Self, address: u16, value: u8) void {
        switch (address) {
            0xff10...0xff14 => self.channels[0].write(@truncate(address - 0xff10), value),
            0xff15 => {},
            0xff16...0xff19 => self.channels[1].write(@as(u8, @truncate(address - 0xff15)), value),

            // Channel 3
            0xff1a => self.nr30 = value,
            0xff1b => self.nr31 = value,
            0xff1c => self.nr32 = value,
            0xff1d => self.nr33 = value,
            0xff1e => self.nr34 = value,
            0xff30...0xff3f => self.wave_pattern[address - 0xff30] = value,

            // Channel 4
            0xff1f => {},
            0xff20 => self.nr41 = value,
            0xff21 => self.nr42 = value,
            0xff22 => self.nr43 = value,
            0xff23 => self.nr44 = value,

            // Control
            0xff24 => self.nr50 = value,
            0xff25 => self.nr51 = value,
            0xff26 => self.nr52 = value,

            0xff27...0xff2f => {},
            else => std.debug.panic("apu: invalid write address: 0x{x}\n", .{address}),
        }
    }
};
