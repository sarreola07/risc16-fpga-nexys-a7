`timescale 1ns / 1ps
//-----------------------------------------------------------------------------
// risc_top.v -- board top level for the Nexys A7-100T
// EE 5193 FPGA and HDL, Summer 2026 -- RISC project
// Sergio Arreola
//
// Wires the CPU core to the board: 100 MHz clock in, BTNC as reset,
// mem[203]/mem[204]/mem[205] out on the 7-segment display in hex as
//      [203] _ [204] _ [205]   ->   "3C E1 FF"
// (digits 7-6, 4-3, 1-0; digits 5 and 2 blanked as separators). While the
// program is still running the display shows dashes; LED0 lights when the
// HALT instruction is reached.
//
// Clocking: everything runs on the raw 100 MHz clock. The CPU is throttled
// with a clock ENABLE that pulses once per 100 cycles (1 MHz architectural
// rate) instead of a divided clock -- my first attempt used a divided clock
// as a second clock domain and produced CDC warnings and a failing timing
// setup; the clock-enable version keeps one clean clock domain (see
// "Problems encountered").
//-----------------------------------------------------------------------------
module risc_top (
    input  wire       clk,     // 100 MHz board clock (E3)
    input  wire       btnC,    // center pushbutton = reset, active high
    output wire [7:0] an,      // 7-seg anodes, active low
    output wire [6:0] seg,     // 7-seg cathodes CG..CA, active low
    output wire       dp,      // decimal point, active low
    output wire       led0     // done indicator
);

    // ---- reset synchronizer ------------------------------------------------
    // BTNC is asynchronous; two flops synchronize it into the clock domain.
    // The FSM only samples state changes every 100 clocks (cpu_en), so any
    // residual contact bounce (~ms) just holds reset a little longer --
    // no separate debouncer is needed for a level-sensitive reset.
    reg [1:0] rst_sync;
    always @(posedge clk)
        rst_sync <= {rst_sync[0], btnC};
    wire reset = rst_sync[1];

    // ---- CPU clock enable: 1 pulse every 100 clocks (1 MHz) ----------------
    reg [6:0] ce_cnt;
    reg       cpu_en;
    always @(posedge clk) begin
        if (reset) begin
            ce_cnt <= 7'd0;
            cpu_en <= 1'b0;
        end else if (ce_cnt == 7'd99) begin
            ce_cnt <= 7'd0;
            cpu_en <= 1'b1;
        end else begin
            ce_cnt <= ce_cnt + 7'd1;
            cpu_en <= 1'b0;
        end
    end

    // ---- CPU core -----------------------------------------------------------
    wire        done;
    wire [7:0]  disp_addr;
    wire [15:0] disp_data;

    risc_core #(.MEM_INIT_FILE("program.mem")) u_core (
        .clk       (clk),
        .reset     (reset),
        .en        (cpu_en),
        .done      (done),
        .disp_addr (disp_addr),
        .disp_data (disp_data)
    );

    assign led0 = done;

    // ---- result capture: scan mem[203..205] through memory port B -----------
    reg  [1:0]  scan_idx;
    reg  [15:0] result [0:2];      // result[0]=mem[203], [1]=204, [2]=205

    assign disp_addr = 8'd203 + {6'd0, scan_idx};

    always @(posedge clk) begin
        if (reset) begin
            scan_idx  <= 2'd0;
            result[0] <= 16'd0;
            result[1] <= 16'd0;
            result[2] <= 16'd0;
        end else begin
            result[scan_idx] <= disp_data;
            scan_idx         <= (scan_idx == 2'd2) ? 2'd0 : scan_idx + 2'd1;
        end
    end

    // ---- display formatting --------------------------------------------------
    // digit:   7    6    5    4    3    2    1    0
    // shows: 203h 203l  --  204h 204l  --  205h 205l
    wire [31:0] digits = { result[0][7:0], 4'h0,
                           result[1][7:0], 4'h0,
                           result[2][7:0] };

    sevenseg_driver u_disp (
        .clk       (clk),
        .reset     (reset),
        .digits    (digits),
        .digit_en  (8'b1101_1011),   // digits 5 and 2 are blank separators
        .show_dash (~done),          // dashes until the program halts
        .an        (an),
        .seg       (seg),
        .dp        (dp)
    );

endmodule
