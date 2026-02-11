pub const FlatBus = struct {
    memory: [65536]u8 = [_]u8{0} ** 65536,

    const Self = @This();

    pub fn init() Self {
        return .{};
    }

    pub fn read(self: *const Self, address: u16) u8 {
        return self.memory[address];
    }

    pub fn write(self: *Self, address: u16, value: u8) void {
        self.memory[address] = value;
    }
};
