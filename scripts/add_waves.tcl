# add_waves.tcl -- add the report-figure signals to the XSim wave window,
# then re-run the whole simulation so every trace has full history.
# Run from Vivado while the behavioral simulation is open:
#   Tools > Run Tcl Script...  and pick this file.

add_wave /risc_tb/dut/u_ctrl/state /risc_tb/dut/u_pc/pc_out /risc_tb/dut/u_ir/ir_out
add_wave /risc_tb/dut/mem_addr /risc_tb/dut/u_mem/dout /risc_tb/dut/u_mem/we
add_wave /risc_tb/dut/rp_addr /risc_tb/dut/u_rf/rp_data /risc_tb/dut/u_rf/rq_data /risc_tb/dut/u_alu/y
add_wave {/risc_tb/dut/u_rf/rf[5]} {/risc_tb/dut/u_rf/rf[7]}
add_wave {/risc_tb/dut/u_mem/ram[203]} {/risc_tb/dut/u_mem/ram[204]} {/risc_tb/dut/u_mem/ram[205]}
restart
run all
