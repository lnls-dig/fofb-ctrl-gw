#######################################################################
##                      Artix 7 AMC V3                               ##
#######################################################################
#
# RX213_0_N MGTPRXN0_213 AM18
# RX213_0_P MGTPRXP0_213 AL18
set_property PACKAGE_PIN AM18 [get_ports p2p_gt_rx_n_i[0]]
set_property PACKAGE_PIN AL18 [get_ports p2p_gt_rx_p_i[0]]

# RX213_1_N MGTPRXN1_213 AK19
# RX213_1_P MGTPRXP1_213 AJ19
set_property PACKAGE_PIN AK19 [get_ports p2p_gt_rx_n_i[1]]
set_property PACKAGE_PIN AJ19 [get_ports p2p_gt_rx_p_i[1]]

# RX213_2_N MGTPRXN2_213 AM20
# RX213_2_P MGTPRXP2_213 AL20
set_property PACKAGE_PIN AM20 [get_ports p2p_gt_rx_n_i[2]]
set_property PACKAGE_PIN AL20 [get_ports p2p_gt_rx_p_i[2]]

# RX213_3_N MGTPRXN3_213 AK21
# RX213_3_P MGTPRXP3_213 AJ21
set_property PACKAGE_PIN AK21 [get_ports p2p_gt_rx_n_i[3]]
set_property PACKAGE_PIN AJ21 [get_ports p2p_gt_rx_p_i[3]]

# TX213_0_N MGTPTXN0_213 AP19
# TX213_0_P MGTPTXP0_213 AN19
set_property PACKAGE_PIN AP19 [get_ports p2p_gt_tx_n_o[0]]
set_property PACKAGE_PIN AN19 [get_ports p2p_gt_tx_p_o[0]]

# TX213_1_N MGTPTXN1_213 AP21
# TX213_1_P MGTPTXP1_213 AN21
set_property PACKAGE_PIN AP21 [get_ports p2p_gt_tx_n_o[1]]
set_property PACKAGE_PIN AN21 [get_ports p2p_gt_tx_p_o[1]]

# TX213_2_N MGTPTXN2_213 AM22
# TX213_2_P MGTPTXP2_213 AL22
set_property PACKAGE_PIN AM22 [get_ports p2p_gt_tx_n_o[2]]
set_property PACKAGE_PIN AL22 [get_ports p2p_gt_tx_p_o[2]]

# TX213_3_N MGTPTXN3_213 AP23
# TX213_3_P MGTPTXP3_213 AN23
set_property PACKAGE_PIN AP23 [get_ports p2p_gt_tx_n_o[3]]
set_property PACKAGE_PIN AN23 [get_ports p2p_gt_tx_p_o[3]]

#######################################################################
##                          Clocks                                   ##
#######################################################################

# RTM FPGA 1 clock. 156.25 MHz
create_clock -period 6.400 -name rtm_fpga_clk1 [get_ports rtm_fpga_clk1_p_i]
set rtm_fpga_clk1_period                       [get_property PERIOD [get_clocks rtm_fpga_clk1]]

# RTM FPGA 2 clock. 156.25 MHz
create_clock -period 6.400 -name rtm_fpga_clk2 [get_ports rtm_fpga_clk2_p_i]
set rtm_fpga_clk2_period                       [get_property PERIOD [get_clocks rtm_fpga_clk2]]

# LINK01 clock. 156.25 MHz
create_clock -period 6.400 -name afc_link01_clk [get_ports afc_link01_clk_p_i]
set afc_link01_clk_period                       [get_property PERIOD [get_clocks afc_link01_clk]]

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
set_max_delay -datapath_only -from               [get_clocks clk_sys] -to [get_clocks rtm_fpga_clk1]    $rtm_fpga_clk1_period
set_max_delay -datapath_only -from               [get_clocks clk_sys] -to [get_clocks rtm_fpga_clk2]    $rtm_fpga_clk2_period
set_max_delay -datapath_only -from               [get_clocks clk_sys] -to [get_clocks afc_link01_clk]    $afc_link01_clk_period

set_max_delay -datapath_only -from               [get_clocks rtm_fpga_clk1]    -to [get_clocks clk_sys] $clk_sys_period
set_max_delay -datapath_only -from               [get_clocks rtm_fpga_clk2]    -to [get_clocks clk_sys] $clk_sys_period
set_max_delay -datapath_only -from               [get_clocks afc_link01_clk]    -to [get_clocks clk_sys] $clk_sys_period

# CDC between Clk Aux (trigger clock) and FS clocks
# These are using pulse_synchronizer2 which is a full feedback sync.
# Give it 1x destination clock.
set_max_delay -datapath_only -from               [get_clocks clk_aux] -to [get_clocks rtm_fpga_clk1]    $rtm_fpga_clk1_period
set_max_delay -datapath_only -from               [get_clocks clk_aux] -to [get_clocks rtm_fpga_clk2]    $rtm_fpga_clk2_period
set_max_delay -datapath_only -from               [get_clocks clk_aux] -to [get_clocks afc_link01_clk]    $afc_link01_clk_period

# CDC between FS clocks and Clk Aux (trigger clock)
# These are using pulse_synchronizer2 which is a full feedback sync.
# Give it 1x destination clock.
set_max_delay -datapath_only -from               [get_clocks rtm_fpga_clk1] -to [get_clocks clk_aux]    $clk_aux_period
set_max_delay -datapath_only -from               [get_clocks rtm_fpga_clk2] -to [get_clocks clk_aux]    $clk_aux_period
set_max_delay -datapath_only -from               [get_clocks afc_link01_clk] -to [get_clocks clk_aux]    $clk_aux_period

#######################################################################
##                      Placement Constraints                        ##
#######################################################################
# Constrain the PCIe core elements placement, so that it won't fail
# timing analysis.
#create_pblock GRP_pcie_core
#add_cells_to_pblock [get_pblocks GRP_pcie_core] [get_cells -hier -filter {NAME =~ *pcie_core_i/*}]
#resize_pblock [get_pblocks GRP_pcie_core] -add {CLOCKREGION_X0Y4:CLOCKREGION_X0Y4}
