`timescale 1ns / 1ps
//-----------------------------------------------------------------------------
// risc_core.v -- datapath + controller wired together (board-independent)
// EE 5193 FPGA and HDL, Summer 2026 -- RISC project
// Sergio Arreola
//
// Every box in the block diagram is its own module instance; this file is
// only wiring plus the three datapath muxes (memory address, register file
// write data, register file Rp read address). Keeping the core free of any
// board logic lets the same module sit under both the testbench (en tied
// high) and risc_top (en driven by the clock-enable divider).
//-----------------------------------------------------------------------------
module risc_core #(
    parameter MEM_INIT_FILE = "program.mem"
) (
    input  wire        clk,
    input  wire        reset,     // synchronous, active high
    input  wire        en,        // CPU clock enable
    output wire        done,      // HALT reached
    // display-side memory read port (used by risc_top, idle in simulation)
    input  wire [7:0]  disp_addr,
    output wire [15:0] disp_data
);

    // ---- interconnect ----------------------------------------------------
    wire [7:0]  pc_out;
    wire [15:0] ir_out;
    wire [15:0] mem_dout;
    wire [15:0] rf_rp_data, rf_rq_data;
    wire [15:0] alu_y;
    wire        rf_rp_zero;

    // control signals
    wire        pc_ld, pc_inc, ir_ld;
    wire        mem_addr_sel, mem_we;
    wire        rf_we, rf_rp_addr_sel;
    wire [1:0]  rf_wdata_sel;
    wire [1:0]  alu_op;

    // ---- datapath muxes ---------------------------------------------------
    // memory address: PC during Fetch, IR[7:0] during LW/SW Execute
    wire [7:0] mem_addr = mem_addr_sel ? ir_out[7:0] : pc_out;

    // register file read port P address: rs field, except SW/JZ where the
    // source register lives in bits [11:8]
    wire [3:0] rp_addr = rf_rp_addr_sel ? ir_out[11:8] : ir_out[7:4];

    // register file write data: ALU result / memory word / zero-extended imm8
    reg [15:0] rf_wdata;
    always @* begin
        case (rf_wdata_sel)
            2'b01:   rf_wdata = mem_dout;                 // LW
            2'b10:   rf_wdata = {8'd0, ir_out[7:0]};      // LI
            default: rf_wdata = alu_y;                    // ADD/SUB/XOR/SRA
        endcase
    end

    // ---- module instances --------------------------------------------------
    controller u_ctrl (
        .clk            (clk),
        .reset          (reset),
        .en             (en),
        .ir             (ir_out),
        .rf_rp_zero     (rf_rp_zero),
        .pc_ld          (pc_ld),
        .pc_inc         (pc_inc),
        .ir_ld          (ir_ld),
        .mem_addr_sel   (mem_addr_sel),
        .mem_we         (mem_we),
        .rf_we          (rf_we),
        .rf_wdata_sel   (rf_wdata_sel),
        .rf_rp_addr_sel (rf_rp_addr_sel),
        .alu_op         (alu_op),
        .done           (done)
    );

    pc u_pc (
        .clk    (clk),
        .reset  (reset),
        .en     (en),
        .ld     (pc_ld),
        .inc    (pc_inc),
        .pc_in  (ir_out[7:0]),     // JZ branch target
        .pc_out (pc_out)
    );

    ir u_ir (
        .clk    (clk),
        .reset  (reset),
        .en     (en),
        .ld     (ir_ld),
        .ir_in  (mem_dout),
        .ir_out (ir_out)
    );

    regfile u_rf (
        .clk     (clk),
        .en      (en),
        .we      (rf_we),
        .waddr   (ir_out[11:8]),   // rd
        .wdata   (rf_wdata),
        .rp_addr (rp_addr),
        .rq_addr (ir_out[3:0]),    // rt
        .rp_data (rf_rp_data),
        .rq_data (rf_rq_data),
        .rp_zero (rf_rp_zero)
    );

    alu u_alu (
        .a  (rf_rp_data),
        .b  (rf_rq_data),
        .op (alu_op),
        .y  (alu_y)
    );

    memory #(.MEM_INIT_FILE(MEM_INIT_FILE)) u_mem (
        .clk    (clk),
        .en     (en),
        .we     (mem_we),
        .addr   (mem_addr),
        .din    (rf_rp_data),      // SW store data
        .dout   (mem_dout),
        .addr_b (disp_addr),
        .dout_b (disp_data)
    );

endmodule
