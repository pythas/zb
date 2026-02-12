const std = @import("std");
const Gpu = @import("gpu.zig").Gpu;
const Apu = @import("apu.zig").Apu;
const Joypad = @import("joypad.zig").Joypad;
const Timer = @import("timer.zig").Timer;

pub const Bus = struct {
    // TODO: should we use a packed struct instead?
    gpu: *Gpu,
    apu: *Apu,
    joypad: *Joypad,
    timer: *Timer,

    bootrom: [0x100]u8 = [_]u8{0} ** 0x100,
    rom: [0x8000]u8 = [_]u8{0} ** 0x8000,
    eram: [0x2000]u8 = [_]u8{0} ** 0x2000,
    wram_0: [0x2000]u8 = [_]u8{0} ** 0x2000,
    wram_n: [0x2000]u8 = [_]u8{0} ** 0x2000,
    io: [0x80]u8 = [_]u8{0} ** 0x80,
    hram: [0x7f]u8 = [_]u8{0} ** 0x7f,
    intf: u8 = 0,
    inte: u8 = 0,
    sb: u8 = 0,
    sc: u8 = 0,
    disable_bootrom: u8 = 0,
    dma: u8 = 0,
    dma_index: u8 = 0,
    in_dma: bool = false,

    const Self = @This();

    pub fn init(
        gpu: *Gpu,
        apu: *Apu,
        joypad: *Joypad,
        timer: *Timer,
    ) Self {
        return .{
            .gpu = gpu,
            .apu = apu,
            .joypad = joypad,
            .timer = timer,
        };
    }

    pub fn loadBootrom(self: *Self, data: []u8) void {
        if (data.len > self.bootrom.len) {
            std.debug.panic("bus: bootrom data too large", .{});
        }

        @memcpy(self.bootrom[0..data.len], data);
    }

    pub fn read(self: *const Self, address: u16) u8 {
        return switch (address) {
            0x0000...0x00ff => {
                return if (self.disable_bootrom == 0)
                    self.bootrom[address]
                else
                    self.rom[address];
            },
            0x0100...0x7fff => self.rom[address],
            0x8000...0x9fff => self.gpu.read(address),
            0xa000...0xbfff => self.eram[address - 0xa000],
            0xc000...0xcfff => self.wram_0[address - 0xc000],
            0xd000...0xdfff => self.wram_n[address - 0xd000],
            0xe000...0xefff => self.wram_0[address - 0xe000],
            0xf000...0xfdff => self.wram_n[address - 0xf000],
            0xfe00...0xfe9f => self.gpu.read(address),
            0xfea0...0xfeff => 0x00, // unusable
            0xff00 => self.joypad.read(address),
            0xff01 => self.sb,
            0xff02 => self.sc,
            0xff03 => self.io[address - 0xff03],
            0xff04...0xff07 => self.timer.read(address),
            0xff08...0xff0e => self.io[address - 0xff08],
            0xff0f => self.intf,
            0xff10...0xff3f => self.apu.read(address),
            0xff40...0xff45 => self.gpu.read(address),
            0xff46 => self.dma,
            0xff47...0xff4b => self.gpu.read(address),
            0xff4c...0xff4f => self.io[address - 0xff4c],
            0xff50 => self.disable_bootrom,
            0xff51...0xff7f => self.io[address - 0xff51],
            0xff80...0xfffe => self.hram[address - 0xff80],
            0xffff => self.inte,
        };
    }

    pub fn write(self: *Self, address: u16, value: u8) void {
        switch (address) {
            0x0000...0x00ff => {
                if (self.disable_bootrom == 0) {
                    self.bootrom[address] = value;
                } else {
                    self.rom[address] = value;
                }
            },
            0x0100...0x7fff => self.rom[address] = value, // TODO: handle memory bank switching
            0x8000...0x9fff => self.gpu.write(address, value),
            0xa000...0xbfff => self.eram[address - 0xa000] = value,
            0xc000...0xcfff => self.wram_0[address - 0xc000] = value,
            0xd000...0xdfff => self.wram_n[address - 0xd000] = value,
            0xe000...0xefff => self.wram_0[address - 0xe000] = value,
            0xf000...0xfdff => self.wram_n[address - 0xf000] = value,
            0xfe00...0xfe9f => self.gpu.write(address, value),
            0xfea0...0xfeff => {}, // unusable
            0xff00 => self.joypad.write(address, value),
            0xff01 => self.sb = value,
            0xff02 => self.sc = value,
            0xff03 => self.io[address - 0xff03] = value,
            0xff04...0xff07 => self.timer.write(address, value),
            0xff08...0xff0e => self.io[address - 0xff08] = value,
            0xff0f => self.intf = value,
            0xff10...0xff3f => self.apu.write(address, value),
            0xff40...0xff45 => self.gpu.write(address, value),
            0xff46 => {
                self.dma = value;
                self.in_dma = true;
            },
            0xff47...0xff4b => self.gpu.write(address, value),
            0xff4c...0xff4f => self.io[address - 0xff4c] = value,
            0xff50 => self.disable_bootrom = value,
            0xff51...0xff7f => self.io[address - 0xff51] = value,
            0xff80...0xfffe => self.hram[address - 0xff80] = value,
            0xffff => self.inte = value,
        }
    }
};
