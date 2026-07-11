`timescale 1ns / 1ps
//-----------------------------------------------------------------------------
// pc.v -- 8-bit program counter
// EE 5193 FPGA and HDL, Summer 2026 -- RISC project
// Sergio Arreola
//
// Holds the address of the current instruction. Supports synchronous load
// (for taken branches) and increment (UpdatePC step). Load has priority over
// increment; the controller never asserts both. All updates are qualified by
// the CPU clock enable `en` so the whole core can be throttled from the
// 100 MHz board clock without a derived clock.
//-----------------------------------------------------------------------------
module pc (
    input  wire       clk,
    input  wire       reset,   // synchronous, active high
    input  wire       en,      // CPU clock enable
    input  wire       ld,      // load pc_in (branch target)
    input  wire       inc,     // pc <= pc + 1
    input  wire [7:0] pc_in,   // branch target from IR[7:0]
    output reg  [7:0] pc_out
);

    always @(posedge clk) begin
        if (reset)
            pc_out <= 8'd0;
        else if (en) begin
            if (ld)
                pc_out <= pc_in;
            else if (inc)
                pc_out <= pc_out + 8'd1;
        end
    end

endmodule
