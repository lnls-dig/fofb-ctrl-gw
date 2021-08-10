#######################################################################
##                          Clocks                                   ##
#######################################################################

# FMC 0 clock. 312.5 MHz
create_clock -period 3.200 -name fmc0_fs_clk  [get_ports clk_core]
set fmc0_fs_clk_period                        [get_property PERIOD [get_clocks fmc0_fs_clk]]
