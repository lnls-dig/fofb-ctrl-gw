files = [
    "afc_ref_fofb_ctrl.vhd",
    "afc_fmc_4sfp+_caen.xdc",
    "afc_ref_fofb_ctrl.xdc",
]

fetchto = "../../ip_cores"

modules = {
    "local" : [
    "../..",
    ],
    "git" : [
        "https://github.com/lnls-dig/infra-cores.git",
        "https://github.com/lnls-dig/general-cores.git",
        "https://github.com/lnls-dig/afc-gw.git",
        "https://github.com/lnls-dig/CommsCtrlFPGA.git",
    ],
}
