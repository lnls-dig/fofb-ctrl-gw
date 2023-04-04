files = [
    "xwb_fofb_sys_id_tb.vhd",
    "../../ip_cores/general-cores/sim/vhdl/sim_wishbone.vhd",
    "../../sim/regs/wb_fofb_sys_id_regs_consts_pkg.vhd",
    "../fofb_tb_pkg.vhd",
]

modules = {
    "local" : [
        "../../ip_cores/general-cores",
        "../../ip_cores/CommsCtrlFPGA",
        "../../modules",
        ],
}
