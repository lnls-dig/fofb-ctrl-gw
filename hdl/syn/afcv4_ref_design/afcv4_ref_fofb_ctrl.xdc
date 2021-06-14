#######################################################################
##                      Artix 7 AMC V4                               ##
#######################################################################

#######################################################################
##                      P2P RX/TX 12-15                              ##
#######################################################################

# RX_12

# RX213_0_N MGTPRXN0_213 AM18
# RX213_0_P MGTPRXP0_213 AL18
set_property PACKAGE_PIN AM18 [get_ports p2p_gt_rx_n_i[0]]
set_property PACKAGE_PIN AL18 [get_ports p2p_gt_rx_p_i[0]]

# RX_13

# RX213_2_N MGTPRXN2_213 AM20
# RX213_2_P MGTPRXP2_213 AL20
set_property PACKAGE_PIN AM20 [get_ports p2p_gt_rx_n_i[1]]
set_property PACKAGE_PIN AL20 [get_ports p2p_gt_rx_p_i[1]]

# RX_14

# RX213_1_N MGTPRXN1_213 AK19
# RX213_1_P MGTPRXP1_213 AJ19
set_property PACKAGE_PIN AK19 [get_ports p2p_gt_rx_n_i[2]]
set_property PACKAGE_PIN AJ19 [get_ports p2p_gt_rx_p_i[2]]

# RX_15

# RX213_3_N MGTPRXN3_213 AK21
# RX213_3_P MGTPRXP3_213 AJ21
set_property PACKAGE_PIN AK21 [get_ports p2p_gt_rx_n_i[3]]
set_property PACKAGE_PIN AJ21 [get_ports p2p_gt_rx_p_i[3]]

# TX_12

# TX213_0_N MGTPTXN0_213 AP19
# TX213_0_P MGTPTXP0_213 AN19
set_property PACKAGE_PIN AP19 [get_ports p2p_gt_tx_n_o[0]]
set_property PACKAGE_PIN AN19 [get_ports p2p_gt_tx_p_o[0]]

# TX_13

# TX213_2_N MGTPTXN2_213 AM22
# TX213_2_P MGTPTXP2_213 AL22
set_property PACKAGE_PIN AM22 [get_ports p2p_gt_tx_n_o[1]]
set_property PACKAGE_PIN AL22 [get_ports p2p_gt_tx_p_o[1]]

# TX_14

# TX213_1_N MGTPTXN1_213 AP21
# TX213_1_P MGTPTXP1_213 AN21
set_property PACKAGE_PIN AP21 [get_ports p2p_gt_tx_n_o[2]]
set_property PACKAGE_PIN AN21 [get_ports p2p_gt_tx_p_o[2]]

# TX_15

# TX213_3_N MGTPTXN3_213 AP23
# TX213_3_P MGTPTXP3_213 AN23
set_property PACKAGE_PIN AP23 [get_ports p2p_gt_tx_n_o[3]]
set_property PACKAGE_PIN AN23 [get_ports p2p_gt_tx_p_o[3]]

#######################################################################
##               Fat Pipe 2 (used as P2P RX/TX 8-12)                 ##
#######################################################################

# RX_8

# RX113_0_N MGTPRXN0_113 AK17
# RX113_0_P MGTPRXP0_113 AJ17
set_property PACKAGE_PIN AK17 [get_ports p2p_gt_rx_n_i[4]]
set_property PACKAGE_PIN AJ17 [get_ports p2p_gt_rx_p_i[4]]

# RX_9

# RX113_1_N MGTPRXN1_113 AM16
# RX113_1_P MGTPRXP1_113 AL16
set_property PACKAGE_PIN AM16 [get_ports p2p_gt_rx_n_i[5]]
set_property PACKAGE_PIN AL16 [get_ports p2p_gt_rx_p_i[5]]

# RX_10

# RX113_2_N MGTPRXN2_113 AK15
# RX113_2_P MGTPRXP2_113 AJ15
set_property PACKAGE_PIN AK15 [get_ports p2p_gt_rx_n_i[6]]
set_property PACKAGE_PIN AJ15 [get_ports p2p_gt_rx_p_i[6]]

# RX_11

# RX113_3_N MGTPRXN3_113 AK13
# RX113_3_P MGTPRXP3_113 AJ13
set_property PACKAGE_PIN AK13 [get_ports p2p_gt_rx_n_i[7]]
set_property PACKAGE_PIN AJ13 [get_ports p2p_gt_rx_p_i[7]]

# TX_8

# TX113_0_N MGTPTXN0_113 AP17
# TX113_0_P MGTPTXP0_113 AN17
set_property PACKAGE_PIN AP17 [get_ports p2p_gt_tx_n_o[4]]
set_property PACKAGE_PIN AN17 [get_ports p2p_gt_tx_p_o[4]]

# TX_9

# TX113_1_N MGTPTXN1_113 AP15
# TX113_1_P MGTPTXP1_113 AN15
set_property PACKAGE_PIN AP15 [get_ports p2p_gt_tx_n_o[5]]
set_property PACKAGE_PIN AN15 [get_ports p2p_gt_tx_p_o[5]]

# TX_10

# TX113_2_N MGTPTXN2_113 AM14
# TX113_2_P MGTPTXP2_113 AL14
set_property PACKAGE_PIN AM14 [get_ports p2p_gt_tx_n_o[6]]
set_property PACKAGE_PIN AL14 [get_ports p2p_gt_tx_p_o[6]]

# TX_11

# TX113_3_N MGTPTXN3_113 AP13
# TX113_3_P MGTPTXP3_113 AN13
set_property PACKAGE_PIN AP13 [get_ports p2p_gt_tx_n_o[7]]
set_property PACKAGE_PIN AN13 [get_ports p2p_gt_tx_p_o[7]]

#######################################################################
##                          Clocks                                   ##
#######################################################################

# FMC 0 clock. 156.25 MHz
create_clock -period 6.400 -name fmc0_fs_clk  [get_ports fmc0_si570_clk_p_i]
set fmc0_fs_clk_period                        [get_property PERIOD [get_clocks fmc0_fs_clk]]

# FP2_CLK1 clock. 156.25 MHz
create_clock -period 6.400 -name afc_fp2_clk1 [get_ports afc_fp2_clk1_p_i]
set afc_fp2_clk1_period                       [get_property PERIOD [get_clocks afc_fp2_clk1]]

# Octo return clock
create_clock -period 10.000 -name rtmlamp_adc_octo_sck_ret    [get_ports rtmlamp_adc_octo_sck_ret_p_i]
set rtmlamp_adc_octo_sck_ret_clk_period                       [get_property PERIOD [get_clocks rtmlamp_adc_octo_sck_ret]]
# Virtual clock for Octo return clock
create_clock -period 10.000 -name virt_rtmlamp_adc_octo_sck_ret

# Quad return clock
create_clock -period 10.000 -name rtmlamp_adc_quad_sck_ret    [get_ports rtmlamp_adc_quad_sck_ret_p_i]
set rtmlamp_adc_quad_sck_ret_clk_period                       [get_property PERIOD [get_clocks rtmlamp_adc_quad_sck_ret]]
# Virtual clock for Quad return clock
create_clock -period 10.000 -name virt_rtmlamp_adc_quad_sck_ret

set clk_dac_master                                            [get_clocks -of_objects [get_nets -hier -filter {NAME =~ */clk_sys}]]
set clk_dac_master_period                                     [get_property PERIOD [get_clocks $clk_dac_master]]

# Get master clock for ADC
set clk_fast_spi                                              [get_clocks -of_objects [get_nets -hier -filter {NAME =~ */clk_user2}]]
set clk_fast_spi_period                                       [get_property PERIOD [get_clocks $clk_fast_spi]]

# Get reference clocks for ADC/DAC/etc
set clk_adcdac_ref                                            [get_clocks -of_objects [get_nets -hier -filter {NAME =~ */clk_aux_raw}]]
set clk_adcdac_ref_period                                     [get_property PERIOD [get_clocks $clk_adcdac_ref]]

#######################################################################
##                          DIFF_TERM                                ##
#######################################################################

set_property DIFF_TERM TRUE                                   [get_ports rtmlamp_adc_octo_sck_ret_n_i]
set_property DIFF_TERM TRUE                                   [get_ports rtmlamp_adc_octo_sck_ret_p_i]

set_property DIFF_TERM TRUE                                   [get_ports rtmlamp_adc_octo_sdoa_n_i]
set_property DIFF_TERM TRUE                                   [get_ports rtmlamp_adc_octo_sdoa_p_i]

set_property DIFF_TERM TRUE                                   [get_ports rtmlamp_adc_octo_sdob_n_i]
set_property DIFF_TERM TRUE                                   [get_ports rtmlamp_adc_octo_sdob_p_i]

set_property DIFF_TERM TRUE                                   [get_ports rtmlamp_adc_octo_sdoc_n_i]
set_property DIFF_TERM TRUE                                   [get_ports rtmlamp_adc_octo_sdoc_p_i]

set_property DIFF_TERM TRUE                                   [get_ports rtmlamp_adc_octo_sdod_n_i]
set_property DIFF_TERM TRUE                                   [get_ports rtmlamp_adc_octo_sdod_p_i]

set_property DIFF_TERM TRUE                                   [get_ports rtmlamp_adc_quad_sck_ret_n_i]
set_property DIFF_TERM TRUE                                   [get_ports rtmlamp_adc_quad_sck_ret_p_i]

set_property DIFF_TERM TRUE                                   [get_ports rtmlamp_adc_quad_sdoa_n_i]
set_property DIFF_TERM TRUE                                   [get_ports rtmlamp_adc_quad_sdoa_p_i]

set_property DIFF_TERM TRUE                                   [get_ports rtmlamp_adc_quad_sdoc_n_i]
set_property DIFF_TERM TRUE                                   [get_ports rtmlamp_adc_quad_sdoc_p_i]

#######################################################################
##                          DELAYS                                   ##
#######################################################################
#
# From LTC2324-16 and LTC2320-16 data sheet (page 06)
#
# SDO Data Remains Valid Delay from CLKOUT falling edge:
# tHSDO_SDR 0.00ns (min) / 1.5ns (max)
#
# So, the rising edge at 0ns generates the window from 6.5ns to 15ns,
# or, equivalently, the rising edge at -10ns generates the window from
# -3.5ns to 5ns.
#
# From Xilinx constraints guide:
#
# Center-Aligned Rising Edge Source Synchronous Inputs
#
# For a center-aligned Source Synchronous interface, the clock
# transition is aligned with the center of the data valid window.
# The same clock edge is used for launching and capturing the
# data. The constraints below rely on the default timing
# analysis (setup = 1 cycle, hold = 0 cycle).
#
# input    ____           __________
# clock        |_________|          |_____
#                        |
#                 dv_bre | dv_are
#                <------>|<------>
#          __    ________|________    __
# data     __XXXX____Rise_Data____XXXX__
#
#
# Input Delay Constraint
# set_input_delay -clock $input_clock -max [expr $input_clock_period - $dv_bre] [get_ports $input_ports];
# set_input_delay -clock $input_clock -min $dv_are                              [get_ports $input_ports];
#
# For our case:
#
# input    ____           __________
# clock        |_________|          |_____
#                        |
#                  3.5ns |  5ns
#                <------>|<------>
#          __    ________|________    __
# data     __XXXX____Rise_Data____XXXX__
#

# These will be ignored by a clock set_clock_groups -asynchronous, but we
# keep it here for reference. Also we sample SDO/SCK with IOB FF, so there is
# not much the tool can improve.
#
# set_input_delay -clock virt_rtmlamp_adc_octo_sck_ret -max 6.5 [get_ports rtmlamp_adc_octo_sdoa_p_i];
# set_input_delay -clock virt_rtmlamp_adc_octo_sck_ret -min 5.0 [get_ports rtmlamp_adc_octo_sdoa_p_i];
# set_input_delay -clock virt_rtmlamp_adc_octo_sck_ret -max 6.5 [get_ports rtmlamp_adc_octo_sdob_p_i];
# set_input_delay -clock virt_rtmlamp_adc_octo_sck_ret -min 5.0 [get_ports rtmlamp_adc_octo_sdob_p_i];
# set_input_delay -clock virt_rtmlamp_adc_octo_sck_ret -max 6.5 [get_ports rtmlamp_adc_octo_sdoc_p_i];
# set_input_delay -clock virt_rtmlamp_adc_octo_sck_ret -min 5.0 [get_ports rtmlamp_adc_octo_sdoc_p_i];
# set_input_delay -clock virt_rtmlamp_adc_octo_sck_ret -max 6.5 [get_ports rtmlamp_adc_octo_sdod_p_i];
# set_input_delay -clock virt_rtmlamp_adc_octo_sck_ret -min 5.0 [get_ports rtmlamp_adc_octo_sdod_p_i];
#
# set_input_delay -clock virt_rtmlamp_adc_quad_sck_ret -max 6.5 [get_ports rtmlamp_adc_quad_sdoa_p_i];
# set_input_delay -clock virt_rtmlamp_adc_quad_sck_ret -min 5.0 [get_ports rtmlamp_adc_quad_sdoa_p_i];
# set_input_delay -clock virt_rtmlamp_adc_quad_sck_ret -max 6.5 [get_ports rtmlamp_adc_quad_sdoc_p_i];
# set_input_delay -clock virt_rtmlamp_adc_quad_sck_ret -min 5.0 [get_ports rtmlamp_adc_quad_sdoc_p_i];

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
set_max_delay -datapath_only -from               [get_clocks clk_sys] -to [get_clocks afc_fp2_clk1]    $afc_fp2_clk1_period

set_max_delay -datapath_only -from               [get_clocks fmc0_fs_clk]    -to [get_clocks clk_sys] $clk_sys_period
set_max_delay -datapath_only -from               [get_clocks afc_fp2_clk1]    -to [get_clocks clk_sys] $clk_sys_period

# CDC FIFO between FAST SPI and CLK SYS domains
set_max_delay -datapath_only -from               [get_clocks clk_sys] -to [get_clocks $clk_fast_spi]  $clk_fast_spi_period
set_max_delay -datapath_only -from               [get_clocks $clk_fast_spi] -to [get_clocks clk_sys] $clk_sys_period

# CDC between Clk Aux (trigger clock) and FS clocks
# These are using pulse_synchronizer2 which is a full feedback sync.
# Give it 1x destination clock.
set_max_delay -datapath_only -from               [get_clocks clk_aux] -to [get_clocks fmc0_fs_clk]    $fmc0_fs_clk_period
set_max_delay -datapath_only -from               [get_clocks clk_aux] -to [get_clocks afc_fp2_clk1]    $afc_fp2_clk1_period
set_max_delay -datapath_only -from               [get_clocks clk_aux] -to [get_clocks $clk_dac_master]          $clk_dac_master_period
set_max_delay -datapath_only -from               [get_clocks $clk_adcdac_ref] -to [get_clocks $clk_dac_master]  $clk_dac_master_period
# CDC for done/ready flags
set_max_delay -datapath_only -from               [get_clocks $clk_adcdac_ref] -to [get_clocks $clk_fast_spi]  $clk_fast_spi_period

# CDC between FS clocks and Clk Aux (trigger clock)
# These are using pulse_synchronizer2 which is a full feedback sync.
# Give it 1x destination clock.
set_max_delay -datapath_only -from               [get_clocks fmc0_fs_clk] -to [get_clocks clk_aux]    $clk_aux_period
set_max_delay -datapath_only -from               [get_clocks afc_fp2_clk1] -to [get_clocks clk_aux]    $clk_aux_period
set_max_delay -datapath_only -from               [get_clocks $clk_dac_master]    -to [get_clocks clk_aux]           $clk_aux_period
set_max_delay -datapath_only -from               [get_clocks $clk_dac_master]    -to [get_clocks $clk_adcdac_ref]   $clk_adcdac_ref_period
# CDC for done/ready flags
set_max_delay -datapath_only -from               [get_clocks $clk_fast_spi]      -to [get_clocks $clk_adcdac_ref]   $clk_adcdac_ref_period

# Cosntraint all ADC inputs as a max delay of clk_fast_spi_period, so theier difference
# are not too large
set_max_delay -datapath_only -from               [get_ports rtmlamp_adc_octo_sck_ret_p_i] \
    -to [get_clocks $clk_fast_spi]  $clk_fast_spi_period
set_max_delay -datapath_only -from               [get_ports rtmlamp_adc_octo_sdoa_p_i] \
    -to [get_clocks $clk_fast_spi]  $clk_fast_spi_period
set_max_delay -datapath_only -from               [get_ports rtmlamp_adc_octo_sdob_p_i] \
    -to [get_clocks $clk_fast_spi]  $clk_fast_spi_period
set_max_delay -datapath_only -from               [get_ports rtmlamp_adc_octo_sdoc_p_i] \
    -to [get_clocks $clk_fast_spi]  $clk_fast_spi_period
set_max_delay -datapath_only -from               [get_ports rtmlamp_adc_octo_sdod_p_i] \
    -to [get_clocks $clk_fast_spi]  $clk_fast_spi_period

set_max_delay -datapath_only -from               [get_ports rtmlamp_adc_quad_sck_ret_p_i] \
    -to [get_clocks $clk_fast_spi]  $clk_fast_spi_period
set_max_delay -datapath_only -from               [get_ports rtmlamp_adc_quad_sdoa_p_i] \
    -to [get_clocks $clk_fast_spi]  $clk_fast_spi_period
set_max_delay -datapath_only -from               [get_ports rtmlamp_adc_quad_sdoc_p_i] \
    -to [get_clocks $clk_fast_spi]  $clk_fast_spi_period

# reset from UART. ORed with a negative reset pulse and an extension of it.
# That's why we have two sets of constraints. How to get all startpoints with
# a single set?
#
# Get all start valid startpoints from all the pins connected to the uart_rstn nets;
# filter it for leaf nodes and outputs;
# set max_delay from all those cells to all valid endpoints at the clk_fast_spi domain
set uart_rstn_startpoints          [all_fanin -flat -only_cells -startpoints_only \
    [ get_pins -of_objects [ get_nets -hier -filter {NAME =~ *uart_rstn} ] -filter {IS_LEAF && (DIRECTION == "OUT")} ]]
set_max_delay -datapath_only -from [ get_cells $uart_rstn_startpoints ]  -to [ get_clocks $clk_fast_spi ] $clk_sys_period

# reset from button
set button_exted_rstn_startpoints          [all_fanin -flat -only_cells -startpoints_only \
    [ get_pins -of_objects [ get_nets -hier -filter {NAME =~ *cmp_button_sys_rst/extended_int_reg*} ] -filter {IS_LEAF && (DIRECTION == "OUT")} ]]
set_max_delay -datapath_only -from [ get_cells $button_exted_rstn_startpoints ]  -to [ get_clocks $clk_fast_spi ] $clk_sys_period

set button_pp_rstn_startpoints          [all_fanin -flat -only_cells -startpoints_only \
    [ get_pins -of_objects [ get_nets -hier -filter {NAME =~ *cmp_button_sys_ffs/*rst_button_sys_pp*} ] -filter {IS_LEAF && (DIRECTION == "OUT")} ]]
set_max_delay -datapath_only -from [ get_cells $button_pp_rstn_startpoints ]  -to [ get_clocks $clk_fast_spi ] $clk_sys_period


#######################################################################
##                      Placement Constraints                        ##
#######################################################################
# Constrain the PCIe core elements placement, so that it won't fail
# timing analysis.
#create_pblock GRP_pcie_core
#add_cells_to_pblock [get_pblocks GRP_pcie_core] [get_cells -hier -filter {NAME =~ *pcie_core_i/*}]
#resize_pblock [get_pblocks GRP_pcie_core] -add {CLOCKREGION_X0Y4:CLOCKREGION_X0Y4}
