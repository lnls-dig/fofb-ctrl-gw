action = "simulation"
sim_tool = "ghdl"
top_module = "fofb_processing_cosim"

modules = {"local" : ["../"]}

sim_pre_cmd = "cargo build --release --manifest-path ../fofb_server/Cargo.toml"

ghdl_opt = "-Wl,../fofb_server/target/release/libfofb_server.a -Wl,-lpthread --std=08"
