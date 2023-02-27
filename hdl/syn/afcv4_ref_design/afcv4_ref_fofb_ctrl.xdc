#######################################################################
##                      Artix 7 AMC V4                               ##
#######################################################################

#######################################################################
##                          Clocks                                   ##
#######################################################################

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

# Get master clock for DAC
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
##                 PCB delays for LTC232x ADCs                       ##
#######################################################################

set rtmlamp_adc_octo_sdoa_delay 0.159
set rtmlamp_adc_octo_sdob_delay 0.125
set rtmlamp_adc_octo_sdoc_delay 0.120
set rtmlamp_adc_octo_sdod_delay 0.107
set rtmlamp_adc_quad_sdoa_delay -0.161
set rtmlamp_adc_quad_sdoc_delay -0.144

set rtmlamp_adc_uncertainty_delay 0.020

set_clock_groups -asynchronous -group rtmlamp_adc_octo_sck_ret -group clk_fast_spi
set_clock_groups -asynchronous -group rtmlamp_adc_quad_sck_ret -group clk_fast_spi

set_input_delay -clock rtmlamp_adc_octo_sck_ret -max [expr {$rtmlamp_adc_octo_sdoa_delay + $rtmlamp_adc_uncertainty_delay}] [get_ports rtmlamp_adc_octo_sdoa_p_i];
set_input_delay -clock rtmlamp_adc_octo_sck_ret -min [expr {$rtmlamp_adc_octo_sdoa_delay - $rtmlamp_adc_uncertainty_delay}] [get_ports rtmlamp_adc_octo_sdoa_p_i];
set_input_delay -clock rtmlamp_adc_octo_sck_ret -max [expr {$rtmlamp_adc_octo_sdob_delay + $rtmlamp_adc_uncertainty_delay}] [get_ports rtmlamp_adc_octo_sdob_p_i];
set_input_delay -clock rtmlamp_adc_octo_sck_ret -min [expr {$rtmlamp_adc_octo_sdob_delay - $rtmlamp_adc_uncertainty_delay}] [get_ports rtmlamp_adc_octo_sdob_p_i];
set_input_delay -clock rtmlamp_adc_octo_sck_ret -max [expr {$rtmlamp_adc_octo_sdoc_delay + $rtmlamp_adc_uncertainty_delay}] [get_ports rtmlamp_adc_octo_sdoc_p_i];
set_input_delay -clock rtmlamp_adc_octo_sck_ret -min [expr {$rtmlamp_adc_octo_sdoc_delay - $rtmlamp_adc_uncertainty_delay}] [get_ports rtmlamp_adc_octo_sdoc_p_i];
set_input_delay -clock rtmlamp_adc_octo_sck_ret -max [expr {$rtmlamp_adc_octo_sdod_delay + $rtmlamp_adc_uncertainty_delay}] [get_ports rtmlamp_adc_octo_sdod_p_i];
set_input_delay -clock rtmlamp_adc_octo_sck_ret -min [expr {$rtmlamp_adc_octo_sdod_delay - $rtmlamp_adc_uncertainty_delay}] [get_ports rtmlamp_adc_octo_sdod_p_i];

set_input_delay -clock rtmlamp_adc_quad_sck_ret -max [expr {$rtmlamp_adc_quad_sdoa_delay + $rtmlamp_adc_uncertainty_delay}] [get_ports rtmlamp_adc_quad_sdoa_p_i];
set_input_delay -clock rtmlamp_adc_quad_sck_ret -min [expr {$rtmlamp_adc_quad_sdoa_delay - $rtmlamp_adc_uncertainty_delay}] [get_ports rtmlamp_adc_quad_sdoa_p_i];
set_input_delay -clock rtmlamp_adc_quad_sck_ret -max [expr {$rtmlamp_adc_quad_sdoc_delay + $rtmlamp_adc_uncertainty_delay}] [get_ports rtmlamp_adc_quad_sdoc_p_i];
set_input_delay -clock rtmlamp_adc_quad_sck_ret -min [expr {$rtmlamp_adc_quad_sdoc_delay - $rtmlamp_adc_uncertainty_delay}] [get_ports rtmlamp_adc_quad_sdoc_p_i];

#######################################################################
##                          DELAY values                             ##
#######################################################################

## Overrides default_delay hdl parameter for the VARIABLE mode.
## For Artix7: Average Tap Delay at 200 MHz = 78 ps, at 300 MHz = 52 ps ???

#######################################################################
##                              CDC                                  ##
#######################################################################

# CDC FIFO between FAST SPI and CLK SYS domains
set_max_delay -datapath_only -from               [get_clocks clk_sys] -to [get_clocks $clk_fast_spi]  $clk_fast_spi_period
set_max_delay -datapath_only -from               [get_clocks $clk_fast_spi] -to [get_clocks clk_sys] $clk_sys_period

# CDC between Clk Aux (trigger clock) and FS clocks
# These are using pulse_synchronizer2 which is a full feedback sync.
# Give it 1x destination clock.
set_max_delay -datapath_only -from               [get_clocks clk_aux] -to [get_clocks $clk_dac_master]          $clk_dac_master_period
set_max_delay -datapath_only -from               [get_clocks $clk_adcdac_ref] -to [get_clocks $clk_dac_master]  $clk_dac_master_period
# CDC for done/ready flags
set_max_delay -datapath_only -from               [get_clocks $clk_adcdac_ref] -to [get_clocks $clk_fast_spi]  $clk_fast_spi_period

# CDC between FS clocks and Clk Aux (trigger clock)
# These are using pulse_synchronizer2 which is a full feedback sync.
# Give it 1x destination clock.
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
