target = "xilinx"
action = "synthesis"

language = "vhdl"

# Allow the user to override fetchto using:
#  hdlmake -p "fetchto='xxx'"
if locals().get('fetchto', None) is None:
  fetchto = "../../ip_cores"

syn_device = "xc7a200t"
syn_grade = "-2"
syn_package = "ffg1156"
syn_top = "afc_ref_fofb_ctrl"
syn_project = "afc_ref_fofb_ctrl"
syn_tool = "vivado"
syn_properties = [
    ["steps.synth_design.args.more options", "-verbose"],
    ["steps.synth_design.args.retiming", "1"],
    ["steps.synth_design.args.assert", "1"],
    ["steps.phys_opt_design.args.directive", "AlternateFlowWithRetiming"],
    ["steps.phys_opt_design.args.more options", "-verbose"],
    ["steps.phys_opt_design.is_enabled", "1"],
    ["steps.post_route_phys_opt_design.args.directive", "AddRetime"],
    ["steps.post_route_phys_opt_design.args.more options", "-verbose"],
    ["steps.post_route_phys_opt_design.is_enabled", "1"],
#    ["steps.place_design.args.directive", "Explore"],
#    ["steps.place_design.args.more options", "-verbose"],
#    ["steps.route_design.args.directive", "Explore"],
#    ["steps.route_design.args.more options", "-verbose"],
    ["steps.write_bitstream.args.verbose", "1"]
]

board = "afc"

# For appending the afc_ref_design.xdc to synthesis
afc_base_xdc = ['acq']

import os
import sys
if os.path.isfile("synthesis_descriptor_pkg.vhd"):
    files = ["synthesis_descriptor_pkg.vhd"];
else:
    sys.exit("Generate the SDB descriptor before using HDLMake (./build_synthesis_sdb.sh)")

modules = {
  "local" : [
      "../../top/afc_ref_design",
  ]
}
