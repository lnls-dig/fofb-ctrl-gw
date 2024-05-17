action = "simulation"
sim_tool = "nvc"
top_module = "xwb_fofb_shaper_filt_tb"
target = "xilinx"
syn_device = "xc7a200t"

modules = {"local" : ["../"]}

nvc_opt = "--std=2008"
nvc_analysis_opt = "--relaxed"
nvc_elab_opt = "--no-collapse"

sim_post_cmd = "nvc -r --dump-arrays %s --wave=%s.fst --format=fst"%(top_module, top_module)
