const std = @import("std");

pub inline fn join(hi: u8, lo: u8) u16 {
    return (@as(u16, hi) << 8) | @as(u16, lo);
}

pub inline fn split(value: u16) struct { hi: u8, lo: u8 } {
    return .{
        .hi = @truncate(value >> 8),
        .lo = @truncate(value),
    };
}

pub inline fn toRelativeOffset(value: u8) u16 {
    return @bitCast(@as(i16, @as(i8, @bitCast(value))));
}
