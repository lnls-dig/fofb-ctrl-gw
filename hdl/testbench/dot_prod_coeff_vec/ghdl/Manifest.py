action = "simulation"
sim_tool = "ghdl"
top_module = "dot_prod_coeff_vec_tb"
target = "xilinx"
syn_device = "XC7"

modules = {"local" : ["../"]}

ghdl_opt = "--std=08 -frelaxed"

sim_post_cmd = "ghdl -r --std=08 %s --wave=%s.ghw"%(top_module, top_module)
