const std = @import("std");
const utils = @import("utils.zig");

const SquareChannel = struct {
    nr0: u8 = 0,
    nr1: u8 = 0,
    nr2: u8 = 0,
    nr3: u8 = 0,
    nr4: u8 = 0,

    dac_enabled: bool = false,
    enabled: bool = false,
    timer: i32 = 0,
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

    pub fn cycle(self: *Self, cycles: u8) void {
        const raw_frequency: u16 = (@as(u16, self.nr4 & 0x7) << 8) | self.nr3;
        const period = (2048 - raw_frequency) * 4;

        self.timer -= cycles;

        if (self.timer <= 0) {
            self.timer += period;

            self.sequence = (self.sequence + 1) % 8;

            self.output_volume = if (self.duty_cycles[self.duty_cycle][self.sequence] == 1) self.volume else 0;
        }
    }

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
            1 => {
                self.nr1 = value;
                self.length = value & 0x3f;
                self.duty_cycle = (value >> 6) & 0x03;
            },
            2 => {
                self.nr2 = value;
                self.dac_enabled = (value & 0xf8) != 0;
                self.volume = (value >> 4) & 0x0f;
            },
            3 => self.nr3 = value,
            4 => {
                self.nr4 = value;

                if (utils.checkBit(value, 7)) {
                    self.enabled = true;
                    self.volume = (self.nr2 >> 4) & 0x0f;

                    const raw_frequency: u16 = (@as(u16, self.nr4 & 0x7) << 8) | self.nr3;
                    self.timer = (2048 - @as(i32, raw_frequency)) * 4;
                }
            },
            else => std.debug.panic("apu sq: invalid register write: 0x{x}\n", .{nr}),
        }
    }
};

pub const Apu = struct {
    allocator: std.mem.Allocator,

    channels: [2]SquareChannel = [_]SquareChannel{.{}} ** 2,

    buffer: std.ArrayListUnmanaged(f32),
    sample_timer: f32 = 0,
    cycles_per_sample: f32,

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
    const ClockSpeed: f32 = 4194304.0;

    pub fn init(allocator: std.mem.Allocator, sample_rate: f32) Self {
        return .{
            .allocator = allocator,
            .buffer = .{},
            .cycles_per_sample = ClockSpeed / sample_rate,
        };
    }

    pub fn deinit(self: *Self) void {
        self.buffer.deinit(self.allocator);
    }

    pub fn reset(self: *Self) void {
        const allocator = self.allocator;
        const cycles_per_sample = self.cycles_per_sample;
        var buffer = self.buffer;
        buffer.clearRetainingCapacity();

        self.* = .{
            .allocator = allocator,
            .cycles_per_sample = cycles_per_sample,
            .buffer = buffer,
        };
    }

    pub fn clearBuffer(self: *Self) void {
        self.buffer.clearRetainingCapacity();
    }

    pub fn cycle(self: *Self, cycles: u8) !void {
        self.channels[0].cycle(cycles);
        self.channels[1].cycle(cycles);

        self.sample_timer -= @floatFromInt(cycles);

        while (self.sample_timer <= 0) {
            self.sample_timer += self.cycles_per_sample;

            var sample: f32 = 0;
            sample += @as(f32, @floatFromInt(self.channels[0].output_volume));
            sample += @as(f32, @floatFromInt(self.channels[1].output_volume));

            sample /= 100.0;

            try self.buffer.append(self.allocator, sample);
        }
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

            // channel 3
            0xff1a => self.nr30 = value,
            0xff1b => self.nr31 = value,
            0xff1c => self.nr32 = value,
            0xff1d => self.nr33 = value,
            0xff1e => self.nr34 = value,
            0xff30...0xff3f => self.wave_pattern[address - 0xff30] = value,

            // channel 4
            0xff1f => {},
            0xff20 => self.nr41 = value,
            0xff21 => self.nr42 = value,
            0xff22 => self.nr43 = value,
            0xff23 => self.nr44 = value,

            // control
            0xff24 => self.nr50 = value,
            0xff25 => self.nr51 = value,
            0xff26 => self.nr52 = value,

            0xff27...0xff2f => {},
            else => std.debug.panic("apu: invalid write address: 0x{x}\n", .{address}),
        }
    }
};
