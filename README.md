# EE 5193 RISC Project — Sergio Arreola

A multi-cycle 16-bit RISC processor for the Digilent Nexys A7-100T
(Artix-7 XC7A100T-1CSG324C), built for EE 5193 FPGA and HDL at UTSA.

## Layout

| Path | Contents |
|---|---|
| `src/` | Synthesizable RTL (one module per file) + `program.mem` memory image |
| `sim/risc_tb.v` | Self-checking testbench (simulation only — do not synthesize) |
| `constraints/nexys_a7_100t.xdc` | Pin/clock constraints for the Nexys A7-100T |
| `report/` | Project report |

## Building in Vivado

1. Create an RTL project targeting part `xc7a100tcsg324-1`.
2. Add all files in `src/` as design sources. **`program.mem` must be added
   too** (as a design source), or synthesis builds an all-zero memory.
3. Add `sim/risc_tb.v` as a *simulation-only* source and `program.mem` to the
   simulation fileset; set `risc_tb` as the simulation top.
4. Add `constraints/nexys_a7_100t.xdc` as the constraints file.
5. Set `risc_top` as the synthesis top module.

## Running the simulation

Run Behavioral Simulation. The testbench executes the ten-instruction demo
program, waits for `done`, and prints PASS/FAIL for every register and
memory result. Expected final line: `=== ALL CHECKS PASSED ===`.

Expected results: `mem[203] = 60 (0x3C)`, `mem[204] = 225 (0xE1)`,
`mem[205] = 255 (0xFF)`.

## On the board

- Program the board, press **BTNC** to reset.
- **Hold BTNC** to keep the CPU in reset: the display shows dashes
  (`-- -- --`) and LED0 is off. Release it and the program re-runs
  (~44 µs), leaving `3C  E1  FF` — mem[203], mem[204], mem[205] in hex.
- **LED0** lights when the HALT instruction is reached.
