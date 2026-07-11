//-----------------------------------------------------------------------------
// controller.v -- four-state FSM controller (Fetch / Decode / Execute / UpdatePC)
// EE 5193 FPGA and HDL, Summer 2026 -- RISC project
// Sergio Arreola
//
// Inputs, exactly as the assignment specifies: the 16-bit IR value and the
// RF_Rp_zero flag from the register file. The FSM walks the four required
// steps for every instruction and branches on the opcode (IR[15:12]) only
// inside the Execute and UpdatePC steps. RF_Rp_zero is consulted only by
// the conditional branch JZ; a HALT opcode parks the machine in a fifth,
// terminal state and raises `done` for the testbench and the display.
//
// State register updates are qualified by `en` (the CPU clock enable), so
// each architectural step lasts one enable period. Outputs are a pure
// function of (state, opcode, rp_zero) -- Moore-style states with a Mealy
// branch decision in UpdatePC -- generated in one combinational block with
// default assignments first, so no latches are inferred.
//-----------------------------------------------------------------------------
module controller (
    input  wire        clk,
    input  wire        reset,          // synchronous, active high
    input  wire        en,             // CPU clock enable
    input  wire [15:0] ir,             // instruction register value
    input  wire        rf_rp_zero,     // register file read-port-P == 0 flag

    // PC controls
    output reg         pc_ld,          // load branch target (taken JZ)
    output reg         pc_inc,         // PC <- PC + 1
    // IR control
    output reg         ir_ld,          // capture memory output into IR
    // Memory controls
    output reg         mem_addr_sel,   // 0: addr = PC (fetch), 1: addr = IR[7:0]
    output reg         mem_we,         // memory write (SW)
    // Register file controls
    output reg         rf_we,          // register write (ADD/SUB/XOR/SRA/LI/LW)
    output reg  [1:0]  rf_wdata_sel,   // 00: ALU, 01: memory, 10: zero-ext imm8
    output reg         rf_rp_addr_sel, // 0: Rp addr = IR[7:4], 1: IR[11:8] (SW/JZ)
    // ALU control
    output reg  [1:0]  alu_op,         // 00 ADD, 01 SUB, 10 XOR, 11 SRA
    // Status
    output reg         done            // program finished (HALT reached)
);

    // Opcodes (IR[15:12])
    localparam [3:0] OP_ADD  = 4'b0000,
                     OP_SUB  = 4'b0001,
                     OP_XOR  = 4'b0100,
                     OP_SRA  = 4'b0110,
                     OP_LI   = 4'b1000,
                     OP_LW   = 4'b1001,
                     OP_SW   = 4'b1010,
                     OP_JZ   = 4'b1100,   // branch if Rp == 0 (uses RF_Rp_zero)
                     OP_HALT = 4'b1111;

    // Write-data mux encodings
    localparam [1:0] WD_ALU = 2'b00,
                     WD_MEM = 2'b01,
                     WD_IMM = 2'b10;

    // States: the four required steps plus a terminal halt state
    localparam [2:0] S_FETCH  = 3'd0,
                     S_DECODE = 3'd1,
                     S_EXEC   = 3'd2,
                     S_UPDATE = 3'd3,
                     S_HALT   = 3'd4;

    reg [2:0] state, next_state;

    wire [3:0] opcode = ir[15:12];

    // ---- state register -----------------------------------------------
    always @(posedge clk) begin
        if (reset)
            state <= S_FETCH;
        else if (en)
            state <= next_state;
    end

    // ---- next-state logic ----------------------------------------------
    always @* begin
        case (state)
            S_FETCH:  next_state = S_DECODE;
            S_DECODE: next_state = S_EXEC;
            S_EXEC:   next_state = (opcode == OP_HALT) ? S_HALT : S_UPDATE;
            S_UPDATE: next_state = S_FETCH;
            S_HALT:   next_state = S_HALT;
            default:  next_state = S_FETCH;
        endcase
    end

    // ---- output logic ----------------------------------------------------
    // Defaults first so every path is covered and nothing infers a latch.
    always @* begin
        pc_ld          = 1'b0;
        pc_inc         = 1'b0;
        ir_ld          = 1'b0;
        mem_addr_sel   = 1'b0;      // default: address = PC
        mem_we         = 1'b0;
        rf_we          = 1'b0;
        rf_wdata_sel   = WD_ALU;
        rf_rp_addr_sel = 1'b0;      // default: Rp reads rs = IR[7:4]
        alu_op         = 2'b00;
        done           = 1'b0;

        case (state)
            // Step 1: instruction at mem[PC] into IR
            S_FETCH: begin
                mem_addr_sel = 1'b0;
                ir_ld        = 1'b1;
            end

            // Step 2: opcode/fields settle; register file read ports and
            // the RF_Rp_zero flag become valid. No register is written.
            S_DECODE: begin
                // no asserted outputs -- decode is combinational off the IR
            end

            // Step 3: per-opcode work
            S_EXEC: begin
                case (opcode)
                    OP_ADD: begin
                        alu_op       = 2'b00;
                        rf_wdata_sel = WD_ALU;
                        rf_we        = 1'b1;
                    end
                    OP_SUB: begin
                        alu_op       = 2'b01;
                        rf_wdata_sel = WD_ALU;
                        rf_we        = 1'b1;
                    end
                    OP_XOR: begin
                        alu_op       = 2'b10;
                        rf_wdata_sel = WD_ALU;
                        rf_we        = 1'b1;
                    end
                    OP_SRA: begin
                        alu_op       = 2'b11;
                        rf_wdata_sel = WD_ALU;
                        rf_we        = 1'b1;
                    end
                    OP_LI: begin
                        rf_wdata_sel = WD_IMM;
                        rf_we        = 1'b1;
                    end
                    OP_LW: begin
                        mem_addr_sel = 1'b1;     // address = IR[7:0]
                        rf_wdata_sel = WD_MEM;
                        rf_we        = 1'b1;
                    end
                    OP_SW: begin
                        mem_addr_sel   = 1'b1;   // address = IR[7:0]
                        rf_rp_addr_sel = 1'b1;   // Rp reads rs = IR[11:8]
                        mem_we         = 1'b1;
                    end
                    OP_JZ: begin
                        rf_rp_addr_sel = 1'b1;   // Rp reads rs = IR[11:8];
                                                 // branch resolves in UpdatePC
                    end
                    default: ;                   // OP_HALT and unused opcodes
                endcase
            end

            // Step 4: next sequential address, or the branch target for a
            // taken JZ (this is the one place RF_Rp_zero is used)
            S_UPDATE: begin
                if (opcode == OP_JZ && rf_rp_zero) begin
                    rf_rp_addr_sel = 1'b1;       // keep rs selected so the
                    pc_ld          = 1'b1;       // flag stays valid
                end else begin
                    pc_inc = 1'b1;
                end
            end

            S_HALT: begin
                done = 1'b1;
            end

            default: ;
        endcase
    end

endmodule
