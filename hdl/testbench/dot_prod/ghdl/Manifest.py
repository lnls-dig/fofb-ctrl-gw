action = "simulation"
sim_tool = "ghdl"
top_module = "dot_prod_tb"

modules = {"local" : ["../"]}

ghdl_opt = "--std=08"

sim_post_cmd = "ghdl -r --std=08 %s --wave=%s.ghw --assert-level=error"%(top_module, top_module)
