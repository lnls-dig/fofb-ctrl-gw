action = "simulation"
sim_tool = "ghdl"
sim_top = "mult_tb"
target = "xilinx"
syn_device = "XC7"

sim_post_cmd = "ghdl -r mult_tb --stop-time=150us --vcd=mult_tb.vcd && gtkwave mult_tb.vcd"

files = [
    "mult_tb.vhd", 
]

modules = {
  "local" : [ "../../ip_cores/general-cores", "../../modules/matmul"],
}
