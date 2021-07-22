action = "simulation"
sim_tool = "ghdl"
sim_top = "mult_tb"

sim_post_cmd = "ghdl -r mult_tb --stop-time=200ms --vcd=mult_tb.vcd && gtkwave mult_tb.vcd"

files = [
    "mult_tb.vhd", 
]

modules = {
  "local" : [ "../../modules/matmul" ],
}
