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

pub inline fn signExtend(value: u8) u16 {
    return @bitCast(@as(i16, @as(i8, @bitCast(value))));
}

pub inline fn checkBit(value: u8, bit: u3) bool {
    return (value & (@as(u8, 1) << bit)) != 0;
}

pub inline fn setBit(value: u8, bit: u3) u8 {
    return value | (@as(u8, 1) << bit);
}

pub inline fn clearBit(value: u8, bit: u3) u8 {
    return value & ~(@as(u8, 1) << bit);
}

pub inline fn getTilePixelColor(byte1: u8, byte2: u8, x: u3) u8 {
    const bit_mask = @as(u8, 1) << (7 - x);
    const lo = if (byte1 & bit_mask != 0) @as(u8, 1) else 0;
    const hi = if (byte2 & bit_mask != 0) @as(u8, 2) else 0;

    return hi | lo;
}

pub inline fn getPaletteColor(palette: u8, color_idx: u8) u8 {
    return (palette >> (@as(u3, @truncate(color_idx)) * 2)) & 0b11;
}
