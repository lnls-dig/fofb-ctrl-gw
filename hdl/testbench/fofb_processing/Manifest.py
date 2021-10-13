action = "simulation"
sim_tool = "ghdl"
sim_top = "dot_tb"
target = "xilinx"
syn_device = "XC7"

sim_post_cmd = "ghdl -r dot_tb --stop-time=150us --vcd=dot_tb.vcd && gtkwave dot_tb.vcd"

files = [
    "dot_tb.vhd", 
]

modules = {
  "local" : [ "../../ip_cores/general-cores", "../../modules/fofb_processing"],
}
