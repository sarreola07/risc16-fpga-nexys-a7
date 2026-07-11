//-----------------------------------------------------------------------------
// alu.v -- 16-bit ALU: ADD, SUB, XOR, SRA
// EE 5193 FPGA and HDL, Summer 2026 -- RISC project
// Sergio Arreola
//
// Adapted from the ALU/shifter developed in the earlier combinational-logic
// lab; trimmed to the four operations this instruction set needs. Purely
// combinational. SRA shifts operand A right by one with sign replication
// (operand B is ignored for that op).
//-----------------------------------------------------------------------------
module alu (
    input  wire [15:0] a,       // register file read port P
    input  wire [15:0] b,       // register file read port Q
    input  wire [1:0]  op,      // 00 ADD, 01 SUB, 10 XOR, 11 SRA
    output reg  [15:0] y
);

    localparam [1:0] ALU_ADD = 2'b00,
                     ALU_SUB = 2'b01,
                     ALU_XOR = 2'b10,
                     ALU_SRA = 2'b11;

    always @* begin
        case (op)
            ALU_ADD: y = a + b;
            ALU_SUB: y = a - b;
            ALU_XOR: y = a ^ b;
            ALU_SRA: y = {a[15], a[15:1]};   // arithmetic shift right by 1
            default: y = 16'd0;
        endcase
    end

endmodule
