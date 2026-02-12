pub const OpcodeMeta = struct {
    mnemonic: []const u8,
    length: u8,
    cycles: u8,
    extra_cycles: u8 = 0,
};

pub const ISA = [_]OpcodeMeta{
    .{ .mnemonic = "NOP", .length = 1, .cycles = 4 }, // 0x00
    .{ .mnemonic = "LD", .length = 3, .cycles = 12 }, // 0x01
    .{ .mnemonic = "LD", .length = 1, .cycles = 8 }, // 0x02
    .{ .mnemonic = "INC", .length = 1, .cycles = 8 }, // 0x03
    .{ .mnemonic = "INC", .length = 1, .cycles = 4 }, // 0x04
    .{ .mnemonic = "DEC", .length = 1, .cycles = 4 }, // 0x05
    .{ .mnemonic = "LD", .length = 2, .cycles = 8 }, // 0x06
    .{ .mnemonic = "RLCA", .length = 1, .cycles = 4 }, // 0x07
    .{ .mnemonic = "LD", .length = 3, .cycles = 20 }, // 0x08
    .{ .mnemonic = "ADD", .length = 1, .cycles = 8 }, // 0x09
    .{ .mnemonic = "LD", .length = 1, .cycles = 8 }, // 0x0a
    .{ .mnemonic = "DEC", .length = 1, .cycles = 8 }, // 0x0b
    .{ .mnemonic = "INC", .length = 1, .cycles = 4 }, // 0x0c
    .{ .mnemonic = "DEC", .length = 1, .cycles = 4 }, // 0x0d
    .{ .mnemonic = "LD", .length = 2, .cycles = 8 }, // 0x0e
    .{ .mnemonic = "RRCA", .length = 1, .cycles = 4 }, // 0x0f
    .{ .mnemonic = "STOP", .length = 2, .cycles = 4 }, // 0x10
    .{ .mnemonic = "LD", .length = 3, .cycles = 12 }, // 0x11
    .{ .mnemonic = "LD", .length = 1, .cycles = 8 }, // 0x12
    .{ .mnemonic = "INC", .length = 1, .cycles = 8 }, // 0x13
    .{ .mnemonic = "INC", .length = 1, .cycles = 4 }, // 0x14
    .{ .mnemonic = "DEC", .length = 1, .cycles = 4 }, // 0x15
    .{ .mnemonic = "LD", .length = 2, .cycles = 8 }, // 0x16
    .{ .mnemonic = "RLA", .length = 1, .cycles = 4 }, // 0x17
    .{ .mnemonic = "JR", .length = 2, .cycles = 12 }, // 0x18
    .{ .mnemonic = "ADD", .length = 1, .cycles = 8 }, // 0x19
    .{ .mnemonic = "LD", .length = 1, .cycles = 8 }, // 0x1a
    .{ .mnemonic = "DEC", .length = 1, .cycles = 8 }, // 0x1b
    .{ .mnemonic = "INC", .length = 1, .cycles = 4 }, // 0x1c
    .{ .mnemonic = "DEC", .length = 1, .cycles = 4 }, // 0x1d
    .{ .mnemonic = "LD", .length = 2, .cycles = 8 }, // 0x1e
    .{ .mnemonic = "RRA", .length = 1, .cycles = 4 }, // 0x1f
    .{ .mnemonic = "JR", .length = 2, .cycles = 8, .extra_cycles = 4 }, // 0x20
    .{ .mnemonic = "LD", .length = 3, .cycles = 12 }, // 0x21
    .{ .mnemonic = "LD", .length = 1, .cycles = 8 }, // 0x22
    .{ .mnemonic = "INC", .length = 1, .cycles = 8 }, // 0x23
    .{ .mnemonic = "INC", .length = 1, .cycles = 4 }, // 0x24
    .{ .mnemonic = "DEC", .length = 1, .cycles = 4 }, // 0x25
    .{ .mnemonic = "LD", .length = 2, .cycles = 8 }, // 0x26
    .{ .mnemonic = "DAA", .length = 1, .cycles = 4 }, // 0x27
    .{ .mnemonic = "JR", .length = 2, .cycles = 8, .extra_cycles = 4 }, // 0x28
    .{ .mnemonic = "ADD", .length = 1, .cycles = 8 }, // 0x29
    .{ .mnemonic = "LD", .length = 1, .cycles = 8 }, // 0x2a
    .{ .mnemonic = "DEC", .length = 1, .cycles = 8 }, // 0x2b
    .{ .mnemonic = "INC", .length = 1, .cycles = 4 }, // 0x2c
    .{ .mnemonic = "DEC", .length = 1, .cycles = 4 }, // 0x2d
    .{ .mnemonic = "LD", .length = 2, .cycles = 8 }, // 0x2e
    .{ .mnemonic = "CPL", .length = 1, .cycles = 4 }, // 0x2f
    .{ .mnemonic = "JR", .length = 2, .cycles = 8, .extra_cycles = 4 }, // 0x30
    .{ .mnemonic = "LD", .length = 3, .cycles = 12 }, // 0x31
    .{ .mnemonic = "LD", .length = 1, .cycles = 8 }, // 0x32
    .{ .mnemonic = "INC", .length = 1, .cycles = 8 }, // 0x33
    .{ .mnemonic = "INC", .length = 1, .cycles = 12 }, // 0x34
    .{ .mnemonic = "DEC", .length = 1, .cycles = 12 }, // 0x35
    .{ .mnemonic = "LD", .length = 2, .cycles = 12 }, // 0x36
    .{ .mnemonic = "SCF", .length = 1, .cycles = 4 }, // 0x37
    .{ .mnemonic = "JR", .length = 2, .cycles = 8, .extra_cycles = 4 }, // 0x38
    .{ .mnemonic = "ADD", .length = 1, .cycles = 8 }, // 0x39
    .{ .mnemonic = "LD", .length = 1, .cycles = 8 }, // 0x3a
    .{ .mnemonic = "DEC", .length = 1, .cycles = 8 }, // 0x3b
    .{ .mnemonic = "INC", .length = 1, .cycles = 4 }, // 0x3c
    .{ .mnemonic = "DEC", .length = 1, .cycles = 4 }, // 0x3d
    .{ .mnemonic = "LD", .length = 2, .cycles = 8 }, // 0x3e
    .{ .mnemonic = "CCF", .length = 1, .cycles = 4 }, // 0x3f
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x40
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x41
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x42
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x43
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x44
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x45
    .{ .mnemonic = "LD", .length = 1, .cycles = 8 }, // 0x46
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x47
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x48
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x49
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x4a
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x4b
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x4c
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x4d
    .{ .mnemonic = "LD", .length = 1, .cycles = 8 }, // 0x4e
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x4f
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x50
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x51
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x52
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x53
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x54
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x55
    .{ .mnemonic = "LD", .length = 1, .cycles = 8 }, // 0x56
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x57
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x58
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x59
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x5a
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x5b
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x5c
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x5d
    .{ .mnemonic = "LD", .length = 1, .cycles = 8 }, // 0x5e
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x5f
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x60
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x61
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x62
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x63
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x64
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x65
    .{ .mnemonic = "LD", .length = 1, .cycles = 8 }, // 0x66
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x67
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x68
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x69
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x6a
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x6b
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x6c
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x6d
    .{ .mnemonic = "LD", .length = 1, .cycles = 8 }, // 0x6e
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x6f
    .{ .mnemonic = "LD", .length = 1, .cycles = 8 }, // 0x70
    .{ .mnemonic = "LD", .length = 1, .cycles = 8 }, // 0x71
    .{ .mnemonic = "LD", .length = 1, .cycles = 8 }, // 0x72
    .{ .mnemonic = "LD", .length = 1, .cycles = 8 }, // 0x73
    .{ .mnemonic = "LD", .length = 1, .cycles = 8 }, // 0x74
    .{ .mnemonic = "LD", .length = 1, .cycles = 8 }, // 0x75
    .{ .mnemonic = "HALT", .length = 1, .cycles = 4 }, // 0x76
    .{ .mnemonic = "LD", .length = 1, .cycles = 8 }, // 0x77
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x78
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x79
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x7a
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x7b
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x7c
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x7d
    .{ .mnemonic = "LD", .length = 1, .cycles = 8 }, // 0x7e
    .{ .mnemonic = "LD", .length = 1, .cycles = 4 }, // 0x7f
    .{ .mnemonic = "ADD", .length = 1, .cycles = 4 }, // 0x80
    .{ .mnemonic = "ADD", .length = 1, .cycles = 4 }, // 0x81
    .{ .mnemonic = "ADD", .length = 1, .cycles = 4 }, // 0x82
    .{ .mnemonic = "ADD", .length = 1, .cycles = 4 }, // 0x83
    .{ .mnemonic = "ADD", .length = 1, .cycles = 4 }, // 0x84
    .{ .mnemonic = "ADD", .length = 1, .cycles = 4 }, // 0x85
    .{ .mnemonic = "ADD", .length = 1, .cycles = 8 }, // 0x86
    .{ .mnemonic = "ADD", .length = 1, .cycles = 4 }, // 0x87
    .{ .mnemonic = "ADC", .length = 1, .cycles = 4 }, // 0x88
    .{ .mnemonic = "ADC", .length = 1, .cycles = 4 }, // 0x89
    .{ .mnemonic = "ADC", .length = 1, .cycles = 4 }, // 0x8a
    .{ .mnemonic = "ADC", .length = 1, .cycles = 4 }, // 0x8b
    .{ .mnemonic = "ADC", .length = 1, .cycles = 4 }, // 0x8c
    .{ .mnemonic = "ADC", .length = 1, .cycles = 4 }, // 0x8d
    .{ .mnemonic = "ADC", .length = 1, .cycles = 8 }, // 0x8e
    .{ .mnemonic = "ADC", .length = 1, .cycles = 4 }, // 0x8f
    .{ .mnemonic = "SUB", .length = 1, .cycles = 4 }, // 0x90
    .{ .mnemonic = "SUB", .length = 1, .cycles = 4 }, // 0x91
    .{ .mnemonic = "SUB", .length = 1, .cycles = 4 }, // 0x92
    .{ .mnemonic = "SUB", .length = 1, .cycles = 4 }, // 0x93
    .{ .mnemonic = "SUB", .length = 1, .cycles = 4 }, // 0x94
    .{ .mnemonic = "SUB", .length = 1, .cycles = 4 }, // 0x95
    .{ .mnemonic = "SUB", .length = 1, .cycles = 8 }, // 0x96
    .{ .mnemonic = "SUB", .length = 1, .cycles = 4 }, // 0x97
    .{ .mnemonic = "SBC", .length = 1, .cycles = 4 }, // 0x98
    .{ .mnemonic = "SBC", .length = 1, .cycles = 4 }, // 0x99
    .{ .mnemonic = "SBC", .length = 1, .cycles = 4 }, // 0x9a
    .{ .mnemonic = "SBC", .length = 1, .cycles = 4 }, // 0x9b
    .{ .mnemonic = "SBC", .length = 1, .cycles = 4 }, // 0x9c
    .{ .mnemonic = "SBC", .length = 1, .cycles = 4 }, // 0x9d
    .{ .mnemonic = "SBC", .length = 1, .cycles = 8 }, // 0x9e
    .{ .mnemonic = "SBC", .length = 1, .cycles = 4 }, // 0x9f
    .{ .mnemonic = "AND", .length = 1, .cycles = 4 }, // 0xa0
    .{ .mnemonic = "AND", .length = 1, .cycles = 4 }, // 0xa1
    .{ .mnemonic = "AND", .length = 1, .cycles = 4 }, // 0xa2
    .{ .mnemonic = "AND", .length = 1, .cycles = 4 }, // 0xa3
    .{ .mnemonic = "AND", .length = 1, .cycles = 4 }, // 0xa4
    .{ .mnemonic = "AND", .length = 1, .cycles = 4 }, // 0xa5
    .{ .mnemonic = "AND", .length = 1, .cycles = 8 }, // 0xa6
    .{ .mnemonic = "AND", .length = 1, .cycles = 4 }, // 0xa7
    .{ .mnemonic = "XOR", .length = 1, .cycles = 4 }, // 0xa8
    .{ .mnemonic = "XOR", .length = 1, .cycles = 4 }, // 0xa9
    .{ .mnemonic = "XOR", .length = 1, .cycles = 4 }, // 0xaa
    .{ .mnemonic = "XOR", .length = 1, .cycles = 4 }, // 0xab
    .{ .mnemonic = "XOR", .length = 1, .cycles = 4 }, // 0xac
    .{ .mnemonic = "XOR", .length = 1, .cycles = 4 }, // 0xad
    .{ .mnemonic = "XOR", .length = 1, .cycles = 8 }, // 0xae
    .{ .mnemonic = "XOR", .length = 1, .cycles = 4 }, // 0xaf
    .{ .mnemonic = "OR", .length = 1, .cycles = 4 }, // 0xb0
    .{ .mnemonic = "OR", .length = 1, .cycles = 4 }, // 0xb1
    .{ .mnemonic = "OR", .length = 1, .cycles = 4 }, // 0xb2
    .{ .mnemonic = "OR", .length = 1, .cycles = 4 }, // 0xb3
    .{ .mnemonic = "OR", .length = 1, .cycles = 4 }, // 0xb4
    .{ .mnemonic = "OR", .length = 1, .cycles = 4 }, // 0xb5
    .{ .mnemonic = "OR", .length = 1, .cycles = 8 }, // 0xb6
    .{ .mnemonic = "OR", .length = 1, .cycles = 4 }, // 0xb7
    .{ .mnemonic = "CP", .length = 1, .cycles = 4 }, // 0xb8
    .{ .mnemonic = "CP", .length = 1, .cycles = 4 }, // 0xb9
    .{ .mnemonic = "CP", .length = 1, .cycles = 4 }, // 0xba
    .{ .mnemonic = "CP", .length = 1, .cycles = 4 }, // 0xbb
    .{ .mnemonic = "CP", .length = 1, .cycles = 4 }, // 0xbc
    .{ .mnemonic = "CP", .length = 1, .cycles = 4 }, // 0xbd
    .{ .mnemonic = "CP", .length = 1, .cycles = 8 }, // 0xbe
    .{ .mnemonic = "CP", .length = 1, .cycles = 4 }, // 0xbf
    .{ .mnemonic = "RET", .length = 1, .cycles = 8, .extra_cycles = 12 }, // 0xc0
    .{ .mnemonic = "POP", .length = 1, .cycles = 12 }, // 0xc1
    .{ .mnemonic = "JP", .length = 3, .cycles = 12, .extra_cycles = 4 }, // 0xc2
    .{ .mnemonic = "JP", .length = 3, .cycles = 16 }, // 0xc3
    .{ .mnemonic = "CALL", .length = 3, .cycles = 12, .extra_cycles = 12 }, // 0xc4
    .{ .mnemonic = "PUSH", .length = 1, .cycles = 16 }, // 0xc5
    .{ .mnemonic = "ADD", .length = 2, .cycles = 8 }, // 0xc6
    .{ .mnemonic = "RST", .length = 1, .cycles = 16 }, // 0xc7
    .{ .mnemonic = "RET", .length = 1, .cycles = 8, .extra_cycles = 12 }, // 0xc8
    .{ .mnemonic = "RET", .length = 1, .cycles = 16 }, // 0xc9
    .{ .mnemonic = "JP", .length = 3, .cycles = 12, .extra_cycles = 4 }, // 0xca
    .{ .mnemonic = "PREFIX", .length = 2, .cycles = 0 }, // 0xcb
    .{ .mnemonic = "CALL", .length = 3, .cycles = 12, .extra_cycles = 12 }, // 0xcc
    .{ .mnemonic = "CALL", .length = 3, .cycles = 24 }, // 0xcd
    .{ .mnemonic = "ADC", .length = 2, .cycles = 8 }, // 0xce
    .{ .mnemonic = "RST", .length = 1, .cycles = 16 }, // 0xcf
    .{ .mnemonic = "RET", .length = 1, .cycles = 8, .extra_cycles = 12 }, // 0xd0
    .{ .mnemonic = "POP", .length = 1, .cycles = 12 }, // 0xd1
    .{ .mnemonic = "JP", .length = 3, .cycles = 12, .extra_cycles = 4 }, // 0xd2
    .{ .mnemonic = "ILLEGAL", .length = 1, .cycles = 4 }, // 0xd3
    .{ .mnemonic = "CALL", .length = 3, .cycles = 12, .extra_cycles = 12 }, // 0xd4
    .{ .mnemonic = "PUSH", .length = 1, .cycles = 16 }, // 0xd5
    .{ .mnemonic = "SUB", .length = 2, .cycles = 8 }, // 0xd6
    .{ .mnemonic = "RST", .length = 1, .cycles = 16 }, // 0xd7
    .{ .mnemonic = "RET", .length = 1, .cycles = 8, .extra_cycles = 12 }, // 0xd8
    .{ .mnemonic = "RETI", .length = 1, .cycles = 16 }, // 0xd9
    .{ .mnemonic = "JP", .length = 3, .cycles = 12, .extra_cycles = 4 }, // 0xda
    .{ .mnemonic = "ILLEGAL", .length = 1, .cycles = 4 }, // 0xdb
    .{ .mnemonic = "CALL", .length = 3, .cycles = 12, .extra_cycles = 12 }, // 0xdc
    .{ .mnemonic = "ILLEGAL", .length = 1, .cycles = 4 }, // 0xdd
    .{ .mnemonic = "SBC", .length = 2, .cycles = 8 }, // 0xde
    .{ .mnemonic = "RST", .length = 1, .cycles = 16 }, // 0xdf
    .{ .mnemonic = "LDH", .length = 2, .cycles = 12 }, // 0xe0
    .{ .mnemonic = "POP", .length = 1, .cycles = 12 }, // 0xe1
    .{ .mnemonic = "LDH", .length = 1, .cycles = 8 }, // 0xe2
    .{ .mnemonic = "ILLEGAL", .length = 1, .cycles = 4 }, // 0xe3
    .{ .mnemonic = "ILLEGAL", .length = 1, .cycles = 4 }, // 0xe4
    .{ .mnemonic = "PUSH", .length = 1, .cycles = 16 }, // 0xe5
    .{ .mnemonic = "AND", .length = 2, .cycles = 8 }, // 0xe6
    .{ .mnemonic = "RST", .length = 1, .cycles = 16 }, // 0xe7
    .{ .mnemonic = "ADD", .length = 2, .cycles = 16 }, // 0xe8
    .{ .mnemonic = "JP", .length = 1, .cycles = 4 }, // 0xe9
    .{ .mnemonic = "LD", .length = 3, .cycles = 16 }, // 0xea
    .{ .mnemonic = "ILLEGAL", .length = 1, .cycles = 4 }, // 0xeb
    .{ .mnemonic = "ILLEGAL", .length = 1, .cycles = 4 }, // 0xec
    .{ .mnemonic = "ILLEGAL", .length = 1, .cycles = 4 }, // 0xed
    .{ .mnemonic = "XOR", .length = 2, .cycles = 8 }, // 0xee
    .{ .mnemonic = "RST", .length = 1, .cycles = 16 }, // 0xef
    .{ .mnemonic = "LDH", .length = 2, .cycles = 12 }, // 0xf0
    .{ .mnemonic = "POP", .length = 1, .cycles = 12 }, // 0xf1
    .{ .mnemonic = "LDH", .length = 1, .cycles = 8 }, // 0xf2
    .{ .mnemonic = "DI", .length = 1, .cycles = 4 }, // 0xf3
    .{ .mnemonic = "ILLEGAL", .length = 1, .cycles = 4 }, // 0xf4
    .{ .mnemonic = "PUSH", .length = 1, .cycles = 16 }, // 0xf5
    .{ .mnemonic = "OR", .length = 2, .cycles = 8 }, // 0xf6
    .{ .mnemonic = "RST", .length = 1, .cycles = 16 }, // 0xf7
    .{ .mnemonic = "LD", .length = 2, .cycles = 12 }, // 0xf8
    .{ .mnemonic = "LD", .length = 1, .cycles = 8 }, // 0xf9
    .{ .mnemonic = "LD", .length = 3, .cycles = 16 }, // 0xfa
    .{ .mnemonic = "EI", .length = 1, .cycles = 4 }, // 0xfb
    .{ .mnemonic = "ILLEGAL", .length = 1, .cycles = 4 }, // 0xfc
    .{ .mnemonic = "ILLEGAL", .length = 1, .cycles = 4 }, // 0xfd
    .{ .mnemonic = "CP", .length = 2, .cycles = 8 }, // 0xfe
    .{ .mnemonic = "RST", .length = 1, .cycles = 16 }, // 0xff
};

pub const CB_ISA = blk: {
    var table: [256]OpcodeMeta = undefined;

    var index: usize = 0;
    while (index < 256) : (index += 1) {
        const opcode: u8 = @intCast(index);
        const reg_index = opcode & 0x07;
        const is_hl = reg_index == 0x06;

        var mnemonic: []const u8 = "CB";
        var cycles: u8 = if (is_hl) 16 else 8;

        switch (opcode) {
            0x00...0x07 => mnemonic = "RLC",
            0x08...0x0f => mnemonic = "RRC",
            0x10...0x17 => mnemonic = "RL",
            0x18...0x1f => mnemonic = "RR",
            0x20...0x27 => mnemonic = "SLA",
            0x28...0x2f => mnemonic = "SRA",
            0x30...0x37 => mnemonic = "SWAP",
            0x38...0x3f => mnemonic = "SRL",
            0x40...0x7f => {
                mnemonic = "BIT";
                cycles = if (is_hl) 12 else 8;
            },
            0x80...0xbf => {
                mnemonic = "RES";
                cycles = if (is_hl) 16 else 8;
            },
            0xc0...0xff => {
                mnemonic = "SET";
                cycles = if (is_hl) 16 else 8;
            },
        }

        table[index] = .{ .mnemonic = mnemonic, .length = 2, .cycles = cycles };
    }

    break :blk table;
};
