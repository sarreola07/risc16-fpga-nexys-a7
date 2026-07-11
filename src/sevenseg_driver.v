//-----------------------------------------------------------------------------
// sevenseg_driver.v -- 8-digit multiplexed 7-segment scan driver (Nexys A7)
// EE 5193 FPGA and HDL, Summer 2026 -- RISC project
// Sergio Arreola
//
// Reused from my earlier display lab, with two additions for this project:
// a per-digit blanking mask (digit_en) and a dash mode used while the CPU
// is still running. Anodes and cathodes are both active low on the Nexys A7.
//
// Scan rate: the digit select comes from bits [19:17] of a free-running
// counter at 100 MHz, so each digit is lit for 2^17 * 10 ns = 1.31 ms and
// the full 8-digit frame refreshes at ~95 Hz -- fast enough not to flicker,
// slow enough that the anode drivers settle (see "Problems encountered"
// for the ghosting I got with a faster scan and no blanking).
//
// seg bit order: seg[6:0] = {CG,CF,CE,CD,CC,CB,CA}, i.e. seg[0] = CA.
//-----------------------------------------------------------------------------
module sevenseg_driver (
    input  wire        clk,        // 100 MHz board clock
    input  wire        reset,      // synchronous, active high
    input  wire [31:0] digits,     // 8 hex nibbles, digit 7 = digits[31:28]
    input  wire [7:0]  digit_en,   // 1 = display this digit, 0 = blank
    input  wire        show_dash,  // 1 = enabled digits show '-'
    output reg  [7:0]  an,         // anodes, active low
    output reg  [6:0]  seg,        // cathodes CG..CA, active low
    output wire        dp          // decimal point, active low (kept off)
);

    assign dp = 1'b1;              // decimal point never used

    // ---- scan counter -----------------------------------------------------
    reg [19:0] scan_cnt;
    always @(posedge clk) begin
        if (reset)
            scan_cnt <= 20'd0;
        else
            scan_cnt <= scan_cnt + 20'd1;
    end

    wire [2:0] digit_sel = scan_cnt[19:17];

    // ---- current nibble ---------------------------------------------------
    reg [3:0] nibble;
    always @* begin
        case (digit_sel)
            3'd0: nibble = digits[3:0];
            3'd1: nibble = digits[7:4];
            3'd2: nibble = digits[11:8];
            3'd3: nibble = digits[15:12];
            3'd4: nibble = digits[19:16];
            3'd5: nibble = digits[23:20];
            3'd6: nibble = digits[27:24];
            3'd7: nibble = digits[31:28];
        endcase
    end

    // ---- hex-to-segment decode (active low, {g,f,e,d,c,b,a}) --------------
    reg [6:0] hex_seg;
    always @* begin
        case (nibble)
            4'h0: hex_seg = 7'b1000000;
            4'h1: hex_seg = 7'b1111001;
            4'h2: hex_seg = 7'b0100100;
            4'h3: hex_seg = 7'b0110000;
            4'h4: hex_seg = 7'b0011001;
            4'h5: hex_seg = 7'b0010010;
            4'h6: hex_seg = 7'b0000010;
            4'h7: hex_seg = 7'b1111000;
            4'h8: hex_seg = 7'b0000000;
            4'h9: hex_seg = 7'b0010000;
            4'hA: hex_seg = 7'b0001000;
            4'hB: hex_seg = 7'b0000011;
            4'hC: hex_seg = 7'b1000110;
            4'hD: hex_seg = 7'b0100001;
            4'hE: hex_seg = 7'b0000110;
            4'hF: hex_seg = 7'b0001110;
        endcase
    end

    localparam [6:0] SEG_DASH  = 7'b0111111;   // segment G only
    localparam [6:0] SEG_BLANK = 7'b1111111;

    // ---- registered outputs (anode and cathode switch together) -----------
    always @(posedge clk) begin
        if (reset) begin
            an  <= 8'hFF;
            seg <= SEG_BLANK;
        end else begin
            if (digit_en[digit_sel]) begin
                an  <= ~(8'd1 << digit_sel);
                seg <= show_dash ? SEG_DASH : hex_seg;
            end else begin
                an  <= 8'hFF;                  // blank digit: no anode driven
                seg <= SEG_BLANK;
            end
        end
    end

endmodule
