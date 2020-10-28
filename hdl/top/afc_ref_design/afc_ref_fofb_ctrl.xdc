#######################################################################
##                      Artix 7 AMC V3                               ##
#######################################################################
#

#######################################################################
##                          Clocks                                   ##
#######################################################################

# FMC 0 clock
create_clock -period 2.500 -name fmc0_adc_dco_p_i [get_ports fmc0_adc_dco_p_i]

# FMC 0 generated clock for user logic
#
# 1. Get the complete name of the fs_clk NET
# 2. Get the pin name that is connected to this NET and filter it
#     so get only the OUT pins and the LEAF name of it (as opposed to
#     a hierarchical name)
# 3. This pin will be probably the Q pin of the driving FF, but for a timing,
#     analysis we want a valid startpoint. So, we get only this by using the all_fanin
#     command
create_generated_clock -name fmc0_fs_clk          [all_fanin -flat -startpoints_only [get_pins -of_objects [get_nets -hier -filter {NAME =~ *cmp_fmc_adc_0_mezzanine/cmp_fofb_ctrl_core/fs_clk}]]]
set fmc0_fs_clk_period                            [get_property PERIOD [get_clocks fmc0_fs_clk]]

# FMC 1 clock
create_clock -period 2.500 -name fmc1_adc_dco_p_i [get_ports fmc1_adc_dco_p_i]

# FMC 0 generated clock for user logic
#
# 1. Get the complete name of the fs_clk NET
# 2. Get the pin name that is connected to this NET and filter it
#     so get only the OUT pins and the LEAF name of it (as opposed to
#     a hierarchical name)
# 3. This pin will be probably the Q pin of the driving FF, but for a timing,
#     analysis we want a valid startpoint. So, we get only this by using the all_fanin
#     command
create_generated_clock -name fmc1_fs_clk          [all_fanin -flat -startpoints_only [get_pins -of_objects [get_nets -hier -filter {NAME =~ *cmp_fmc_adc_1_mezzanine/cmp_fofb_ctrl_core/fs_clk}]]]
set fmc1_fs_clk_period                            [get_property PERIOD [get_clocks fmc1_fs_clk]]

#######################################################################
##                          DELAYS                                   ##
#######################################################################

# From LTC2175-12/LTC2174-12/LTC2173-12 data sheet (page 06)
#
#Output Clock to Data Propagation Delay:
# tdata Rising/Falling Edge 0.35 * tSER (min) / 0.5 * tSER (typ) / 0.65 * tSER (max)
#                       1/800*1e3*0.35 = 0.43750 ns / 0.62500 ns (typ) / 0.81250 ns (max)
#
# Center-Aligned Double Data Rate Source Synchronous Inputs
#
# For a center-aligned Source Synchronous interface, the clock
# transition is aligned with the center of the data valid window.
# The same clock edge is used for launching and capturing the
# data. The constraints below rely on the default timing
# analysis (setup = 1/2 cycle, hold = 0 cycle).
#
# input                  ____________________
# clock    _____________|                    |_____________
#                       |                    |
#                dv_bre | dv_are      dv_bfe | dv_afe
#               <------>|<------>    <------>|<------>
#          _    ________|________    ________|________    _
# data     _XXXX____Rise_Data____XXXX____Fall_Data____XXXX_
#
#
# set input_clock         <clock_name>;      # Name of input clock
# set input_clock_period  <period_value>;    # Period of input clock (full-period)
# set dv_bre              0.000;             # Data valid before the rising clock edge
# set dv_are              0.000;             # Data valid after the rising clock edge
# set dv_bfe              0.000;             # Data valid before the falling clock edge
# set dv_afe              0.000;             # Data valid after the falling clock edge
# set input_ports         <input_ports>;     # List of input ports
#
# # Input Delay Constraint
# set_input_delay -clock $input_clock -max [expr $input_clock_period/2 - $dv_bfe] [get_ports $input_ports];
# set_input_delay -clock $input_clock -min $dv_are                                [get_ports $input_ports];
# set_input_delay -clock $input_clock -max [expr $input_clock_period/2 - $dv_bre] [get_ports $input_ports] -clock_fall -add_delay;
# set_input_delay -clock $input_clock -min $dv_afe                                [get_ports $input_ports] -clock_fall -add_delay;
#
# Add 0.100 ns data off-center relative to the eye, both to rising and falling edges
#
#set_input_delay -clock [get_clocks fmc0_adc_dco_p_i] -max 0.91250 [get_ports {fmc0_adc_outa_p_i[*]}]
#set_input_delay -clock [get_clocks fmc0_adc_dco_p_i] -min 0.71250 [get_ports {fmc0_adc_outa_p_i[*]}]
#set_input_delay -clock [get_clocks fmc0_adc_dco_p_i] -max 0.91250 [get_ports {fmc0_adc_outa_p_i[*]}] -clock_fall -add_delay
#set_input_delay -clock [get_clocks fmc0_adc_dco_p_i] -min 0.71250 [get_ports {fmc0_adc_outa_p_i[*]}] -clock_fall -add_delay
#set_input_delay -clock [get_clocks fmc0_adc_dco_p_i] -max 0.91250 [get_ports {fmc0_adc_outb_p_i[*]}]
#set_input_delay -clock [get_clocks fmc0_adc_dco_p_i] -min 0.71250 [get_ports {fmc0_adc_outb_p_i[*]}]
#set_input_delay -clock [get_clocks fmc0_adc_dco_p_i] -max 0.91250 [get_ports {fmc0_adc_outb_p_i[*]}] -clock_fall -add_delay
#set_input_delay -clock [get_clocks fmc0_adc_dco_p_i] -min 0.71250 [get_ports {fmc0_adc_outb_p_i[*]}] -clock_fall -add_delay
#
#set_input_delay -clock [get_clocks fmc0_adc_dco_p_i] -max 0.91250 [get_ports {fmc0_adc_fr_p_i}]
#set_input_delay -clock [get_clocks fmc0_adc_dco_p_i] -min 0.71250 [get_ports {fmc0_adc_fr_p_i}]
#set_input_delay -clock [get_clocks fmc0_adc_dco_p_i] -max 0.91250 [get_ports {fmc0_adc_fr_p_i}] -clock_fall -add_delay
#set_input_delay -clock [get_clocks fmc0_adc_dco_p_i] -min 0.71250 [get_ports {fmc0_adc_fr_p_i}] -clock_fall -add_delay
#
#set_input_delay -clock [get_clocks fmc1_adc_dco_p_i] -max 0.91250 [get_ports {fmc1_adc_outa_p_i[*]}]
#set_input_delay -clock [get_clocks fmc1_adc_dco_p_i] -min 0.71250 [get_ports {fmc1_adc_outa_p_i[*]}]
#set_input_delay -clock [get_clocks fmc1_adc_dco_p_i] -max 0.91250 [get_ports {fmc1_adc_outa_p_i[*]}] -clock_fall -add_delay
#set_input_delay -clock [get_clocks fmc1_adc_dco_p_i] -min 0.71250 [get_ports {fmc1_adc_outa_p_i[*]}] -clock_fall -add_delay
#set_input_delay -clock [get_clocks fmc1_adc_dco_p_i] -max 0.91250 [get_ports {fmc1_adc_outb_p_i[*]}]
#set_input_delay -clock [get_clocks fmc1_adc_dco_p_i] -min 0.71250 [get_ports {fmc1_adc_outb_p_i[*]}]
#set_input_delay -clock [get_clocks fmc1_adc_dco_p_i] -max 0.91250 [get_ports {fmc1_adc_outb_p_i[*]}] -clock_fall -add_delay
#set_input_delay -clock [get_clocks fmc1_adc_dco_p_i] -min 0.71250 [get_ports {fmc1_adc_outb_p_i[*]}] -clock_fall -add_delay
#
#set_input_delay -clock [get_clocks fmc1_adc_dco_p_i] -max 0.91250 [get_ports {fmc1_adc_fr_p_i}]
#set_input_delay -clock [get_clocks fmc1_adc_dco_p_i] -min 0.71250 [get_ports {fmc1_adc_fr_p_i}]
#set_input_delay -clock [get_clocks fmc1_adc_dco_p_i] -max 0.91250 [get_ports {fmc1_adc_fr_p_i}] -clock_fall -add_delay
#set_input_delay -clock [get_clocks fmc1_adc_dco_p_i] -min 0.71250 [get_ports {fmc1_adc_fr_p_i}] -clock_fall -add_delay

#######################################################################
##                          DELAY values                             ##
#######################################################################

## Overrides default_delay hdl parameter for the VARIABLE mode.
## For Artix7: Average Tap Delay at 200 MHz = 78 ps, at 300 MHz = 52 ps ???

# FMC 0 Clock
set_property IDELAY_VALUE 0 [get_cells -hier -filter {NAME =~ *cmp_fmc_adc_0_mezzanine/cmp_fofb_ctrl_core/cmp_adc_serdes/cmp_clk_iodelay}]

# FMC 0 Data
set_property IDELAY_VALUE 9  [get_cells -hier -filter {NAME =~ *cmp_fmc_adc_0_mezzanine/cmp_fofb_ctrl_core/cmp_adc_serdes/gen_adc_data_iodelay[0].cmp_data_outa_iodelay}]
set_property IDELAY_VALUE 9  [get_cells -hier -filter {NAME =~ *cmp_fmc_adc_0_mezzanine/cmp_fofb_ctrl_core/cmp_adc_serdes/gen_adc_data_iodelay[1].cmp_data_outa_iodelay}]
set_property IDELAY_VALUE 9  [get_cells -hier -filter {NAME =~ *cmp_fmc_adc_0_mezzanine/cmp_fofb_ctrl_core/cmp_adc_serdes/gen_adc_data_iodelay[2].cmp_data_outa_iodelay}]
set_property IDELAY_VALUE 9  [get_cells -hier -filter {NAME =~ *cmp_fmc_adc_0_mezzanine/cmp_fofb_ctrl_core/cmp_adc_serdes/gen_adc_data_iodelay[3].cmp_data_outa_iodelay}]
set_property IDELAY_VALUE 9  [get_cells -hier -filter {NAME =~ *cmp_fmc_adc_0_mezzanine/cmp_fofb_ctrl_core/cmp_adc_serdes/gen_adc_data_iodelay[0].cmp_data_outb_iodelay}]
set_property IDELAY_VALUE 9  [get_cells -hier -filter {NAME =~ *cmp_fmc_adc_0_mezzanine/cmp_fofb_ctrl_core/cmp_adc_serdes/gen_adc_data_iodelay[1].cmp_data_outb_iodelay}]
set_property IDELAY_VALUE 9  [get_cells -hier -filter {NAME =~ *cmp_fmc_adc_0_mezzanine/cmp_fofb_ctrl_core/cmp_adc_serdes/gen_adc_data_iodelay[2].cmp_data_outb_iodelay}]
set_property IDELAY_VALUE 9  [get_cells -hier -filter {NAME =~ *cmp_fmc_adc_0_mezzanine/cmp_fofb_ctrl_core/cmp_adc_serdes/gen_adc_data_iodelay[3].cmp_data_outb_iodelay}]
# FMC 0 Frame
set_property IDELAY_VALUE 10 [get_cells -hier -filter {NAME =~ *adc_0_mezzanine/cmp_fofb_ctrl_core/cmp_adc_serdes/cmp_fr_iodelay}]

# FMC 1 Clock
set_property IDELAY_VALUE 0  [get_cells -hier -filter {NAME =~ *cmp_fmc_adc_1_mezzanine/cmp_fofb_ctrl_core/cmp_adc_serdes/cmp_clk_iodelay}]

# FMC 1 Data
set_property IDELAY_VALUE 9  [get_cells -hier -filter {NAME =~ *cmp_fmc_adc_1_mezzanine/cmp_fofb_ctrl_core/cmp_adc_serdes/gen_adc_data_iodelay[0].cmp_data_outa_iodelay}]
set_property IDELAY_VALUE 9  [get_cells -hier -filter {NAME =~ *cmp_fmc_adc_1_mezzanine/cmp_fofb_ctrl_core/cmp_adc_serdes/gen_adc_data_iodelay[1].cmp_data_outa_iodelay}]
set_property IDELAY_VALUE 9  [get_cells -hier -filter {NAME =~ *cmp_fmc_adc_1_mezzanine/cmp_fofb_ctrl_core/cmp_adc_serdes/gen_adc_data_iodelay[2].cmp_data_outa_iodelay}]
set_property IDELAY_VALUE 10 [get_cells -hier -filter {NAME =~ *cmp_fmc_adc_1_mezzanine/cmp_fofb_ctrl_core/cmp_adc_serdes/gen_adc_data_iodelay[3].cmp_data_outa_iodelay}]
set_property IDELAY_VALUE 10 [get_cells -hier -filter {NAME =~ *cmp_fmc_adc_1_mezzanine/cmp_fofb_ctrl_core/cmp_adc_serdes/gen_adc_data_iodelay[0].cmp_data_outb_iodelay}]
set_property IDELAY_VALUE 9 [get_cells -hier -filter {NAME =~ *cmp_fmc_adc_1_mezzanine/cmp_fofb_ctrl_core/cmp_adc_serdes/gen_adc_data_iodelay[1].cmp_data_outb_iodelay}]
set_property IDELAY_VALUE 10 [get_cells -hier -filter {NAME =~ *cmp_fmc_adc_1_mezzanine/cmp_fofb_ctrl_core/cmp_adc_serdes/gen_adc_data_iodelay[2].cmp_data_outb_iodelay}]
set_property IDELAY_VALUE 9  [get_cells -hier -filter {NAME =~ *cmp_fmc_adc_1_mezzanine/cmp_fofb_ctrl_core/cmp_adc_serdes/gen_adc_data_iodelay[3].cmp_data_outb_iodelay}]
# FMC 1 Frame
set_property IDELAY_VALUE 10 [get_cells -hier -filter {NAME =~ *adc_1_mezzanine/cmp_fofb_ctrl_core/cmp_adc_serdes/cmp_fr_iodelay}]

#######################################################################
##                              CDC                                  ##
#######################################################################

# Synchronizer FF. Set the internal path of synchronizer to be very near each other,
# even though the ASYNC_REG property would take care of this
set_max_delay -datapath_only -from               [get_cells -hier -filter {NAME =~ *cmp_fmc_adc_*_mezzanine/*/cmp_ext_trig_sync/gc_sync_ffs_in}]  1.5

# CDC between Wishbone clock and FS clocks
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
