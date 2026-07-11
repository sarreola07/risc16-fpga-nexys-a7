//-----------------------------------------------------------------------------
// risc_tb.v -- self-checking testbench for the EE 5193 RISC core
// EE 5193 FPGA and HDL, Summer 2026 -- RISC project
// Sergio Arreola
//
// Runs the ten-instruction demo program on risc_core with the clock enable
// tied high (one FSM state per clock), waits for `done`, then checks
// mem[203..205] and the involved registers against the hand-calculated
// values:
//     mem[201]=25, mem[202]=35
//     r5=25, r6=35, r7=60  -> mem[203] = 60  (0x3C)
//     r8=250, r4=225       -> mem[204] = 225 (0xE1)
//     r3=30,  r2=255       -> mem[205] = 255 (0xFF)
// Prints PASS/FAIL per check and a summary. A watchdog kills the run if
// `done` never rises (e.g. a broken FSM loop).
//-----------------------------------------------------------------------------
`timescale 1ns / 1ps

module risc_tb;

    reg  clk = 1'b0;
    reg  reset;
    wire done;

    integer errors = 0;

    // Device under test: core only, display port parked at 0
    risc_core #(.MEM_INIT_FILE("program.mem")) dut (
        .clk       (clk),
        .reset     (reset),
        .en        (1'b1),
        .done      (done),
        .disp_addr (8'd0),
        .disp_data ()               // unused in simulation
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    // ---- check helpers ------------------------------------------------------
    task check_mem;
        input [7:0]  addr;
        input [15:0] expect;
        begin
            if (dut.u_mem.ram[addr] === expect)
                $display("PASS  mem[%0d] = %0d (0x%02h)",
                         addr, dut.u_mem.ram[addr], dut.u_mem.ram[addr]);
            else begin
                $display("FAIL  mem[%0d] = %0d, expected %0d",
                         addr, dut.u_mem.ram[addr], expect);
                errors = errors + 1;
            end
        end
    endtask

    task check_reg;
        input [3:0]  rnum;
        input [15:0] expect;
        begin
            if (dut.u_rf.rf[rnum] === expect)
                $display("PASS  r%0d = %0d", rnum, dut.u_rf.rf[rnum]);
            else begin
                $display("FAIL  r%0d = %0d, expected %0d",
                         rnum, dut.u_rf.rf[rnum], expect);
                errors = errors + 1;
            end
        end
    endtask

    // ---- stimulus ------------------------------------------------------------
    initial begin
        $display("=== EE 5193 RISC testbench ===");
        reset = 1'b1;
        repeat (4) @(posedge clk);
        reset = 1'b0;

        wait (done);
        repeat (2) @(posedge clk);

        $display("--- program halted at PC = %0d after %0t ---",
                 dut.u_pc.pc_out, $time);

        check_reg(4'd5, 16'd25);      // LW  r5, 201
        check_reg(4'd6, 16'd35);      // LW  r6, 202
        check_reg(4'd7, 16'd60);      // ADD r7, r5, r6
        check_reg(4'd8, 16'd250);     // LI  r8, 250
        check_reg(4'd4, 16'd225);     // SUB r4, r8, r5
        check_reg(4'd3, 16'd30);      // SRA r3, r7
        check_reg(4'd2, 16'd255);     // XOR r2, r3, r4

        check_mem(8'd203, 16'd60);    // SW r7, 203
        check_mem(8'd204, 16'd225);   // SW r4, 204
        check_mem(8'd205, 16'd255);   // SW r2, 205

        if (errors == 0)
            $display("=== ALL CHECKS PASSED ===");
        else
            $display("=== %0d CHECK(S) FAILED ===", errors);
        $finish;
    end

    // ---- watchdog -------------------------------------------------------------
    initial begin
        #10000;   // 10 us >> 11 instructions x 4 states x 10 ns
        $display("FAIL  watchdog timeout: done never asserted");
        $finish;
    end

endmodule
