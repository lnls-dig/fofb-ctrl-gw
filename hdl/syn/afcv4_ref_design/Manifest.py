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
syn_top = "afcv4_ref_fofb_ctrl"
syn_project = "afcv4_ref_fofb_ctrl"
syn_tool = "vivado"
syn_properties = [
    ["steps.synth_design.args.more options", "-verbose"],
    ["steps.synth_design.args.retiming", "1"],
    ["steps.synth_design.args.assert", "1"],
    ["steps.place_design.args.directive", "Explore"],
    ["steps.place_design.args.more options", "-verbose"],
    ["steps.route_design.args.directive", "Explore"],
    ["steps.route_design.args.more options", "-verbose"],
    ["steps.write_bitstream.args.verbose", "1"]
]

board = "afcv4"

# For appending the afc_ref_design.xdc to synthesis
afc_base_xdc = ['acq']

import os
import sys
if os.path.isfile("synthesis_descriptor_pkg.vhd"):
    files = ["synthesis_descriptor_pkg.vhd"]
else:
    sys.exit("Generate the SDB descriptor before using HDLMake (./build_synthesis_sdb.sh)")

# Pass more XDC to afc-gw so it will merge it last with
# other .xdc. We need this as we depend on variables defined
# on afc_base xdc files.
xdc_files = [
    "afcv4_fmc_4sfp+_caen.xdc",
    "afcv4_rtm_lamp_ohwr.xdc",
    "../afc_common/afc_fmc_4sfp_gts.xdc",
    "../afc_common/afc_p2p_gts.xdc",
    "afcv4_ref_fofb_ctrl.xdc",
]

additional_xdc = []
for f in xdc_files:
    additional_xdc.append(os.path.abspath(f))

modules = {
    "local" : [
        "../../top/afcv4_ref_design",
    ]
}
