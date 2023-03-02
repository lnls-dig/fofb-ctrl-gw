-- Do not edit.  Generated on Thu Mar 02 09:08:53 2023 by guilherme.ricioli
-- With Cheby 1.4.0 and these options:
--  -i wb_fofb_processing_regs.cheby --hdl vhdl --gen-hdl wb_fofb_processing_regs.vhd --doc html --gen-doc doc/wb_fofb_processing_regs.html --gen-c wb_fofb_processing_regs.h --consts-style verilog --gen-consts ../../../sim/regs/wb_fofb_processing_regs.vh --consts-style vhdl-ohwr --gen-consts ../../../sim/regs/wb_fofb_processing_regs_consts_pkg.vhd


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wishbone_pkg.all;
use work.cheby_pkg.all;

entity wb_fofb_processing_regs is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_i                 : in    t_wishbone_slave_in;
    wb_o                 : out   t_wishbone_slave_out;

    -- fofb processing coefficients fixed-point position constant
    -- fixed-point position constant value
    fixed_point_pos_coeff_val_i : in    std_logic_vector(31 downto 0);

    -- fofb processing accumulators' gains fixed-point position register
    -- value
    fixed_point_pos_accs_gains_val_i : in    std_logic_vector(31 downto 0);

    -- fofb processing loop interlock control register
    -- write 0: no effect
    -- write 1: clears loop interlock status (this bit autoclears)
    loop_intlk_ctl_sta_clr_o : out   std_logic;
    -- write 0: disables source
    -- write 1: enables source
    loop_intlk_ctl_src_en_orb_distort_o : out   std_logic;
    -- write 0: disables source
    -- write 1: enables source
    loop_intlk_ctl_src_en_packet_loss_o : out   std_logic;

    -- fofb processing loop interlock status register
    -- read 0: not interlocked
    -- read 1: interlocked
    loop_intlk_sta_orb_distort_i : in    std_logic;
    -- read 0: not interlocked
    -- read 1: interlocked
    loop_intlk_sta_packet_loss_i : in    std_logic;

    -- fofb processing loop interlock orbit distortion limit value register
    -- value
    loop_intlk_orb_distort_limit_val_o : out   std_logic_vector(31 downto 0);

    -- fofb processing loop interlock minimum number of packets per timeframe value register
    -- value
    loop_intlk_min_num_pkts_val_o : out   std_logic_vector(31 downto 0);

    -- RAM port for sps_ram_bank
    sps_ram_bank_adr_i   : in    std_logic_vector(8 downto 0);
    sps_ram_bank_data_rd_i : in    std_logic;
    sps_ram_bank_data_dat_o : out   std_logic_vector(31 downto 0);

    -- RAM port for ch_0_coeff_ram_bank
    ch_0_coeff_ram_bank_adr_i : in    std_logic_vector(8 downto 0);
    ch_0_coeff_ram_bank_data_rd_i : in    std_logic;
    ch_0_coeff_ram_bank_data_dat_o : out   std_logic_vector(31 downto 0);

    -- fofb processing accumulator control register (per channel)
    -- write 0: no effect
    -- write 1: clears accumulator (this bit autoclears)
    ch_0_acc_ctl_clear_o : out   std_logic;
    -- write 0: no effect on accumulator
    -- write 1: freezes accumulator
    ch_0_acc_ctl_freeze_o : out   std_logic;

    -- fofb processing accumulator gain register (per channel)
    -- value
    ch_0_acc_gain_val_o  : out   std_logic_vector(31 downto 0);

    -- fofb processing maximum saturation value register (per channel)
    -- value
    ch_0_sp_limits_max_val_o : out   std_logic_vector(31 downto 0);

    -- fofb processing minimum saturation value register (per channel)
    -- value
    ch_0_sp_limits_min_val_o : out   std_logic_vector(31 downto 0);

    -- RAM port for ch_1_coeff_ram_bank
    ch_1_coeff_ram_bank_adr_i : in    std_logic_vector(8 downto 0);
    ch_1_coeff_ram_bank_data_rd_i : in    std_logic;
    ch_1_coeff_ram_bank_data_dat_o : out   std_logic_vector(31 downto 0);

    -- fofb processing accumulator control register (per channel)
    -- write 0: no effect
    -- write 1: clears accumulator (this bit autoclears)
    ch_1_acc_ctl_clear_o : out   std_logic;
    -- write 0: no effect on accumulator
    -- write 1: freezes accumulator
    ch_1_acc_ctl_freeze_o : out   std_logic;

    -- fofb processing accumulator gain register (per channel)
    -- value
    ch_1_acc_gain_val_o  : out   std_logic_vector(31 downto 0);

    -- fofb processing maximum saturation value register (per channel)
    -- value
    ch_1_sp_limits_max_val_o : out   std_logic_vector(31 downto 0);

    -- fofb processing minimum saturation value register (per channel)
    -- value
    ch_1_sp_limits_min_val_o : out   std_logic_vector(31 downto 0);

    -- RAM port for ch_2_coeff_ram_bank
    ch_2_coeff_ram_bank_adr_i : in    std_logic_vector(8 downto 0);
    ch_2_coeff_ram_bank_data_rd_i : in    std_logic;
    ch_2_coeff_ram_bank_data_dat_o : out   std_logic_vector(31 downto 0);

    -- fofb processing accumulator control register (per channel)
    -- write 0: no effect
    -- write 1: clears accumulator (this bit autoclears)
    ch_2_acc_ctl_clear_o : out   std_logic;
    -- write 0: no effect on accumulator
    -- write 1: freezes accumulator
    ch_2_acc_ctl_freeze_o : out   std_logic;

    -- fofb processing accumulator gain register (per channel)
    -- value
    ch_2_acc_gain_val_o  : out   std_logic_vector(31 downto 0);

    -- fofb processing maximum saturation value register (per channel)
    -- value
    ch_2_sp_limits_max_val_o : out   std_logic_vector(31 downto 0);

    -- fofb processing minimum saturation value register (per channel)
    -- value
    ch_2_sp_limits_min_val_o : out   std_logic_vector(31 downto 0);

    -- RAM port for ch_3_coeff_ram_bank
    ch_3_coeff_ram_bank_adr_i : in    std_logic_vector(8 downto 0);
    ch_3_coeff_ram_bank_data_rd_i : in    std_logic;
    ch_3_coeff_ram_bank_data_dat_o : out   std_logic_vector(31 downto 0);

    -- fofb processing accumulator control register (per channel)
    -- write 0: no effect
    -- write 1: clears accumulator (this bit autoclears)
    ch_3_acc_ctl_clear_o : out   std_logic;
    -- write 0: no effect on accumulator
    -- write 1: freezes accumulator
    ch_3_acc_ctl_freeze_o : out   std_logic;

    -- fofb processing accumulator gain register (per channel)
    -- value
    ch_3_acc_gain_val_o  : out   std_logic_vector(31 downto 0);

    -- fofb processing maximum saturation value register (per channel)
    -- value
    ch_3_sp_limits_max_val_o : out   std_logic_vector(31 downto 0);

    -- fofb processing minimum saturation value register (per channel)
    -- value
    ch_3_sp_limits_min_val_o : out   std_logic_vector(31 downto 0);

    -- RAM port for ch_4_coeff_ram_bank
    ch_4_coeff_ram_bank_adr_i : in    std_logic_vector(8 downto 0);
    ch_4_coeff_ram_bank_data_rd_i : in    std_logic;
    ch_4_coeff_ram_bank_data_dat_o : out   std_logic_vector(31 downto 0);

    -- fofb processing accumulator control register (per channel)
    -- write 0: no effect
    -- write 1: clears accumulator (this bit autoclears)
    ch_4_acc_ctl_clear_o : out   std_logic;
    -- write 0: no effect on accumulator
    -- write 1: freezes accumulator
    ch_4_acc_ctl_freeze_o : out   std_logic;

    -- fofb processing accumulator gain register (per channel)
    -- value
    ch_4_acc_gain_val_o  : out   std_logic_vector(31 downto 0);

    -- fofb processing maximum saturation value register (per channel)
    -- value
    ch_4_sp_limits_max_val_o : out   std_logic_vector(31 downto 0);

    -- fofb processing minimum saturation value register (per channel)
    -- value
    ch_4_sp_limits_min_val_o : out   std_logic_vector(31 downto 0);

    -- RAM port for ch_5_coeff_ram_bank
    ch_5_coeff_ram_bank_adr_i : in    std_logic_vector(8 downto 0);
    ch_5_coeff_ram_bank_data_rd_i : in    std_logic;
    ch_5_coeff_ram_bank_data_dat_o : out   std_logic_vector(31 downto 0);

    -- fofb processing accumulator control register (per channel)
    -- write 0: no effect
    -- write 1: clears accumulator (this bit autoclears)
    ch_5_acc_ctl_clear_o : out   std_logic;
    -- write 0: no effect on accumulator
    -- write 1: freezes accumulator
    ch_5_acc_ctl_freeze_o : out   std_logic;

    -- fofb processing accumulator gain register (per channel)
    -- value
    ch_5_acc_gain_val_o  : out   std_logic_vector(31 downto 0);

    -- fofb processing maximum saturation value register (per channel)
    -- value
    ch_5_sp_limits_max_val_o : out   std_logic_vector(31 downto 0);

    -- fofb processing minimum saturation value register (per channel)
    -- value
    ch_5_sp_limits_min_val_o : out   std_logic_vector(31 downto 0);

    -- RAM port for ch_6_coeff_ram_bank
    ch_6_coeff_ram_bank_adr_i : in    std_logic_vector(8 downto 0);
    ch_6_coeff_ram_bank_data_rd_i : in    std_logic;
    ch_6_coeff_ram_bank_data_dat_o : out   std_logic_vector(31 downto 0);

    -- fofb processing accumulator control register (per channel)
    -- write 0: no effect
    -- write 1: clears accumulator (this bit autoclears)
    ch_6_acc_ctl_clear_o : out   std_logic;
    -- write 0: no effect on accumulator
    -- write 1: freezes accumulator
    ch_6_acc_ctl_freeze_o : out   std_logic;

    -- fofb processing accumulator gain register (per channel)
    -- value
    ch_6_acc_gain_val_o  : out   std_logic_vector(31 downto 0);

    -- fofb processing maximum saturation value register (per channel)
    -- value
    ch_6_sp_limits_max_val_o : out   std_logic_vector(31 downto 0);

    -- fofb processing minimum saturation value register (per channel)
    -- value
    ch_6_sp_limits_min_val_o : out   std_logic_vector(31 downto 0);

    -- RAM port for ch_7_coeff_ram_bank
    ch_7_coeff_ram_bank_adr_i : in    std_logic_vector(8 downto 0);
    ch_7_coeff_ram_bank_data_rd_i : in    std_logic;
    ch_7_coeff_ram_bank_data_dat_o : out   std_logic_vector(31 downto 0);

    -- fofb processing accumulator control register (per channel)
    -- write 0: no effect
    -- write 1: clears accumulator (this bit autoclears)
    ch_7_acc_ctl_clear_o : out   std_logic;
    -- write 0: no effect on accumulator
    -- write 1: freezes accumulator
    ch_7_acc_ctl_freeze_o : out   std_logic;

    -- fofb processing accumulator gain register (per channel)
    -- value
    ch_7_acc_gain_val_o  : out   std_logic_vector(31 downto 0);

    -- fofb processing maximum saturation value register (per channel)
    -- value
    ch_7_sp_limits_max_val_o : out   std_logic_vector(31 downto 0);

    -- fofb processing minimum saturation value register (per channel)
    -- value
    ch_7_sp_limits_min_val_o : out   std_logic_vector(31 downto 0);

    -- RAM port for ch_8_coeff_ram_bank
    ch_8_coeff_ram_bank_adr_i : in    std_logic_vector(8 downto 0);
    ch_8_coeff_ram_bank_data_rd_i : in    std_logic;
    ch_8_coeff_ram_bank_data_dat_o : out   std_logic_vector(31 downto 0);

    -- fofb processing accumulator control register (per channel)
    -- write 0: no effect
    -- write 1: clears accumulator (this bit autoclears)
    ch_8_acc_ctl_clear_o : out   std_logic;
    -- write 0: no effect on accumulator
    -- write 1: freezes accumulator
    ch_8_acc_ctl_freeze_o : out   std_logic;

    -- fofb processing accumulator gain register (per channel)
    -- value
    ch_8_acc_gain_val_o  : out   std_logic_vector(31 downto 0);

    -- fofb processing maximum saturation value register (per channel)
    -- value
    ch_8_sp_limits_max_val_o : out   std_logic_vector(31 downto 0);

    -- fofb processing minimum saturation value register (per channel)
    -- value
    ch_8_sp_limits_min_val_o : out   std_logic_vector(31 downto 0);

    -- RAM port for ch_9_coeff_ram_bank
    ch_9_coeff_ram_bank_adr_i : in    std_logic_vector(8 downto 0);
    ch_9_coeff_ram_bank_data_rd_i : in    std_logic;
    ch_9_coeff_ram_bank_data_dat_o : out   std_logic_vector(31 downto 0);

    -- fofb processing accumulator control register (per channel)
    -- write 0: no effect
    -- write 1: clears accumulator (this bit autoclears)
    ch_9_acc_ctl_clear_o : out   std_logic;
    -- write 0: no effect on accumulator
    -- write 1: freezes accumulator
    ch_9_acc_ctl_freeze_o : out   std_logic;

    -- fofb processing accumulator gain register (per channel)
    -- value
    ch_9_acc_gain_val_o  : out   std_logic_vector(31 downto 0);

    -- fofb processing maximum saturation value register (per channel)
    -- value
    ch_9_sp_limits_max_val_o : out   std_logic_vector(31 downto 0);

    -- fofb processing minimum saturation value register (per channel)
    -- value
    ch_9_sp_limits_min_val_o : out   std_logic_vector(31 downto 0);

    -- RAM port for ch_10_coeff_ram_bank
    ch_10_coeff_ram_bank_adr_i : in    std_logic_vector(8 downto 0);
    ch_10_coeff_ram_bank_data_rd_i : in    std_logic;
    ch_10_coeff_ram_bank_data_dat_o : out   std_logic_vector(31 downto 0);

    -- fofb processing accumulator control register (per channel)
    -- write 0: no effect
    -- write 1: clears accumulator (this bit autoclears)
    ch_10_acc_ctl_clear_o : out   std_logic;
    -- write 0: no effect on accumulator
    -- write 1: freezes accumulator
    ch_10_acc_ctl_freeze_o : out   std_logic;

    -- fofb processing accumulator gain register (per channel)
    -- value
    ch_10_acc_gain_val_o : out   std_logic_vector(31 downto 0);

    -- fofb processing maximum saturation value register (per channel)
    -- value
    ch_10_sp_limits_max_val_o : out   std_logic_vector(31 downto 0);

    -- fofb processing minimum saturation value register (per channel)
    -- value
    ch_10_sp_limits_min_val_o : out   std_logic_vector(31 downto 0);

    -- RAM port for ch_11_coeff_ram_bank
    ch_11_coeff_ram_bank_adr_i : in    std_logic_vector(8 downto 0);
    ch_11_coeff_ram_bank_data_rd_i : in    std_logic;
    ch_11_coeff_ram_bank_data_dat_o : out   std_logic_vector(31 downto 0);

    -- fofb processing accumulator control register (per channel)
    -- write 0: no effect
    -- write 1: clears accumulator (this bit autoclears)
    ch_11_acc_ctl_clear_o : out   std_logic;
    -- write 0: no effect on accumulator
    -- write 1: freezes accumulator
    ch_11_acc_ctl_freeze_o : out   std_logic;

    -- fofb processing accumulator gain register (per channel)
    -- value
    ch_11_acc_gain_val_o : out   std_logic_vector(31 downto 0);

    -- fofb processing maximum saturation value register (per channel)
    -- value
    ch_11_sp_limits_max_val_o : out   std_logic_vector(31 downto 0);

    -- fofb processing minimum saturation value register (per channel)
    -- value
    ch_11_sp_limits_min_val_o : out   std_logic_vector(31 downto 0)
  );
end wb_fofb_processing_regs;

architecture syn of wb_fofb_processing_regs is
  signal adr_int                        : std_logic_vector(15 downto 2);
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal loop_intlk_ctl_sta_clr_reg     : std_logic;
  signal loop_intlk_ctl_src_en_orb_distort_reg : std_logic;
  signal loop_intlk_ctl_src_en_packet_loss_reg : std_logic;
  signal loop_intlk_ctl_wreq            : std_logic;
  signal loop_intlk_ctl_wack            : std_logic;
  signal loop_intlk_orb_distort_limit_val_reg : std_logic_vector(31 downto 0);
  signal loop_intlk_orb_distort_limit_wreq : std_logic;
  signal loop_intlk_orb_distort_limit_wack : std_logic;
  signal loop_intlk_min_num_pkts_val_reg : std_logic_vector(31 downto 0);
  signal loop_intlk_min_num_pkts_wreq   : std_logic;
  signal loop_intlk_min_num_pkts_wack   : std_logic;
  signal sps_ram_bank_data_int_dato     : std_logic_vector(31 downto 0);
  signal sps_ram_bank_data_ext_dat      : std_logic_vector(31 downto 0);
  signal sps_ram_bank_data_rreq         : std_logic;
  signal sps_ram_bank_data_rack         : std_logic;
  signal sps_ram_bank_data_int_wr       : std_logic;
  signal ch_0_coeff_ram_bank_data_int_dato : std_logic_vector(31 downto 0);
  signal ch_0_coeff_ram_bank_data_ext_dat : std_logic_vector(31 downto 0);
  signal ch_0_coeff_ram_bank_data_rreq  : std_logic;
  signal ch_0_coeff_ram_bank_data_rack  : std_logic;
  signal ch_0_coeff_ram_bank_data_int_wr : std_logic;
  signal ch_0_acc_ctl_clear_reg         : std_logic;
  signal ch_0_acc_ctl_freeze_reg        : std_logic;
  signal ch_0_acc_ctl_wreq              : std_logic;
  signal ch_0_acc_ctl_wack              : std_logic;
  signal ch_0_acc_gain_val_reg          : std_logic_vector(31 downto 0);
  signal ch_0_acc_gain_wreq             : std_logic;
  signal ch_0_acc_gain_wack             : std_logic;
  signal ch_0_sp_limits_max_val_reg     : std_logic_vector(31 downto 0);
  signal ch_0_sp_limits_max_wreq        : std_logic;
  signal ch_0_sp_limits_max_wack        : std_logic;
  signal ch_0_sp_limits_min_val_reg     : std_logic_vector(31 downto 0);
  signal ch_0_sp_limits_min_wreq        : std_logic;
  signal ch_0_sp_limits_min_wack        : std_logic;
  signal ch_1_coeff_ram_bank_data_int_dato : std_logic_vector(31 downto 0);
  signal ch_1_coeff_ram_bank_data_ext_dat : std_logic_vector(31 downto 0);
  signal ch_1_coeff_ram_bank_data_rreq  : std_logic;
  signal ch_1_coeff_ram_bank_data_rack  : std_logic;
  signal ch_1_coeff_ram_bank_data_int_wr : std_logic;
  signal ch_1_acc_ctl_clear_reg         : std_logic;
  signal ch_1_acc_ctl_freeze_reg        : std_logic;
  signal ch_1_acc_ctl_wreq              : std_logic;
  signal ch_1_acc_ctl_wack              : std_logic;
  signal ch_1_acc_gain_val_reg          : std_logic_vector(31 downto 0);
  signal ch_1_acc_gain_wreq             : std_logic;
  signal ch_1_acc_gain_wack             : std_logic;
  signal ch_1_sp_limits_max_val_reg     : std_logic_vector(31 downto 0);
  signal ch_1_sp_limits_max_wreq        : std_logic;
  signal ch_1_sp_limits_max_wack        : std_logic;
  signal ch_1_sp_limits_min_val_reg     : std_logic_vector(31 downto 0);
  signal ch_1_sp_limits_min_wreq        : std_logic;
  signal ch_1_sp_limits_min_wack        : std_logic;
  signal ch_2_coeff_ram_bank_data_int_dato : std_logic_vector(31 downto 0);
  signal ch_2_coeff_ram_bank_data_ext_dat : std_logic_vector(31 downto 0);
  signal ch_2_coeff_ram_bank_data_rreq  : std_logic;
  signal ch_2_coeff_ram_bank_data_rack  : std_logic;
  signal ch_2_coeff_ram_bank_data_int_wr : std_logic;
  signal ch_2_acc_ctl_clear_reg         : std_logic;
  signal ch_2_acc_ctl_freeze_reg        : std_logic;
  signal ch_2_acc_ctl_wreq              : std_logic;
  signal ch_2_acc_ctl_wack              : std_logic;
  signal ch_2_acc_gain_val_reg          : std_logic_vector(31 downto 0);
  signal ch_2_acc_gain_wreq             : std_logic;
  signal ch_2_acc_gain_wack             : std_logic;
  signal ch_2_sp_limits_max_val_reg     : std_logic_vector(31 downto 0);
  signal ch_2_sp_limits_max_wreq        : std_logic;
  signal ch_2_sp_limits_max_wack        : std_logic;
  signal ch_2_sp_limits_min_val_reg     : std_logic_vector(31 downto 0);
  signal ch_2_sp_limits_min_wreq        : std_logic;
  signal ch_2_sp_limits_min_wack        : std_logic;
  signal ch_3_coeff_ram_bank_data_int_dato : std_logic_vector(31 downto 0);
  signal ch_3_coeff_ram_bank_data_ext_dat : std_logic_vector(31 downto 0);
  signal ch_3_coeff_ram_bank_data_rreq  : std_logic;
  signal ch_3_coeff_ram_bank_data_rack  : std_logic;
  signal ch_3_coeff_ram_bank_data_int_wr : std_logic;
  signal ch_3_acc_ctl_clear_reg         : std_logic;
  signal ch_3_acc_ctl_freeze_reg        : std_logic;
  signal ch_3_acc_ctl_wreq              : std_logic;
  signal ch_3_acc_ctl_wack              : std_logic;
  signal ch_3_acc_gain_val_reg          : std_logic_vector(31 downto 0);
  signal ch_3_acc_gain_wreq             : std_logic;
  signal ch_3_acc_gain_wack             : std_logic;
  signal ch_3_sp_limits_max_val_reg     : std_logic_vector(31 downto 0);
  signal ch_3_sp_limits_max_wreq        : std_logic;
  signal ch_3_sp_limits_max_wack        : std_logic;
  signal ch_3_sp_limits_min_val_reg     : std_logic_vector(31 downto 0);
  signal ch_3_sp_limits_min_wreq        : std_logic;
  signal ch_3_sp_limits_min_wack        : std_logic;
  signal ch_4_coeff_ram_bank_data_int_dato : std_logic_vector(31 downto 0);
  signal ch_4_coeff_ram_bank_data_ext_dat : std_logic_vector(31 downto 0);
  signal ch_4_coeff_ram_bank_data_rreq  : std_logic;
  signal ch_4_coeff_ram_bank_data_rack  : std_logic;
  signal ch_4_coeff_ram_bank_data_int_wr : std_logic;
  signal ch_4_acc_ctl_clear_reg         : std_logic;
  signal ch_4_acc_ctl_freeze_reg        : std_logic;
  signal ch_4_acc_ctl_wreq              : std_logic;
  signal ch_4_acc_ctl_wack              : std_logic;
  signal ch_4_acc_gain_val_reg          : std_logic_vector(31 downto 0);
  signal ch_4_acc_gain_wreq             : std_logic;
  signal ch_4_acc_gain_wack             : std_logic;
  signal ch_4_sp_limits_max_val_reg     : std_logic_vector(31 downto 0);
  signal ch_4_sp_limits_max_wreq        : std_logic;
  signal ch_4_sp_limits_max_wack        : std_logic;
  signal ch_4_sp_limits_min_val_reg     : std_logic_vector(31 downto 0);
  signal ch_4_sp_limits_min_wreq        : std_logic;
  signal ch_4_sp_limits_min_wack        : std_logic;
  signal ch_5_coeff_ram_bank_data_int_dato : std_logic_vector(31 downto 0);
  signal ch_5_coeff_ram_bank_data_ext_dat : std_logic_vector(31 downto 0);
  signal ch_5_coeff_ram_bank_data_rreq  : std_logic;
  signal ch_5_coeff_ram_bank_data_rack  : std_logic;
  signal ch_5_coeff_ram_bank_data_int_wr : std_logic;
  signal ch_5_acc_ctl_clear_reg         : std_logic;
  signal ch_5_acc_ctl_freeze_reg        : std_logic;
  signal ch_5_acc_ctl_wreq              : std_logic;
  signal ch_5_acc_ctl_wack              : std_logic;
  signal ch_5_acc_gain_val_reg          : std_logic_vector(31 downto 0);
  signal ch_5_acc_gain_wreq             : std_logic;
  signal ch_5_acc_gain_wack             : std_logic;
  signal ch_5_sp_limits_max_val_reg     : std_logic_vector(31 downto 0);
  signal ch_5_sp_limits_max_wreq        : std_logic;
  signal ch_5_sp_limits_max_wack        : std_logic;
  signal ch_5_sp_limits_min_val_reg     : std_logic_vector(31 downto 0);
  signal ch_5_sp_limits_min_wreq        : std_logic;
  signal ch_5_sp_limits_min_wack        : std_logic;
  signal ch_6_coeff_ram_bank_data_int_dato : std_logic_vector(31 downto 0);
  signal ch_6_coeff_ram_bank_data_ext_dat : std_logic_vector(31 downto 0);
  signal ch_6_coeff_ram_bank_data_rreq  : std_logic;
  signal ch_6_coeff_ram_bank_data_rack  : std_logic;
  signal ch_6_coeff_ram_bank_data_int_wr : std_logic;
  signal ch_6_acc_ctl_clear_reg         : std_logic;
  signal ch_6_acc_ctl_freeze_reg        : std_logic;
  signal ch_6_acc_ctl_wreq              : std_logic;
  signal ch_6_acc_ctl_wack              : std_logic;
  signal ch_6_acc_gain_val_reg          : std_logic_vector(31 downto 0);
  signal ch_6_acc_gain_wreq             : std_logic;
  signal ch_6_acc_gain_wack             : std_logic;
  signal ch_6_sp_limits_max_val_reg     : std_logic_vector(31 downto 0);
  signal ch_6_sp_limits_max_wreq        : std_logic;
  signal ch_6_sp_limits_max_wack        : std_logic;
  signal ch_6_sp_limits_min_val_reg     : std_logic_vector(31 downto 0);
  signal ch_6_sp_limits_min_wreq        : std_logic;
  signal ch_6_sp_limits_min_wack        : std_logic;
  signal ch_7_coeff_ram_bank_data_int_dato : std_logic_vector(31 downto 0);
  signal ch_7_coeff_ram_bank_data_ext_dat : std_logic_vector(31 downto 0);
  signal ch_7_coeff_ram_bank_data_rreq  : std_logic;
  signal ch_7_coeff_ram_bank_data_rack  : std_logic;
  signal ch_7_coeff_ram_bank_data_int_wr : std_logic;
  signal ch_7_acc_ctl_clear_reg         : std_logic;
  signal ch_7_acc_ctl_freeze_reg        : std_logic;
  signal ch_7_acc_ctl_wreq              : std_logic;
  signal ch_7_acc_ctl_wack              : std_logic;
  signal ch_7_acc_gain_val_reg          : std_logic_vector(31 downto 0);
  signal ch_7_acc_gain_wreq             : std_logic;
  signal ch_7_acc_gain_wack             : std_logic;
  signal ch_7_sp_limits_max_val_reg     : std_logic_vector(31 downto 0);
  signal ch_7_sp_limits_max_wreq        : std_logic;
  signal ch_7_sp_limits_max_wack        : std_logic;
  signal ch_7_sp_limits_min_val_reg     : std_logic_vector(31 downto 0);
  signal ch_7_sp_limits_min_wreq        : std_logic;
  signal ch_7_sp_limits_min_wack        : std_logic;
  signal ch_8_coeff_ram_bank_data_int_dato : std_logic_vector(31 downto 0);
  signal ch_8_coeff_ram_bank_data_ext_dat : std_logic_vector(31 downto 0);
  signal ch_8_coeff_ram_bank_data_rreq  : std_logic;
  signal ch_8_coeff_ram_bank_data_rack  : std_logic;
  signal ch_8_coeff_ram_bank_data_int_wr : std_logic;
  signal ch_8_acc_ctl_clear_reg         : std_logic;
  signal ch_8_acc_ctl_freeze_reg        : std_logic;
  signal ch_8_acc_ctl_wreq              : std_logic;
  signal ch_8_acc_ctl_wack              : std_logic;
  signal ch_8_acc_gain_val_reg          : std_logic_vector(31 downto 0);
  signal ch_8_acc_gain_wreq             : std_logic;
  signal ch_8_acc_gain_wack             : std_logic;
  signal ch_8_sp_limits_max_val_reg     : std_logic_vector(31 downto 0);
  signal ch_8_sp_limits_max_wreq        : std_logic;
  signal ch_8_sp_limits_max_wack        : std_logic;
  signal ch_8_sp_limits_min_val_reg     : std_logic_vector(31 downto 0);
  signal ch_8_sp_limits_min_wreq        : std_logic;
  signal ch_8_sp_limits_min_wack        : std_logic;
  signal ch_9_coeff_ram_bank_data_int_dato : std_logic_vector(31 downto 0);
  signal ch_9_coeff_ram_bank_data_ext_dat : std_logic_vector(31 downto 0);
  signal ch_9_coeff_ram_bank_data_rreq  : std_logic;
  signal ch_9_coeff_ram_bank_data_rack  : std_logic;
  signal ch_9_coeff_ram_bank_data_int_wr : std_logic;
  signal ch_9_acc_ctl_clear_reg         : std_logic;
  signal ch_9_acc_ctl_freeze_reg        : std_logic;
  signal ch_9_acc_ctl_wreq              : std_logic;
  signal ch_9_acc_ctl_wack              : std_logic;
  signal ch_9_acc_gain_val_reg          : std_logic_vector(31 downto 0);
  signal ch_9_acc_gain_wreq             : std_logic;
  signal ch_9_acc_gain_wack             : std_logic;
  signal ch_9_sp_limits_max_val_reg     : std_logic_vector(31 downto 0);
  signal ch_9_sp_limits_max_wreq        : std_logic;
  signal ch_9_sp_limits_max_wack        : std_logic;
  signal ch_9_sp_limits_min_val_reg     : std_logic_vector(31 downto 0);
  signal ch_9_sp_limits_min_wreq        : std_logic;
  signal ch_9_sp_limits_min_wack        : std_logic;
  signal ch_10_coeff_ram_bank_data_int_dato : std_logic_vector(31 downto 0);
  signal ch_10_coeff_ram_bank_data_ext_dat : std_logic_vector(31 downto 0);
  signal ch_10_coeff_ram_bank_data_rreq : std_logic;
  signal ch_10_coeff_ram_bank_data_rack : std_logic;
  signal ch_10_coeff_ram_bank_data_int_wr : std_logic;
  signal ch_10_acc_ctl_clear_reg        : std_logic;
  signal ch_10_acc_ctl_freeze_reg       : std_logic;
  signal ch_10_acc_ctl_wreq             : std_logic;
  signal ch_10_acc_ctl_wack             : std_logic;
  signal ch_10_acc_gain_val_reg         : std_logic_vector(31 downto 0);
  signal ch_10_acc_gain_wreq            : std_logic;
  signal ch_10_acc_gain_wack            : std_logic;
  signal ch_10_sp_limits_max_val_reg    : std_logic_vector(31 downto 0);
  signal ch_10_sp_limits_max_wreq       : std_logic;
  signal ch_10_sp_limits_max_wack       : std_logic;
  signal ch_10_sp_limits_min_val_reg    : std_logic_vector(31 downto 0);
  signal ch_10_sp_limits_min_wreq       : std_logic;
  signal ch_10_sp_limits_min_wack       : std_logic;
  signal ch_11_coeff_ram_bank_data_int_dato : std_logic_vector(31 downto 0);
  signal ch_11_coeff_ram_bank_data_ext_dat : std_logic_vector(31 downto 0);
  signal ch_11_coeff_ram_bank_data_rreq : std_logic;
  signal ch_11_coeff_ram_bank_data_rack : std_logic;
  signal ch_11_coeff_ram_bank_data_int_wr : std_logic;
  signal ch_11_acc_ctl_clear_reg        : std_logic;
  signal ch_11_acc_ctl_freeze_reg       : std_logic;
  signal ch_11_acc_ctl_wreq             : std_logic;
  signal ch_11_acc_ctl_wack             : std_logic;
  signal ch_11_acc_gain_val_reg         : std_logic_vector(31 downto 0);
  signal ch_11_acc_gain_wreq            : std_logic;
  signal ch_11_acc_gain_wack            : std_logic;
  signal ch_11_sp_limits_max_val_reg    : std_logic_vector(31 downto 0);
  signal ch_11_sp_limits_max_wreq       : std_logic;
  signal ch_11_sp_limits_max_wack       : std_logic;
  signal ch_11_sp_limits_min_val_reg    : std_logic_vector(31 downto 0);
  signal ch_11_sp_limits_min_wreq       : std_logic;
  signal ch_11_sp_limits_min_wack       : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(15 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_sel_d0                      : std_logic_vector(3 downto 0);
  signal sps_ram_bank_wr                : std_logic;
  signal sps_ram_bank_rr                : std_logic;
  signal sps_ram_bank_wreq              : std_logic;
  signal sps_ram_bank_adr_int           : std_logic_vector(8 downto 0);
  signal ch_0_coeff_ram_bank_wr         : std_logic;
  signal ch_0_coeff_ram_bank_rr         : std_logic;
  signal ch_0_coeff_ram_bank_wreq       : std_logic;
  signal ch_0_coeff_ram_bank_adr_int    : std_logic_vector(8 downto 0);
  signal ch_1_coeff_ram_bank_wr         : std_logic;
  signal ch_1_coeff_ram_bank_rr         : std_logic;
  signal ch_1_coeff_ram_bank_wreq       : std_logic;
  signal ch_1_coeff_ram_bank_adr_int    : std_logic_vector(8 downto 0);
  signal ch_2_coeff_ram_bank_wr         : std_logic;
  signal ch_2_coeff_ram_bank_rr         : std_logic;
  signal ch_2_coeff_ram_bank_wreq       : std_logic;
  signal ch_2_coeff_ram_bank_adr_int    : std_logic_vector(8 downto 0);
  signal ch_3_coeff_ram_bank_wr         : std_logic;
  signal ch_3_coeff_ram_bank_rr         : std_logic;
  signal ch_3_coeff_ram_bank_wreq       : std_logic;
  signal ch_3_coeff_ram_bank_adr_int    : std_logic_vector(8 downto 0);
  signal ch_4_coeff_ram_bank_wr         : std_logic;
  signal ch_4_coeff_ram_bank_rr         : std_logic;
  signal ch_4_coeff_ram_bank_wreq       : std_logic;
  signal ch_4_coeff_ram_bank_adr_int    : std_logic_vector(8 downto 0);
  signal ch_5_coeff_ram_bank_wr         : std_logic;
  signal ch_5_coeff_ram_bank_rr         : std_logic;
  signal ch_5_coeff_ram_bank_wreq       : std_logic;
  signal ch_5_coeff_ram_bank_adr_int    : std_logic_vector(8 downto 0);
  signal ch_6_coeff_ram_bank_wr         : std_logic;
  signal ch_6_coeff_ram_bank_rr         : std_logic;
  signal ch_6_coeff_ram_bank_wreq       : std_logic;
  signal ch_6_coeff_ram_bank_adr_int    : std_logic_vector(8 downto 0);
  signal ch_7_coeff_ram_bank_wr         : std_logic;
  signal ch_7_coeff_ram_bank_rr         : std_logic;
  signal ch_7_coeff_ram_bank_wreq       : std_logic;
  signal ch_7_coeff_ram_bank_adr_int    : std_logic_vector(8 downto 0);
  signal ch_8_coeff_ram_bank_wr         : std_logic;
  signal ch_8_coeff_ram_bank_rr         : std_logic;
  signal ch_8_coeff_ram_bank_wreq       : std_logic;
  signal ch_8_coeff_ram_bank_adr_int    : std_logic_vector(8 downto 0);
  signal ch_9_coeff_ram_bank_wr         : std_logic;
  signal ch_9_coeff_ram_bank_rr         : std_logic;
  signal ch_9_coeff_ram_bank_wreq       : std_logic;
  signal ch_9_coeff_ram_bank_adr_int    : std_logic_vector(8 downto 0);
  signal ch_10_coeff_ram_bank_wr        : std_logic;
  signal ch_10_coeff_ram_bank_rr        : std_logic;
  signal ch_10_coeff_ram_bank_wreq      : std_logic;
  signal ch_10_coeff_ram_bank_adr_int   : std_logic_vector(8 downto 0);
  signal ch_11_coeff_ram_bank_wr        : std_logic;
  signal ch_11_coeff_ram_bank_rr        : std_logic;
  signal ch_11_coeff_ram_bank_wreq      : std_logic;
  signal ch_11_coeff_ram_bank_adr_int   : std_logic_vector(8 downto 0);
begin

  -- WB decode signals
  adr_int <= wb_i.adr(15 downto 2);
  wb_en <= wb_i.cyc and wb_i.stb;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_rip <= '0';
      else
        wb_rip <= (wb_rip or (wb_en and not wb_i.we)) and not rd_ack_int;
      end if;
    end if;
  end process;
  rd_req_int <= (wb_en and not wb_i.we) and not wb_rip;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_wip <= '0';
      else
        wb_wip <= (wb_wip or (wb_en and wb_i.we)) and not wr_ack_int;
      end if;
    end if;
  end process;
  wr_req_int <= (wb_en and wb_i.we) and not wb_wip;

  ack_int <= rd_ack_int or wr_ack_int;
  wb_o.ack <= ack_int;
  wb_o.stall <= not ack_int and wb_en;
  wb_o.rty <= '0';
  wb_o.err <= '0';

  -- pipelining for wr-in+rd-out
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rd_ack_int <= '0';
        wr_req_d0 <= '0';
      else
        rd_ack_int <= rd_ack_d0;
        wb_o.dat <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_adr_d0 <= adr_int;
        wr_dat_d0 <= wb_i.dat;
        wr_sel_d0 <= wb_i.sel;
      end if;
    end if;
  end process;

  -- Register fixed_point_pos_coeff

  -- Register fixed_point_pos_accs_gains

  -- Register loop_intlk_ctl
  loop_intlk_ctl_sta_clr_o <= loop_intlk_ctl_sta_clr_reg;
  loop_intlk_ctl_src_en_orb_distort_o <= loop_intlk_ctl_src_en_orb_distort_reg;
  loop_intlk_ctl_src_en_packet_loss_o <= loop_intlk_ctl_src_en_packet_loss_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        loop_intlk_ctl_sta_clr_reg <= '0';
        loop_intlk_ctl_src_en_orb_distort_reg <= '0';
        loop_intlk_ctl_src_en_packet_loss_reg <= '0';
        loop_intlk_ctl_wack <= '0';
      else
        if loop_intlk_ctl_wreq = '1' then
          loop_intlk_ctl_sta_clr_reg <= wr_dat_d0(0);
          loop_intlk_ctl_src_en_orb_distort_reg <= wr_dat_d0(1);
          loop_intlk_ctl_src_en_packet_loss_reg <= wr_dat_d0(2);
        else
          loop_intlk_ctl_sta_clr_reg <= '0';
        end if;
        loop_intlk_ctl_wack <= loop_intlk_ctl_wreq;
      end if;
    end if;
  end process;

  -- Register loop_intlk_sta

  -- Register loop_intlk_orb_distort_limit
  loop_intlk_orb_distort_limit_val_o <= loop_intlk_orb_distort_limit_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        loop_intlk_orb_distort_limit_val_reg <= "00000000000000000000000000000000";
        loop_intlk_orb_distort_limit_wack <= '0';
      else
        if loop_intlk_orb_distort_limit_wreq = '1' then
          loop_intlk_orb_distort_limit_val_reg <= wr_dat_d0;
        end if;
        loop_intlk_orb_distort_limit_wack <= loop_intlk_orb_distort_limit_wreq;
      end if;
    end if;
  end process;

  -- Register loop_intlk_min_num_pkts
  loop_intlk_min_num_pkts_val_o <= loop_intlk_min_num_pkts_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        loop_intlk_min_num_pkts_val_reg <= "00000000000000000000000000000000";
        loop_intlk_min_num_pkts_wack <= '0';
      else
        if loop_intlk_min_num_pkts_wreq = '1' then
          loop_intlk_min_num_pkts_val_reg <= wr_dat_d0;
        end if;
        loop_intlk_min_num_pkts_wack <= loop_intlk_min_num_pkts_wreq;
      end if;
    end if;
  end process;

  -- Memory sps_ram_bank
  process (adr_int, wr_adr_d0, sps_ram_bank_wr) begin
    if sps_ram_bank_wr = '1' then
      sps_ram_bank_adr_int <= wr_adr_d0(10 downto 2);
    else
      sps_ram_bank_adr_int <= adr_int(10 downto 2);
    end if;
  end process;
  sps_ram_bank_wreq <= sps_ram_bank_data_int_wr;
  sps_ram_bank_rr <= sps_ram_bank_data_rreq and not sps_ram_bank_wreq;
  sps_ram_bank_wr <= sps_ram_bank_wreq;
  sps_ram_bank_data_raminst: cheby_dpssram
    generic map (
      g_data_width         => 32,
      g_size               => 512,
      g_addr_width         => 9,
      g_dual_clock         => '0',
      g_use_bwsel          => '1'
    )
    port map (
      clk_a_i              => clk_i,
      clk_b_i              => clk_i,
      addr_a_i             => sps_ram_bank_adr_int,
      bwsel_a_i            => wr_sel_d0,
      data_a_i             => wr_dat_d0,
      data_a_o             => sps_ram_bank_data_int_dato,
      rd_a_i               => sps_ram_bank_data_rreq,
      wr_a_i               => sps_ram_bank_data_int_wr,
      addr_b_i             => sps_ram_bank_adr_i,
      bwsel_b_i            => (others => '1'),
      data_b_i             => sps_ram_bank_data_ext_dat,
      data_b_o             => sps_ram_bank_data_dat_o,
      rd_b_i               => sps_ram_bank_data_rd_i,
      wr_b_i               => '0'
    );
  
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        sps_ram_bank_data_rack <= '0';
      else
        sps_ram_bank_data_rack <= sps_ram_bank_data_rreq;
      end if;
    end if;
  end process;

  -- Memory ch_0_coeff_ram_bank
  process (adr_int, wr_adr_d0, ch_0_coeff_ram_bank_wr) begin
    if ch_0_coeff_ram_bank_wr = '1' then
      ch_0_coeff_ram_bank_adr_int <= wr_adr_d0(10 downto 2);
    else
      ch_0_coeff_ram_bank_adr_int <= adr_int(10 downto 2);
    end if;
  end process;
  ch_0_coeff_ram_bank_wreq <= ch_0_coeff_ram_bank_data_int_wr;
  ch_0_coeff_ram_bank_rr <= ch_0_coeff_ram_bank_data_rreq and not ch_0_coeff_ram_bank_wreq;
  ch_0_coeff_ram_bank_wr <= ch_0_coeff_ram_bank_wreq;
  ch_0_coeff_ram_bank_data_raminst: cheby_dpssram
    generic map (
      g_data_width         => 32,
      g_size               => 512,
      g_addr_width         => 9,
      g_dual_clock         => '0',
      g_use_bwsel          => '1'
    )
    port map (
      clk_a_i              => clk_i,
      clk_b_i              => clk_i,
      addr_a_i             => ch_0_coeff_ram_bank_adr_int,
      bwsel_a_i            => wr_sel_d0,
      data_a_i             => wr_dat_d0,
      data_a_o             => ch_0_coeff_ram_bank_data_int_dato,
      rd_a_i               => ch_0_coeff_ram_bank_data_rreq,
      wr_a_i               => ch_0_coeff_ram_bank_data_int_wr,
      addr_b_i             => ch_0_coeff_ram_bank_adr_i,
      bwsel_b_i            => (others => '1'),
      data_b_i             => ch_0_coeff_ram_bank_data_ext_dat,
      data_b_o             => ch_0_coeff_ram_bank_data_dat_o,
      rd_b_i               => ch_0_coeff_ram_bank_data_rd_i,
      wr_b_i               => '0'
    );
  
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_0_coeff_ram_bank_data_rack <= '0';
      else
        ch_0_coeff_ram_bank_data_rack <= ch_0_coeff_ram_bank_data_rreq;
      end if;
    end if;
  end process;

  -- Register ch_0_acc_ctl
  ch_0_acc_ctl_clear_o <= ch_0_acc_ctl_clear_reg;
  ch_0_acc_ctl_freeze_o <= ch_0_acc_ctl_freeze_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_0_acc_ctl_clear_reg <= '0';
        ch_0_acc_ctl_freeze_reg <= '0';
        ch_0_acc_ctl_wack <= '0';
      else
        if ch_0_acc_ctl_wreq = '1' then
          ch_0_acc_ctl_clear_reg <= wr_dat_d0(0);
          ch_0_acc_ctl_freeze_reg <= wr_dat_d0(1);
        else
          ch_0_acc_ctl_clear_reg <= '0';
        end if;
        ch_0_acc_ctl_wack <= ch_0_acc_ctl_wreq;
      end if;
    end if;
  end process;

  -- Register ch_0_acc_gain
  ch_0_acc_gain_val_o <= ch_0_acc_gain_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_0_acc_gain_val_reg <= "00000000000000000000000000000000";
        ch_0_acc_gain_wack <= '0';
      else
        if ch_0_acc_gain_wreq = '1' then
          ch_0_acc_gain_val_reg <= wr_dat_d0;
        end if;
        ch_0_acc_gain_wack <= ch_0_acc_gain_wreq;
      end if;
    end if;
  end process;

  -- Register ch_0_sp_limits_max
  ch_0_sp_limits_max_val_o <= ch_0_sp_limits_max_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_0_sp_limits_max_val_reg <= "00000000000000000000000000000000";
        ch_0_sp_limits_max_wack <= '0';
      else
        if ch_0_sp_limits_max_wreq = '1' then
          ch_0_sp_limits_max_val_reg <= wr_dat_d0;
        end if;
        ch_0_sp_limits_max_wack <= ch_0_sp_limits_max_wreq;
      end if;
    end if;
  end process;

  -- Register ch_0_sp_limits_min
  ch_0_sp_limits_min_val_o <= ch_0_sp_limits_min_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_0_sp_limits_min_val_reg <= "00000000000000000000000000000000";
        ch_0_sp_limits_min_wack <= '0';
      else
        if ch_0_sp_limits_min_wreq = '1' then
          ch_0_sp_limits_min_val_reg <= wr_dat_d0;
        end if;
        ch_0_sp_limits_min_wack <= ch_0_sp_limits_min_wreq;
      end if;
    end if;
  end process;

  -- Memory ch_1_coeff_ram_bank
  process (adr_int, wr_adr_d0, ch_1_coeff_ram_bank_wr) begin
    if ch_1_coeff_ram_bank_wr = '1' then
      ch_1_coeff_ram_bank_adr_int <= wr_adr_d0(10 downto 2);
    else
      ch_1_coeff_ram_bank_adr_int <= adr_int(10 downto 2);
    end if;
  end process;
  ch_1_coeff_ram_bank_wreq <= ch_1_coeff_ram_bank_data_int_wr;
  ch_1_coeff_ram_bank_rr <= ch_1_coeff_ram_bank_data_rreq and not ch_1_coeff_ram_bank_wreq;
  ch_1_coeff_ram_bank_wr <= ch_1_coeff_ram_bank_wreq;
  ch_1_coeff_ram_bank_data_raminst: cheby_dpssram
    generic map (
      g_data_width         => 32,
      g_size               => 512,
      g_addr_width         => 9,
      g_dual_clock         => '0',
      g_use_bwsel          => '1'
    )
    port map (
      clk_a_i              => clk_i,
      clk_b_i              => clk_i,
      addr_a_i             => ch_1_coeff_ram_bank_adr_int,
      bwsel_a_i            => wr_sel_d0,
      data_a_i             => wr_dat_d0,
      data_a_o             => ch_1_coeff_ram_bank_data_int_dato,
      rd_a_i               => ch_1_coeff_ram_bank_data_rreq,
      wr_a_i               => ch_1_coeff_ram_bank_data_int_wr,
      addr_b_i             => ch_1_coeff_ram_bank_adr_i,
      bwsel_b_i            => (others => '1'),
      data_b_i             => ch_1_coeff_ram_bank_data_ext_dat,
      data_b_o             => ch_1_coeff_ram_bank_data_dat_o,
      rd_b_i               => ch_1_coeff_ram_bank_data_rd_i,
      wr_b_i               => '0'
    );
  
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_1_coeff_ram_bank_data_rack <= '0';
      else
        ch_1_coeff_ram_bank_data_rack <= ch_1_coeff_ram_bank_data_rreq;
      end if;
    end if;
  end process;

  -- Register ch_1_acc_ctl
  ch_1_acc_ctl_clear_o <= ch_1_acc_ctl_clear_reg;
  ch_1_acc_ctl_freeze_o <= ch_1_acc_ctl_freeze_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_1_acc_ctl_clear_reg <= '0';
        ch_1_acc_ctl_freeze_reg <= '0';
        ch_1_acc_ctl_wack <= '0';
      else
        if ch_1_acc_ctl_wreq = '1' then
          ch_1_acc_ctl_clear_reg <= wr_dat_d0(0);
          ch_1_acc_ctl_freeze_reg <= wr_dat_d0(1);
        else
          ch_1_acc_ctl_clear_reg <= '0';
        end if;
        ch_1_acc_ctl_wack <= ch_1_acc_ctl_wreq;
      end if;
    end if;
  end process;

  -- Register ch_1_acc_gain
  ch_1_acc_gain_val_o <= ch_1_acc_gain_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_1_acc_gain_val_reg <= "00000000000000000000000000000000";
        ch_1_acc_gain_wack <= '0';
      else
        if ch_1_acc_gain_wreq = '1' then
          ch_1_acc_gain_val_reg <= wr_dat_d0;
        end if;
        ch_1_acc_gain_wack <= ch_1_acc_gain_wreq;
      end if;
    end if;
  end process;

  -- Register ch_1_sp_limits_max
  ch_1_sp_limits_max_val_o <= ch_1_sp_limits_max_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_1_sp_limits_max_val_reg <= "00000000000000000000000000000000";
        ch_1_sp_limits_max_wack <= '0';
      else
        if ch_1_sp_limits_max_wreq = '1' then
          ch_1_sp_limits_max_val_reg <= wr_dat_d0;
        end if;
        ch_1_sp_limits_max_wack <= ch_1_sp_limits_max_wreq;
      end if;
    end if;
  end process;

  -- Register ch_1_sp_limits_min
  ch_1_sp_limits_min_val_o <= ch_1_sp_limits_min_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_1_sp_limits_min_val_reg <= "00000000000000000000000000000000";
        ch_1_sp_limits_min_wack <= '0';
      else
        if ch_1_sp_limits_min_wreq = '1' then
          ch_1_sp_limits_min_val_reg <= wr_dat_d0;
        end if;
        ch_1_sp_limits_min_wack <= ch_1_sp_limits_min_wreq;
      end if;
    end if;
  end process;

  -- Memory ch_2_coeff_ram_bank
  process (adr_int, wr_adr_d0, ch_2_coeff_ram_bank_wr) begin
    if ch_2_coeff_ram_bank_wr = '1' then
      ch_2_coeff_ram_bank_adr_int <= wr_adr_d0(10 downto 2);
    else
      ch_2_coeff_ram_bank_adr_int <= adr_int(10 downto 2);
    end if;
  end process;
  ch_2_coeff_ram_bank_wreq <= ch_2_coeff_ram_bank_data_int_wr;
  ch_2_coeff_ram_bank_rr <= ch_2_coeff_ram_bank_data_rreq and not ch_2_coeff_ram_bank_wreq;
  ch_2_coeff_ram_bank_wr <= ch_2_coeff_ram_bank_wreq;
  ch_2_coeff_ram_bank_data_raminst: cheby_dpssram
    generic map (
      g_data_width         => 32,
      g_size               => 512,
      g_addr_width         => 9,
      g_dual_clock         => '0',
      g_use_bwsel          => '1'
    )
    port map (
      clk_a_i              => clk_i,
      clk_b_i              => clk_i,
      addr_a_i             => ch_2_coeff_ram_bank_adr_int,
      bwsel_a_i            => wr_sel_d0,
      data_a_i             => wr_dat_d0,
      data_a_o             => ch_2_coeff_ram_bank_data_int_dato,
      rd_a_i               => ch_2_coeff_ram_bank_data_rreq,
      wr_a_i               => ch_2_coeff_ram_bank_data_int_wr,
      addr_b_i             => ch_2_coeff_ram_bank_adr_i,
      bwsel_b_i            => (others => '1'),
      data_b_i             => ch_2_coeff_ram_bank_data_ext_dat,
      data_b_o             => ch_2_coeff_ram_bank_data_dat_o,
      rd_b_i               => ch_2_coeff_ram_bank_data_rd_i,
      wr_b_i               => '0'
    );
  
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_2_coeff_ram_bank_data_rack <= '0';
      else
        ch_2_coeff_ram_bank_data_rack <= ch_2_coeff_ram_bank_data_rreq;
      end if;
    end if;
  end process;

  -- Register ch_2_acc_ctl
  ch_2_acc_ctl_clear_o <= ch_2_acc_ctl_clear_reg;
  ch_2_acc_ctl_freeze_o <= ch_2_acc_ctl_freeze_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_2_acc_ctl_clear_reg <= '0';
        ch_2_acc_ctl_freeze_reg <= '0';
        ch_2_acc_ctl_wack <= '0';
      else
        if ch_2_acc_ctl_wreq = '1' then
          ch_2_acc_ctl_clear_reg <= wr_dat_d0(0);
          ch_2_acc_ctl_freeze_reg <= wr_dat_d0(1);
        else
          ch_2_acc_ctl_clear_reg <= '0';
        end if;
        ch_2_acc_ctl_wack <= ch_2_acc_ctl_wreq;
      end if;
    end if;
  end process;

  -- Register ch_2_acc_gain
  ch_2_acc_gain_val_o <= ch_2_acc_gain_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_2_acc_gain_val_reg <= "00000000000000000000000000000000";
        ch_2_acc_gain_wack <= '0';
      else
        if ch_2_acc_gain_wreq = '1' then
          ch_2_acc_gain_val_reg <= wr_dat_d0;
        end if;
        ch_2_acc_gain_wack <= ch_2_acc_gain_wreq;
      end if;
    end if;
  end process;

  -- Register ch_2_sp_limits_max
  ch_2_sp_limits_max_val_o <= ch_2_sp_limits_max_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_2_sp_limits_max_val_reg <= "00000000000000000000000000000000";
        ch_2_sp_limits_max_wack <= '0';
      else
        if ch_2_sp_limits_max_wreq = '1' then
          ch_2_sp_limits_max_val_reg <= wr_dat_d0;
        end if;
        ch_2_sp_limits_max_wack <= ch_2_sp_limits_max_wreq;
      end if;
    end if;
  end process;

  -- Register ch_2_sp_limits_min
  ch_2_sp_limits_min_val_o <= ch_2_sp_limits_min_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_2_sp_limits_min_val_reg <= "00000000000000000000000000000000";
        ch_2_sp_limits_min_wack <= '0';
      else
        if ch_2_sp_limits_min_wreq = '1' then
          ch_2_sp_limits_min_val_reg <= wr_dat_d0;
        end if;
        ch_2_sp_limits_min_wack <= ch_2_sp_limits_min_wreq;
      end if;
    end if;
  end process;

  -- Memory ch_3_coeff_ram_bank
  process (adr_int, wr_adr_d0, ch_3_coeff_ram_bank_wr) begin
    if ch_3_coeff_ram_bank_wr = '1' then
      ch_3_coeff_ram_bank_adr_int <= wr_adr_d0(10 downto 2);
    else
      ch_3_coeff_ram_bank_adr_int <= adr_int(10 downto 2);
    end if;
  end process;
  ch_3_coeff_ram_bank_wreq <= ch_3_coeff_ram_bank_data_int_wr;
  ch_3_coeff_ram_bank_rr <= ch_3_coeff_ram_bank_data_rreq and not ch_3_coeff_ram_bank_wreq;
  ch_3_coeff_ram_bank_wr <= ch_3_coeff_ram_bank_wreq;
  ch_3_coeff_ram_bank_data_raminst: cheby_dpssram
    generic map (
      g_data_width         => 32,
      g_size               => 512,
      g_addr_width         => 9,
      g_dual_clock         => '0',
      g_use_bwsel          => '1'
    )
    port map (
      clk_a_i              => clk_i,
      clk_b_i              => clk_i,
      addr_a_i             => ch_3_coeff_ram_bank_adr_int,
      bwsel_a_i            => wr_sel_d0,
      data_a_i             => wr_dat_d0,
      data_a_o             => ch_3_coeff_ram_bank_data_int_dato,
      rd_a_i               => ch_3_coeff_ram_bank_data_rreq,
      wr_a_i               => ch_3_coeff_ram_bank_data_int_wr,
      addr_b_i             => ch_3_coeff_ram_bank_adr_i,
      bwsel_b_i            => (others => '1'),
      data_b_i             => ch_3_coeff_ram_bank_data_ext_dat,
      data_b_o             => ch_3_coeff_ram_bank_data_dat_o,
      rd_b_i               => ch_3_coeff_ram_bank_data_rd_i,
      wr_b_i               => '0'
    );
  
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_3_coeff_ram_bank_data_rack <= '0';
      else
        ch_3_coeff_ram_bank_data_rack <= ch_3_coeff_ram_bank_data_rreq;
      end if;
    end if;
  end process;

  -- Register ch_3_acc_ctl
  ch_3_acc_ctl_clear_o <= ch_3_acc_ctl_clear_reg;
  ch_3_acc_ctl_freeze_o <= ch_3_acc_ctl_freeze_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_3_acc_ctl_clear_reg <= '0';
        ch_3_acc_ctl_freeze_reg <= '0';
        ch_3_acc_ctl_wack <= '0';
      else
        if ch_3_acc_ctl_wreq = '1' then
          ch_3_acc_ctl_clear_reg <= wr_dat_d0(0);
          ch_3_acc_ctl_freeze_reg <= wr_dat_d0(1);
        else
          ch_3_acc_ctl_clear_reg <= '0';
        end if;
        ch_3_acc_ctl_wack <= ch_3_acc_ctl_wreq;
      end if;
    end if;
  end process;

  -- Register ch_3_acc_gain
  ch_3_acc_gain_val_o <= ch_3_acc_gain_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_3_acc_gain_val_reg <= "00000000000000000000000000000000";
        ch_3_acc_gain_wack <= '0';
      else
        if ch_3_acc_gain_wreq = '1' then
          ch_3_acc_gain_val_reg <= wr_dat_d0;
        end if;
        ch_3_acc_gain_wack <= ch_3_acc_gain_wreq;
      end if;
    end if;
  end process;

  -- Register ch_3_sp_limits_max
  ch_3_sp_limits_max_val_o <= ch_3_sp_limits_max_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_3_sp_limits_max_val_reg <= "00000000000000000000000000000000";
        ch_3_sp_limits_max_wack <= '0';
      else
        if ch_3_sp_limits_max_wreq = '1' then
          ch_3_sp_limits_max_val_reg <= wr_dat_d0;
        end if;
        ch_3_sp_limits_max_wack <= ch_3_sp_limits_max_wreq;
      end if;
    end if;
  end process;

  -- Register ch_3_sp_limits_min
  ch_3_sp_limits_min_val_o <= ch_3_sp_limits_min_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_3_sp_limits_min_val_reg <= "00000000000000000000000000000000";
        ch_3_sp_limits_min_wack <= '0';
      else
        if ch_3_sp_limits_min_wreq = '1' then
          ch_3_sp_limits_min_val_reg <= wr_dat_d0;
        end if;
        ch_3_sp_limits_min_wack <= ch_3_sp_limits_min_wreq;
      end if;
    end if;
  end process;

  -- Memory ch_4_coeff_ram_bank
  process (adr_int, wr_adr_d0, ch_4_coeff_ram_bank_wr) begin
    if ch_4_coeff_ram_bank_wr = '1' then
      ch_4_coeff_ram_bank_adr_int <= wr_adr_d0(10 downto 2);
    else
      ch_4_coeff_ram_bank_adr_int <= adr_int(10 downto 2);
    end if;
  end process;
  ch_4_coeff_ram_bank_wreq <= ch_4_coeff_ram_bank_data_int_wr;
  ch_4_coeff_ram_bank_rr <= ch_4_coeff_ram_bank_data_rreq and not ch_4_coeff_ram_bank_wreq;
  ch_4_coeff_ram_bank_wr <= ch_4_coeff_ram_bank_wreq;
  ch_4_coeff_ram_bank_data_raminst: cheby_dpssram
    generic map (
      g_data_width         => 32,
      g_size               => 512,
      g_addr_width         => 9,
      g_dual_clock         => '0',
      g_use_bwsel          => '1'
    )
    port map (
      clk_a_i              => clk_i,
      clk_b_i              => clk_i,
      addr_a_i             => ch_4_coeff_ram_bank_adr_int,
      bwsel_a_i            => wr_sel_d0,
      data_a_i             => wr_dat_d0,
      data_a_o             => ch_4_coeff_ram_bank_data_int_dato,
      rd_a_i               => ch_4_coeff_ram_bank_data_rreq,
      wr_a_i               => ch_4_coeff_ram_bank_data_int_wr,
      addr_b_i             => ch_4_coeff_ram_bank_adr_i,
      bwsel_b_i            => (others => '1'),
      data_b_i             => ch_4_coeff_ram_bank_data_ext_dat,
      data_b_o             => ch_4_coeff_ram_bank_data_dat_o,
      rd_b_i               => ch_4_coeff_ram_bank_data_rd_i,
      wr_b_i               => '0'
    );
  
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_4_coeff_ram_bank_data_rack <= '0';
      else
        ch_4_coeff_ram_bank_data_rack <= ch_4_coeff_ram_bank_data_rreq;
      end if;
    end if;
  end process;

  -- Register ch_4_acc_ctl
  ch_4_acc_ctl_clear_o <= ch_4_acc_ctl_clear_reg;
  ch_4_acc_ctl_freeze_o <= ch_4_acc_ctl_freeze_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_4_acc_ctl_clear_reg <= '0';
        ch_4_acc_ctl_freeze_reg <= '0';
        ch_4_acc_ctl_wack <= '0';
      else
        if ch_4_acc_ctl_wreq = '1' then
          ch_4_acc_ctl_clear_reg <= wr_dat_d0(0);
          ch_4_acc_ctl_freeze_reg <= wr_dat_d0(1);
        else
          ch_4_acc_ctl_clear_reg <= '0';
        end if;
        ch_4_acc_ctl_wack <= ch_4_acc_ctl_wreq;
      end if;
    end if;
  end process;

  -- Register ch_4_acc_gain
  ch_4_acc_gain_val_o <= ch_4_acc_gain_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_4_acc_gain_val_reg <= "00000000000000000000000000000000";
        ch_4_acc_gain_wack <= '0';
      else
        if ch_4_acc_gain_wreq = '1' then
          ch_4_acc_gain_val_reg <= wr_dat_d0;
        end if;
        ch_4_acc_gain_wack <= ch_4_acc_gain_wreq;
      end if;
    end if;
  end process;

  -- Register ch_4_sp_limits_max
  ch_4_sp_limits_max_val_o <= ch_4_sp_limits_max_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_4_sp_limits_max_val_reg <= "00000000000000000000000000000000";
        ch_4_sp_limits_max_wack <= '0';
      else
        if ch_4_sp_limits_max_wreq = '1' then
          ch_4_sp_limits_max_val_reg <= wr_dat_d0;
        end if;
        ch_4_sp_limits_max_wack <= ch_4_sp_limits_max_wreq;
      end if;
    end if;
  end process;

  -- Register ch_4_sp_limits_min
  ch_4_sp_limits_min_val_o <= ch_4_sp_limits_min_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_4_sp_limits_min_val_reg <= "00000000000000000000000000000000";
        ch_4_sp_limits_min_wack <= '0';
      else
        if ch_4_sp_limits_min_wreq = '1' then
          ch_4_sp_limits_min_val_reg <= wr_dat_d0;
        end if;
        ch_4_sp_limits_min_wack <= ch_4_sp_limits_min_wreq;
      end if;
    end if;
  end process;

  -- Memory ch_5_coeff_ram_bank
  process (adr_int, wr_adr_d0, ch_5_coeff_ram_bank_wr) begin
    if ch_5_coeff_ram_bank_wr = '1' then
      ch_5_coeff_ram_bank_adr_int <= wr_adr_d0(10 downto 2);
    else
      ch_5_coeff_ram_bank_adr_int <= adr_int(10 downto 2);
    end if;
  end process;
  ch_5_coeff_ram_bank_wreq <= ch_5_coeff_ram_bank_data_int_wr;
  ch_5_coeff_ram_bank_rr <= ch_5_coeff_ram_bank_data_rreq and not ch_5_coeff_ram_bank_wreq;
  ch_5_coeff_ram_bank_wr <= ch_5_coeff_ram_bank_wreq;
  ch_5_coeff_ram_bank_data_raminst: cheby_dpssram
    generic map (
      g_data_width         => 32,
      g_size               => 512,
      g_addr_width         => 9,
      g_dual_clock         => '0',
      g_use_bwsel          => '1'
    )
    port map (
      clk_a_i              => clk_i,
      clk_b_i              => clk_i,
      addr_a_i             => ch_5_coeff_ram_bank_adr_int,
      bwsel_a_i            => wr_sel_d0,
      data_a_i             => wr_dat_d0,
      data_a_o             => ch_5_coeff_ram_bank_data_int_dato,
      rd_a_i               => ch_5_coeff_ram_bank_data_rreq,
      wr_a_i               => ch_5_coeff_ram_bank_data_int_wr,
      addr_b_i             => ch_5_coeff_ram_bank_adr_i,
      bwsel_b_i            => (others => '1'),
      data_b_i             => ch_5_coeff_ram_bank_data_ext_dat,
      data_b_o             => ch_5_coeff_ram_bank_data_dat_o,
      rd_b_i               => ch_5_coeff_ram_bank_data_rd_i,
      wr_b_i               => '0'
    );
  
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_5_coeff_ram_bank_data_rack <= '0';
      else
        ch_5_coeff_ram_bank_data_rack <= ch_5_coeff_ram_bank_data_rreq;
      end if;
    end if;
  end process;

  -- Register ch_5_acc_ctl
  ch_5_acc_ctl_clear_o <= ch_5_acc_ctl_clear_reg;
  ch_5_acc_ctl_freeze_o <= ch_5_acc_ctl_freeze_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_5_acc_ctl_clear_reg <= '0';
        ch_5_acc_ctl_freeze_reg <= '0';
        ch_5_acc_ctl_wack <= '0';
      else
        if ch_5_acc_ctl_wreq = '1' then
          ch_5_acc_ctl_clear_reg <= wr_dat_d0(0);
          ch_5_acc_ctl_freeze_reg <= wr_dat_d0(1);
        else
          ch_5_acc_ctl_clear_reg <= '0';
        end if;
        ch_5_acc_ctl_wack <= ch_5_acc_ctl_wreq;
      end if;
    end if;
  end process;

  -- Register ch_5_acc_gain
  ch_5_acc_gain_val_o <= ch_5_acc_gain_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_5_acc_gain_val_reg <= "00000000000000000000000000000000";
        ch_5_acc_gain_wack <= '0';
      else
        if ch_5_acc_gain_wreq = '1' then
          ch_5_acc_gain_val_reg <= wr_dat_d0;
        end if;
        ch_5_acc_gain_wack <= ch_5_acc_gain_wreq;
      end if;
    end if;
  end process;

  -- Register ch_5_sp_limits_max
  ch_5_sp_limits_max_val_o <= ch_5_sp_limits_max_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_5_sp_limits_max_val_reg <= "00000000000000000000000000000000";
        ch_5_sp_limits_max_wack <= '0';
      else
        if ch_5_sp_limits_max_wreq = '1' then
          ch_5_sp_limits_max_val_reg <= wr_dat_d0;
        end if;
        ch_5_sp_limits_max_wack <= ch_5_sp_limits_max_wreq;
      end if;
    end if;
  end process;

  -- Register ch_5_sp_limits_min
  ch_5_sp_limits_min_val_o <= ch_5_sp_limits_min_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_5_sp_limits_min_val_reg <= "00000000000000000000000000000000";
        ch_5_sp_limits_min_wack <= '0';
      else
        if ch_5_sp_limits_min_wreq = '1' then
          ch_5_sp_limits_min_val_reg <= wr_dat_d0;
        end if;
        ch_5_sp_limits_min_wack <= ch_5_sp_limits_min_wreq;
      end if;
    end if;
  end process;

  -- Memory ch_6_coeff_ram_bank
  process (adr_int, wr_adr_d0, ch_6_coeff_ram_bank_wr) begin
    if ch_6_coeff_ram_bank_wr = '1' then
      ch_6_coeff_ram_bank_adr_int <= wr_adr_d0(10 downto 2);
    else
      ch_6_coeff_ram_bank_adr_int <= adr_int(10 downto 2);
    end if;
  end process;
  ch_6_coeff_ram_bank_wreq <= ch_6_coeff_ram_bank_data_int_wr;
  ch_6_coeff_ram_bank_rr <= ch_6_coeff_ram_bank_data_rreq and not ch_6_coeff_ram_bank_wreq;
  ch_6_coeff_ram_bank_wr <= ch_6_coeff_ram_bank_wreq;
  ch_6_coeff_ram_bank_data_raminst: cheby_dpssram
    generic map (
      g_data_width         => 32,
      g_size               => 512,
      g_addr_width         => 9,
      g_dual_clock         => '0',
      g_use_bwsel          => '1'
    )
    port map (
      clk_a_i              => clk_i,
      clk_b_i              => clk_i,
      addr_a_i             => ch_6_coeff_ram_bank_adr_int,
      bwsel_a_i            => wr_sel_d0,
      data_a_i             => wr_dat_d0,
      data_a_o             => ch_6_coeff_ram_bank_data_int_dato,
      rd_a_i               => ch_6_coeff_ram_bank_data_rreq,
      wr_a_i               => ch_6_coeff_ram_bank_data_int_wr,
      addr_b_i             => ch_6_coeff_ram_bank_adr_i,
      bwsel_b_i            => (others => '1'),
      data_b_i             => ch_6_coeff_ram_bank_data_ext_dat,
      data_b_o             => ch_6_coeff_ram_bank_data_dat_o,
      rd_b_i               => ch_6_coeff_ram_bank_data_rd_i,
      wr_b_i               => '0'
    );
  
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_6_coeff_ram_bank_data_rack <= '0';
      else
        ch_6_coeff_ram_bank_data_rack <= ch_6_coeff_ram_bank_data_rreq;
      end if;
    end if;
  end process;

  -- Register ch_6_acc_ctl
  ch_6_acc_ctl_clear_o <= ch_6_acc_ctl_clear_reg;
  ch_6_acc_ctl_freeze_o <= ch_6_acc_ctl_freeze_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_6_acc_ctl_clear_reg <= '0';
        ch_6_acc_ctl_freeze_reg <= '0';
        ch_6_acc_ctl_wack <= '0';
      else
        if ch_6_acc_ctl_wreq = '1' then
          ch_6_acc_ctl_clear_reg <= wr_dat_d0(0);
          ch_6_acc_ctl_freeze_reg <= wr_dat_d0(1);
        else
          ch_6_acc_ctl_clear_reg <= '0';
        end if;
        ch_6_acc_ctl_wack <= ch_6_acc_ctl_wreq;
      end if;
    end if;
  end process;

  -- Register ch_6_acc_gain
  ch_6_acc_gain_val_o <= ch_6_acc_gain_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_6_acc_gain_val_reg <= "00000000000000000000000000000000";
        ch_6_acc_gain_wack <= '0';
      else
        if ch_6_acc_gain_wreq = '1' then
          ch_6_acc_gain_val_reg <= wr_dat_d0;
        end if;
        ch_6_acc_gain_wack <= ch_6_acc_gain_wreq;
      end if;
    end if;
  end process;

  -- Register ch_6_sp_limits_max
  ch_6_sp_limits_max_val_o <= ch_6_sp_limits_max_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_6_sp_limits_max_val_reg <= "00000000000000000000000000000000";
        ch_6_sp_limits_max_wack <= '0';
      else
        if ch_6_sp_limits_max_wreq = '1' then
          ch_6_sp_limits_max_val_reg <= wr_dat_d0;
        end if;
        ch_6_sp_limits_max_wack <= ch_6_sp_limits_max_wreq;
      end if;
    end if;
  end process;

  -- Register ch_6_sp_limits_min
  ch_6_sp_limits_min_val_o <= ch_6_sp_limits_min_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_6_sp_limits_min_val_reg <= "00000000000000000000000000000000";
        ch_6_sp_limits_min_wack <= '0';
      else
        if ch_6_sp_limits_min_wreq = '1' then
          ch_6_sp_limits_min_val_reg <= wr_dat_d0;
        end if;
        ch_6_sp_limits_min_wack <= ch_6_sp_limits_min_wreq;
      end if;
    end if;
  end process;

  -- Memory ch_7_coeff_ram_bank
  process (adr_int, wr_adr_d0, ch_7_coeff_ram_bank_wr) begin
    if ch_7_coeff_ram_bank_wr = '1' then
      ch_7_coeff_ram_bank_adr_int <= wr_adr_d0(10 downto 2);
    else
      ch_7_coeff_ram_bank_adr_int <= adr_int(10 downto 2);
    end if;
  end process;
  ch_7_coeff_ram_bank_wreq <= ch_7_coeff_ram_bank_data_int_wr;
  ch_7_coeff_ram_bank_rr <= ch_7_coeff_ram_bank_data_rreq and not ch_7_coeff_ram_bank_wreq;
  ch_7_coeff_ram_bank_wr <= ch_7_coeff_ram_bank_wreq;
  ch_7_coeff_ram_bank_data_raminst: cheby_dpssram
    generic map (
      g_data_width         => 32,
      g_size               => 512,
      g_addr_width         => 9,
      g_dual_clock         => '0',
      g_use_bwsel          => '1'
    )
    port map (
      clk_a_i              => clk_i,
      clk_b_i              => clk_i,
      addr_a_i             => ch_7_coeff_ram_bank_adr_int,
      bwsel_a_i            => wr_sel_d0,
      data_a_i             => wr_dat_d0,
      data_a_o             => ch_7_coeff_ram_bank_data_int_dato,
      rd_a_i               => ch_7_coeff_ram_bank_data_rreq,
      wr_a_i               => ch_7_coeff_ram_bank_data_int_wr,
      addr_b_i             => ch_7_coeff_ram_bank_adr_i,
      bwsel_b_i            => (others => '1'),
      data_b_i             => ch_7_coeff_ram_bank_data_ext_dat,
      data_b_o             => ch_7_coeff_ram_bank_data_dat_o,
      rd_b_i               => ch_7_coeff_ram_bank_data_rd_i,
      wr_b_i               => '0'
    );
  
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_7_coeff_ram_bank_data_rack <= '0';
      else
        ch_7_coeff_ram_bank_data_rack <= ch_7_coeff_ram_bank_data_rreq;
      end if;
    end if;
  end process;

  -- Register ch_7_acc_ctl
  ch_7_acc_ctl_clear_o <= ch_7_acc_ctl_clear_reg;
  ch_7_acc_ctl_freeze_o <= ch_7_acc_ctl_freeze_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_7_acc_ctl_clear_reg <= '0';
        ch_7_acc_ctl_freeze_reg <= '0';
        ch_7_acc_ctl_wack <= '0';
      else
        if ch_7_acc_ctl_wreq = '1' then
          ch_7_acc_ctl_clear_reg <= wr_dat_d0(0);
          ch_7_acc_ctl_freeze_reg <= wr_dat_d0(1);
        else
          ch_7_acc_ctl_clear_reg <= '0';
        end if;
        ch_7_acc_ctl_wack <= ch_7_acc_ctl_wreq;
      end if;
    end if;
  end process;

  -- Register ch_7_acc_gain
  ch_7_acc_gain_val_o <= ch_7_acc_gain_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_7_acc_gain_val_reg <= "00000000000000000000000000000000";
        ch_7_acc_gain_wack <= '0';
      else
        if ch_7_acc_gain_wreq = '1' then
          ch_7_acc_gain_val_reg <= wr_dat_d0;
        end if;
        ch_7_acc_gain_wack <= ch_7_acc_gain_wreq;
      end if;
    end if;
  end process;

  -- Register ch_7_sp_limits_max
  ch_7_sp_limits_max_val_o <= ch_7_sp_limits_max_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_7_sp_limits_max_val_reg <= "00000000000000000000000000000000";
        ch_7_sp_limits_max_wack <= '0';
      else
        if ch_7_sp_limits_max_wreq = '1' then
          ch_7_sp_limits_max_val_reg <= wr_dat_d0;
        end if;
        ch_7_sp_limits_max_wack <= ch_7_sp_limits_max_wreq;
      end if;
    end if;
  end process;

  -- Register ch_7_sp_limits_min
  ch_7_sp_limits_min_val_o <= ch_7_sp_limits_min_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_7_sp_limits_min_val_reg <= "00000000000000000000000000000000";
        ch_7_sp_limits_min_wack <= '0';
      else
        if ch_7_sp_limits_min_wreq = '1' then
          ch_7_sp_limits_min_val_reg <= wr_dat_d0;
        end if;
        ch_7_sp_limits_min_wack <= ch_7_sp_limits_min_wreq;
      end if;
    end if;
  end process;

  -- Memory ch_8_coeff_ram_bank
  process (adr_int, wr_adr_d0, ch_8_coeff_ram_bank_wr) begin
    if ch_8_coeff_ram_bank_wr = '1' then
      ch_8_coeff_ram_bank_adr_int <= wr_adr_d0(10 downto 2);
    else
      ch_8_coeff_ram_bank_adr_int <= adr_int(10 downto 2);
    end if;
  end process;
  ch_8_coeff_ram_bank_wreq <= ch_8_coeff_ram_bank_data_int_wr;
  ch_8_coeff_ram_bank_rr <= ch_8_coeff_ram_bank_data_rreq and not ch_8_coeff_ram_bank_wreq;
  ch_8_coeff_ram_bank_wr <= ch_8_coeff_ram_bank_wreq;
  ch_8_coeff_ram_bank_data_raminst: cheby_dpssram
    generic map (
      g_data_width         => 32,
      g_size               => 512,
      g_addr_width         => 9,
      g_dual_clock         => '0',
      g_use_bwsel          => '1'
    )
    port map (
      clk_a_i              => clk_i,
      clk_b_i              => clk_i,
      addr_a_i             => ch_8_coeff_ram_bank_adr_int,
      bwsel_a_i            => wr_sel_d0,
      data_a_i             => wr_dat_d0,
      data_a_o             => ch_8_coeff_ram_bank_data_int_dato,
      rd_a_i               => ch_8_coeff_ram_bank_data_rreq,
      wr_a_i               => ch_8_coeff_ram_bank_data_int_wr,
      addr_b_i             => ch_8_coeff_ram_bank_adr_i,
      bwsel_b_i            => (others => '1'),
      data_b_i             => ch_8_coeff_ram_bank_data_ext_dat,
      data_b_o             => ch_8_coeff_ram_bank_data_dat_o,
      rd_b_i               => ch_8_coeff_ram_bank_data_rd_i,
      wr_b_i               => '0'
    );
  
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_8_coeff_ram_bank_data_rack <= '0';
      else
        ch_8_coeff_ram_bank_data_rack <= ch_8_coeff_ram_bank_data_rreq;
      end if;
    end if;
  end process;

  -- Register ch_8_acc_ctl
  ch_8_acc_ctl_clear_o <= ch_8_acc_ctl_clear_reg;
  ch_8_acc_ctl_freeze_o <= ch_8_acc_ctl_freeze_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_8_acc_ctl_clear_reg <= '0';
        ch_8_acc_ctl_freeze_reg <= '0';
        ch_8_acc_ctl_wack <= '0';
      else
        if ch_8_acc_ctl_wreq = '1' then
          ch_8_acc_ctl_clear_reg <= wr_dat_d0(0);
          ch_8_acc_ctl_freeze_reg <= wr_dat_d0(1);
        else
          ch_8_acc_ctl_clear_reg <= '0';
        end if;
        ch_8_acc_ctl_wack <= ch_8_acc_ctl_wreq;
      end if;
    end if;
  end process;

  -- Register ch_8_acc_gain
  ch_8_acc_gain_val_o <= ch_8_acc_gain_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_8_acc_gain_val_reg <= "00000000000000000000000000000000";
        ch_8_acc_gain_wack <= '0';
      else
        if ch_8_acc_gain_wreq = '1' then
          ch_8_acc_gain_val_reg <= wr_dat_d0;
        end if;
        ch_8_acc_gain_wack <= ch_8_acc_gain_wreq;
      end if;
    end if;
  end process;

  -- Register ch_8_sp_limits_max
  ch_8_sp_limits_max_val_o <= ch_8_sp_limits_max_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_8_sp_limits_max_val_reg <= "00000000000000000000000000000000";
        ch_8_sp_limits_max_wack <= '0';
      else
        if ch_8_sp_limits_max_wreq = '1' then
          ch_8_sp_limits_max_val_reg <= wr_dat_d0;
        end if;
        ch_8_sp_limits_max_wack <= ch_8_sp_limits_max_wreq;
      end if;
    end if;
  end process;

  -- Register ch_8_sp_limits_min
  ch_8_sp_limits_min_val_o <= ch_8_sp_limits_min_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_8_sp_limits_min_val_reg <= "00000000000000000000000000000000";
        ch_8_sp_limits_min_wack <= '0';
      else
        if ch_8_sp_limits_min_wreq = '1' then
          ch_8_sp_limits_min_val_reg <= wr_dat_d0;
        end if;
        ch_8_sp_limits_min_wack <= ch_8_sp_limits_min_wreq;
      end if;
    end if;
  end process;

  -- Memory ch_9_coeff_ram_bank
  process (adr_int, wr_adr_d0, ch_9_coeff_ram_bank_wr) begin
    if ch_9_coeff_ram_bank_wr = '1' then
      ch_9_coeff_ram_bank_adr_int <= wr_adr_d0(10 downto 2);
    else
      ch_9_coeff_ram_bank_adr_int <= adr_int(10 downto 2);
    end if;
  end process;
  ch_9_coeff_ram_bank_wreq <= ch_9_coeff_ram_bank_data_int_wr;
  ch_9_coeff_ram_bank_rr <= ch_9_coeff_ram_bank_data_rreq and not ch_9_coeff_ram_bank_wreq;
  ch_9_coeff_ram_bank_wr <= ch_9_coeff_ram_bank_wreq;
  ch_9_coeff_ram_bank_data_raminst: cheby_dpssram
    generic map (
      g_data_width         => 32,
      g_size               => 512,
      g_addr_width         => 9,
      g_dual_clock         => '0',
      g_use_bwsel          => '1'
    )
    port map (
      clk_a_i              => clk_i,
      clk_b_i              => clk_i,
      addr_a_i             => ch_9_coeff_ram_bank_adr_int,
      bwsel_a_i            => wr_sel_d0,
      data_a_i             => wr_dat_d0,
      data_a_o             => ch_9_coeff_ram_bank_data_int_dato,
      rd_a_i               => ch_9_coeff_ram_bank_data_rreq,
      wr_a_i               => ch_9_coeff_ram_bank_data_int_wr,
      addr_b_i             => ch_9_coeff_ram_bank_adr_i,
      bwsel_b_i            => (others => '1'),
      data_b_i             => ch_9_coeff_ram_bank_data_ext_dat,
      data_b_o             => ch_9_coeff_ram_bank_data_dat_o,
      rd_b_i               => ch_9_coeff_ram_bank_data_rd_i,
      wr_b_i               => '0'
    );
  
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_9_coeff_ram_bank_data_rack <= '0';
      else
        ch_9_coeff_ram_bank_data_rack <= ch_9_coeff_ram_bank_data_rreq;
      end if;
    end if;
  end process;

  -- Register ch_9_acc_ctl
  ch_9_acc_ctl_clear_o <= ch_9_acc_ctl_clear_reg;
  ch_9_acc_ctl_freeze_o <= ch_9_acc_ctl_freeze_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_9_acc_ctl_clear_reg <= '0';
        ch_9_acc_ctl_freeze_reg <= '0';
        ch_9_acc_ctl_wack <= '0';
      else
        if ch_9_acc_ctl_wreq = '1' then
          ch_9_acc_ctl_clear_reg <= wr_dat_d0(0);
          ch_9_acc_ctl_freeze_reg <= wr_dat_d0(1);
        else
          ch_9_acc_ctl_clear_reg <= '0';
        end if;
        ch_9_acc_ctl_wack <= ch_9_acc_ctl_wreq;
      end if;
    end if;
  end process;

  -- Register ch_9_acc_gain
  ch_9_acc_gain_val_o <= ch_9_acc_gain_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_9_acc_gain_val_reg <= "00000000000000000000000000000000";
        ch_9_acc_gain_wack <= '0';
      else
        if ch_9_acc_gain_wreq = '1' then
          ch_9_acc_gain_val_reg <= wr_dat_d0;
        end if;
        ch_9_acc_gain_wack <= ch_9_acc_gain_wreq;
      end if;
    end if;
  end process;

  -- Register ch_9_sp_limits_max
  ch_9_sp_limits_max_val_o <= ch_9_sp_limits_max_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_9_sp_limits_max_val_reg <= "00000000000000000000000000000000";
        ch_9_sp_limits_max_wack <= '0';
      else
        if ch_9_sp_limits_max_wreq = '1' then
          ch_9_sp_limits_max_val_reg <= wr_dat_d0;
        end if;
        ch_9_sp_limits_max_wack <= ch_9_sp_limits_max_wreq;
      end if;
    end if;
  end process;

  -- Register ch_9_sp_limits_min
  ch_9_sp_limits_min_val_o <= ch_9_sp_limits_min_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_9_sp_limits_min_val_reg <= "00000000000000000000000000000000";
        ch_9_sp_limits_min_wack <= '0';
      else
        if ch_9_sp_limits_min_wreq = '1' then
          ch_9_sp_limits_min_val_reg <= wr_dat_d0;
        end if;
        ch_9_sp_limits_min_wack <= ch_9_sp_limits_min_wreq;
      end if;
    end if;
  end process;

  -- Memory ch_10_coeff_ram_bank
  process (adr_int, wr_adr_d0, ch_10_coeff_ram_bank_wr) begin
    if ch_10_coeff_ram_bank_wr = '1' then
      ch_10_coeff_ram_bank_adr_int <= wr_adr_d0(10 downto 2);
    else
      ch_10_coeff_ram_bank_adr_int <= adr_int(10 downto 2);
    end if;
  end process;
  ch_10_coeff_ram_bank_wreq <= ch_10_coeff_ram_bank_data_int_wr;
  ch_10_coeff_ram_bank_rr <= ch_10_coeff_ram_bank_data_rreq and not ch_10_coeff_ram_bank_wreq;
  ch_10_coeff_ram_bank_wr <= ch_10_coeff_ram_bank_wreq;
  ch_10_coeff_ram_bank_data_raminst: cheby_dpssram
    generic map (
      g_data_width         => 32,
      g_size               => 512,
      g_addr_width         => 9,
      g_dual_clock         => '0',
      g_use_bwsel          => '1'
    )
    port map (
      clk_a_i              => clk_i,
      clk_b_i              => clk_i,
      addr_a_i             => ch_10_coeff_ram_bank_adr_int,
      bwsel_a_i            => wr_sel_d0,
      data_a_i             => wr_dat_d0,
      data_a_o             => ch_10_coeff_ram_bank_data_int_dato,
      rd_a_i               => ch_10_coeff_ram_bank_data_rreq,
      wr_a_i               => ch_10_coeff_ram_bank_data_int_wr,
      addr_b_i             => ch_10_coeff_ram_bank_adr_i,
      bwsel_b_i            => (others => '1'),
      data_b_i             => ch_10_coeff_ram_bank_data_ext_dat,
      data_b_o             => ch_10_coeff_ram_bank_data_dat_o,
      rd_b_i               => ch_10_coeff_ram_bank_data_rd_i,
      wr_b_i               => '0'
    );
  
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_10_coeff_ram_bank_data_rack <= '0';
      else
        ch_10_coeff_ram_bank_data_rack <= ch_10_coeff_ram_bank_data_rreq;
      end if;
    end if;
  end process;

  -- Register ch_10_acc_ctl
  ch_10_acc_ctl_clear_o <= ch_10_acc_ctl_clear_reg;
  ch_10_acc_ctl_freeze_o <= ch_10_acc_ctl_freeze_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_10_acc_ctl_clear_reg <= '0';
        ch_10_acc_ctl_freeze_reg <= '0';
        ch_10_acc_ctl_wack <= '0';
      else
        if ch_10_acc_ctl_wreq = '1' then
          ch_10_acc_ctl_clear_reg <= wr_dat_d0(0);
          ch_10_acc_ctl_freeze_reg <= wr_dat_d0(1);
        else
          ch_10_acc_ctl_clear_reg <= '0';
        end if;
        ch_10_acc_ctl_wack <= ch_10_acc_ctl_wreq;
      end if;
    end if;
  end process;

  -- Register ch_10_acc_gain
  ch_10_acc_gain_val_o <= ch_10_acc_gain_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_10_acc_gain_val_reg <= "00000000000000000000000000000000";
        ch_10_acc_gain_wack <= '0';
      else
        if ch_10_acc_gain_wreq = '1' then
          ch_10_acc_gain_val_reg <= wr_dat_d0;
        end if;
        ch_10_acc_gain_wack <= ch_10_acc_gain_wreq;
      end if;
    end if;
  end process;

  -- Register ch_10_sp_limits_max
  ch_10_sp_limits_max_val_o <= ch_10_sp_limits_max_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_10_sp_limits_max_val_reg <= "00000000000000000000000000000000";
        ch_10_sp_limits_max_wack <= '0';
      else
        if ch_10_sp_limits_max_wreq = '1' then
          ch_10_sp_limits_max_val_reg <= wr_dat_d0;
        end if;
        ch_10_sp_limits_max_wack <= ch_10_sp_limits_max_wreq;
      end if;
    end if;
  end process;

  -- Register ch_10_sp_limits_min
  ch_10_sp_limits_min_val_o <= ch_10_sp_limits_min_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_10_sp_limits_min_val_reg <= "00000000000000000000000000000000";
        ch_10_sp_limits_min_wack <= '0';
      else
        if ch_10_sp_limits_min_wreq = '1' then
          ch_10_sp_limits_min_val_reg <= wr_dat_d0;
        end if;
        ch_10_sp_limits_min_wack <= ch_10_sp_limits_min_wreq;
      end if;
    end if;
  end process;

  -- Memory ch_11_coeff_ram_bank
  process (adr_int, wr_adr_d0, ch_11_coeff_ram_bank_wr) begin
    if ch_11_coeff_ram_bank_wr = '1' then
      ch_11_coeff_ram_bank_adr_int <= wr_adr_d0(10 downto 2);
    else
      ch_11_coeff_ram_bank_adr_int <= adr_int(10 downto 2);
    end if;
  end process;
  ch_11_coeff_ram_bank_wreq <= ch_11_coeff_ram_bank_data_int_wr;
  ch_11_coeff_ram_bank_rr <= ch_11_coeff_ram_bank_data_rreq and not ch_11_coeff_ram_bank_wreq;
  ch_11_coeff_ram_bank_wr <= ch_11_coeff_ram_bank_wreq;
  ch_11_coeff_ram_bank_data_raminst: cheby_dpssram
    generic map (
      g_data_width         => 32,
      g_size               => 512,
      g_addr_width         => 9,
      g_dual_clock         => '0',
      g_use_bwsel          => '1'
    )
    port map (
      clk_a_i              => clk_i,
      clk_b_i              => clk_i,
      addr_a_i             => ch_11_coeff_ram_bank_adr_int,
      bwsel_a_i            => wr_sel_d0,
      data_a_i             => wr_dat_d0,
      data_a_o             => ch_11_coeff_ram_bank_data_int_dato,
      rd_a_i               => ch_11_coeff_ram_bank_data_rreq,
      wr_a_i               => ch_11_coeff_ram_bank_data_int_wr,
      addr_b_i             => ch_11_coeff_ram_bank_adr_i,
      bwsel_b_i            => (others => '1'),
      data_b_i             => ch_11_coeff_ram_bank_data_ext_dat,
      data_b_o             => ch_11_coeff_ram_bank_data_dat_o,
      rd_b_i               => ch_11_coeff_ram_bank_data_rd_i,
      wr_b_i               => '0'
    );
  
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_11_coeff_ram_bank_data_rack <= '0';
      else
        ch_11_coeff_ram_bank_data_rack <= ch_11_coeff_ram_bank_data_rreq;
      end if;
    end if;
  end process;

  -- Register ch_11_acc_ctl
  ch_11_acc_ctl_clear_o <= ch_11_acc_ctl_clear_reg;
  ch_11_acc_ctl_freeze_o <= ch_11_acc_ctl_freeze_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_11_acc_ctl_clear_reg <= '0';
        ch_11_acc_ctl_freeze_reg <= '0';
        ch_11_acc_ctl_wack <= '0';
      else
        if ch_11_acc_ctl_wreq = '1' then
          ch_11_acc_ctl_clear_reg <= wr_dat_d0(0);
          ch_11_acc_ctl_freeze_reg <= wr_dat_d0(1);
        else
          ch_11_acc_ctl_clear_reg <= '0';
        end if;
        ch_11_acc_ctl_wack <= ch_11_acc_ctl_wreq;
      end if;
    end if;
  end process;

  -- Register ch_11_acc_gain
  ch_11_acc_gain_val_o <= ch_11_acc_gain_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_11_acc_gain_val_reg <= "00000000000000000000000000000000";
        ch_11_acc_gain_wack <= '0';
      else
        if ch_11_acc_gain_wreq = '1' then
          ch_11_acc_gain_val_reg <= wr_dat_d0;
        end if;
        ch_11_acc_gain_wack <= ch_11_acc_gain_wreq;
      end if;
    end if;
  end process;

  -- Register ch_11_sp_limits_max
  ch_11_sp_limits_max_val_o <= ch_11_sp_limits_max_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_11_sp_limits_max_val_reg <= "00000000000000000000000000000000";
        ch_11_sp_limits_max_wack <= '0';
      else
        if ch_11_sp_limits_max_wreq = '1' then
          ch_11_sp_limits_max_val_reg <= wr_dat_d0;
        end if;
        ch_11_sp_limits_max_wack <= ch_11_sp_limits_max_wreq;
      end if;
    end if;
  end process;

  -- Register ch_11_sp_limits_min
  ch_11_sp_limits_min_val_o <= ch_11_sp_limits_min_val_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch_11_sp_limits_min_val_reg <= "00000000000000000000000000000000";
        ch_11_sp_limits_min_wack <= '0';
      else
        if ch_11_sp_limits_min_wreq = '1' then
          ch_11_sp_limits_min_val_reg <= wr_dat_d0;
        end if;
        ch_11_sp_limits_min_wack <= ch_11_sp_limits_min_wreq;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, loop_intlk_ctl_wack, loop_intlk_orb_distort_limit_wack, loop_intlk_min_num_pkts_wack, ch_0_acc_ctl_wack, ch_0_acc_gain_wack, ch_0_sp_limits_max_wack, ch_0_sp_limits_min_wack, ch_1_acc_ctl_wack, ch_1_acc_gain_wack, ch_1_sp_limits_max_wack, ch_1_sp_limits_min_wack, ch_2_acc_ctl_wack, ch_2_acc_gain_wack, ch_2_sp_limits_max_wack, ch_2_sp_limits_min_wack, ch_3_acc_ctl_wack, ch_3_acc_gain_wack, ch_3_sp_limits_max_wack, ch_3_sp_limits_min_wack, ch_4_acc_ctl_wack, ch_4_acc_gain_wack, ch_4_sp_limits_max_wack, ch_4_sp_limits_min_wack, ch_5_acc_ctl_wack, ch_5_acc_gain_wack, ch_5_sp_limits_max_wack, ch_5_sp_limits_min_wack, ch_6_acc_ctl_wack, ch_6_acc_gain_wack, ch_6_sp_limits_max_wack, ch_6_sp_limits_min_wack, ch_7_acc_ctl_wack, ch_7_acc_gain_wack, ch_7_sp_limits_max_wack, ch_7_sp_limits_min_wack, ch_8_acc_ctl_wack, ch_8_acc_gain_wack, ch_8_sp_limits_max_wack, ch_8_sp_limits_min_wack, ch_9_acc_ctl_wack, ch_9_acc_gain_wack, ch_9_sp_limits_max_wack, ch_9_sp_limits_min_wack, ch_10_acc_ctl_wack, ch_10_acc_gain_wack, ch_10_sp_limits_max_wack, ch_10_sp_limits_min_wack, ch_11_acc_ctl_wack, ch_11_acc_gain_wack, ch_11_sp_limits_max_wack, ch_11_sp_limits_min_wack) begin
    loop_intlk_ctl_wreq <= '0';
    loop_intlk_orb_distort_limit_wreq <= '0';
    loop_intlk_min_num_pkts_wreq <= '0';
    sps_ram_bank_data_int_wr <= '0';
    ch_0_coeff_ram_bank_data_int_wr <= '0';
    ch_0_acc_ctl_wreq <= '0';
    ch_0_acc_gain_wreq <= '0';
    ch_0_sp_limits_max_wreq <= '0';
    ch_0_sp_limits_min_wreq <= '0';
    ch_1_coeff_ram_bank_data_int_wr <= '0';
    ch_1_acc_ctl_wreq <= '0';
    ch_1_acc_gain_wreq <= '0';
    ch_1_sp_limits_max_wreq <= '0';
    ch_1_sp_limits_min_wreq <= '0';
    ch_2_coeff_ram_bank_data_int_wr <= '0';
    ch_2_acc_ctl_wreq <= '0';
    ch_2_acc_gain_wreq <= '0';
    ch_2_sp_limits_max_wreq <= '0';
    ch_2_sp_limits_min_wreq <= '0';
    ch_3_coeff_ram_bank_data_int_wr <= '0';
    ch_3_acc_ctl_wreq <= '0';
    ch_3_acc_gain_wreq <= '0';
    ch_3_sp_limits_max_wreq <= '0';
    ch_3_sp_limits_min_wreq <= '0';
    ch_4_coeff_ram_bank_data_int_wr <= '0';
    ch_4_acc_ctl_wreq <= '0';
    ch_4_acc_gain_wreq <= '0';
    ch_4_sp_limits_max_wreq <= '0';
    ch_4_sp_limits_min_wreq <= '0';
    ch_5_coeff_ram_bank_data_int_wr <= '0';
    ch_5_acc_ctl_wreq <= '0';
    ch_5_acc_gain_wreq <= '0';
    ch_5_sp_limits_max_wreq <= '0';
    ch_5_sp_limits_min_wreq <= '0';
    ch_6_coeff_ram_bank_data_int_wr <= '0';
    ch_6_acc_ctl_wreq <= '0';
    ch_6_acc_gain_wreq <= '0';
    ch_6_sp_limits_max_wreq <= '0';
    ch_6_sp_limits_min_wreq <= '0';
    ch_7_coeff_ram_bank_data_int_wr <= '0';
    ch_7_acc_ctl_wreq <= '0';
    ch_7_acc_gain_wreq <= '0';
    ch_7_sp_limits_max_wreq <= '0';
    ch_7_sp_limits_min_wreq <= '0';
    ch_8_coeff_ram_bank_data_int_wr <= '0';
    ch_8_acc_ctl_wreq <= '0';
    ch_8_acc_gain_wreq <= '0';
    ch_8_sp_limits_max_wreq <= '0';
    ch_8_sp_limits_min_wreq <= '0';
    ch_9_coeff_ram_bank_data_int_wr <= '0';
    ch_9_acc_ctl_wreq <= '0';
    ch_9_acc_gain_wreq <= '0';
    ch_9_sp_limits_max_wreq <= '0';
    ch_9_sp_limits_min_wreq <= '0';
    ch_10_coeff_ram_bank_data_int_wr <= '0';
    ch_10_acc_ctl_wreq <= '0';
    ch_10_acc_gain_wreq <= '0';
    ch_10_sp_limits_max_wreq <= '0';
    ch_10_sp_limits_min_wreq <= '0';
    ch_11_coeff_ram_bank_data_int_wr <= '0';
    ch_11_acc_ctl_wreq <= '0';
    ch_11_acc_gain_wreq <= '0';
    ch_11_sp_limits_max_wreq <= '0';
    ch_11_sp_limits_min_wreq <= '0';
    case wr_adr_d0(15 downto 11) is
    when "00000" =>
      case wr_adr_d0(10 downto 2) is
      when "000000000" =>
        -- Reg fixed_point_pos_coeff
        wr_ack_int <= wr_req_d0;
      when "000000001" =>
        -- Reg fixed_point_pos_accs_gains
        wr_ack_int <= wr_req_d0;
      when "000010000" =>
        -- Reg loop_intlk_ctl
        loop_intlk_ctl_wreq <= wr_req_d0;
        wr_ack_int <= loop_intlk_ctl_wack;
      when "000010001" =>
        -- Reg loop_intlk_sta
        wr_ack_int <= wr_req_d0;
      when "000010010" =>
        -- Reg loop_intlk_orb_distort_limit
        loop_intlk_orb_distort_limit_wreq <= wr_req_d0;
        wr_ack_int <= loop_intlk_orb_distort_limit_wack;
      when "000010011" =>
        -- Reg loop_intlk_min_num_pkts
        loop_intlk_min_num_pkts_wreq <= wr_req_d0;
        wr_ack_int <= loop_intlk_min_num_pkts_wack;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "00001" =>
      -- Memory sps_ram_bank
      sps_ram_bank_data_int_wr <= wr_req_d0;
      wr_ack_int <= wr_req_d0;
    when "00010" =>
      -- Memory ch_0_coeff_ram_bank
      ch_0_coeff_ram_bank_data_int_wr <= wr_req_d0;
      wr_ack_int <= wr_req_d0;
    when "00011" =>
      case wr_adr_d0(10 downto 2) is
      when "000000000" =>
        -- Reg ch_0_acc_ctl
        ch_0_acc_ctl_wreq <= wr_req_d0;
        wr_ack_int <= ch_0_acc_ctl_wack;
      when "000000001" =>
        -- Reg ch_0_acc_gain
        ch_0_acc_gain_wreq <= wr_req_d0;
        wr_ack_int <= ch_0_acc_gain_wack;
      when "000001000" =>
        -- Reg ch_0_sp_limits_max
        ch_0_sp_limits_max_wreq <= wr_req_d0;
        wr_ack_int <= ch_0_sp_limits_max_wack;
      when "000001001" =>
        -- Reg ch_0_sp_limits_min
        ch_0_sp_limits_min_wreq <= wr_req_d0;
        wr_ack_int <= ch_0_sp_limits_min_wack;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "00100" =>
      -- Memory ch_1_coeff_ram_bank
      ch_1_coeff_ram_bank_data_int_wr <= wr_req_d0;
      wr_ack_int <= wr_req_d0;
    when "00101" =>
      case wr_adr_d0(10 downto 2) is
      when "000000000" =>
        -- Reg ch_1_acc_ctl
        ch_1_acc_ctl_wreq <= wr_req_d0;
        wr_ack_int <= ch_1_acc_ctl_wack;
      when "000000001" =>
        -- Reg ch_1_acc_gain
        ch_1_acc_gain_wreq <= wr_req_d0;
        wr_ack_int <= ch_1_acc_gain_wack;
      when "000001000" =>
        -- Reg ch_1_sp_limits_max
        ch_1_sp_limits_max_wreq <= wr_req_d0;
        wr_ack_int <= ch_1_sp_limits_max_wack;
      when "000001001" =>
        -- Reg ch_1_sp_limits_min
        ch_1_sp_limits_min_wreq <= wr_req_d0;
        wr_ack_int <= ch_1_sp_limits_min_wack;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "00110" =>
      -- Memory ch_2_coeff_ram_bank
      ch_2_coeff_ram_bank_data_int_wr <= wr_req_d0;
      wr_ack_int <= wr_req_d0;
    when "00111" =>
      case wr_adr_d0(10 downto 2) is
      when "000000000" =>
        -- Reg ch_2_acc_ctl
        ch_2_acc_ctl_wreq <= wr_req_d0;
        wr_ack_int <= ch_2_acc_ctl_wack;
      when "000000001" =>
        -- Reg ch_2_acc_gain
        ch_2_acc_gain_wreq <= wr_req_d0;
        wr_ack_int <= ch_2_acc_gain_wack;
      when "000001000" =>
        -- Reg ch_2_sp_limits_max
        ch_2_sp_limits_max_wreq <= wr_req_d0;
        wr_ack_int <= ch_2_sp_limits_max_wack;
      when "000001001" =>
        -- Reg ch_2_sp_limits_min
        ch_2_sp_limits_min_wreq <= wr_req_d0;
        wr_ack_int <= ch_2_sp_limits_min_wack;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "01000" =>
      -- Memory ch_3_coeff_ram_bank
      ch_3_coeff_ram_bank_data_int_wr <= wr_req_d0;
      wr_ack_int <= wr_req_d0;
    when "01001" =>
      case wr_adr_d0(10 downto 2) is
      when "000000000" =>
        -- Reg ch_3_acc_ctl
        ch_3_acc_ctl_wreq <= wr_req_d0;
        wr_ack_int <= ch_3_acc_ctl_wack;
      when "000000001" =>
        -- Reg ch_3_acc_gain
        ch_3_acc_gain_wreq <= wr_req_d0;
        wr_ack_int <= ch_3_acc_gain_wack;
      when "000001000" =>
        -- Reg ch_3_sp_limits_max
        ch_3_sp_limits_max_wreq <= wr_req_d0;
        wr_ack_int <= ch_3_sp_limits_max_wack;
      when "000001001" =>
        -- Reg ch_3_sp_limits_min
        ch_3_sp_limits_min_wreq <= wr_req_d0;
        wr_ack_int <= ch_3_sp_limits_min_wack;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "01010" =>
      -- Memory ch_4_coeff_ram_bank
      ch_4_coeff_ram_bank_data_int_wr <= wr_req_d0;
      wr_ack_int <= wr_req_d0;
    when "01011" =>
      case wr_adr_d0(10 downto 2) is
      when "000000000" =>
        -- Reg ch_4_acc_ctl
        ch_4_acc_ctl_wreq <= wr_req_d0;
        wr_ack_int <= ch_4_acc_ctl_wack;
      when "000000001" =>
        -- Reg ch_4_acc_gain
        ch_4_acc_gain_wreq <= wr_req_d0;
        wr_ack_int <= ch_4_acc_gain_wack;
      when "000001000" =>
        -- Reg ch_4_sp_limits_max
        ch_4_sp_limits_max_wreq <= wr_req_d0;
        wr_ack_int <= ch_4_sp_limits_max_wack;
      when "000001001" =>
        -- Reg ch_4_sp_limits_min
        ch_4_sp_limits_min_wreq <= wr_req_d0;
        wr_ack_int <= ch_4_sp_limits_min_wack;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "01100" =>
      -- Memory ch_5_coeff_ram_bank
      ch_5_coeff_ram_bank_data_int_wr <= wr_req_d0;
      wr_ack_int <= wr_req_d0;
    when "01101" =>
      case wr_adr_d0(10 downto 2) is
      when "000000000" =>
        -- Reg ch_5_acc_ctl
        ch_5_acc_ctl_wreq <= wr_req_d0;
        wr_ack_int <= ch_5_acc_ctl_wack;
      when "000000001" =>
        -- Reg ch_5_acc_gain
        ch_5_acc_gain_wreq <= wr_req_d0;
        wr_ack_int <= ch_5_acc_gain_wack;
      when "000001000" =>
        -- Reg ch_5_sp_limits_max
        ch_5_sp_limits_max_wreq <= wr_req_d0;
        wr_ack_int <= ch_5_sp_limits_max_wack;
      when "000001001" =>
        -- Reg ch_5_sp_limits_min
        ch_5_sp_limits_min_wreq <= wr_req_d0;
        wr_ack_int <= ch_5_sp_limits_min_wack;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "01110" =>
      -- Memory ch_6_coeff_ram_bank
      ch_6_coeff_ram_bank_data_int_wr <= wr_req_d0;
      wr_ack_int <= wr_req_d0;
    when "01111" =>
      case wr_adr_d0(10 downto 2) is
      when "000000000" =>
        -- Reg ch_6_acc_ctl
        ch_6_acc_ctl_wreq <= wr_req_d0;
        wr_ack_int <= ch_6_acc_ctl_wack;
      when "000000001" =>
        -- Reg ch_6_acc_gain
        ch_6_acc_gain_wreq <= wr_req_d0;
        wr_ack_int <= ch_6_acc_gain_wack;
      when "000001000" =>
        -- Reg ch_6_sp_limits_max
        ch_6_sp_limits_max_wreq <= wr_req_d0;
        wr_ack_int <= ch_6_sp_limits_max_wack;
      when "000001001" =>
        -- Reg ch_6_sp_limits_min
        ch_6_sp_limits_min_wreq <= wr_req_d0;
        wr_ack_int <= ch_6_sp_limits_min_wack;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "10000" =>
      -- Memory ch_7_coeff_ram_bank
      ch_7_coeff_ram_bank_data_int_wr <= wr_req_d0;
      wr_ack_int <= wr_req_d0;
    when "10001" =>
      case wr_adr_d0(10 downto 2) is
      when "000000000" =>
        -- Reg ch_7_acc_ctl
        ch_7_acc_ctl_wreq <= wr_req_d0;
        wr_ack_int <= ch_7_acc_ctl_wack;
      when "000000001" =>
        -- Reg ch_7_acc_gain
        ch_7_acc_gain_wreq <= wr_req_d0;
        wr_ack_int <= ch_7_acc_gain_wack;
      when "000001000" =>
        -- Reg ch_7_sp_limits_max
        ch_7_sp_limits_max_wreq <= wr_req_d0;
        wr_ack_int <= ch_7_sp_limits_max_wack;
      when "000001001" =>
        -- Reg ch_7_sp_limits_min
        ch_7_sp_limits_min_wreq <= wr_req_d0;
        wr_ack_int <= ch_7_sp_limits_min_wack;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "10010" =>
      -- Memory ch_8_coeff_ram_bank
      ch_8_coeff_ram_bank_data_int_wr <= wr_req_d0;
      wr_ack_int <= wr_req_d0;
    when "10011" =>
      case wr_adr_d0(10 downto 2) is
      when "000000000" =>
        -- Reg ch_8_acc_ctl
        ch_8_acc_ctl_wreq <= wr_req_d0;
        wr_ack_int <= ch_8_acc_ctl_wack;
      when "000000001" =>
        -- Reg ch_8_acc_gain
        ch_8_acc_gain_wreq <= wr_req_d0;
        wr_ack_int <= ch_8_acc_gain_wack;
      when "000001000" =>
        -- Reg ch_8_sp_limits_max
        ch_8_sp_limits_max_wreq <= wr_req_d0;
        wr_ack_int <= ch_8_sp_limits_max_wack;
      when "000001001" =>
        -- Reg ch_8_sp_limits_min
        ch_8_sp_limits_min_wreq <= wr_req_d0;
        wr_ack_int <= ch_8_sp_limits_min_wack;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "10100" =>
      -- Memory ch_9_coeff_ram_bank
      ch_9_coeff_ram_bank_data_int_wr <= wr_req_d0;
      wr_ack_int <= wr_req_d0;
    when "10101" =>
      case wr_adr_d0(10 downto 2) is
      when "000000000" =>
        -- Reg ch_9_acc_ctl
        ch_9_acc_ctl_wreq <= wr_req_d0;
        wr_ack_int <= ch_9_acc_ctl_wack;
      when "000000001" =>
        -- Reg ch_9_acc_gain
        ch_9_acc_gain_wreq <= wr_req_d0;
        wr_ack_int <= ch_9_acc_gain_wack;
      when "000001000" =>
        -- Reg ch_9_sp_limits_max
        ch_9_sp_limits_max_wreq <= wr_req_d0;
        wr_ack_int <= ch_9_sp_limits_max_wack;
      when "000001001" =>
        -- Reg ch_9_sp_limits_min
        ch_9_sp_limits_min_wreq <= wr_req_d0;
        wr_ack_int <= ch_9_sp_limits_min_wack;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "10110" =>
      -- Memory ch_10_coeff_ram_bank
      ch_10_coeff_ram_bank_data_int_wr <= wr_req_d0;
      wr_ack_int <= wr_req_d0;
    when "10111" =>
      case wr_adr_d0(10 downto 2) is
      when "000000000" =>
        -- Reg ch_10_acc_ctl
        ch_10_acc_ctl_wreq <= wr_req_d0;
        wr_ack_int <= ch_10_acc_ctl_wack;
      when "000000001" =>
        -- Reg ch_10_acc_gain
        ch_10_acc_gain_wreq <= wr_req_d0;
        wr_ack_int <= ch_10_acc_gain_wack;
      when "000001000" =>
        -- Reg ch_10_sp_limits_max
        ch_10_sp_limits_max_wreq <= wr_req_d0;
        wr_ack_int <= ch_10_sp_limits_max_wack;
      when "000001001" =>
        -- Reg ch_10_sp_limits_min
        ch_10_sp_limits_min_wreq <= wr_req_d0;
        wr_ack_int <= ch_10_sp_limits_min_wack;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "11000" =>
      -- Memory ch_11_coeff_ram_bank
      ch_11_coeff_ram_bank_data_int_wr <= wr_req_d0;
      wr_ack_int <= wr_req_d0;
    when "11001" =>
      case wr_adr_d0(10 downto 2) is
      when "000000000" =>
        -- Reg ch_11_acc_ctl
        ch_11_acc_ctl_wreq <= wr_req_d0;
        wr_ack_int <= ch_11_acc_ctl_wack;
      when "000000001" =>
        -- Reg ch_11_acc_gain
        ch_11_acc_gain_wreq <= wr_req_d0;
        wr_ack_int <= ch_11_acc_gain_wack;
      when "000001000" =>
        -- Reg ch_11_sp_limits_max
        ch_11_sp_limits_max_wreq <= wr_req_d0;
        wr_ack_int <= ch_11_sp_limits_max_wack;
      when "000001001" =>
        -- Reg ch_11_sp_limits_min
        ch_11_sp_limits_min_wreq <= wr_req_d0;
        wr_ack_int <= ch_11_sp_limits_min_wack;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (adr_int, rd_req_int, fixed_point_pos_coeff_val_i, fixed_point_pos_accs_gains_val_i, loop_intlk_ctl_src_en_orb_distort_reg, loop_intlk_ctl_src_en_packet_loss_reg, loop_intlk_sta_orb_distort_i, loop_intlk_sta_packet_loss_i, loop_intlk_orb_distort_limit_val_reg, loop_intlk_min_num_pkts_val_reg, sps_ram_bank_data_int_dato, sps_ram_bank_data_rack, ch_0_coeff_ram_bank_data_int_dato, ch_0_coeff_ram_bank_data_rack, ch_0_acc_ctl_freeze_reg, ch_0_acc_gain_val_reg, ch_0_sp_limits_max_val_reg, ch_0_sp_limits_min_val_reg, ch_1_coeff_ram_bank_data_int_dato, ch_1_coeff_ram_bank_data_rack, ch_1_acc_ctl_freeze_reg, ch_1_acc_gain_val_reg, ch_1_sp_limits_max_val_reg, ch_1_sp_limits_min_val_reg, ch_2_coeff_ram_bank_data_int_dato, ch_2_coeff_ram_bank_data_rack, ch_2_acc_ctl_freeze_reg, ch_2_acc_gain_val_reg, ch_2_sp_limits_max_val_reg, ch_2_sp_limits_min_val_reg, ch_3_coeff_ram_bank_data_int_dato, ch_3_coeff_ram_bank_data_rack, ch_3_acc_ctl_freeze_reg, ch_3_acc_gain_val_reg, ch_3_sp_limits_max_val_reg, ch_3_sp_limits_min_val_reg, ch_4_coeff_ram_bank_data_int_dato, ch_4_coeff_ram_bank_data_rack, ch_4_acc_ctl_freeze_reg, ch_4_acc_gain_val_reg, ch_4_sp_limits_max_val_reg, ch_4_sp_limits_min_val_reg, ch_5_coeff_ram_bank_data_int_dato, ch_5_coeff_ram_bank_data_rack, ch_5_acc_ctl_freeze_reg, ch_5_acc_gain_val_reg, ch_5_sp_limits_max_val_reg, ch_5_sp_limits_min_val_reg, ch_6_coeff_ram_bank_data_int_dato, ch_6_coeff_ram_bank_data_rack, ch_6_acc_ctl_freeze_reg, ch_6_acc_gain_val_reg, ch_6_sp_limits_max_val_reg, ch_6_sp_limits_min_val_reg, ch_7_coeff_ram_bank_data_int_dato, ch_7_coeff_ram_bank_data_rack, ch_7_acc_ctl_freeze_reg, ch_7_acc_gain_val_reg, ch_7_sp_limits_max_val_reg, ch_7_sp_limits_min_val_reg, ch_8_coeff_ram_bank_data_int_dato, ch_8_coeff_ram_bank_data_rack, ch_8_acc_ctl_freeze_reg, ch_8_acc_gain_val_reg, ch_8_sp_limits_max_val_reg, ch_8_sp_limits_min_val_reg, ch_9_coeff_ram_bank_data_int_dato, ch_9_coeff_ram_bank_data_rack, ch_9_acc_ctl_freeze_reg, ch_9_acc_gain_val_reg, ch_9_sp_limits_max_val_reg, ch_9_sp_limits_min_val_reg, ch_10_coeff_ram_bank_data_int_dato, ch_10_coeff_ram_bank_data_rack, ch_10_acc_ctl_freeze_reg, ch_10_acc_gain_val_reg, ch_10_sp_limits_max_val_reg, ch_10_sp_limits_min_val_reg, ch_11_coeff_ram_bank_data_int_dato, ch_11_coeff_ram_bank_data_rack, ch_11_acc_ctl_freeze_reg, ch_11_acc_gain_val_reg, ch_11_sp_limits_max_val_reg, ch_11_sp_limits_min_val_reg) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    sps_ram_bank_data_rreq <= '0';
    ch_0_coeff_ram_bank_data_rreq <= '0';
    ch_1_coeff_ram_bank_data_rreq <= '0';
    ch_2_coeff_ram_bank_data_rreq <= '0';
    ch_3_coeff_ram_bank_data_rreq <= '0';
    ch_4_coeff_ram_bank_data_rreq <= '0';
    ch_5_coeff_ram_bank_data_rreq <= '0';
    ch_6_coeff_ram_bank_data_rreq <= '0';
    ch_7_coeff_ram_bank_data_rreq <= '0';
    ch_8_coeff_ram_bank_data_rreq <= '0';
    ch_9_coeff_ram_bank_data_rreq <= '0';
    ch_10_coeff_ram_bank_data_rreq <= '0';
    ch_11_coeff_ram_bank_data_rreq <= '0';
    case adr_int(15 downto 11) is
    when "00000" =>
      case adr_int(10 downto 2) is
      when "000000000" =>
        -- Reg fixed_point_pos_coeff
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= fixed_point_pos_coeff_val_i;
      when "000000001" =>
        -- Reg fixed_point_pos_accs_gains
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= fixed_point_pos_accs_gains_val_i;
      when "000010000" =>
        -- Reg loop_intlk_ctl
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= '0';
        rd_dat_d0(1) <= loop_intlk_ctl_src_en_orb_distort_reg;
        rd_dat_d0(2) <= loop_intlk_ctl_src_en_packet_loss_reg;
        rd_dat_d0(31 downto 3) <= (others => '0');
      when "000010001" =>
        -- Reg loop_intlk_sta
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= loop_intlk_sta_orb_distort_i;
        rd_dat_d0(1) <= loop_intlk_sta_packet_loss_i;
        rd_dat_d0(31 downto 2) <= (others => '0');
      when "000010010" =>
        -- Reg loop_intlk_orb_distort_limit
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= loop_intlk_orb_distort_limit_val_reg;
      when "000010011" =>
        -- Reg loop_intlk_min_num_pkts
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= loop_intlk_min_num_pkts_val_reg;
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "00001" =>
      -- Memory sps_ram_bank
      rd_dat_d0 <= sps_ram_bank_data_int_dato;
      sps_ram_bank_data_rreq <= rd_req_int;
      rd_ack_d0 <= sps_ram_bank_data_rack;
    when "00010" =>
      -- Memory ch_0_coeff_ram_bank
      rd_dat_d0 <= ch_0_coeff_ram_bank_data_int_dato;
      ch_0_coeff_ram_bank_data_rreq <= rd_req_int;
      rd_ack_d0 <= ch_0_coeff_ram_bank_data_rack;
    when "00011" =>
      case adr_int(10 downto 2) is
      when "000000000" =>
        -- Reg ch_0_acc_ctl
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= '0';
        rd_dat_d0(1) <= ch_0_acc_ctl_freeze_reg;
        rd_dat_d0(31 downto 2) <= (others => '0');
      when "000000001" =>
        -- Reg ch_0_acc_gain
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_0_acc_gain_val_reg;
      when "000001000" =>
        -- Reg ch_0_sp_limits_max
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_0_sp_limits_max_val_reg;
      when "000001001" =>
        -- Reg ch_0_sp_limits_min
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_0_sp_limits_min_val_reg;
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "00100" =>
      -- Memory ch_1_coeff_ram_bank
      rd_dat_d0 <= ch_1_coeff_ram_bank_data_int_dato;
      ch_1_coeff_ram_bank_data_rreq <= rd_req_int;
      rd_ack_d0 <= ch_1_coeff_ram_bank_data_rack;
    when "00101" =>
      case adr_int(10 downto 2) is
      when "000000000" =>
        -- Reg ch_1_acc_ctl
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= '0';
        rd_dat_d0(1) <= ch_1_acc_ctl_freeze_reg;
        rd_dat_d0(31 downto 2) <= (others => '0');
      when "000000001" =>
        -- Reg ch_1_acc_gain
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_1_acc_gain_val_reg;
      when "000001000" =>
        -- Reg ch_1_sp_limits_max
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_1_sp_limits_max_val_reg;
      when "000001001" =>
        -- Reg ch_1_sp_limits_min
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_1_sp_limits_min_val_reg;
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "00110" =>
      -- Memory ch_2_coeff_ram_bank
      rd_dat_d0 <= ch_2_coeff_ram_bank_data_int_dato;
      ch_2_coeff_ram_bank_data_rreq <= rd_req_int;
      rd_ack_d0 <= ch_2_coeff_ram_bank_data_rack;
    when "00111" =>
      case adr_int(10 downto 2) is
      when "000000000" =>
        -- Reg ch_2_acc_ctl
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= '0';
        rd_dat_d0(1) <= ch_2_acc_ctl_freeze_reg;
        rd_dat_d0(31 downto 2) <= (others => '0');
      when "000000001" =>
        -- Reg ch_2_acc_gain
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_2_acc_gain_val_reg;
      when "000001000" =>
        -- Reg ch_2_sp_limits_max
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_2_sp_limits_max_val_reg;
      when "000001001" =>
        -- Reg ch_2_sp_limits_min
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_2_sp_limits_min_val_reg;
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "01000" =>
      -- Memory ch_3_coeff_ram_bank
      rd_dat_d0 <= ch_3_coeff_ram_bank_data_int_dato;
      ch_3_coeff_ram_bank_data_rreq <= rd_req_int;
      rd_ack_d0 <= ch_3_coeff_ram_bank_data_rack;
    when "01001" =>
      case adr_int(10 downto 2) is
      when "000000000" =>
        -- Reg ch_3_acc_ctl
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= '0';
        rd_dat_d0(1) <= ch_3_acc_ctl_freeze_reg;
        rd_dat_d0(31 downto 2) <= (others => '0');
      when "000000001" =>
        -- Reg ch_3_acc_gain
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_3_acc_gain_val_reg;
      when "000001000" =>
        -- Reg ch_3_sp_limits_max
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_3_sp_limits_max_val_reg;
      when "000001001" =>
        -- Reg ch_3_sp_limits_min
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_3_sp_limits_min_val_reg;
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "01010" =>
      -- Memory ch_4_coeff_ram_bank
      rd_dat_d0 <= ch_4_coeff_ram_bank_data_int_dato;
      ch_4_coeff_ram_bank_data_rreq <= rd_req_int;
      rd_ack_d0 <= ch_4_coeff_ram_bank_data_rack;
    when "01011" =>
      case adr_int(10 downto 2) is
      when "000000000" =>
        -- Reg ch_4_acc_ctl
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= '0';
        rd_dat_d0(1) <= ch_4_acc_ctl_freeze_reg;
        rd_dat_d0(31 downto 2) <= (others => '0');
      when "000000001" =>
        -- Reg ch_4_acc_gain
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_4_acc_gain_val_reg;
      when "000001000" =>
        -- Reg ch_4_sp_limits_max
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_4_sp_limits_max_val_reg;
      when "000001001" =>
        -- Reg ch_4_sp_limits_min
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_4_sp_limits_min_val_reg;
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "01100" =>
      -- Memory ch_5_coeff_ram_bank
      rd_dat_d0 <= ch_5_coeff_ram_bank_data_int_dato;
      ch_5_coeff_ram_bank_data_rreq <= rd_req_int;
      rd_ack_d0 <= ch_5_coeff_ram_bank_data_rack;
    when "01101" =>
      case adr_int(10 downto 2) is
      when "000000000" =>
        -- Reg ch_5_acc_ctl
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= '0';
        rd_dat_d0(1) <= ch_5_acc_ctl_freeze_reg;
        rd_dat_d0(31 downto 2) <= (others => '0');
      when "000000001" =>
        -- Reg ch_5_acc_gain
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_5_acc_gain_val_reg;
      when "000001000" =>
        -- Reg ch_5_sp_limits_max
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_5_sp_limits_max_val_reg;
      when "000001001" =>
        -- Reg ch_5_sp_limits_min
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_5_sp_limits_min_val_reg;
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "01110" =>
      -- Memory ch_6_coeff_ram_bank
      rd_dat_d0 <= ch_6_coeff_ram_bank_data_int_dato;
      ch_6_coeff_ram_bank_data_rreq <= rd_req_int;
      rd_ack_d0 <= ch_6_coeff_ram_bank_data_rack;
    when "01111" =>
      case adr_int(10 downto 2) is
      when "000000000" =>
        -- Reg ch_6_acc_ctl
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= '0';
        rd_dat_d0(1) <= ch_6_acc_ctl_freeze_reg;
        rd_dat_d0(31 downto 2) <= (others => '0');
      when "000000001" =>
        -- Reg ch_6_acc_gain
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_6_acc_gain_val_reg;
      when "000001000" =>
        -- Reg ch_6_sp_limits_max
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_6_sp_limits_max_val_reg;
      when "000001001" =>
        -- Reg ch_6_sp_limits_min
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_6_sp_limits_min_val_reg;
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "10000" =>
      -- Memory ch_7_coeff_ram_bank
      rd_dat_d0 <= ch_7_coeff_ram_bank_data_int_dato;
      ch_7_coeff_ram_bank_data_rreq <= rd_req_int;
      rd_ack_d0 <= ch_7_coeff_ram_bank_data_rack;
    when "10001" =>
      case adr_int(10 downto 2) is
      when "000000000" =>
        -- Reg ch_7_acc_ctl
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= '0';
        rd_dat_d0(1) <= ch_7_acc_ctl_freeze_reg;
        rd_dat_d0(31 downto 2) <= (others => '0');
      when "000000001" =>
        -- Reg ch_7_acc_gain
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_7_acc_gain_val_reg;
      when "000001000" =>
        -- Reg ch_7_sp_limits_max
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_7_sp_limits_max_val_reg;
      when "000001001" =>
        -- Reg ch_7_sp_limits_min
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_7_sp_limits_min_val_reg;
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "10010" =>
      -- Memory ch_8_coeff_ram_bank
      rd_dat_d0 <= ch_8_coeff_ram_bank_data_int_dato;
      ch_8_coeff_ram_bank_data_rreq <= rd_req_int;
      rd_ack_d0 <= ch_8_coeff_ram_bank_data_rack;
    when "10011" =>
      case adr_int(10 downto 2) is
      when "000000000" =>
        -- Reg ch_8_acc_ctl
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= '0';
        rd_dat_d0(1) <= ch_8_acc_ctl_freeze_reg;
        rd_dat_d0(31 downto 2) <= (others => '0');
      when "000000001" =>
        -- Reg ch_8_acc_gain
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_8_acc_gain_val_reg;
      when "000001000" =>
        -- Reg ch_8_sp_limits_max
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_8_sp_limits_max_val_reg;
      when "000001001" =>
        -- Reg ch_8_sp_limits_min
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_8_sp_limits_min_val_reg;
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "10100" =>
      -- Memory ch_9_coeff_ram_bank
      rd_dat_d0 <= ch_9_coeff_ram_bank_data_int_dato;
      ch_9_coeff_ram_bank_data_rreq <= rd_req_int;
      rd_ack_d0 <= ch_9_coeff_ram_bank_data_rack;
    when "10101" =>
      case adr_int(10 downto 2) is
      when "000000000" =>
        -- Reg ch_9_acc_ctl
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= '0';
        rd_dat_d0(1) <= ch_9_acc_ctl_freeze_reg;
        rd_dat_d0(31 downto 2) <= (others => '0');
      when "000000001" =>
        -- Reg ch_9_acc_gain
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_9_acc_gain_val_reg;
      when "000001000" =>
        -- Reg ch_9_sp_limits_max
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_9_sp_limits_max_val_reg;
      when "000001001" =>
        -- Reg ch_9_sp_limits_min
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_9_sp_limits_min_val_reg;
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "10110" =>
      -- Memory ch_10_coeff_ram_bank
      rd_dat_d0 <= ch_10_coeff_ram_bank_data_int_dato;
      ch_10_coeff_ram_bank_data_rreq <= rd_req_int;
      rd_ack_d0 <= ch_10_coeff_ram_bank_data_rack;
    when "10111" =>
      case adr_int(10 downto 2) is
      when "000000000" =>
        -- Reg ch_10_acc_ctl
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= '0';
        rd_dat_d0(1) <= ch_10_acc_ctl_freeze_reg;
        rd_dat_d0(31 downto 2) <= (others => '0');
      when "000000001" =>
        -- Reg ch_10_acc_gain
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_10_acc_gain_val_reg;
      when "000001000" =>
        -- Reg ch_10_sp_limits_max
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_10_sp_limits_max_val_reg;
      when "000001001" =>
        -- Reg ch_10_sp_limits_min
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_10_sp_limits_min_val_reg;
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "11000" =>
      -- Memory ch_11_coeff_ram_bank
      rd_dat_d0 <= ch_11_coeff_ram_bank_data_int_dato;
      ch_11_coeff_ram_bank_data_rreq <= rd_req_int;
      rd_ack_d0 <= ch_11_coeff_ram_bank_data_rack;
    when "11001" =>
      case adr_int(10 downto 2) is
      when "000000000" =>
        -- Reg ch_11_acc_ctl
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= '0';
        rd_dat_d0(1) <= ch_11_acc_ctl_freeze_reg;
        rd_dat_d0(31 downto 2) <= (others => '0');
      when "000000001" =>
        -- Reg ch_11_acc_gain
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_11_acc_gain_val_reg;
      when "000001000" =>
        -- Reg ch_11_sp_limits_max
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_11_sp_limits_max_val_reg;
      when "000001001" =>
        -- Reg ch_11_sp_limits_min
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ch_11_sp_limits_min_val_reg;
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
