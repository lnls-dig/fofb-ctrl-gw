#######################################################################
##                          Clocks                                   ##
#######################################################################

# FMC 0 clock. 312.5 MHz
create_clock -period 3.200 -name fmc0_fs_clk -add [get_ports clk_core]

