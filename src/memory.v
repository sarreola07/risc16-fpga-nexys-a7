`timescale 1ns / 1ps
//-----------------------------------------------------------------------------
// memory.v -- unified 256 x 16-bit instruction/data memory
// EE 5193 FPGA and HDL, Summer 2026 -- RISC project
// Sergio Arreola
//
// One memory holds both the program (addresses 0..10) and the data
// (201/202 in, 203..205 out), so a single address mux switches the CPU
// between fetching (addr = PC) and load/store (addr = IR[7:0]).
//
// Port A is the CPU port: combinational read, synchronous write. The
// combinational read is deliberate -- it lets Fetch and LW each complete in
// one FSM state. Vivado infers distributed (LUT) RAM for this, which is
// cheap at 256x16. I originally wrote a registered-read version that maps
// to block RAM, but the one-cycle read latency broke the four-state execute
// model (see "Problems encountered" in the report).
//
// Port B is a read-only combinational port used only by the display logic
// in the top level to scan mem[203..205]; the CPU never touches it.
//
// Initial contents come from program.mem via $readmemb: the ten demo
// instructions plus a HALT at 0..10, and the operands 25/35 at 201/202.
//-----------------------------------------------------------------------------
module memory #(
    parameter MEM_INIT_FILE = "program.mem"
) (
    input  wire        clk,
    input  wire        en,       // CPU clock enable
    input  wire        we,       // write enable (Execute step of SW)
    input  wire [7:0]  addr,     // port A address (PC or IR[7:0])
    input  wire [15:0] din,      // store data (register file port P)
    output wire [15:0] dout,     // port A read data
    input  wire [7:0]  addr_b,   // port B address (display scan)
    output wire [15:0] dout_b    // port B read data
);

    reg [15:0] ram [0:255];

    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            ram[i] = 16'd0;
        $readmemb(MEM_INIT_FILE, ram);
    end

    always @(posedge clk) begin
        if (en && we)
            ram[addr] <= din;
    end

    assign dout   = ram[addr];
    assign dout_b = ram[addr_b];

endmodule
