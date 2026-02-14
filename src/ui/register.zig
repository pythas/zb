const ig = @import("cimgui_docking");

const Bus = @import("../bus.zig").Bus;
const Cpu = @import("../cpu.zig").Cpu;
const WindowConfig = @import("state.zig").WindowConfig;

pub const RegisterWindow = struct {
    const Self = @This();

    pub fn init() Self {
        return .{};
    }

    pub fn draw(_: *Self, config: *WindowConfig, cpu: *Cpu(Bus)) void {
        if (!config.visible) {
            return;
        }

        ig.igSetNextWindowPos(config.pos, ig.ImGuiCond_FirstUseEver);
        ig.igSetNextWindowSize(config.size, ig.ImGuiCond_FirstUseEver);

        if (ig.igBegin("Registers", &config.visible, 0)) {
            ig.igText("PC: 0x%04X", cpu.pc);
            ig.igText("SP: 0x%04X", cpu.sp);

            ig.igSeparator();

            ig.igText("A: 0x%02X F: 0x%02X", cpu.a, cpu.f);
            ig.igText("B: 0x%02X C: 0x%02X", cpu.b, cpu.c);
            ig.igText("D: 0x%02X E: 0x%02X", cpu.d, cpu.e);
            ig.igText("H: 0x%02X L: 0x%02X", cpu.h, cpu.l);

            ig.igSeparator();

            ig.igText(
                "Flags: %s%s%s%s",
                if (cpu.getFlag(.Z)) "Z" else "-",
                if (cpu.getFlag(.N)) "N" else "-",
                if (cpu.getFlag(.H)) "H" else "-",
                if (cpu.getFlag(.C)) "C" else "-",
            );
        }
        ig.igEnd();
    }
};
