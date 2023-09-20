files = [
    "xwb_fofb_shaper_filt_tb.vhd",
    "../../sim/sim_wishbone.vhd",
    "../../sim/regs/wb_fofb_shaper_filt_regs_consts_pkg.vhd",
    "../fofb_tb_pkg.vhd",
]

modules = {
    "local" : [
        "../../ip_cores/CommsCtrlFPGA",
        "../../ip_cores/general-cores",
        "../../ip_cores/infra-cores",
        "../../modules",
        ],
}
