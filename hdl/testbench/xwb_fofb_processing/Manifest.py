files = [
    "xwb_fofb_processing_tb.vhd",
    "../../sim/regs/wb_fofb_processing_regs_consts_pkg.vhd",
    "../../sim/sim_wishbone.vhd",
    "../fofb_tb_pkg.vhd",
]

modules = {
    "local" : [
        "../../ip_cores/general-cores",
        "../../ip_cores/infra-cores",
        "../../ip_cores/CommsCtrlFPGA",
        "../../modules",
        ],
}
