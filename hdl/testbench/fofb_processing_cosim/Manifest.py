files = [
    "fofb_processing_cosim.vhd",
    "fofb_server_pkg.vhd",
    "../fofb_tb_pkg.vhd",
]

modules = {
    "local" : [
        "../../ip_cores/infra-cores",
        "../../ip_cores/general-cores",
        "../../modules/fofb_processing"
        ],
}
