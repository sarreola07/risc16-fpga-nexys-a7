`timescale 1ns / 1ps
//-----------------------------------------------------------------------------
// ir.v -- 16-bit instruction register
// EE 5193 FPGA and HDL, Summer 2026 -- RISC project
// Sergio Arreola
//
// Captures the memory output word at the end of the Fetch step. The
// controller decodes ir_out directly; the fields are
//   ir_out[15:12] opcode
//   ir_out[11:8]  rd (or rs for SW/JZ)
//   ir_out[7:4]   rs
//   ir_out[3:0]   rt
//   ir_out[7:0]   imm8 / addr8
//-----------------------------------------------------------------------------
module ir (
    input  wire        clk,
    input  wire        reset,   // synchronous, active high
    input  wire        en,      // CPU clock enable
    input  wire        ld,      // capture ir_in
    input  wire [15:0] ir_in,   // memory read data
    output reg  [15:0] ir_out
);

    always @(posedge clk) begin
        if (reset)
            ir_out <= 16'd0;
        else if (en && ld)
            ir_out <= ir_in;
    end

endmodule
