files = [
    "afc_ref_fofb_ctrl.vhd",
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
