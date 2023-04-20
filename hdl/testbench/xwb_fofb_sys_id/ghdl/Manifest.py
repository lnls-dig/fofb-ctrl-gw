action = "simulation"
sim_tool = "ghdl"
top_module = "xwb_fofb_sys_id_tb"
target = "xilinx"
syn_device = "xc7a200t"

modules = {"local" : ["../"]}

ghdl_opt = "--std=08 -frelaxed"

sim_post_cmd = "ghdl -r --std=08 %s --wave=%s.ghw --assert-level=error"% (top_module, top_module)
