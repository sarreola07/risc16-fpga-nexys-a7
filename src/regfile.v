//-----------------------------------------------------------------------------
// regfile.v -- 16 x 16-bit register file, 2 read ports / 1 write port
// EE 5193 FPGA and HDL, Summer 2026 -- RISC project
// Sergio Arreola
//
// Read ports are combinational (the Decode step gives the read data a full
// state period to settle before the Execute step uses it). The write port is
// synchronous and qualified by the CPU clock enable. Writes use a
// non-blocking assignment so a read and a write in the same cycle return the
// OLD register value -- see the report, "Problems encountered", for the
// blocking-assignment bug this replaced.
//
// rp_zero is the flag required by the assignment: it is high whenever the
// value currently presented on read port P is zero. The controller samples
// it during Execute to resolve the conditional branch (JZ).
//-----------------------------------------------------------------------------
module regfile (
    input  wire        clk,
    input  wire        en,        // CPU clock enable
    input  wire        we,        // write enable (Execute step of writing ops)
    input  wire [3:0]  waddr,     // destination register rd
    input  wire [15:0] wdata,     // from write-data mux (ALU / mem / imm)
    input  wire [3:0]  rp_addr,   // read port P address
    input  wire [3:0]  rq_addr,   // read port Q address
    output wire [15:0] rp_data,
    output wire [15:0] rq_data,
    output wire        rp_zero    // flag to controller: rp_data == 0
);

    reg [15:0] rf [0:15];

    integer i;
    initial begin
        for (i = 0; i < 16; i = i + 1)
            rf[i] = 16'd0;
    end

    always @(posedge clk) begin
        if (en && we)
            rf[waddr] <= wdata;
    end

    assign rp_data = rf[rp_addr];
    assign rq_data = rf[rq_addr];
    assign rp_zero = (rp_data == 16'd0);

endmodule
