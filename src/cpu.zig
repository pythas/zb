const std = @import("std");
const FlatBus = @import("flat_bus.zig").FlatBus;
const Bus = @import("bus.zig").Bus;
const Gpu = @import("gpu.zig").Gpu;
const Apu = @import("apu.zig").Apu;
const Joypad = @import("joypad.zig").Joypad;
const Timer = @import("timer.zig").Timer;
const utils = @import("utils.zig");

const OpcodeMeta = struct {
    mnemonic: []const u8,
    length: u8,
    cycles: u8,
};

const ISA = [_]OpcodeMeta{
    .{ .mnemonic = "NOP", .length = 1, .cycles = 4 },
} ++ [_]OpcodeMeta{.{ .mnemonic = "???", .length = 1, .cycles = 4 }} ** 255;

const Operand = enum { A, B, C, D, E, H, L, SP, AF, AFRef, BC, BCRef, DE, DERef, HL, HLRef, N, NN, NNRef };

const OperandData = union(enum) {
    u8: u8,
    u16: u16,
};

const Condition = enum {
    Z,
    C,
    NZ,
    NC,
    None,
};

const Flag = enum(u8) {
    Z = 0b1000_0000,
    N = 0b0100_0000,
    H = 0b0010_0000,
    C = 0b0001_0000,
};

const Direction = enum {
    Left,
    Right,
};

pub fn Cpu(comptime BusType: type) type {
    return struct {
        bus: *BusType,
        // clock: Clock,
        a: u8,
        f: u8,
        b: u8,
        c: u8,
        d: u8,
        e: u8,
        h: u8,
        l: u8,
        sp: u16,
        pc: u16,
        ime: bool,
        halted: bool,

        const Self = @This();

        pub fn init(bus: *BusType) Self {
            return .{
                .bus = bus,
                .a = 0,
                .f = 0,
                .b = 0,
                .c = 0,
                .d = 0,
                .e = 0,
                .h = 0,
                .l = 0,
                .sp = 0,
                .pc = 0,
                .ime = true,
                .halted = false,
            };
        }

        pub inline fn getAf(self: Self) u16 {
            return utils.join(self.a, self.f);
        }

        pub inline fn setAf(self: *Self, value: u16) void {
            const parts = utils.split(value);
            self.a = parts.hi;
            self.f = parts.lo & 0xf0; // sanitize flags
        }

        pub inline fn getBc(self: Self) u16 {
            return utils.join(self.b, self.c);
        }

        pub inline fn setBc(self: *Self, value: u16) void {
            const parts = utils.split(value);
            self.b = parts.hi;
            self.c = parts.lo;
        }

        pub inline fn getDe(self: Self) u16 {
            return utils.join(self.d, self.e);
        }

        pub inline fn setDe(self: *Self, value: u16) void {
            const parts = utils.split(value);
            self.d = parts.hi;
            self.e = parts.lo;
        }

        pub inline fn getHl(self: Self) u16 {
            return utils.join(self.h, self.l);
        }

        pub inline fn setHl(self: *Self, value: u16) void {
            const parts = utils.split(value);
            self.h = parts.hi;
            self.l = parts.lo;
        }

        pub inline fn getFlag(self: Self, flag: Flag) bool {
            return self.f & @intFromEnum(flag) != 0;
        }

        pub inline fn setFlag(self: *Self, flag: Flag, value: bool) void {
            if (value) {
                self.f = self.f | @intFromEnum(flag);
            } else {
                self.f = self.f & ~@intFromEnum(flag);
            }
        }

        pub fn readOperand(self: *Self, operand: Operand) OperandData {
            return switch (operand) {
                .A => .{ .u8 = self.a },
                .B => .{ .u8 = self.b },
                .C => .{ .u8 = self.c },
                .D => .{ .u8 = self.d },
                .E => .{ .u8 = self.e },
                .H => .{ .u8 = self.h },
                .L => .{ .u8 = self.l },
                .SP => .{ .u16 = self.sp },
                .AF => .{ .u16 = self.getAf() },
                .AFRef => .{ .u8 = self.bus.read(self.getAf()) },
                .BC => .{ .u16 = self.getBc() },
                .BCRef => .{ .u8 = self.bus.read(self.getBc()) },
                .DE => .{ .u16 = self.getDe() },
                .DERef => .{ .u8 = self.bus.read(self.getDe()) },
                .HL => .{ .u16 = self.getHl() },
                .HLRef => .{ .u8 = self.bus.read(self.getHl()) },
                .N => {
                    const data = self.bus.read(self.pc);

                    self.pc += 1;

                    return .{ .u8 = data };
                },
                .NN => {
                    const lo = self.bus.read(self.pc);
                    const hi = self.bus.read(self.pc + 1);
                    const data = utils.join(hi, lo);

                    self.pc += 2;

                    return .{ .u16 = data };
                },
                .NNRef => {
                    const lo = self.bus.read(self.pc);
                    const hi = self.bus.read(self.pc + 1);
                    const address = utils.join(hi, lo);

                    self.pc += 2;

                    return .{ .u8 = self.bus.read(address) };
                },
            };
        }

        pub fn writeOperand(self: *Self, operand: Operand, operand_data: OperandData) void {
            switch (operand) {
                .A => self.a = operand_data.u8,
                .B => self.b = operand_data.u8,
                .C => self.c = operand_data.u8,
                .D => self.d = operand_data.u8,
                .E => self.e = operand_data.u8,
                .H => self.h = operand_data.u8,
                .L => self.l = operand_data.u8,
                .SP => self.sp = operand_data.u16,
                .AF => self.setAf(operand_data.u16),
                .AFRef => unreachable,
                .BC => self.setBc(operand_data.u16),
                .BCRef => self.bus.write(self.getBc(), operand_data.u8),
                .DE => self.setDe(operand_data.u16),
                .DERef => self.bus.write(self.getDe(), operand_data.u8),
                .HL => self.setHl(operand_data.u16),
                .HLRef => self.bus.write(self.getHl(), operand_data.u8),
                .N => unreachable,
                .NN => unreachable,
                .NNRef => {
                    switch (operand_data) {
                        .u8 => |data| {
                            const lo = self.bus.read(self.pc);
                            const hi = self.bus.read(self.pc + 1);
                            const address = utils.join(hi, lo);

                            self.pc += 2;

                            self.bus.write(address, data);
                        },
                        .u16 => |data| {
                            const lo = self.bus.read(self.pc);
                            const hi = self.bus.read(self.pc + 1);
                            const address = utils.join(hi, lo);

                            self.pc += 2;

                            self.bus.write(address, @truncate(data));
                            self.bus.write(address + 1, @truncate(data >> 8));
                        },
                    }
                },
            }
        }

        pub fn step(self: *Self) u8 {
            const opcode = self.bus.read(self.pc);
            self.pc = self.pc +% 1;

            const meta = ISA[opcode];

            switch (opcode) {
                0x00 => self.op_nop(),
                // load
                0x01 => self.op_ld(.BC, .NN),
                0x02 => self.op_ld(.BCRef, .A),
                0x06 => self.op_ld(.B, .N),
                0x08 => self.op_ld(.NNRef, .SP),
                0x0a => self.op_ld(.A, .BCRef),
                0x0e => self.op_ld(.C, .N),
                0x11 => self.op_ld(.DE, .NN),
                0x12 => self.op_ld(.DERef, .A),
                0x16 => self.op_ld(.D, .N),
                0x1a => self.op_ld(.A, .DERef),
                0x1e => self.op_ld(.E, .N),
                0x21 => self.op_ld(.HL, .NN),
                0x22 => self.op_ldi(.HLRef, .A),
                0x26 => self.op_ld(.H, .N),
                0x2a => self.op_ldi(.A, .HLRef),
                0x2e => self.op_ld(.L, .N),
                0x31 => self.op_ld(.SP, .NN),
                0x32 => self.op_ldd(.HLRef, .A),
                0x36 => self.op_ld(.HLRef, .N),
                0x3a => self.op_ldd(.A, .HLRef),
                0x3e => self.op_ld(.A, .N),
                0x40 => self.op_ld(.B, .B),
                0x41 => self.op_ld(.B, .C),
                0x42 => self.op_ld(.B, .D),
                0x43 => self.op_ld(.B, .E),
                0x44 => self.op_ld(.B, .H),
                0x45 => self.op_ld(.B, .L),
                0x46 => self.op_ld(.B, .HLRef),
                0x47 => self.op_ld(.B, .A),
                0x48 => self.op_ld(.C, .B),
                0x49 => self.op_ld(.C, .C),
                0x4a => self.op_ld(.C, .D),
                0x4b => self.op_ld(.C, .E),
                0x4c => self.op_ld(.C, .H),
                0x4d => self.op_ld(.C, .L),
                0x4e => self.op_ld(.C, .HLRef),
                0x4f => self.op_ld(.C, .A),
                0x50 => self.op_ld(.D, .B),
                0x51 => self.op_ld(.D, .C),
                0x52 => self.op_ld(.D, .D),
                0x53 => self.op_ld(.D, .E),
                0x54 => self.op_ld(.D, .H),
                0x55 => self.op_ld(.D, .L),
                0x56 => self.op_ld(.D, .HLRef),
                0x57 => self.op_ld(.D, .A),
                0x58 => self.op_ld(.E, .B),
                0x59 => self.op_ld(.E, .C),
                0x5a => self.op_ld(.E, .D),
                0x5b => self.op_ld(.E, .E),
                0x5c => self.op_ld(.E, .H),
                0x5d => self.op_ld(.E, .L),
                0x5e => self.op_ld(.E, .HLRef),
                0x5f => self.op_ld(.E, .A),
                0x60 => self.op_ld(.H, .B),
                0x61 => self.op_ld(.H, .C),
                0x62 => self.op_ld(.H, .D),
                0x63 => self.op_ld(.H, .E),
                0x64 => self.op_ld(.H, .H),
                0x65 => self.op_ld(.H, .L),
                0x66 => self.op_ld(.H, .HLRef),
                0x67 => self.op_ld(.H, .A),
                0x68 => self.op_ld(.L, .B),
                0x69 => self.op_ld(.L, .C),
                0x6a => self.op_ld(.L, .D),
                0x6b => self.op_ld(.L, .E),
                0x6c => self.op_ld(.L, .H),
                0x6d => self.op_ld(.L, .L),
                0x6e => self.op_ld(.L, .HLRef),
                0x6f => self.op_ld(.L, .A),
                0x70 => self.op_ld(.HLRef, .B),
                0x71 => self.op_ld(.HLRef, .C),
                0x72 => self.op_ld(.HLRef, .D),
                0x73 => self.op_ld(.HLRef, .E),
                0x74 => self.op_ld(.HLRef, .H),
                0x75 => self.op_ld(.HLRef, .L),
                0x77 => self.op_ld(.HLRef, .A),
                0x78 => self.op_ld(.A, .B),
                0x79 => self.op_ld(.A, .C),
                0x7a => self.op_ld(.A, .D),
                0x7b => self.op_ld(.A, .E),
                0x7c => self.op_ld(.A, .H),
                0x7d => self.op_ld(.A, .L),
                0x7e => self.op_ld(.A, .HLRef),
                0x7f => self.op_ld(.A, .A),

                // arithmetic
                0x03 => self.op_inc(.BC),
                0x04 => self.op_inc(.B),
                0x05 => self.op_dec(.B),
                0x07 => self.op_rca(.Left),
                0x09 => self.op_add(.HL, .BC),
                0x0b => self.op_dec(.BC),
                0x0c => self.op_inc(.C),
                0x0d => self.op_dec(.C),
                0x0f => self.op_rca(.Right),
                0x13 => self.op_inc(.DE),
                0x14 => self.op_inc(.D),
                0x15 => self.op_dec(.D),
                0x17 => self.op_ra(.Left),
                0x1f => self.op_ra(.Right),
                0x19 => self.op_add(.HL, .DE),
                0x1b => self.op_dec(.DE),
                0x1c => self.op_inc(.E),
                0x1d => self.op_dec(.E),
                0x23 => self.op_inc(.HL),
                0x24 => self.op_inc(.H),
                0x25 => self.op_dec(.H),
                0x29 => self.op_add(.HL, .HL),
                0x2b => self.op_dec(.HL),
                0x2c => self.op_inc(.L),
                0x2d => self.op_dec(.L),
                0x33 => self.op_inc(.SP),
                0x34 => self.op_inc(.HLRef),
                0x35 => self.op_dec(.HLRef),
                0x39 => self.op_add(.HL, .SP),
                0x3b => self.op_dec(.SP),
                0x3c => self.op_inc(.A),
                0x3d => self.op_dec(.A),
                0x80 => self.op_add(.A, .B),
                0x81 => self.op_add(.A, .C),
                0x82 => self.op_add(.A, .D),
                0x83 => self.op_add(.A, .E),
                0x84 => self.op_add(.A, .H),
                0x85 => self.op_add(.A, .L),
                0x86 => self.op_add(.A, .HLRef),
                0x87 => self.op_add(.A, .A),
                0x88 => self.op_adc(.A, .B),
                0x89 => self.op_adc(.A, .C),
                0x8a => self.op_adc(.A, .D),
                0x8b => self.op_adc(.A, .E),
                0x8c => self.op_adc(.A, .H),
                0x8d => self.op_adc(.A, .L),
                0x8e => self.op_adc(.A, .HLRef),
                0x8f => self.op_adc(.A, .A),
                0x90 => self.op_sub(.A, .B),
                0x91 => self.op_sub(.A, .C),
                0x92 => self.op_sub(.A, .D),
                0x93 => self.op_sub(.A, .E),
                0x94 => self.op_sub(.A, .H),
                0x95 => self.op_sub(.A, .L),
                0x96 => self.op_sub(.A, .HLRef),
                0x97 => self.op_sub(.A, .A),
                0x98 => self.op_sbc(.A, .B),
                0x99 => self.op_sbc(.A, .C),
                0x9a => self.op_sbc(.A, .D),
                0x9b => self.op_sbc(.A, .E),
                0x9c => self.op_sbc(.A, .H),
                0x9d => self.op_sbc(.A, .L),
                0x9e => self.op_sbc(.A, .HLRef),
                0x9f => self.op_sbc(.A, .A),
                0xa0 => self.op_and(.A, .B),
                0xa1 => self.op_and(.A, .C),
                0xa2 => self.op_and(.A, .D),
                0xa3 => self.op_and(.A, .E),
                0xa4 => self.op_and(.A, .H),
                0xa5 => self.op_and(.A, .L),
                0xa6 => self.op_and(.A, .HLRef),
                0xa7 => self.op_and(.A, .A),
                0xa8 => self.op_xor(.A, .B),
                0xa9 => self.op_xor(.A, .C),
                0xaa => self.op_xor(.A, .D),
                0xab => self.op_xor(.A, .E),
                0xac => self.op_xor(.A, .H),
                0xad => self.op_xor(.A, .L),
                0xae => self.op_xor(.A, .HLRef),
                0xaf => self.op_xor(.A, .A),
                0xb0 => self.op_or(.A, .B),
                0xb1 => self.op_or(.A, .C),
                0xb2 => self.op_or(.A, .D),
                0xb3 => self.op_or(.A, .E),
                0xb4 => self.op_or(.A, .H),
                0xb5 => self.op_or(.A, .L),
                0xb6 => self.op_or(.A, .HLRef),
                0xb7 => self.op_or(.A, .A),
                0xc6 => self.op_add(.A, .N),
                0xce => self.op_adc(.A, .N),
                0xde => self.op_sbc(.A, .N),
                0xd6 => self.op_sub(.A, .N),
                0xe6 => self.op_and(.A, .N),
                0xe8 => self.op_add(.SP, .N),
                0xee => self.op_xor(.A, .N),
                0xf6 => self.op_or(.A, .N),

                // jump
                0x18 => _ = self.op_jr(.None, .N),
                0x20 => _ = self.op_jr(.NZ, .N),
                0x28 => _ = self.op_jr(.Z, .N),
                0x30 => _ = self.op_jr(.NC, .N),
                0x38 => _ = self.op_jr(.C, .N),
                0xc0 => _ = self.op_ret(.NZ),
                0xc2 => _ = self.op_jp(.NZ, .NN),
                0xc3 => _ = self.op_jp(.None, .NN),
                0xc8 => _ = self.op_ret(.Z),
                0xc9 => _ = self.op_ret(.None),
                0xca => _ = self.op_jp(.Z, .NN),
                0xd0 => _ = self.op_ret(.NC),
                0xd2 => _ = self.op_jp(.NC, .NN),
                0xd8 => _ = self.op_ret(.C),
                0xd9 => _ = self.op_reti(),
                0xda => _ = self.op_jp(.C, .NN),
                0xe9 => _ = self.op_jp(.None, .HL),
                0xc4 => _ = self.op_call(.NZ, .NN),
                0xcc => _ = self.op_call(.Z, .NN),
                0xcd => _ = self.op_call(.None, .NN),
                0xd4 => _ = self.op_call(.NC, .NN),
                0xdc => _ = self.op_call(.C, .NN),

                // stack
                // 0xc1 => self.op_pop(.BC),
                // 0xc5 => self.op_push(.BC),
                // 0xd1 => self.op_pop(.DE),
                // 0xd5 => self.op_push(.DE),
                // 0xe1 => self.op_pop(.HL),
                // 0xe5 => self.op_push(.HL),
                // 0xf1 => self.op_pop(.AF),
                // 0xf5 => self.op_push(.AF),

                // misc
                0x10 => {}, // TODO: STOP mode
                0x27 => self.op_daa(),
                0x2f => self.op_cpl(),
                0x37 => self.op_scf(),
                0x3f => self.op_ccf(),
                // 0x76 => self.op_halt(),
                // 0xb8 => self.op_cp(.A, .B),
                // 0xb9 => self.op_cp(.A, .C),
                // 0xba => self.op_cp(.A, .D),
                // 0xbb => self.op_cp(.A, .E),
                // 0xbc => self.op_cp(.A, .H),
                // 0xbd => self.op_cp(.A, .L),
                // 0xbe => self.op_cp(.A, .HLRef),
                // 0xbf => self.op_cp(.A, .A),
                // 0xf3 => self.op_di(),
                // 0xfb => self.op_ei(),
                // 0xfe => self.op_cp(.A, .N),
                // 0xc7 => self.op_rst(0x00),
                // 0xd7 => self.op_rst(0x10),
                // 0xe7 => self.op_rst(0x20),
                // 0xf7 => self.op_rst(0x30),
                // 0xcf => self.op_rst(0x08),
                // 0xdf => self.op_rst(0x18),
                // 0xef => self.op_rst(0x28),
                // 0xff => self.op_rst(0x38),

                else => std.debug.panic("Opcode 0x{x} not implemented\n", .{opcode}),
            }

            return meta.cycles;
        }

        fn pushWord(self: *Self, value: u16) void {
            self.sp -%= 2;

            const parts = utils.split(value);
            self.bus.write(self.sp, parts.lo);
            self.bus.write(self.sp +% 1, parts.hi);
        }

        fn popWord(self: *Self) u16 {
            const value = utils.join(self.bus.read(self.sp + 1), self.bus.read(self.sp));

            self.sp +%= 2;

            return value;
        }

        pub fn op_nop(_: *Self) void {}

        // --- load
        pub fn op_ld(self: *Self, target: Operand, source: Operand) void {
            self.writeOperand(target, self.readOperand(source));
        }

        pub fn op_ldi(self: *Self, target: Operand, source: Operand) void {
            self.op_ld(target, source);
            self.setHl(self.getHl() +% 1);
        }

        pub fn op_ldd(self: *Self, target: Operand, source: Operand) void {
            self.op_ld(target, source);
            self.setHl(self.getHl() -% 1);
        }

        // --- arithmetic
        pub fn op_inc(self: *Self, target: Operand) void {
            switch (self.readOperand(target)) {
                .u8 => |data| {
                    const result = data +% 1;
                    self.writeOperand(target, .{ .u8 = result });

                    self.setFlag(.Z, result == 0);
                    self.setFlag(.N, false);
                    self.setFlag(.H, (data & 0x0f) == 0x0f);
                },
                .u16 => |data| {
                    const result = data +% 1;
                    self.writeOperand(target, .{ .u16 = result });
                },
            }
        }

        pub fn op_dec(self: *Self, target: Operand) void {
            switch (self.readOperand(target)) {
                .u8 => |data| {
                    const result = data -% 1;
                    self.writeOperand(target, .{ .u8 = result });

                    self.setFlag(.Z, result == 0);
                    self.setFlag(.N, true);
                    self.setFlag(.H, (data & 0x0f) == 0);
                },
                .u16 => |data| {
                    const result = data -% 1;
                    self.writeOperand(target, .{ .u16 = result });
                },
            }
        }

        pub fn op_add(self: *Self, comptime target: Operand, comptime source: Operand) void {
            const target_op_data = self.readOperand(target);
            const source_op_data = self.readOperand(source);

            switch (target_op_data) {
                .u8 => |target_data| {
                    const source_data = source_op_data.u8;

                    const result_tuple = @addWithOverflow(target_data, source_data);
                    const result = result_tuple[0];
                    const overflow = result_tuple[1] == 1;

                    self.setFlag(.Z, result == 0);
                    self.setFlag(.N, false);
                    self.setFlag(.H, ((target_data & 0xF) + (source_data & 0xF)) > 0xF);
                    self.setFlag(.C, overflow);

                    self.writeOperand(target, .{ .u8 = result });
                },
                .u16 => |target_data| {
                    switch (source_op_data) {
                        .u8 => |source_data| {
                            const lo: u8 = @truncate(target_data);
                            const result_tuple = @addWithOverflow(lo, source_data);
                            const overflow = result_tuple[1] == 1;

                            const offset_signed: i16 = @as(i8, @bitCast(source_data));
                            const offset_u16: u16 = @bitCast(offset_signed);

                            const signed_result = target_data +% offset_u16;

                            self.setFlag(.Z, false);
                            self.setFlag(.N, false);
                            self.setFlag(.H, ((lo & 0xF) + (source_data & 0xF)) > 0xF);
                            self.setFlag(.C, overflow);

                            self.writeOperand(target, .{ .u16 = signed_result });
                        },
                        .u16 => |source_data| {
                            const result_tuple = @addWithOverflow(target_data, source_data);
                            const result = result_tuple[0];
                            const overflow = result_tuple[1] == 1;

                            self.setFlag(.N, false);
                            self.setFlag(.H, ((target_data & 0xFFF) + (source_data & 0xFFF)) > 0xFFF);
                            self.setFlag(.C, overflow);

                            self.writeOperand(target, .{ .u16 = result });
                        },
                    }
                },
            }
        }

        pub fn op_sub(self: *Self, comptime target: Operand, comptime source: Operand) void {
            const target_op_data = self.readOperand(target);
            const source_op_data = self.readOperand(source);

            switch (target_op_data) {
                .u8 => |target_data| {
                    const source_data = source_op_data.u8;

                    const result_tuple = @subWithOverflow(target_data, source_data);
                    const result = result_tuple[0];
                    const overflow = result_tuple[1] == 1;

                    self.setFlag(.Z, result == 0);
                    self.setFlag(.N, true);
                    self.setFlag(.H, (target_data & 0x0F) < (source_data & 0x0F));
                    self.setFlag(.C, overflow);

                    self.writeOperand(target, .{ .u8 = result });
                },
                else => unreachable,
            }
        }

        pub fn op_adc(self: *Self, comptime target: Operand, comptime source: Operand) void {
            const target_op_data = self.readOperand(target);
            const source_op_data = self.readOperand(source);

            switch (target_op_data) {
                .u8 => |target_data| {
                    const source_data = source_op_data.u8;

                    const carry: u8 = @intFromBool(self.getFlag(.C));

                    const sum: u16 = @as(u16, target_data) + @as(u16, source_data) + @as(u16, carry);
                    const result: u8 = @truncate(sum);

                    self.setFlag(.Z, result == 0);
                    self.setFlag(.N, false);
                    self.setFlag(.H, (target_data & 0x0F) + (source_data & 0x0F) + carry > 0x0F);
                    self.setFlag(.C, sum > 0xFF);

                    self.writeOperand(target, .{ .u8 = result });
                },
                else => unreachable,
            }
        }

        pub fn op_sbc(self: *Self, comptime target: Operand, comptime source: Operand) void {
            const target_op_data = self.readOperand(target);
            const source_op_data = self.readOperand(source);

            switch (target_op_data) {
                .u8 => |target_data| {
                    const source_data = source_op_data.u8;

                    const carry = @intFromBool(self.getFlag(.C));

                    const result_signed: i16 = @as(i16, target_data) - @as(i16, source_data) - @as(i16, carry);

                    const result: u8 = @truncate(@as(u16, @bitCast(result_signed)));

                    self.setFlag(.Z, result == 0);
                    self.setFlag(.N, true);

                    const nibble_a = @as(i16, target_data & 0xF);
                    const nibble_b = @as(i16, source_data & 0xF);
                    self.setFlag(.H, (nibble_a - nibble_b - @as(i16, carry)) < 0);
                    self.setFlag(.C, result_signed < 0);

                    self.writeOperand(target, .{ .u8 = result });
                },
                else => unreachable,
            }
        }

        pub fn op_ra(self: *Self, direction: Direction) void {
            const old_carry: u8 = @intFromBool(self.getFlag(.C));

            const result = switch (direction) {
                .Left => .{
                    ((self.a & 0x7F) << 1) | old_carry,
                    (self.a & 0x80) != 0,
                },
                .Right => .{
                    (self.a >> 1) | (old_carry << 7),
                    (self.a & 1) != 0,
                },
            };

            self.setFlag(.Z, false);
            self.setFlag(.N, false);
            self.setFlag(.H, false);
            self.setFlag(.C, result[1]);

            self.a = result[0];
        }

        pub fn op_rca(self: *Self, direction: Direction) void {
            const result = switch (direction) {
                .Left => .{ std.math.rotl(u8, self.a, 1), (self.a & (1 << 7)) != 0 },
                .Right => .{ std.math.rotr(u8, self.a, 1), (self.a & 1) != 0 },
            };

            self.setFlag(.Z, false);
            self.setFlag(.N, false);
            self.setFlag(.H, false);
            self.setFlag(.C, result[1]);

            self.a = result[0];
        }

        pub fn op_xor(self: *Self, comptime target: Operand, comptime source: Operand) void {
            const target_op_data = self.readOperand(target);
            const source_op_data = self.readOperand(source);

            switch (target_op_data) {
                .u8 => |target_data| {
                    const source_data = source_op_data.u8;

                    const result = target_data ^ source_data;

                    self.setFlag(.Z, result == 0);
                    self.setFlag(.N, false);
                    self.setFlag(.H, false);
                    self.setFlag(.C, false);

                    self.a = result;
                },
                else => unreachable,
            }
        }

        pub fn op_or(self: *Self, comptime target: Operand, comptime source: Operand) void {
            const target_op_data = self.readOperand(target);
            const source_op_data = self.readOperand(source);

            switch (target_op_data) {
                .u8 => |target_data| {
                    const source_data = source_op_data.u8;

                    const result = target_data | source_data;

                    self.setFlag(.Z, result == 0);
                    self.setFlag(.N, false);
                    self.setFlag(.H, false);
                    self.setFlag(.C, false);

                    self.writeOperand(target, .{ .u8 = result });
                },
                else => unreachable,
            }
        }

        pub fn op_and(self: *Self, comptime target: Operand, comptime source: Operand) void {
            const target_op_data = self.readOperand(target);
            const source_op_data = self.readOperand(source);

            switch (target_op_data) {
                .u8 => |target_data| {
                    const source_data = source_op_data.u8;

                    const result = target_data & source_data;

                    self.setFlag(.Z, result == 0);
                    self.setFlag(.N, false);
                    self.setFlag(.H, true);
                    self.setFlag(.C, false);

                    self.writeOperand(target, .{ .u8 = result });
                },
                else => unreachable,
            }
        }

        pub fn op_cp(self: *Self, comptime target: Operand, comptime source: Operand) void {
            const target_op_data = self.readOperand(target);
            const source_op_data = self.readOperand(source);

            switch (target_op_data) {
                .u8 => |target_data| {
                    const source_data = source_op_data.u8;

                    const result = target_data -% source_data;

                    self.setFlag(.Z, result == 0);
                    self.setFlag(.N, true);
                    self.setFlag(.H, (target_data & 0x0F) < (source_data & 0x0F));
                    self.setFlag(.C, target_data < source_data);
                },
                else => unreachable,
            }
        }

        // --- jump
        pub fn op_jr(self: *Self, condition: Condition, operand: Operand) bool {
            const operand_data = self.readOperand(operand);

            const data = switch (operand_data) {
                .u8 => |data| data,
                else => std.debug.panic("Invalid jr address", .{}),
            };

            const offset = utils.toRelativeOffset(data);

            const should_jump = switch (condition) {
                .Z => self.getFlag(.Z),
                .C => self.getFlag(.C),
                .NZ => !self.getFlag(.Z),
                .NC => !self.getFlag(.C),
                .None => true,
            };

            if (!should_jump) {
                return false;
            }

            self.pc +%= offset;

            return true;
        }

        pub fn op_jp(self: *Self, condition: Condition, operand: Operand) bool {
            const operand_data = self.readOperand(operand);

            const address = switch (operand_data) {
                .u8 => |data| data,
                else => std.debug.panic("Invalid jr address", .{}),
            };

            const should_jump = switch (condition) {
                .Z => self.getFlag(.Z),
                .C => self.getFlag(.C),
                .NZ => !self.getFlag(.Z),
                .NC => !self.getFlag(.C),
                .None => true,
            };

            if (!should_jump) {
                return false;
            }

            self.pc = address;

            return true;
        }

        pub fn op_ret(self: *Self, condition: Condition) bool {
            const should_return = switch (condition) {
                .Z => self.getFlag(.Z),
                .C => self.getFlag(.C),
                .NZ => !self.getFlag(.Z),
                .NC => !self.getFlag(.C),
                .None => true,
            };

            if (!should_return) {
                return false;
            }

            self.pc = self.popWord();

            return true;
        }

        pub fn op_reti(self: *Self) void {
            _ = self;
            unreachable;
        }

        pub fn op_call(self: *Self, condition: Condition, operand: Operand) bool {
            const operand_data = self.readOperand(operand);

            const address = switch (operand_data) {
                .u8 => |data| data,
                else => std.debug.panic("Invalid jr address", .{}),
            };

            const should_call = switch (condition) {
                .Z => self.getFlag(.Z),
                .C => self.getFlag(.C),
                .NZ => !self.getFlag(.Z),
                .NC => !self.getFlag(.C),
                .None => true,
            };

            if (!should_call) {
                return false;
            }

            self.pushWord(self.pc);
            self.pc = address;

            return true;
        }

        pub fn op_rst(self: *Self, vector: u8) void {
            self.pushWord(self.pc);
            self.pc = vector;
        }

        pub fn op_pop(self: *Self, operand: Operand) void {
            const value = self.popWord();

            self.writeOperand(operand, .{ .u16 = value });
        }

        pub fn op_push(self: *Self, operand: Operand) void {
            const value = switch (self.readOperand(operand)) {
                .u16 => |v| v,
                else => unreachable,
            };

            self.pushWord(value);
        }

        // --- misc
        pub fn op_di(self: *Self) void {
            self.ime = false;
        }

        pub fn op_ei(self: *Self) void {
            self.ime = true;
        }

        pub fn op_halt(self: *Self) void {
            self.halted = true;
        }

        pub fn op_daa(self: *Self) void {
            if (self.getFlag(.N)) {
                if (self.getFlag(.C)) {
                    self.a -%= 0x60;
                }

                if (self.getFlag(.H)) {
                    self.a -%= 0x06;
                }
            } else {
                if (self.getFlag(.C) or self.a > 0x99) {
                    self.a +%= 0x60;
                    self.setFlag(.C, true);
                }

                if (self.getFlag(.H) or (self.a & 0x0f) > 0x09) {
                    self.a +%= 0x06;
                }
            }

            self.setFlag(.Z, self.a == 0);
            self.setFlag(.H, false);
        }

        pub fn op_cpl(self: *Self) void {
            self.a = ~self.a;

            self.setFlag(.N, true);
            self.setFlag(.H, true);
        }

        pub fn op_scf(self: *Self) void {
            self.setFlag(.N, false);
            self.setFlag(.H, false);
            self.setFlag(.C, true);
        }

        pub fn op_ccf(self: *Self) void {
            const c = self.getFlag(.C);

            self.setFlag(.N, false);
            self.setFlag(.H, false);
            self.setFlag(.C, !c);
        }
    };
}

// --------------------------------------------------------
// Tests
// --------------------------------------------------------

const testing = std.testing;
const config = @import("config");

test "simple test" {
    std.debug.print("Simple test running\n", .{});
}

const TestState = struct {
    pc: u16,
    sp: u16,
    a: u8,
    b: u8,
    c: u8,
    d: u8,
    e: u8,
    f: u8,
    h: u8,
    l: u8,
    ram: [][]u32,
};

const TestCase = struct {
    name: []const u8,
    initial: TestState,
    final: TestState,
};

test "sm83 v1" {
    std.debug.print("sm83 v1 test started\n", .{});
    const test_dir = config.test_dir orelse {
        std.debug.print("test_dir is null, skipping sm83 v1 tests\n", .{});
        return;
    };

    const allocator = testing.allocator;
    var dir = std.fs.cwd().openDir(test_dir, .{ .iterate = true }) catch |err| {
        std.debug.print("Failed to open test_dir: {}\n", .{err});
        return err;
    };
    defer dir.close();

    var it = dir.iterate();
    while (try it.next()) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.name, ".json")) continue;

        if (config.test_filter) |filter| {
            if (!std.mem.eql(u8, entry.name, filter)) continue;
        }

        std.debug.print("Processing file: {s}\n", .{entry.name});

        const file_content = try dir.readFileAlloc(allocator, entry.name, 1024 * 1024 * 10);
        defer allocator.free(file_content);

        const parsed = try std.json.parseFromSlice([]TestCase, allocator, file_content, .{
            .ignore_unknown_fields = true,
        });
        defer parsed.deinit();

        for (parsed.value) |case| {
            std.debug.print("Running test case: {s}\n", .{case.name});

            // TODO: test cycles

            var bus = FlatBus.init();
            var cpu = Cpu(FlatBus).init(&bus);

            cpu.pc = case.initial.pc;
            cpu.sp = case.initial.sp;
            cpu.a = case.initial.a;
            cpu.b = case.initial.b;
            cpu.c = case.initial.c;
            cpu.d = case.initial.d;
            cpu.e = case.initial.e;
            cpu.h = case.initial.h;
            cpu.l = case.initial.l;
            cpu.f = case.initial.f & 0xf0;

            for (case.initial.ram) |entry_ram| {
                const address: u16 = @truncate(entry_ram[0]);
                const value: u8 = @truncate(entry_ram[1]);

                bus.write(address, value);
            }

            _ = cpu.step();

            try testing.expectEqual(case.final.pc, cpu.pc);
            try testing.expectEqual(case.final.sp, cpu.sp);
            try testing.expectEqual(case.final.a, cpu.a);
            try testing.expectEqual(case.final.b, cpu.b);
            try testing.expectEqual(case.final.c, cpu.c);
            try testing.expectEqual(case.final.d, cpu.d);
            try testing.expectEqual(case.final.e, cpu.e);
            try testing.expectEqual(case.final.h, cpu.h);
            try testing.expectEqual(case.final.l, cpu.l);
            try testing.expectEqual(case.final.f & 0xf0, cpu.f & 0xf0);

            for (case.final.ram) |entry_ram| {
                const address: u16 = @truncate(entry_ram[0]);
                const value: u8 = @truncate(entry_ram[1]);

                try testing.expectEqual(value, bus.read(address));
            }
        }
    }
}
