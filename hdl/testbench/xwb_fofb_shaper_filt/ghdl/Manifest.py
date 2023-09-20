action = "simulation"
sim_tool = "ghdl"
ghdl_opt = "--std=08 -frelaxed"

target = "xilinx"
syn_device = "xc7a200t"

top_module = "xwb_fofb_shaper_filt_tb"
modules = {"local" : ["../"]}

sim_post_cmd = "ghdl -r --std=08 %s --wave=%s.ghw --assert-level=error" % (top_module, top_module)
