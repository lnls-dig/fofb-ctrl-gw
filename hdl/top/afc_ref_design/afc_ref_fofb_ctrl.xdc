#######################################################################
##                      Artix 7 AMC V3                               ##
#######################################################################
#

#######################################################################
##                          Clocks                                   ##
#######################################################################

# FMC 0 clock. 156.25 MHz
create_clock -period 6.400 -name fmc0_fs_clk [get_ports fmc0_si570_clk_p_i]
set fmc0_fs_clk_period                       [get_property PERIOD [get_clocks fmc0_fs_clk]]

# FMC 1 clock. 156.25 MHz
create_clock -period 6.400 -name fmc1_fs_clk [get_ports fmc1_si570_clk_p_i]
set fmc1_fs_clk_period                       [get_property PERIOD [get_clocks fmc1_fs_clk]]

#######################################################################
##                          DELAYS                                   ##
#######################################################################

#######################################################################
##                          DELAY values                             ##
#######################################################################

## Overrides default_delay hdl parameter for the VARIABLE mode.
## For Artix7: Average Tap Delay at 200 MHz = 78 ps, at 300 MHz = 52 ps ???

#######################################################################
##                              CDC                                  ##
#######################################################################

# CDC between Wishbone clock and Transceiver clocks
# These are slow control registers taken care of synched by FFs.
# Give it 1x destination clock. Could be 2x, but lets keep things tight.
set_max_delay -datapath_only -from               [get_clocks clk_sys] -to [get_clocks fmc0_fs_clk]    $fmc0_fs_clk_period
set_max_delay -datapath_only -from               [get_clocks clk_sys] -to [get_clocks fmc1_fs_clk]    $fmc1_fs_clk_period

set_max_delay -datapath_only -from               [get_clocks fmc0_fs_clk]    -to [get_clocks clk_sys] $clk_sys_period
set_max_delay -datapath_only -from               [get_clocks fmc1_fs_clk]    -to [get_clocks clk_sys] $clk_sys_period

# CDC between Clk Aux (trigger clock) and FS clocks
# These are using pulse_synchronizer2 which is a full feedback sync.
# Give it 1x destination clock.
set_max_delay -datapath_only -from               [get_clocks clk_aux] -to [get_clocks fmc0_fs_clk]    $fmc0_fs_clk_period
set_max_delay -datapath_only -from               [get_clocks clk_aux] -to [get_clocks fmc1_fs_clk]    $fmc1_fs_clk_period

# CDC between FS clocks and Clk Aux (trigger clock)
# These are using pulse_synchronizer2 which is a full feedback sync.
# Give it 1x destination clock.
set_max_delay -datapath_only -from               [get_clocks fmc0_fs_clk] -to [get_clocks clk_aux]    $clk_aux_period
set_max_delay -datapath_only -from               [get_clocks fmc1_fs_clk] -to [get_clocks clk_aux]    $clk_aux_period

#######################################################################
##                      Placement Constraints                        ##
#######################################################################
# Constrain the PCIe core elements placement, so that it won't fail
# timing analysis.
create_pblock GRP_pcie_core
add_cells_to_pblock [get_pblocks GRP_pcie_core] [get_cells -hier -filter {NAME =~ *pcie_core_i/*}]
resize_pblock [get_pblocks GRP_pcie_core] -add {CLOCKREGION_X0Y4:CLOCKREGION_X0Y4}
