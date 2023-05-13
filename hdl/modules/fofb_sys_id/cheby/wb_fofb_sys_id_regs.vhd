-- Do not edit.  Generated on Sat May 13 12:01:33 2023 by guilherme.ricioli
-- With Cheby 1.4.0 and these options:
--  -i wb_fofb_sys_id_regs.cheby --hdl vhdl --gen-hdl wb_fofb_sys_id_regs.vhd --doc html --gen-doc doc/wb_fofb_sys_id_regs.html --gen-c wb_fofb_sys_id_regs.h --consts-style vhdl-ohwr --gen-consts ../../../sim/regs/wb_fofb_sys_id_regs_consts_pkg.vhd


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wishbone_pkg.all;
use work.cheby_pkg.all;

entity wb_fofb_sys_id_regs is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_i                 : in    t_wishbone_slave_in;
    wb_o                 : out   t_wishbone_slave_out;

    -- BPM positions flatenizers control register

    -- Together with max_num_cte, defines the ranges of BPM
    -- positions indexes being flatenized, which are given by

    -- [base_bpm_id, base_bpm_id + max_num_cte): BPM x positions
    -- [base_bpm_id + 256, base_bpm_id + 256 + max_num_cte): BPM y positions

    bpm_pos_flatenizer_ctl_base_bpm_id_o : out   std_logic_vector(7 downto 0);

    -- Maximum number of BPM positions that can be flatenized per axis
    -- (x or y)

    bpm_pos_flatenizer_max_num_cte_i : in    std_logic_vector(15 downto 0);

    -- PRBS distortion control register

    -- Resets PRBS
    -- NOTE: This is only effectived via external trigger.

    -- write 0: no effect
    -- write 1: resets PRBS

    prbs_ctl_rst_o       : out   std_logic;
    -- Duration of each PRBS step in FOFB cycles (max: 0x3FF)

    -- write 0x000: new PRBS iteration at each FOFB cycle
    -- write 0x001: new PRBS iteration at each 2 FOFB cycles
    -- ...
    -- write 0x3FF: new PRBS iteration at each 1024 FOFB cycles

    prbs_ctl_step_duration_o : out   std_logic_vector(9 downto 0);
    -- Length of internal LFSR (max: 0x1E)
    -- Together with step_duration, defines the duration of PRBS,
    -- which is given by [2^(lfsr_length + 2) - 1]*(step_duration + 1)

    -- write 0x00: set LFSR length to 2
    -- write 0x01: set LFSR length to 3
    -- ...
    -- write 0x1E: set LFSR length to 32

    prbs_ctl_lfsr_length_o : out   std_logic_vector(4 downto 0);
    -- Enables/disables PRBS-based distortion on BPM positions
    -- NOTE: This is only effectived via external trigger.

    -- write 0: distortion disabled
    -- write 1: distortion enabled

    prbs_ctl_bpm_pos_distort_en_o : out   std_logic;
    -- Enables/disables PRBS-based distortion on setpoints
    -- NOTE: This is only effectived via external trigger.

    -- write 0: distortion disabled
    -- write 1: distortion enabled

    prbs_ctl_sp_distort_en_o : out   std_logic;
    -- Selects the number of taps for averaging the setpoints
    -- distortion. The number of taps being selected is given by
    -- '2**sp_distort_mov_avg_num_taps_sel'.
    -- NOTE: The maximum value for this field is given by
    --       sp_distort_mov_avg_max_num_taps_sel_cte.

    -- write 0x00: set number of taps to 1 (no averaging)
    -- write 0x01: set number of taps to 2
    -- write 0x02: set number of taps to 8
    -- ...
    -- write sp_distort_mov_avg_max_num_taps_sel_cte : set number
    --  of taps to 2**sp_distort_mov_avg_max_num_taps_sel_cte.

    prbs_ctl_sp_distort_mov_avg_num_taps_sel_o : out   std_logic_vector(2 downto 0);

    -- The maximum allowed value for prbs.ctl
    -- sp_distort_mov_avg_num_taps_sel field.

    prbs_sp_distort_mov_avg_max_num_taps_sel_cte_i : in    std_logic_vector(7 downto 0);

    -- Two signed 16-bit distortion levels in RTM-LAMP ADC
    -- counts, one for each PRBS value.

    -- 15 - 0: distortion level for PRBS value 0
    -- 31 - 16: distortion level for PRBS value 1

    -- Signed 16-bit distortion level in RTM-LAMP ADC
    -- counts for PRBS value 0.

    prbs_sp_distort_ch_0_levels_level_0_o : out   std_logic_vector(15 downto 0);
    -- Signed 16-bit distortion level in RTM-LAMP ADC
    -- counts for PRBS value 1.

    prbs_sp_distort_ch_0_levels_level_1_o : out   std_logic_vector(15 downto 0);

    -- Two signed 16-bit distortion levels in RTM-LAMP ADC
    -- counts, one for each PRBS value.

    -- 15 - 0: distortion level for PRBS value 0
    -- 31 - 16: distortion level for PRBS value 1

    -- Signed 16-bit distortion level in RTM-LAMP ADC
    -- counts for PRBS value 0.

    prbs_sp_distort_ch_1_levels_level_0_o : out   std_logic_vector(15 downto 0);
    -- Signed 16-bit distortion level in RTM-LAMP ADC
    -- counts for PRBS value 1.

    prbs_sp_distort_ch_1_levels_level_1_o : out   std_logic_vector(15 downto 0);

    -- Two signed 16-bit distortion levels in RTM-LAMP ADC
    -- counts, one for each PRBS value.

    -- 15 - 0: distortion level for PRBS value 0
    -- 31 - 16: distortion level for PRBS value 1

    -- Signed 16-bit distortion level in RTM-LAMP ADC
    -- counts for PRBS value 0.

    prbs_sp_distort_ch_2_levels_level_0_o : out   std_logic_vector(15 downto 0);
    -- Signed 16-bit distortion level in RTM-LAMP ADC
    -- counts for PRBS value 1.

    prbs_sp_distort_ch_2_levels_level_1_o : out   std_logic_vector(15 downto 0);

    -- Two signed 16-bit distortion levels in RTM-LAMP ADC
    -- counts, one for each PRBS value.

    -- 15 - 0: distortion level for PRBS value 0
    -- 31 - 16: distortion level for PRBS value 1

    -- Signed 16-bit distortion level in RTM-LAMP ADC
    -- counts for PRBS value 0.

    prbs_sp_distort_ch_3_levels_level_0_o : out   std_logic_vector(15 downto 0);
    -- Signed 16-bit distortion level in RTM-LAMP ADC
    -- counts for PRBS value 1.

    prbs_sp_distort_ch_3_levels_level_1_o : out   std_logic_vector(15 downto 0);

    -- Two signed 16-bit distortion levels in RTM-LAMP ADC
    -- counts, one for each PRBS value.

    -- 15 - 0: distortion level for PRBS value 0
    -- 31 - 16: distortion level for PRBS value 1

    -- Signed 16-bit distortion level in RTM-LAMP ADC
    -- counts for PRBS value 0.

    prbs_sp_distort_ch_4_levels_level_0_o : out   std_logic_vector(15 downto 0);
    -- Signed 16-bit distortion level in RTM-LAMP ADC
    -- counts for PRBS value 1.

    prbs_sp_distort_ch_4_levels_level_1_o : out   std_logic_vector(15 downto 0);

    -- Two signed 16-bit distortion levels in RTM-LAMP ADC
    -- counts, one for each PRBS value.

    -- 15 - 0: distortion level for PRBS value 0
    -- 31 - 16: distortion level for PRBS value 1

    -- Signed 16-bit distortion level in RTM-LAMP ADC
    -- counts for PRBS value 0.

    prbs_sp_distort_ch_5_levels_level_0_o : out   std_logic_vector(15 downto 0);
    -- Signed 16-bit distortion level in RTM-LAMP ADC
    -- counts for PRBS value 1.

    prbs_sp_distort_ch_5_levels_level_1_o : out   std_logic_vector(15 downto 0);

    -- Two signed 16-bit distortion levels in RTM-LAMP ADC
    -- counts, one for each PRBS value.

    -- 15 - 0: distortion level for PRBS value 0
    -- 31 - 16: distortion level for PRBS value 1

    -- Signed 16-bit distortion level in RTM-LAMP ADC
    -- counts for PRBS value 0.

    prbs_sp_distort_ch_6_levels_level_0_o : out   std_logic_vector(15 downto 0);
    -- Signed 16-bit distortion level in RTM-LAMP ADC
    -- counts for PRBS value 1.

    prbs_sp_distort_ch_6_levels_level_1_o : out   std_logic_vector(15 downto 0);

    -- Two signed 16-bit distortion levels in RTM-LAMP ADC
    -- counts, one for each PRBS value.

    -- 15 - 0: distortion level for PRBS value 0
    -- 31 - 16: distortion level for PRBS value 1

    -- Signed 16-bit distortion level in RTM-LAMP ADC
    -- counts for PRBS value 0.

    prbs_sp_distort_ch_7_levels_level_0_o : out   std_logic_vector(15 downto 0);
    -- Signed 16-bit distortion level in RTM-LAMP ADC
    -- counts for PRBS value 1.

    prbs_sp_distort_ch_7_levels_level_1_o : out   std_logic_vector(15 downto 0);

    -- Two signed 16-bit distortion levels in RTM-LAMP ADC
    -- counts, one for each PRBS value.

    -- 15 - 0: distortion level for PRBS value 0
    -- 31 - 16: distortion level for PRBS value 1

    -- Signed 16-bit distortion level in RTM-LAMP ADC
    -- counts for PRBS value 0.

    prbs_sp_distort_ch_8_levels_level_0_o : out   std_logic_vector(15 downto 0);
    -- Signed 16-bit distortion level in RTM-LAMP ADC
    -- counts for PRBS value 1.

    prbs_sp_distort_ch_8_levels_level_1_o : out   std_logic_vector(15 downto 0);

    -- Two signed 16-bit distortion levels in RTM-LAMP ADC
    -- counts, one for each PRBS value.

    -- 15 - 0: distortion level for PRBS value 0
    -- 31 - 16: distortion level for PRBS value 1

    -- Signed 16-bit distortion level in RTM-LAMP ADC
    -- counts for PRBS value 0.

    prbs_sp_distort_ch_9_levels_level_0_o : out   std_logic_vector(15 downto 0);
    -- Signed 16-bit distortion level in RTM-LAMP ADC
    -- counts for PRBS value 1.

    prbs_sp_distort_ch_9_levels_level_1_o : out   std_logic_vector(15 downto 0);

    -- Two signed 16-bit distortion levels in RTM-LAMP ADC
    -- counts, one for each PRBS value.

    -- 15 - 0: distortion level for PRBS value 0
    -- 31 - 16: distortion level for PRBS value 1

    -- Signed 16-bit distortion level in RTM-LAMP ADC
    -- counts for PRBS value 0.

    prbs_sp_distort_ch_10_levels_level_0_o : out   std_logic_vector(15 downto 0);
    -- Signed 16-bit distortion level in RTM-LAMP ADC
    -- counts for PRBS value 1.

    prbs_sp_distort_ch_10_levels_level_1_o : out   std_logic_vector(15 downto 0);

    -- Two signed 16-bit distortion levels in RTM-LAMP ADC
    -- counts, one for each PRBS value.

    -- 15 - 0: distortion level for PRBS value 0
    -- 31 - 16: distortion level for PRBS value 1

    -- Signed 16-bit distortion level in RTM-LAMP ADC
    -- counts for PRBS value 0.

    prbs_sp_distort_ch_11_levels_level_0_o : out   std_logic_vector(15 downto 0);
    -- Signed 16-bit distortion level in RTM-LAMP ADC
    -- counts for PRBS value 1.

    prbs_sp_distort_ch_11_levels_level_1_o : out   std_logic_vector(15 downto 0);

    -- RAM port for prbs_bpm_pos_distort_distort_ram
    prbs_bpm_pos_distort_distort_ram_adr_i : in    std_logic_vector(8 downto 0);
    prbs_bpm_pos_distort_distort_ram_levels_rd_i : in    std_logic;
    prbs_bpm_pos_distort_distort_ram_levels_dat_o : out   std_logic_vector(31 downto 0)
  );
end wb_fofb_sys_id_regs;

architecture syn of wb_fofb_sys_id_regs is
  signal adr_int                        : std_logic_vector(12 downto 2);
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal bpm_pos_flatenizer_ctl_base_bpm_id_reg : std_logic_vector(7 downto 0);
  signal bpm_pos_flatenizer_ctl_wreq    : std_logic;
  signal bpm_pos_flatenizer_ctl_wack    : std_logic;
  signal prbs_ctl_rst_reg               : std_logic;
  signal prbs_ctl_step_duration_reg     : std_logic_vector(9 downto 0);
  signal prbs_ctl_lfsr_length_reg       : std_logic_vector(4 downto 0);
  signal prbs_ctl_bpm_pos_distort_en_reg : std_logic;
  signal prbs_ctl_sp_distort_en_reg     : std_logic;
  signal prbs_ctl_sp_distort_mov_avg_num_taps_sel_reg : std_logic_vector(2 downto 0);
  signal prbs_ctl_wreq                  : std_logic;
  signal prbs_ctl_wack                  : std_logic;
  signal prbs_sp_distort_ch_0_levels_level_0_reg : std_logic_vector(15 downto 0);
  signal prbs_sp_distort_ch_0_levels_level_1_reg : std_logic_vector(15 downto 0);
  signal prbs_sp_distort_ch_0_levels_wreq : std_logic;
  signal prbs_sp_distort_ch_0_levels_wack : std_logic;
  signal prbs_sp_distort_ch_1_levels_level_0_reg : std_logic_vector(15 downto 0);
  signal prbs_sp_distort_ch_1_levels_level_1_reg : std_logic_vector(15 downto 0);
  signal prbs_sp_distort_ch_1_levels_wreq : std_logic;
  signal prbs_sp_distort_ch_1_levels_wack : std_logic;
  signal prbs_sp_distort_ch_2_levels_level_0_reg : std_logic_vector(15 downto 0);
  signal prbs_sp_distort_ch_2_levels_level_1_reg : std_logic_vector(15 downto 0);
  signal prbs_sp_distort_ch_2_levels_wreq : std_logic;
  signal prbs_sp_distort_ch_2_levels_wack : std_logic;
  signal prbs_sp_distort_ch_3_levels_level_0_reg : std_logic_vector(15 downto 0);
  signal prbs_sp_distort_ch_3_levels_level_1_reg : std_logic_vector(15 downto 0);
  signal prbs_sp_distort_ch_3_levels_wreq : std_logic;
  signal prbs_sp_distort_ch_3_levels_wack : std_logic;
  signal prbs_sp_distort_ch_4_levels_level_0_reg : std_logic_vector(15 downto 0);
  signal prbs_sp_distort_ch_4_levels_level_1_reg : std_logic_vector(15 downto 0);
  signal prbs_sp_distort_ch_4_levels_wreq : std_logic;
  signal prbs_sp_distort_ch_4_levels_wack : std_logic;
  signal prbs_sp_distort_ch_5_levels_level_0_reg : std_logic_vector(15 downto 0);
  signal prbs_sp_distort_ch_5_levels_level_1_reg : std_logic_vector(15 downto 0);
  signal prbs_sp_distort_ch_5_levels_wreq : std_logic;
  signal prbs_sp_distort_ch_5_levels_wack : std_logic;
  signal prbs_sp_distort_ch_6_levels_level_0_reg : std_logic_vector(15 downto 0);
  signal prbs_sp_distort_ch_6_levels_level_1_reg : std_logic_vector(15 downto 0);
  signal prbs_sp_distort_ch_6_levels_wreq : std_logic;
  signal prbs_sp_distort_ch_6_levels_wack : std_logic;
  signal prbs_sp_distort_ch_7_levels_level_0_reg : std_logic_vector(15 downto 0);
  signal prbs_sp_distort_ch_7_levels_level_1_reg : std_logic_vector(15 downto 0);
  signal prbs_sp_distort_ch_7_levels_wreq : std_logic;
  signal prbs_sp_distort_ch_7_levels_wack : std_logic;
  signal prbs_sp_distort_ch_8_levels_level_0_reg : std_logic_vector(15 downto 0);
  signal prbs_sp_distort_ch_8_levels_level_1_reg : std_logic_vector(15 downto 0);
  signal prbs_sp_distort_ch_8_levels_wreq : std_logic;
  signal prbs_sp_distort_ch_8_levels_wack : std_logic;
  signal prbs_sp_distort_ch_9_levels_level_0_reg : std_logic_vector(15 downto 0);
  signal prbs_sp_distort_ch_9_levels_level_1_reg : std_logic_vector(15 downto 0);
  signal prbs_sp_distort_ch_9_levels_wreq : std_logic;
  signal prbs_sp_distort_ch_9_levels_wack : std_logic;
  signal prbs_sp_distort_ch_10_levels_level_0_reg : std_logic_vector(15 downto 0);
  signal prbs_sp_distort_ch_10_levels_level_1_reg : std_logic_vector(15 downto 0);
  signal prbs_sp_distort_ch_10_levels_wreq : std_logic;
  signal prbs_sp_distort_ch_10_levels_wack : std_logic;
  signal prbs_sp_distort_ch_11_levels_level_0_reg : std_logic_vector(15 downto 0);
  signal prbs_sp_distort_ch_11_levels_level_1_reg : std_logic_vector(15 downto 0);
  signal prbs_sp_distort_ch_11_levels_wreq : std_logic;
  signal prbs_sp_distort_ch_11_levels_wack : std_logic;
  signal prbs_bpm_pos_distort_distort_ram_levels_int_dato : std_logic_vector(31 downto 0);
  signal prbs_bpm_pos_distort_distort_ram_levels_ext_dat : std_logic_vector(31 downto 0);
  signal prbs_bpm_pos_distort_distort_ram_levels_rreq : std_logic;
  signal prbs_bpm_pos_distort_distort_ram_levels_rack : std_logic;
  signal prbs_bpm_pos_distort_distort_ram_levels_int_wr : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(12 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_sel_d0                      : std_logic_vector(3 downto 0);
  signal prbs_bpm_pos_distort_distort_ram_wr : std_logic;
  signal prbs_bpm_pos_distort_distort_ram_rr : std_logic;
  signal prbs_bpm_pos_distort_distort_ram_wreq : std_logic;
  signal prbs_bpm_pos_distort_distort_ram_adr_int : std_logic_vector(8 downto 0);
begin

  -- WB decode signals
  adr_int <= wb_i.adr(12 downto 2);
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

  -- Register bpm_pos_flatenizer_ctl
  bpm_pos_flatenizer_ctl_base_bpm_id_o <= bpm_pos_flatenizer_ctl_base_bpm_id_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        bpm_pos_flatenizer_ctl_base_bpm_id_reg <= "00000000";
        bpm_pos_flatenizer_ctl_wack <= '0';
      else
        if bpm_pos_flatenizer_ctl_wreq = '1' then
          bpm_pos_flatenizer_ctl_base_bpm_id_reg <= wr_dat_d0(7 downto 0);
        end if;
        bpm_pos_flatenizer_ctl_wack <= bpm_pos_flatenizer_ctl_wreq;
      end if;
    end if;
  end process;

  -- Register bpm_pos_flatenizer_max_num_cte

  -- Register prbs_ctl
  prbs_ctl_rst_o <= prbs_ctl_rst_reg;
  prbs_ctl_step_duration_o <= prbs_ctl_step_duration_reg;
  prbs_ctl_lfsr_length_o <= prbs_ctl_lfsr_length_reg;
  prbs_ctl_bpm_pos_distort_en_o <= prbs_ctl_bpm_pos_distort_en_reg;
  prbs_ctl_sp_distort_en_o <= prbs_ctl_sp_distort_en_reg;
  prbs_ctl_sp_distort_mov_avg_num_taps_sel_o <= prbs_ctl_sp_distort_mov_avg_num_taps_sel_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        prbs_ctl_rst_reg <= '0';
        prbs_ctl_step_duration_reg <= "0000000000";
        prbs_ctl_lfsr_length_reg <= "00000";
        prbs_ctl_bpm_pos_distort_en_reg <= '0';
        prbs_ctl_sp_distort_en_reg <= '0';
        prbs_ctl_sp_distort_mov_avg_num_taps_sel_reg <= "000";
        prbs_ctl_wack <= '0';
      else
        if prbs_ctl_wreq = '1' then
          prbs_ctl_rst_reg <= wr_dat_d0(0);
          prbs_ctl_step_duration_reg <= wr_dat_d0(10 downto 1);
          prbs_ctl_lfsr_length_reg <= wr_dat_d0(15 downto 11);
          prbs_ctl_bpm_pos_distort_en_reg <= wr_dat_d0(16);
          prbs_ctl_sp_distort_en_reg <= wr_dat_d0(17);
          prbs_ctl_sp_distort_mov_avg_num_taps_sel_reg <= wr_dat_d0(20 downto 18);
        end if;
        prbs_ctl_wack <= prbs_ctl_wreq;
      end if;
    end if;
  end process;

  -- Register prbs_sp_distort_mov_avg_max_num_taps_sel_cte

  -- Register prbs_sp_distort_ch_0_levels
  prbs_sp_distort_ch_0_levels_level_0_o <= prbs_sp_distort_ch_0_levels_level_0_reg;
  prbs_sp_distort_ch_0_levels_level_1_o <= prbs_sp_distort_ch_0_levels_level_1_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        prbs_sp_distort_ch_0_levels_level_0_reg <= "0000000000000000";
        prbs_sp_distort_ch_0_levels_level_1_reg <= "0000000000000000";
        prbs_sp_distort_ch_0_levels_wack <= '0';
      else
        if prbs_sp_distort_ch_0_levels_wreq = '1' then
          prbs_sp_distort_ch_0_levels_level_0_reg <= wr_dat_d0(15 downto 0);
          prbs_sp_distort_ch_0_levels_level_1_reg <= wr_dat_d0(31 downto 16);
        end if;
        prbs_sp_distort_ch_0_levels_wack <= prbs_sp_distort_ch_0_levels_wreq;
      end if;
    end if;
  end process;

  -- Register prbs_sp_distort_ch_1_levels
  prbs_sp_distort_ch_1_levels_level_0_o <= prbs_sp_distort_ch_1_levels_level_0_reg;
  prbs_sp_distort_ch_1_levels_level_1_o <= prbs_sp_distort_ch_1_levels_level_1_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        prbs_sp_distort_ch_1_levels_level_0_reg <= "0000000000000000";
        prbs_sp_distort_ch_1_levels_level_1_reg <= "0000000000000000";
        prbs_sp_distort_ch_1_levels_wack <= '0';
      else
        if prbs_sp_distort_ch_1_levels_wreq = '1' then
          prbs_sp_distort_ch_1_levels_level_0_reg <= wr_dat_d0(15 downto 0);
          prbs_sp_distort_ch_1_levels_level_1_reg <= wr_dat_d0(31 downto 16);
        end if;
        prbs_sp_distort_ch_1_levels_wack <= prbs_sp_distort_ch_1_levels_wreq;
      end if;
    end if;
  end process;

  -- Register prbs_sp_distort_ch_2_levels
  prbs_sp_distort_ch_2_levels_level_0_o <= prbs_sp_distort_ch_2_levels_level_0_reg;
  prbs_sp_distort_ch_2_levels_level_1_o <= prbs_sp_distort_ch_2_levels_level_1_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        prbs_sp_distort_ch_2_levels_level_0_reg <= "0000000000000000";
        prbs_sp_distort_ch_2_levels_level_1_reg <= "0000000000000000";
        prbs_sp_distort_ch_2_levels_wack <= '0';
      else
        if prbs_sp_distort_ch_2_levels_wreq = '1' then
          prbs_sp_distort_ch_2_levels_level_0_reg <= wr_dat_d0(15 downto 0);
          prbs_sp_distort_ch_2_levels_level_1_reg <= wr_dat_d0(31 downto 16);
        end if;
        prbs_sp_distort_ch_2_levels_wack <= prbs_sp_distort_ch_2_levels_wreq;
      end if;
    end if;
  end process;

  -- Register prbs_sp_distort_ch_3_levels
  prbs_sp_distort_ch_3_levels_level_0_o <= prbs_sp_distort_ch_3_levels_level_0_reg;
  prbs_sp_distort_ch_3_levels_level_1_o <= prbs_sp_distort_ch_3_levels_level_1_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        prbs_sp_distort_ch_3_levels_level_0_reg <= "0000000000000000";
        prbs_sp_distort_ch_3_levels_level_1_reg <= "0000000000000000";
        prbs_sp_distort_ch_3_levels_wack <= '0';
      else
        if prbs_sp_distort_ch_3_levels_wreq = '1' then
          prbs_sp_distort_ch_3_levels_level_0_reg <= wr_dat_d0(15 downto 0);
          prbs_sp_distort_ch_3_levels_level_1_reg <= wr_dat_d0(31 downto 16);
        end if;
        prbs_sp_distort_ch_3_levels_wack <= prbs_sp_distort_ch_3_levels_wreq;
      end if;
    end if;
  end process;

  -- Register prbs_sp_distort_ch_4_levels
  prbs_sp_distort_ch_4_levels_level_0_o <= prbs_sp_distort_ch_4_levels_level_0_reg;
  prbs_sp_distort_ch_4_levels_level_1_o <= prbs_sp_distort_ch_4_levels_level_1_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        prbs_sp_distort_ch_4_levels_level_0_reg <= "0000000000000000";
        prbs_sp_distort_ch_4_levels_level_1_reg <= "0000000000000000";
        prbs_sp_distort_ch_4_levels_wack <= '0';
      else
        if prbs_sp_distort_ch_4_levels_wreq = '1' then
          prbs_sp_distort_ch_4_levels_level_0_reg <= wr_dat_d0(15 downto 0);
          prbs_sp_distort_ch_4_levels_level_1_reg <= wr_dat_d0(31 downto 16);
        end if;
        prbs_sp_distort_ch_4_levels_wack <= prbs_sp_distort_ch_4_levels_wreq;
      end if;
    end if;
  end process;

  -- Register prbs_sp_distort_ch_5_levels
  prbs_sp_distort_ch_5_levels_level_0_o <= prbs_sp_distort_ch_5_levels_level_0_reg;
  prbs_sp_distort_ch_5_levels_level_1_o <= prbs_sp_distort_ch_5_levels_level_1_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        prbs_sp_distort_ch_5_levels_level_0_reg <= "0000000000000000";
        prbs_sp_distort_ch_5_levels_level_1_reg <= "0000000000000000";
        prbs_sp_distort_ch_5_levels_wack <= '0';
      else
        if prbs_sp_distort_ch_5_levels_wreq = '1' then
          prbs_sp_distort_ch_5_levels_level_0_reg <= wr_dat_d0(15 downto 0);
          prbs_sp_distort_ch_5_levels_level_1_reg <= wr_dat_d0(31 downto 16);
        end if;
        prbs_sp_distort_ch_5_levels_wack <= prbs_sp_distort_ch_5_levels_wreq;
      end if;
    end if;
  end process;

  -- Register prbs_sp_distort_ch_6_levels
  prbs_sp_distort_ch_6_levels_level_0_o <= prbs_sp_distort_ch_6_levels_level_0_reg;
  prbs_sp_distort_ch_6_levels_level_1_o <= prbs_sp_distort_ch_6_levels_level_1_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        prbs_sp_distort_ch_6_levels_level_0_reg <= "0000000000000000";
        prbs_sp_distort_ch_6_levels_level_1_reg <= "0000000000000000";
        prbs_sp_distort_ch_6_levels_wack <= '0';
      else
        if prbs_sp_distort_ch_6_levels_wreq = '1' then
          prbs_sp_distort_ch_6_levels_level_0_reg <= wr_dat_d0(15 downto 0);
          prbs_sp_distort_ch_6_levels_level_1_reg <= wr_dat_d0(31 downto 16);
        end if;
        prbs_sp_distort_ch_6_levels_wack <= prbs_sp_distort_ch_6_levels_wreq;
      end if;
    end if;
  end process;

  -- Register prbs_sp_distort_ch_7_levels
  prbs_sp_distort_ch_7_levels_level_0_o <= prbs_sp_distort_ch_7_levels_level_0_reg;
  prbs_sp_distort_ch_7_levels_level_1_o <= prbs_sp_distort_ch_7_levels_level_1_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        prbs_sp_distort_ch_7_levels_level_0_reg <= "0000000000000000";
        prbs_sp_distort_ch_7_levels_level_1_reg <= "0000000000000000";
        prbs_sp_distort_ch_7_levels_wack <= '0';
      else
        if prbs_sp_distort_ch_7_levels_wreq = '1' then
          prbs_sp_distort_ch_7_levels_level_0_reg <= wr_dat_d0(15 downto 0);
          prbs_sp_distort_ch_7_levels_level_1_reg <= wr_dat_d0(31 downto 16);
        end if;
        prbs_sp_distort_ch_7_levels_wack <= prbs_sp_distort_ch_7_levels_wreq;
      end if;
    end if;
  end process;

  -- Register prbs_sp_distort_ch_8_levels
  prbs_sp_distort_ch_8_levels_level_0_o <= prbs_sp_distort_ch_8_levels_level_0_reg;
  prbs_sp_distort_ch_8_levels_level_1_o <= prbs_sp_distort_ch_8_levels_level_1_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        prbs_sp_distort_ch_8_levels_level_0_reg <= "0000000000000000";
        prbs_sp_distort_ch_8_levels_level_1_reg <= "0000000000000000";
        prbs_sp_distort_ch_8_levels_wack <= '0';
      else
        if prbs_sp_distort_ch_8_levels_wreq = '1' then
          prbs_sp_distort_ch_8_levels_level_0_reg <= wr_dat_d0(15 downto 0);
          prbs_sp_distort_ch_8_levels_level_1_reg <= wr_dat_d0(31 downto 16);
        end if;
        prbs_sp_distort_ch_8_levels_wack <= prbs_sp_distort_ch_8_levels_wreq;
      end if;
    end if;
  end process;

  -- Register prbs_sp_distort_ch_9_levels
  prbs_sp_distort_ch_9_levels_level_0_o <= prbs_sp_distort_ch_9_levels_level_0_reg;
  prbs_sp_distort_ch_9_levels_level_1_o <= prbs_sp_distort_ch_9_levels_level_1_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        prbs_sp_distort_ch_9_levels_level_0_reg <= "0000000000000000";
        prbs_sp_distort_ch_9_levels_level_1_reg <= "0000000000000000";
        prbs_sp_distort_ch_9_levels_wack <= '0';
      else
        if prbs_sp_distort_ch_9_levels_wreq = '1' then
          prbs_sp_distort_ch_9_levels_level_0_reg <= wr_dat_d0(15 downto 0);
          prbs_sp_distort_ch_9_levels_level_1_reg <= wr_dat_d0(31 downto 16);
        end if;
        prbs_sp_distort_ch_9_levels_wack <= prbs_sp_distort_ch_9_levels_wreq;
      end if;
    end if;
  end process;

  -- Register prbs_sp_distort_ch_10_levels
  prbs_sp_distort_ch_10_levels_level_0_o <= prbs_sp_distort_ch_10_levels_level_0_reg;
  prbs_sp_distort_ch_10_levels_level_1_o <= prbs_sp_distort_ch_10_levels_level_1_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        prbs_sp_distort_ch_10_levels_level_0_reg <= "0000000000000000";
        prbs_sp_distort_ch_10_levels_level_1_reg <= "0000000000000000";
        prbs_sp_distort_ch_10_levels_wack <= '0';
      else
        if prbs_sp_distort_ch_10_levels_wreq = '1' then
          prbs_sp_distort_ch_10_levels_level_0_reg <= wr_dat_d0(15 downto 0);
          prbs_sp_distort_ch_10_levels_level_1_reg <= wr_dat_d0(31 downto 16);
        end if;
        prbs_sp_distort_ch_10_levels_wack <= prbs_sp_distort_ch_10_levels_wreq;
      end if;
    end if;
  end process;

  -- Register prbs_sp_distort_ch_11_levels
  prbs_sp_distort_ch_11_levels_level_0_o <= prbs_sp_distort_ch_11_levels_level_0_reg;
  prbs_sp_distort_ch_11_levels_level_1_o <= prbs_sp_distort_ch_11_levels_level_1_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        prbs_sp_distort_ch_11_levels_level_0_reg <= "0000000000000000";
        prbs_sp_distort_ch_11_levels_level_1_reg <= "0000000000000000";
        prbs_sp_distort_ch_11_levels_wack <= '0';
      else
        if prbs_sp_distort_ch_11_levels_wreq = '1' then
          prbs_sp_distort_ch_11_levels_level_0_reg <= wr_dat_d0(15 downto 0);
          prbs_sp_distort_ch_11_levels_level_1_reg <= wr_dat_d0(31 downto 16);
        end if;
        prbs_sp_distort_ch_11_levels_wack <= prbs_sp_distort_ch_11_levels_wreq;
      end if;
    end if;
  end process;

  -- Memory prbs_bpm_pos_distort_distort_ram
  process (adr_int, wr_adr_d0, prbs_bpm_pos_distort_distort_ram_wr) begin
    if prbs_bpm_pos_distort_distort_ram_wr = '1' then
      prbs_bpm_pos_distort_distort_ram_adr_int <= wr_adr_d0(10 downto 2);
    else
      prbs_bpm_pos_distort_distort_ram_adr_int <= adr_int(10 downto 2);
    end if;
  end process;
  prbs_bpm_pos_distort_distort_ram_wreq <= prbs_bpm_pos_distort_distort_ram_levels_int_wr;
  prbs_bpm_pos_distort_distort_ram_rr <= prbs_bpm_pos_distort_distort_ram_levels_rreq and not prbs_bpm_pos_distort_distort_ram_wreq;
  prbs_bpm_pos_distort_distort_ram_wr <= prbs_bpm_pos_distort_distort_ram_wreq;
  prbs_bpm_pos_distort_distort_ram_levels_raminst: cheby_dpssram
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
      addr_a_i             => prbs_bpm_pos_distort_distort_ram_adr_int,
      bwsel_a_i            => wr_sel_d0,
      data_a_i             => wr_dat_d0,
      data_a_o             => prbs_bpm_pos_distort_distort_ram_levels_int_dato,
      rd_a_i               => prbs_bpm_pos_distort_distort_ram_levels_rreq,
      wr_a_i               => prbs_bpm_pos_distort_distort_ram_levels_int_wr,
      addr_b_i             => prbs_bpm_pos_distort_distort_ram_adr_i,
      bwsel_b_i            => (others => '1'),
      data_b_i             => prbs_bpm_pos_distort_distort_ram_levels_ext_dat,
      data_b_o             => prbs_bpm_pos_distort_distort_ram_levels_dat_o,
      rd_b_i               => prbs_bpm_pos_distort_distort_ram_levels_rd_i,
      wr_b_i               => '0'
    );
  
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        prbs_bpm_pos_distort_distort_ram_levels_rack <= '0';
      else
        prbs_bpm_pos_distort_distort_ram_levels_rack <= prbs_bpm_pos_distort_distort_ram_levels_rreq;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, bpm_pos_flatenizer_ctl_wack, prbs_ctl_wack, prbs_sp_distort_ch_0_levels_wack, prbs_sp_distort_ch_1_levels_wack, prbs_sp_distort_ch_2_levels_wack, prbs_sp_distort_ch_3_levels_wack, prbs_sp_distort_ch_4_levels_wack, prbs_sp_distort_ch_5_levels_wack, prbs_sp_distort_ch_6_levels_wack, prbs_sp_distort_ch_7_levels_wack, prbs_sp_distort_ch_8_levels_wack, prbs_sp_distort_ch_9_levels_wack, prbs_sp_distort_ch_10_levels_wack, prbs_sp_distort_ch_11_levels_wack) begin
    bpm_pos_flatenizer_ctl_wreq <= '0';
    prbs_ctl_wreq <= '0';
    prbs_sp_distort_ch_0_levels_wreq <= '0';
    prbs_sp_distort_ch_1_levels_wreq <= '0';
    prbs_sp_distort_ch_2_levels_wreq <= '0';
    prbs_sp_distort_ch_3_levels_wreq <= '0';
    prbs_sp_distort_ch_4_levels_wreq <= '0';
    prbs_sp_distort_ch_5_levels_wreq <= '0';
    prbs_sp_distort_ch_6_levels_wreq <= '0';
    prbs_sp_distort_ch_7_levels_wreq <= '0';
    prbs_sp_distort_ch_8_levels_wreq <= '0';
    prbs_sp_distort_ch_9_levels_wreq <= '0';
    prbs_sp_distort_ch_10_levels_wreq <= '0';
    prbs_sp_distort_ch_11_levels_wreq <= '0';
    prbs_bpm_pos_distort_distort_ram_levels_int_wr <= '0';
    case wr_adr_d0(12 downto 11) is
    when "00" =>
      case wr_adr_d0(10 downto 2) is
      when "000000000" =>
        -- Reg bpm_pos_flatenizer_ctl
        bpm_pos_flatenizer_ctl_wreq <= wr_req_d0;
        wr_ack_int <= bpm_pos_flatenizer_ctl_wack;
      when "000000001" =>
        -- Reg bpm_pos_flatenizer_max_num_cte
        wr_ack_int <= wr_req_d0;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "10" =>
      case wr_adr_d0(10 downto 2) is
      when "000000000" =>
        -- Reg prbs_ctl
        prbs_ctl_wreq <= wr_req_d0;
        wr_ack_int <= prbs_ctl_wack;
      when "000000001" =>
        -- Reg prbs_sp_distort_mov_avg_max_num_taps_sel_cte
        wr_ack_int <= wr_req_d0;
      when "000010000" =>
        -- Reg prbs_sp_distort_ch_0_levels
        prbs_sp_distort_ch_0_levels_wreq <= wr_req_d0;
        wr_ack_int <= prbs_sp_distort_ch_0_levels_wack;
      when "000010001" =>
        -- Reg prbs_sp_distort_ch_1_levels
        prbs_sp_distort_ch_1_levels_wreq <= wr_req_d0;
        wr_ack_int <= prbs_sp_distort_ch_1_levels_wack;
      when "000010010" =>
        -- Reg prbs_sp_distort_ch_2_levels
        prbs_sp_distort_ch_2_levels_wreq <= wr_req_d0;
        wr_ack_int <= prbs_sp_distort_ch_2_levels_wack;
      when "000010011" =>
        -- Reg prbs_sp_distort_ch_3_levels
        prbs_sp_distort_ch_3_levels_wreq <= wr_req_d0;
        wr_ack_int <= prbs_sp_distort_ch_3_levels_wack;
      when "000010100" =>
        -- Reg prbs_sp_distort_ch_4_levels
        prbs_sp_distort_ch_4_levels_wreq <= wr_req_d0;
        wr_ack_int <= prbs_sp_distort_ch_4_levels_wack;
      when "000010101" =>
        -- Reg prbs_sp_distort_ch_5_levels
        prbs_sp_distort_ch_5_levels_wreq <= wr_req_d0;
        wr_ack_int <= prbs_sp_distort_ch_5_levels_wack;
      when "000010110" =>
        -- Reg prbs_sp_distort_ch_6_levels
        prbs_sp_distort_ch_6_levels_wreq <= wr_req_d0;
        wr_ack_int <= prbs_sp_distort_ch_6_levels_wack;
      when "000010111" =>
        -- Reg prbs_sp_distort_ch_7_levels
        prbs_sp_distort_ch_7_levels_wreq <= wr_req_d0;
        wr_ack_int <= prbs_sp_distort_ch_7_levels_wack;
      when "000011000" =>
        -- Reg prbs_sp_distort_ch_8_levels
        prbs_sp_distort_ch_8_levels_wreq <= wr_req_d0;
        wr_ack_int <= prbs_sp_distort_ch_8_levels_wack;
      when "000011001" =>
        -- Reg prbs_sp_distort_ch_9_levels
        prbs_sp_distort_ch_9_levels_wreq <= wr_req_d0;
        wr_ack_int <= prbs_sp_distort_ch_9_levels_wack;
      when "000011010" =>
        -- Reg prbs_sp_distort_ch_10_levels
        prbs_sp_distort_ch_10_levels_wreq <= wr_req_d0;
        wr_ack_int <= prbs_sp_distort_ch_10_levels_wack;
      when "000011011" =>
        -- Reg prbs_sp_distort_ch_11_levels
        prbs_sp_distort_ch_11_levels_wreq <= wr_req_d0;
        wr_ack_int <= prbs_sp_distort_ch_11_levels_wack;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "11" =>
      -- Memory prbs_bpm_pos_distort_distort_ram
      prbs_bpm_pos_distort_distort_ram_levels_int_wr <= wr_req_d0;
      wr_ack_int <= wr_req_d0;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (adr_int, rd_req_int, bpm_pos_flatenizer_ctl_base_bpm_id_reg, bpm_pos_flatenizer_max_num_cte_i, prbs_ctl_rst_reg, prbs_ctl_step_duration_reg, prbs_ctl_lfsr_length_reg, prbs_ctl_bpm_pos_distort_en_reg, prbs_ctl_sp_distort_en_reg, prbs_ctl_sp_distort_mov_avg_num_taps_sel_reg, prbs_sp_distort_mov_avg_max_num_taps_sel_cte_i, prbs_sp_distort_ch_0_levels_level_0_reg, prbs_sp_distort_ch_0_levels_level_1_reg, prbs_sp_distort_ch_1_levels_level_0_reg, prbs_sp_distort_ch_1_levels_level_1_reg, prbs_sp_distort_ch_2_levels_level_0_reg, prbs_sp_distort_ch_2_levels_level_1_reg, prbs_sp_distort_ch_3_levels_level_0_reg, prbs_sp_distort_ch_3_levels_level_1_reg, prbs_sp_distort_ch_4_levels_level_0_reg, prbs_sp_distort_ch_4_levels_level_1_reg, prbs_sp_distort_ch_5_levels_level_0_reg, prbs_sp_distort_ch_5_levels_level_1_reg, prbs_sp_distort_ch_6_levels_level_0_reg, prbs_sp_distort_ch_6_levels_level_1_reg, prbs_sp_distort_ch_7_levels_level_0_reg, prbs_sp_distort_ch_7_levels_level_1_reg, prbs_sp_distort_ch_8_levels_level_0_reg, prbs_sp_distort_ch_8_levels_level_1_reg, prbs_sp_distort_ch_9_levels_level_0_reg, prbs_sp_distort_ch_9_levels_level_1_reg, prbs_sp_distort_ch_10_levels_level_0_reg, prbs_sp_distort_ch_10_levels_level_1_reg, prbs_sp_distort_ch_11_levels_level_0_reg, prbs_sp_distort_ch_11_levels_level_1_reg, prbs_bpm_pos_distort_distort_ram_levels_int_dato, prbs_bpm_pos_distort_distort_ram_levels_rack) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    prbs_bpm_pos_distort_distort_ram_levels_rreq <= '0';
    case adr_int(12 downto 11) is
    when "00" =>
      case adr_int(10 downto 2) is
      when "000000000" =>
        -- Reg bpm_pos_flatenizer_ctl
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(7 downto 0) <= bpm_pos_flatenizer_ctl_base_bpm_id_reg;
        rd_dat_d0(31 downto 8) <= (others => '0');
      when "000000001" =>
        -- Reg bpm_pos_flatenizer_max_num_cte
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(15 downto 0) <= bpm_pos_flatenizer_max_num_cte_i;
        rd_dat_d0(31 downto 16) <= (others => '0');
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "10" =>
      case adr_int(10 downto 2) is
      when "000000000" =>
        -- Reg prbs_ctl
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= prbs_ctl_rst_reg;
        rd_dat_d0(10 downto 1) <= prbs_ctl_step_duration_reg;
        rd_dat_d0(15 downto 11) <= prbs_ctl_lfsr_length_reg;
        rd_dat_d0(16) <= prbs_ctl_bpm_pos_distort_en_reg;
        rd_dat_d0(17) <= prbs_ctl_sp_distort_en_reg;
        rd_dat_d0(20 downto 18) <= prbs_ctl_sp_distort_mov_avg_num_taps_sel_reg;
        rd_dat_d0(31 downto 21) <= (others => '0');
      when "000000001" =>
        -- Reg prbs_sp_distort_mov_avg_max_num_taps_sel_cte
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(7 downto 0) <= prbs_sp_distort_mov_avg_max_num_taps_sel_cte_i;
        rd_dat_d0(31 downto 8) <= (others => '0');
      when "000010000" =>
        -- Reg prbs_sp_distort_ch_0_levels
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(15 downto 0) <= prbs_sp_distort_ch_0_levels_level_0_reg;
        rd_dat_d0(31 downto 16) <= prbs_sp_distort_ch_0_levels_level_1_reg;
      when "000010001" =>
        -- Reg prbs_sp_distort_ch_1_levels
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(15 downto 0) <= prbs_sp_distort_ch_1_levels_level_0_reg;
        rd_dat_d0(31 downto 16) <= prbs_sp_distort_ch_1_levels_level_1_reg;
      when "000010010" =>
        -- Reg prbs_sp_distort_ch_2_levels
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(15 downto 0) <= prbs_sp_distort_ch_2_levels_level_0_reg;
        rd_dat_d0(31 downto 16) <= prbs_sp_distort_ch_2_levels_level_1_reg;
      when "000010011" =>
        -- Reg prbs_sp_distort_ch_3_levels
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(15 downto 0) <= prbs_sp_distort_ch_3_levels_level_0_reg;
        rd_dat_d0(31 downto 16) <= prbs_sp_distort_ch_3_levels_level_1_reg;
      when "000010100" =>
        -- Reg prbs_sp_distort_ch_4_levels
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(15 downto 0) <= prbs_sp_distort_ch_4_levels_level_0_reg;
        rd_dat_d0(31 downto 16) <= prbs_sp_distort_ch_4_levels_level_1_reg;
      when "000010101" =>
        -- Reg prbs_sp_distort_ch_5_levels
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(15 downto 0) <= prbs_sp_distort_ch_5_levels_level_0_reg;
        rd_dat_d0(31 downto 16) <= prbs_sp_distort_ch_5_levels_level_1_reg;
      when "000010110" =>
        -- Reg prbs_sp_distort_ch_6_levels
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(15 downto 0) <= prbs_sp_distort_ch_6_levels_level_0_reg;
        rd_dat_d0(31 downto 16) <= prbs_sp_distort_ch_6_levels_level_1_reg;
      when "000010111" =>
        -- Reg prbs_sp_distort_ch_7_levels
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(15 downto 0) <= prbs_sp_distort_ch_7_levels_level_0_reg;
        rd_dat_d0(31 downto 16) <= prbs_sp_distort_ch_7_levels_level_1_reg;
      when "000011000" =>
        -- Reg prbs_sp_distort_ch_8_levels
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(15 downto 0) <= prbs_sp_distort_ch_8_levels_level_0_reg;
        rd_dat_d0(31 downto 16) <= prbs_sp_distort_ch_8_levels_level_1_reg;
      when "000011001" =>
        -- Reg prbs_sp_distort_ch_9_levels
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(15 downto 0) <= prbs_sp_distort_ch_9_levels_level_0_reg;
        rd_dat_d0(31 downto 16) <= prbs_sp_distort_ch_9_levels_level_1_reg;
      when "000011010" =>
        -- Reg prbs_sp_distort_ch_10_levels
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(15 downto 0) <= prbs_sp_distort_ch_10_levels_level_0_reg;
        rd_dat_d0(31 downto 16) <= prbs_sp_distort_ch_10_levels_level_1_reg;
      when "000011011" =>
        -- Reg prbs_sp_distort_ch_11_levels
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(15 downto 0) <= prbs_sp_distort_ch_11_levels_level_0_reg;
        rd_dat_d0(31 downto 16) <= prbs_sp_distort_ch_11_levels_level_1_reg;
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "11" =>
      -- Memory prbs_bpm_pos_distort_distort_ram
      rd_dat_d0 <= prbs_bpm_pos_distort_distort_ram_levels_int_dato;
      prbs_bpm_pos_distort_distort_ram_levels_rreq <= rd_req_int;
      rd_ack_d0 <= prbs_bpm_pos_distort_distort_ram_levels_rack;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
