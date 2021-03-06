-------------------------------------------------------------------------------
-- Title          : Wishbone slave core for FOFB CC registers
-------------------------------------------------------------------------------
-- File           : fofb_cc_regs.vhdl
-- Author         : auto-generated by wbgen2 from fofb_cc_regs.wb
-- Created        : Mon Feb 22 18:59:46 2021
-- Standard       : VHDL'87
-------------------------------------------------------------------------------
-- THIS FILE WAS GENERATED BY wbgen2 FROM SOURCE FILE fofb_cc_regs.wb
-- DO NOT HAND-EDIT UNLESS IT'S ABSOLUTELY NECESSARY!
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wbgen2_pkg.all;

entity wb_fofb_cc_regs is
  port (
    rst_n_i              : in    std_logic;
    clk_sys_i            : in    std_logic;
    wb_adr_i             : in    std_logic_vector(11 downto 0);
    wb_dat_i             : in    std_logic_vector(31 downto 0);
    wb_dat_o             : out   std_logic_vector(31 downto 0);
    wb_cyc_i             : in    std_logic;
    wb_sel_i             : in    std_logic_vector(3 downto 0);
    wb_stb_i             : in    std_logic;
    wb_we_i              : in    std_logic;
    wb_ack_o             : out   std_logic;
    wb_stall_o           : out   std_logic;
    fofb_cc_clk_ram_reg_i : in    std_logic;
    fofb_cc_clk_sys_i    : in    std_logic;
    -- Port for asynchronous (clock: fofb_cc_clk_ram_reg_i) MONOSTABLE field: 'signals FOFB CC module to read configuration RAM' in reg: 'FOFB CC configuration register'
    fofb_cc_regs_cfg_val_act_part_o : out   std_logic;
    -- Port for asynchronous (clock: fofb_cc_clk_ram_reg_i) BIT field: 'unused' in reg: 'FOFB CC configuration register'
    fofb_cc_regs_cfg_val_unused_o : out   std_logic;
    -- Port for asynchronous (clock: fofb_cc_clk_ram_reg_i) MONOSTABLE field: 'clears gigabit transceiver errors' in reg: 'FOFB CC configuration register'
    fofb_cc_regs_cfg_val_err_clr_o : out   std_logic;
    -- Port for asynchronous (clock: fofb_cc_clk_ram_reg_i) BIT field: 'enables CC module' in reg: 'FOFB CC configuration register'
    fofb_cc_regs_cfg_val_cc_enable_o : out   std_logic;
    -- Port for asynchronous (clock: fofb_cc_clk_ram_reg_i) BIT field: 'timeframe start override. BPM can override internal timeframe start signal and use MGT generated one.' in reg: 'FOFB CC configuration register'
    fofb_cc_regs_cfg_val_tfs_override_o : out   std_logic;
    -- Port for asynchronous (clock: fofb_cc_clk_ram_reg_i) BIT field: 'enable FOFB CC TOA module for reading' in reg: 'FOFB CC Time-of-Arrival configuration register'
    fofb_cc_regs_toa_ctl_rd_en_o : out   std_logic;
    -- Port for asynchronous (clock: fofb_cc_clk_ram_reg_i) MONOSTABLE field: 'Read next TOA address' in reg: 'FOFB CC Time-of-Arrival configuration register'
    fofb_cc_regs_toa_ctl_rd_str_o : out   std_logic;
    -- Port for asynchronous (clock: fofb_cc_clk_sys_i) std_logic_vector field: 'FOFB CC TOA data' in reg: 'FOFB CC Time-of-Arrival data'
    fofb_cc_regs_toa_data_val_i : in    std_logic_vector(31 downto 0);
    -- Port for asynchronous (clock: fofb_cc_clk_ram_reg_i) BIT field: 'enable FOFB CC RCB module for reading' in reg: 'FOFB CC Received Buffer configuration register'
    fofb_cc_regs_rcb_ctl_rd_en_o : out   std_logic;
    -- Port for asynchronous (clock: fofb_cc_clk_ram_reg_i) MONOSTABLE field: 'Read next RCB address' in reg: 'FOFB CC Received Buffer configuration register'
    fofb_cc_regs_rcb_ctl_rd_str_o : out   std_logic;
    -- Port for asynchronous (clock: fofb_cc_clk_sys_i) std_logic_vector field: 'FOFB CC RCB data' in reg: 'FOFB CC Received Buffer data'
    fofb_cc_regs_rcb_data_val_i : in    std_logic_vector(31 downto 0);
    -- Port for asynchronous (clock: fofb_cc_clk_sys_i) std_logic_vector field: 'unused' in reg: 'FOFB CC X/Y buffer configuration register'
    fofb_cc_regs_xy_buff_ctl_unused_i : in    std_logic_vector(15 downto 0);
    -- Ports for asynchronous (clock: fofb_cc_clk_ram_reg_i) std_logic_vector field: 'Read XY_BUFF address' in reg: 'FOFB CC X/Y buffer configuration register'
    fofb_cc_regs_xy_buff_ctl_addr_o : out   std_logic_vector(15 downto 0);
    fofb_cc_regs_xy_buff_ctl_addr_i : in    std_logic_vector(15 downto 0);
    fofb_cc_regs_xy_buff_ctl_addr_load_o : out   std_logic;
    -- Port for asynchronous (clock: fofb_cc_clk_sys_i) std_logic_vector field: 'FOFB CC XY_BUFF data MSB' in reg: 'FOFB CC X/Y buffer MSB'
    fofb_cc_regs_xy_buff_data_msb_val_i : in    std_logic_vector(31 downto 0);
    -- Port for asynchronous (clock: fofb_cc_clk_sys_i) std_logic_vector field: 'FOFB CC XY_BUFF data LSB' in reg: 'FOFB CC X/Y buffer LSB'
    fofb_cc_regs_xy_buff_data_lsb_val_i : in    std_logic_vector(31 downto 0);
    -- Ports for RAM: FOFB CC RAM for register map
    fofb_cc_regs_ram_reg_addr_i : in    std_logic_vector(10 downto 0);
    -- Read data output
    fofb_cc_regs_ram_reg_data_o : out   std_logic_vector(31 downto 0);
    -- Read strobe input (active high)
    fofb_cc_regs_ram_reg_rd_i : in    std_logic;
    -- Write data input
    fofb_cc_regs_ram_reg_data_i : in    std_logic_vector(31 downto 0);
    -- Write strobe (active high)
    fofb_cc_regs_ram_reg_wr_i : in    std_logic
  );
end wb_fofb_cc_regs;

architecture syn of wb_fofb_cc_regs is

  signal fofb_cc_regs_cfg_val_act_part_int : std_logic;
  signal fofb_cc_regs_cfg_val_act_part_int_delay : std_logic;
  signal fofb_cc_regs_cfg_val_act_part_sync0 : std_logic;
  signal fofb_cc_regs_cfg_val_act_part_sync1 : std_logic;
  signal fofb_cc_regs_cfg_val_act_part_sync2 : std_logic;
  signal fofb_cc_regs_cfg_val_unused_int : std_logic;
  signal fofb_cc_regs_cfg_val_unused_sync0 : std_logic;
  signal fofb_cc_regs_cfg_val_unused_sync1 : std_logic;
  signal fofb_cc_regs_cfg_val_err_clr_int : std_logic;
  signal fofb_cc_regs_cfg_val_err_clr_int_delay : std_logic;
  signal fofb_cc_regs_cfg_val_err_clr_sync0 : std_logic;
  signal fofb_cc_regs_cfg_val_err_clr_sync1 : std_logic;
  signal fofb_cc_regs_cfg_val_err_clr_sync2 : std_logic;
  signal fofb_cc_regs_cfg_val_cc_enable_int : std_logic;
  signal fofb_cc_regs_cfg_val_cc_enable_sync0 : std_logic;
  signal fofb_cc_regs_cfg_val_cc_enable_sync1 : std_logic;
  signal fofb_cc_regs_cfg_val_tfs_override_int : std_logic;
  signal fofb_cc_regs_cfg_val_tfs_override_sync0 : std_logic;
  signal fofb_cc_regs_cfg_val_tfs_override_sync1 : std_logic;
  signal fofb_cc_regs_toa_ctl_rd_en_int : std_logic;
  signal fofb_cc_regs_toa_ctl_rd_en_sync0 : std_logic;
  signal fofb_cc_regs_toa_ctl_rd_en_sync1 : std_logic;
  signal fofb_cc_regs_toa_ctl_rd_str_int : std_logic;
  signal fofb_cc_regs_toa_ctl_rd_str_int_delay : std_logic;
  signal fofb_cc_regs_toa_ctl_rd_str_sync0 : std_logic;
  signal fofb_cc_regs_toa_ctl_rd_str_sync1 : std_logic;
  signal fofb_cc_regs_toa_ctl_rd_str_sync2 : std_logic;
  signal fofb_cc_regs_toa_data_val_int  : std_logic_vector(31 downto 0);
  signal fofb_cc_regs_toa_data_val_lwb  : std_logic;
  signal fofb_cc_regs_toa_data_val_lwb_delay : std_logic;
  signal fofb_cc_regs_toa_data_val_lwb_in_progress : std_logic;
  signal fofb_cc_regs_toa_data_val_lwb_s0 : std_logic;
  signal fofb_cc_regs_toa_data_val_lwb_s1 : std_logic;
  signal fofb_cc_regs_toa_data_val_lwb_s2 : std_logic;
  signal fofb_cc_regs_rcb_ctl_rd_en_int : std_logic;
  signal fofb_cc_regs_rcb_ctl_rd_en_sync0 : std_logic;
  signal fofb_cc_regs_rcb_ctl_rd_en_sync1 : std_logic;
  signal fofb_cc_regs_rcb_ctl_rd_str_int : std_logic;
  signal fofb_cc_regs_rcb_ctl_rd_str_int_delay : std_logic;
  signal fofb_cc_regs_rcb_ctl_rd_str_sync0 : std_logic;
  signal fofb_cc_regs_rcb_ctl_rd_str_sync1 : std_logic;
  signal fofb_cc_regs_rcb_ctl_rd_str_sync2 : std_logic;
  signal fofb_cc_regs_rcb_data_val_int  : std_logic_vector(31 downto 0);
  signal fofb_cc_regs_rcb_data_val_lwb  : std_logic;
  signal fofb_cc_regs_rcb_data_val_lwb_delay : std_logic;
  signal fofb_cc_regs_rcb_data_val_lwb_in_progress : std_logic;
  signal fofb_cc_regs_rcb_data_val_lwb_s0 : std_logic;
  signal fofb_cc_regs_rcb_data_val_lwb_s1 : std_logic;
  signal fofb_cc_regs_rcb_data_val_lwb_s2 : std_logic;
  signal fofb_cc_regs_xy_buff_ctl_unused_int : std_logic_vector(15 downto 0);
  signal fofb_cc_regs_xy_buff_ctl_unused_lwb : std_logic;
  signal fofb_cc_regs_xy_buff_ctl_unused_lwb_delay : std_logic;
  signal fofb_cc_regs_xy_buff_ctl_unused_lwb_in_progress : std_logic;
  signal fofb_cc_regs_xy_buff_ctl_unused_lwb_s0 : std_logic;
  signal fofb_cc_regs_xy_buff_ctl_unused_lwb_s1 : std_logic;
  signal fofb_cc_regs_xy_buff_ctl_unused_lwb_s2 : std_logic;
  signal fofb_cc_regs_xy_buff_ctl_addr_int_read : std_logic_vector(15 downto 0);
  signal fofb_cc_regs_xy_buff_ctl_addr_int_write : std_logic_vector(15 downto 0);
  signal fofb_cc_regs_xy_buff_ctl_addr_lw : std_logic;
  signal fofb_cc_regs_xy_buff_ctl_addr_lw_delay : std_logic;
  signal fofb_cc_regs_xy_buff_ctl_addr_lw_read_in_progress : std_logic;
  signal fofb_cc_regs_xy_buff_ctl_addr_lw_s0 : std_logic;
  signal fofb_cc_regs_xy_buff_ctl_addr_lw_s1 : std_logic;
  signal fofb_cc_regs_xy_buff_ctl_addr_lw_s2 : std_logic;
  signal fofb_cc_regs_xy_buff_ctl_addr_rwsel : std_logic;
  signal fofb_cc_regs_xy_buff_data_msb_val_int : std_logic_vector(31 downto 0);
  signal fofb_cc_regs_xy_buff_data_msb_val_lwb : std_logic;
  signal fofb_cc_regs_xy_buff_data_msb_val_lwb_delay : std_logic;
  signal fofb_cc_regs_xy_buff_data_msb_val_lwb_in_progress : std_logic;
  signal fofb_cc_regs_xy_buff_data_msb_val_lwb_s0 : std_logic;
  signal fofb_cc_regs_xy_buff_data_msb_val_lwb_s1 : std_logic;
  signal fofb_cc_regs_xy_buff_data_msb_val_lwb_s2 : std_logic;
  signal fofb_cc_regs_xy_buff_data_lsb_val_int : std_logic_vector(31 downto 0);
  signal fofb_cc_regs_xy_buff_data_lsb_val_lwb : std_logic;
  signal fofb_cc_regs_xy_buff_data_lsb_val_lwb_delay : std_logic;
  signal fofb_cc_regs_xy_buff_data_lsb_val_lwb_in_progress : std_logic;
  signal fofb_cc_regs_xy_buff_data_lsb_val_lwb_s0 : std_logic;
  signal fofb_cc_regs_xy_buff_data_lsb_val_lwb_s1 : std_logic;
  signal fofb_cc_regs_xy_buff_data_lsb_val_lwb_s2 : std_logic;
  signal fofb_cc_regs_ram_reg_rddata_int : std_logic_vector(31 downto 0);
  signal fofb_cc_regs_ram_reg_rd_int    : std_logic;
  signal fofb_cc_regs_ram_reg_wr_int    : std_logic;
  signal ack_sreg                       : std_logic_vector(9 downto 0);
  signal rddata_reg                     : std_logic_vector(31 downto 0);
  signal wrdata_reg                     : std_logic_vector(31 downto 0);
  signal bwsel_reg                      : std_logic_vector(3 downto 0);
  signal rwaddr_reg                     : std_logic_vector(11 downto 0);
  signal ack_in_progress                : std_logic;
  signal wr_int                         : std_logic;
  signal rd_int                         : std_logic;
  signal allones                        : std_logic_vector(31 downto 0);
  signal allzeros                       : std_logic_vector(31 downto 0);

begin
  -- Some internal signals assignments. For (foreseen) compatibility with other bus standards.
  wrdata_reg <= wb_dat_i;
  bwsel_reg <= wb_sel_i;
  rd_int <= wb_cyc_i and (wb_stb_i and (not wb_we_i));
  wr_int <= wb_cyc_i and (wb_stb_i and wb_we_i);
  allones <= (others => '1');
  allzeros <= (others => '0');
  -- 
  -- Main register bank access process.
  process (clk_sys_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      ack_sreg <= "0000000000";
      ack_in_progress <= '0';
      rddata_reg <= "00000000000000000000000000000000";
      fofb_cc_regs_cfg_val_act_part_int <= '0';
      fofb_cc_regs_cfg_val_act_part_int_delay <= '0';
      fofb_cc_regs_cfg_val_unused_int <= '0';
      fofb_cc_regs_cfg_val_err_clr_int <= '0';
      fofb_cc_regs_cfg_val_err_clr_int_delay <= '0';
      fofb_cc_regs_cfg_val_cc_enable_int <= '0';
      fofb_cc_regs_cfg_val_tfs_override_int <= '0';
      fofb_cc_regs_toa_ctl_rd_en_int <= '0';
      fofb_cc_regs_toa_ctl_rd_str_int <= '0';
      fofb_cc_regs_toa_ctl_rd_str_int_delay <= '0';
      fofb_cc_regs_toa_data_val_lwb <= '0';
      fofb_cc_regs_toa_data_val_lwb_delay <= '0';
      fofb_cc_regs_toa_data_val_lwb_in_progress <= '0';
      fofb_cc_regs_rcb_ctl_rd_en_int <= '0';
      fofb_cc_regs_rcb_ctl_rd_str_int <= '0';
      fofb_cc_regs_rcb_ctl_rd_str_int_delay <= '0';
      fofb_cc_regs_rcb_data_val_lwb <= '0';
      fofb_cc_regs_rcb_data_val_lwb_delay <= '0';
      fofb_cc_regs_rcb_data_val_lwb_in_progress <= '0';
      fofb_cc_regs_xy_buff_ctl_unused_lwb <= '0';
      fofb_cc_regs_xy_buff_ctl_unused_lwb_delay <= '0';
      fofb_cc_regs_xy_buff_ctl_unused_lwb_in_progress <= '0';
      fofb_cc_regs_xy_buff_ctl_addr_lw <= '0';
      fofb_cc_regs_xy_buff_ctl_addr_lw_delay <= '0';
      fofb_cc_regs_xy_buff_ctl_addr_lw_read_in_progress <= '0';
      fofb_cc_regs_xy_buff_ctl_addr_rwsel <= '0';
      fofb_cc_regs_xy_buff_ctl_addr_int_write <= "0000000000000000";
      fofb_cc_regs_xy_buff_data_msb_val_lwb <= '0';
      fofb_cc_regs_xy_buff_data_msb_val_lwb_delay <= '0';
      fofb_cc_regs_xy_buff_data_msb_val_lwb_in_progress <= '0';
      fofb_cc_regs_xy_buff_data_lsb_val_lwb <= '0';
      fofb_cc_regs_xy_buff_data_lsb_val_lwb_delay <= '0';
      fofb_cc_regs_xy_buff_data_lsb_val_lwb_in_progress <= '0';
    elsif rising_edge(clk_sys_i) then
      -- advance the ACK generator shift register
      ack_sreg(8 downto 0) <= ack_sreg(9 downto 1);
      ack_sreg(9) <= '0';
      if (ack_in_progress = '1') then
        if (ack_sreg(0) = '1') then
          ack_in_progress <= '0';
        else
          fofb_cc_regs_cfg_val_act_part_int <= fofb_cc_regs_cfg_val_act_part_int_delay;
          fofb_cc_regs_cfg_val_act_part_int_delay <= '0';
          fofb_cc_regs_cfg_val_err_clr_int <= fofb_cc_regs_cfg_val_err_clr_int_delay;
          fofb_cc_regs_cfg_val_err_clr_int_delay <= '0';
          fofb_cc_regs_toa_ctl_rd_str_int <= fofb_cc_regs_toa_ctl_rd_str_int_delay;
          fofb_cc_regs_toa_ctl_rd_str_int_delay <= '0';
          fofb_cc_regs_toa_data_val_lwb <= fofb_cc_regs_toa_data_val_lwb_delay;
          fofb_cc_regs_toa_data_val_lwb_delay <= '0';
          if ((ack_sreg(1) = '1') and (fofb_cc_regs_toa_data_val_lwb_in_progress = '1')) then
            rddata_reg(31 downto 0) <= fofb_cc_regs_toa_data_val_int;
            fofb_cc_regs_toa_data_val_lwb_in_progress <= '0';
          end if;
          fofb_cc_regs_rcb_ctl_rd_str_int <= fofb_cc_regs_rcb_ctl_rd_str_int_delay;
          fofb_cc_regs_rcb_ctl_rd_str_int_delay <= '0';
          fofb_cc_regs_rcb_data_val_lwb <= fofb_cc_regs_rcb_data_val_lwb_delay;
          fofb_cc_regs_rcb_data_val_lwb_delay <= '0';
          if ((ack_sreg(1) = '1') and (fofb_cc_regs_rcb_data_val_lwb_in_progress = '1')) then
            rddata_reg(31 downto 0) <= fofb_cc_regs_rcb_data_val_int;
            fofb_cc_regs_rcb_data_val_lwb_in_progress <= '0';
          end if;
          fofb_cc_regs_xy_buff_ctl_unused_lwb <= fofb_cc_regs_xy_buff_ctl_unused_lwb_delay;
          fofb_cc_regs_xy_buff_ctl_unused_lwb_delay <= '0';
          if ((ack_sreg(1) = '1') and (fofb_cc_regs_xy_buff_ctl_unused_lwb_in_progress = '1')) then
            rddata_reg(15 downto 0) <= fofb_cc_regs_xy_buff_ctl_unused_int;
            fofb_cc_regs_xy_buff_ctl_unused_lwb_in_progress <= '0';
          end if;
          fofb_cc_regs_xy_buff_ctl_addr_lw <= fofb_cc_regs_xy_buff_ctl_addr_lw_delay;
          fofb_cc_regs_xy_buff_ctl_addr_lw_delay <= '0';
          if ((ack_sreg(1) = '1') and (fofb_cc_regs_xy_buff_ctl_addr_lw_read_in_progress = '1')) then
            rddata_reg(31 downto 16) <= fofb_cc_regs_xy_buff_ctl_addr_int_read;
            fofb_cc_regs_xy_buff_ctl_addr_lw_read_in_progress <= '0';
          end if;
          fofb_cc_regs_xy_buff_data_msb_val_lwb <= fofb_cc_regs_xy_buff_data_msb_val_lwb_delay;
          fofb_cc_regs_xy_buff_data_msb_val_lwb_delay <= '0';
          if ((ack_sreg(1) = '1') and (fofb_cc_regs_xy_buff_data_msb_val_lwb_in_progress = '1')) then
            rddata_reg(31 downto 0) <= fofb_cc_regs_xy_buff_data_msb_val_int;
            fofb_cc_regs_xy_buff_data_msb_val_lwb_in_progress <= '0';
          end if;
          fofb_cc_regs_xy_buff_data_lsb_val_lwb <= fofb_cc_regs_xy_buff_data_lsb_val_lwb_delay;
          fofb_cc_regs_xy_buff_data_lsb_val_lwb_delay <= '0';
          if ((ack_sreg(1) = '1') and (fofb_cc_regs_xy_buff_data_lsb_val_lwb_in_progress = '1')) then
            rddata_reg(31 downto 0) <= fofb_cc_regs_xy_buff_data_lsb_val_int;
            fofb_cc_regs_xy_buff_data_lsb_val_lwb_in_progress <= '0';
          end if;
        end if;
      else
        if ((wb_cyc_i = '1') and (wb_stb_i = '1')) then
          case rwaddr_reg(11) is
          when '0' =>
            case rwaddr_reg(2 downto 0) is
            when "000" =>
              if (wb_we_i = '1') then
                fofb_cc_regs_cfg_val_act_part_int <= wrdata_reg(0);
                fofb_cc_regs_cfg_val_act_part_int_delay <= wrdata_reg(0);
                fofb_cc_regs_cfg_val_unused_int <= wrdata_reg(1);
                fofb_cc_regs_cfg_val_err_clr_int <= wrdata_reg(2);
                fofb_cc_regs_cfg_val_err_clr_int_delay <= wrdata_reg(2);
                fofb_cc_regs_cfg_val_cc_enable_int <= wrdata_reg(3);
                fofb_cc_regs_cfg_val_tfs_override_int <= wrdata_reg(4);
              end if;
              rddata_reg(0) <= '0';
              rddata_reg(1) <= fofb_cc_regs_cfg_val_unused_int;
              rddata_reg(2) <= '0';
              rddata_reg(3) <= fofb_cc_regs_cfg_val_cc_enable_int;
              rddata_reg(4) <= fofb_cc_regs_cfg_val_tfs_override_int;
              rddata_reg(5) <= 'X';
              rddata_reg(6) <= 'X';
              rddata_reg(7) <= 'X';
              rddata_reg(8) <= 'X';
              rddata_reg(9) <= 'X';
              rddata_reg(10) <= 'X';
              rddata_reg(11) <= 'X';
              rddata_reg(12) <= 'X';
              rddata_reg(13) <= 'X';
              rddata_reg(14) <= 'X';
              rddata_reg(15) <= 'X';
              rddata_reg(16) <= 'X';
              rddata_reg(17) <= 'X';
              rddata_reg(18) <= 'X';
              rddata_reg(19) <= 'X';
              rddata_reg(20) <= 'X';
              rddata_reg(21) <= 'X';
              rddata_reg(22) <= 'X';
              rddata_reg(23) <= 'X';
              rddata_reg(24) <= 'X';
              rddata_reg(25) <= 'X';
              rddata_reg(26) <= 'X';
              rddata_reg(27) <= 'X';
              rddata_reg(28) <= 'X';
              rddata_reg(29) <= 'X';
              rddata_reg(30) <= 'X';
              rddata_reg(31) <= 'X';
              ack_sreg(4) <= '1';
              ack_in_progress <= '1';
            when "001" =>
              if (wb_we_i = '1') then
                fofb_cc_regs_toa_ctl_rd_en_int <= wrdata_reg(0);
                fofb_cc_regs_toa_ctl_rd_str_int <= wrdata_reg(1);
                fofb_cc_regs_toa_ctl_rd_str_int_delay <= wrdata_reg(1);
              end if;
              rddata_reg(0) <= fofb_cc_regs_toa_ctl_rd_en_int;
              rddata_reg(1) <= '0';
              rddata_reg(2) <= 'X';
              rddata_reg(3) <= 'X';
              rddata_reg(4) <= 'X';
              rddata_reg(5) <= 'X';
              rddata_reg(6) <= 'X';
              rddata_reg(7) <= 'X';
              rddata_reg(8) <= 'X';
              rddata_reg(9) <= 'X';
              rddata_reg(10) <= 'X';
              rddata_reg(11) <= 'X';
              rddata_reg(12) <= 'X';
              rddata_reg(13) <= 'X';
              rddata_reg(14) <= 'X';
              rddata_reg(15) <= 'X';
              rddata_reg(16) <= 'X';
              rddata_reg(17) <= 'X';
              rddata_reg(18) <= 'X';
              rddata_reg(19) <= 'X';
              rddata_reg(20) <= 'X';
              rddata_reg(21) <= 'X';
              rddata_reg(22) <= 'X';
              rddata_reg(23) <= 'X';
              rddata_reg(24) <= 'X';
              rddata_reg(25) <= 'X';
              rddata_reg(26) <= 'X';
              rddata_reg(27) <= 'X';
              rddata_reg(28) <= 'X';
              rddata_reg(29) <= 'X';
              rddata_reg(30) <= 'X';
              rddata_reg(31) <= 'X';
              ack_sreg(4) <= '1';
              ack_in_progress <= '1';
            when "010" =>
              if (wb_we_i = '1') then
              end if;
              if (wb_we_i = '0') then
                fofb_cc_regs_toa_data_val_lwb <= '1';
                fofb_cc_regs_toa_data_val_lwb_delay <= '1';
                fofb_cc_regs_toa_data_val_lwb_in_progress <= '1';
              end if;
              ack_sreg(5) <= '1';
              ack_in_progress <= '1';
            when "011" =>
              if (wb_we_i = '1') then
                fofb_cc_regs_rcb_ctl_rd_en_int <= wrdata_reg(0);
                fofb_cc_regs_rcb_ctl_rd_str_int <= wrdata_reg(1);
                fofb_cc_regs_rcb_ctl_rd_str_int_delay <= wrdata_reg(1);
              end if;
              rddata_reg(0) <= fofb_cc_regs_rcb_ctl_rd_en_int;
              rddata_reg(1) <= '0';
              rddata_reg(2) <= 'X';
              rddata_reg(3) <= 'X';
              rddata_reg(4) <= 'X';
              rddata_reg(5) <= 'X';
              rddata_reg(6) <= 'X';
              rddata_reg(7) <= 'X';
              rddata_reg(8) <= 'X';
              rddata_reg(9) <= 'X';
              rddata_reg(10) <= 'X';
              rddata_reg(11) <= 'X';
              rddata_reg(12) <= 'X';
              rddata_reg(13) <= 'X';
              rddata_reg(14) <= 'X';
              rddata_reg(15) <= 'X';
              rddata_reg(16) <= 'X';
              rddata_reg(17) <= 'X';
              rddata_reg(18) <= 'X';
              rddata_reg(19) <= 'X';
              rddata_reg(20) <= 'X';
              rddata_reg(21) <= 'X';
              rddata_reg(22) <= 'X';
              rddata_reg(23) <= 'X';
              rddata_reg(24) <= 'X';
              rddata_reg(25) <= 'X';
              rddata_reg(26) <= 'X';
              rddata_reg(27) <= 'X';
              rddata_reg(28) <= 'X';
              rddata_reg(29) <= 'X';
              rddata_reg(30) <= 'X';
              rddata_reg(31) <= 'X';
              ack_sreg(4) <= '1';
              ack_in_progress <= '1';
            when "100" =>
              if (wb_we_i = '1') then
              end if;
              if (wb_we_i = '0') then
                fofb_cc_regs_rcb_data_val_lwb <= '1';
                fofb_cc_regs_rcb_data_val_lwb_delay <= '1';
                fofb_cc_regs_rcb_data_val_lwb_in_progress <= '1';
              end if;
              ack_sreg(5) <= '1';
              ack_in_progress <= '1';
            when "101" =>
              if (wb_we_i = '1') then
                fofb_cc_regs_xy_buff_ctl_addr_int_write <= wrdata_reg(31 downto 16);
                fofb_cc_regs_xy_buff_ctl_addr_lw <= '1';
                fofb_cc_regs_xy_buff_ctl_addr_lw_delay <= '1';
                fofb_cc_regs_xy_buff_ctl_addr_lw_read_in_progress <= '0';
                fofb_cc_regs_xy_buff_ctl_addr_rwsel <= '1';
              end if;
              if (wb_we_i = '0') then
                fofb_cc_regs_xy_buff_ctl_unused_lwb <= '1';
                fofb_cc_regs_xy_buff_ctl_unused_lwb_delay <= '1';
                fofb_cc_regs_xy_buff_ctl_unused_lwb_in_progress <= '1';
              end if;
              if (wb_we_i = '0') then
                fofb_cc_regs_xy_buff_ctl_addr_lw <= '1';
                fofb_cc_regs_xy_buff_ctl_addr_lw_delay <= '1';
                fofb_cc_regs_xy_buff_ctl_addr_lw_read_in_progress <= '1';
                fofb_cc_regs_xy_buff_ctl_addr_rwsel <= '0';
              end if;
              ack_sreg(5) <= '1';
              ack_in_progress <= '1';
            when "110" =>
              if (wb_we_i = '1') then
              end if;
              if (wb_we_i = '0') then
                fofb_cc_regs_xy_buff_data_msb_val_lwb <= '1';
                fofb_cc_regs_xy_buff_data_msb_val_lwb_delay <= '1';
                fofb_cc_regs_xy_buff_data_msb_val_lwb_in_progress <= '1';
              end if;
              ack_sreg(5) <= '1';
              ack_in_progress <= '1';
            when "111" =>
              if (wb_we_i = '1') then
              end if;
              if (wb_we_i = '0') then
                fofb_cc_regs_xy_buff_data_lsb_val_lwb <= '1';
                fofb_cc_regs_xy_buff_data_lsb_val_lwb_delay <= '1';
                fofb_cc_regs_xy_buff_data_lsb_val_lwb_in_progress <= '1';
              end if;
              ack_sreg(5) <= '1';
              ack_in_progress <= '1';
            when others =>
              -- prevent the slave from hanging the bus on invalid address
              ack_in_progress <= '1';
              ack_sreg(0) <= '1';
            end case;
          when '1' =>
            if (rd_int = '1') then
              ack_sreg(0) <= '1';
            else
              ack_sreg(0) <= '1';
            end if;
            ack_in_progress <= '1';
          when others =>
            -- prevent the slave from hanging the bus on invalid address
            ack_in_progress <= '1';
            ack_sreg(0) <= '1';
          end case;
        end if;
      end if;
    end if;
  end process;


  -- Data output multiplexer process
  process (rddata_reg, rwaddr_reg, fofb_cc_regs_ram_reg_rddata_int, wb_adr_i  )
  begin
    case rwaddr_reg(11) is
    when '1' =>
      wb_dat_o(31 downto 0) <= fofb_cc_regs_ram_reg_rddata_int;
    when others =>
      wb_dat_o <= rddata_reg;
    end case;
  end process;


  -- Read & write lines decoder for RAMs
  process (wb_adr_i, rd_int, wr_int  )
  begin
    if (wb_adr_i(11) = '1') then
      fofb_cc_regs_ram_reg_rd_int <= rd_int;
      fofb_cc_regs_ram_reg_wr_int <= wr_int;
    else
      fofb_cc_regs_ram_reg_wr_int <= '0';
      fofb_cc_regs_ram_reg_rd_int <= '0';
    end if;
  end process;


  -- signals FOFB CC module to read configuration RAM
  process (fofb_cc_clk_ram_reg_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      fofb_cc_regs_cfg_val_act_part_o <= '0';
      fofb_cc_regs_cfg_val_act_part_sync0 <= '0';
      fofb_cc_regs_cfg_val_act_part_sync1 <= '0';
      fofb_cc_regs_cfg_val_act_part_sync2 <= '0';
    elsif rising_edge(fofb_cc_clk_ram_reg_i) then
      fofb_cc_regs_cfg_val_act_part_sync0 <= fofb_cc_regs_cfg_val_act_part_int;
      fofb_cc_regs_cfg_val_act_part_sync1 <= fofb_cc_regs_cfg_val_act_part_sync0;
      fofb_cc_regs_cfg_val_act_part_sync2 <= fofb_cc_regs_cfg_val_act_part_sync1;
      fofb_cc_regs_cfg_val_act_part_o <= fofb_cc_regs_cfg_val_act_part_sync2 and (not fofb_cc_regs_cfg_val_act_part_sync1);
    end if;
  end process;


  -- unused
  -- synchronizer chain for field : unused (type RW/RO, clk_sys_i <-> fofb_cc_clk_ram_reg_i)
  process (fofb_cc_clk_ram_reg_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      fofb_cc_regs_cfg_val_unused_o <= '0';
      fofb_cc_regs_cfg_val_unused_sync0 <= '0';
      fofb_cc_regs_cfg_val_unused_sync1 <= '0';
    elsif rising_edge(fofb_cc_clk_ram_reg_i) then
      fofb_cc_regs_cfg_val_unused_sync0 <= fofb_cc_regs_cfg_val_unused_int;
      fofb_cc_regs_cfg_val_unused_sync1 <= fofb_cc_regs_cfg_val_unused_sync0;
      fofb_cc_regs_cfg_val_unused_o <= fofb_cc_regs_cfg_val_unused_sync1;
    end if;
  end process;


  -- clears gigabit transceiver errors
  process (fofb_cc_clk_ram_reg_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      fofb_cc_regs_cfg_val_err_clr_o <= '0';
      fofb_cc_regs_cfg_val_err_clr_sync0 <= '0';
      fofb_cc_regs_cfg_val_err_clr_sync1 <= '0';
      fofb_cc_regs_cfg_val_err_clr_sync2 <= '0';
    elsif rising_edge(fofb_cc_clk_ram_reg_i) then
      fofb_cc_regs_cfg_val_err_clr_sync0 <= fofb_cc_regs_cfg_val_err_clr_int;
      fofb_cc_regs_cfg_val_err_clr_sync1 <= fofb_cc_regs_cfg_val_err_clr_sync0;
      fofb_cc_regs_cfg_val_err_clr_sync2 <= fofb_cc_regs_cfg_val_err_clr_sync1;
      fofb_cc_regs_cfg_val_err_clr_o <= fofb_cc_regs_cfg_val_err_clr_sync2 and (not fofb_cc_regs_cfg_val_err_clr_sync1);
    end if;
  end process;


  -- enables CC module
  -- synchronizer chain for field : enables CC module (type RW/RO, clk_sys_i <-> fofb_cc_clk_ram_reg_i)
  process (fofb_cc_clk_ram_reg_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      fofb_cc_regs_cfg_val_cc_enable_o <= '0';
      fofb_cc_regs_cfg_val_cc_enable_sync0 <= '0';
      fofb_cc_regs_cfg_val_cc_enable_sync1 <= '0';
    elsif rising_edge(fofb_cc_clk_ram_reg_i) then
      fofb_cc_regs_cfg_val_cc_enable_sync0 <= fofb_cc_regs_cfg_val_cc_enable_int;
      fofb_cc_regs_cfg_val_cc_enable_sync1 <= fofb_cc_regs_cfg_val_cc_enable_sync0;
      fofb_cc_regs_cfg_val_cc_enable_o <= fofb_cc_regs_cfg_val_cc_enable_sync1;
    end if;
  end process;


  -- timeframe start override. BPM can override internal timeframe start signal and use MGT generated one.
  -- synchronizer chain for field : timeframe start override. BPM can override internal timeframe start signal and use MGT generated one. (type RW/RO, clk_sys_i <-> fofb_cc_clk_ram_reg_i)
  process (fofb_cc_clk_ram_reg_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      fofb_cc_regs_cfg_val_tfs_override_o <= '0';
      fofb_cc_regs_cfg_val_tfs_override_sync0 <= '0';
      fofb_cc_regs_cfg_val_tfs_override_sync1 <= '0';
    elsif rising_edge(fofb_cc_clk_ram_reg_i) then
      fofb_cc_regs_cfg_val_tfs_override_sync0 <= fofb_cc_regs_cfg_val_tfs_override_int;
      fofb_cc_regs_cfg_val_tfs_override_sync1 <= fofb_cc_regs_cfg_val_tfs_override_sync0;
      fofb_cc_regs_cfg_val_tfs_override_o <= fofb_cc_regs_cfg_val_tfs_override_sync1;
    end if;
  end process;


  -- enable FOFB CC TOA module for reading
  -- synchronizer chain for field : enable FOFB CC TOA module for reading (type RW/RO, clk_sys_i <-> fofb_cc_clk_ram_reg_i)
  process (fofb_cc_clk_ram_reg_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      fofb_cc_regs_toa_ctl_rd_en_o <= '0';
      fofb_cc_regs_toa_ctl_rd_en_sync0 <= '0';
      fofb_cc_regs_toa_ctl_rd_en_sync1 <= '0';
    elsif rising_edge(fofb_cc_clk_ram_reg_i) then
      fofb_cc_regs_toa_ctl_rd_en_sync0 <= fofb_cc_regs_toa_ctl_rd_en_int;
      fofb_cc_regs_toa_ctl_rd_en_sync1 <= fofb_cc_regs_toa_ctl_rd_en_sync0;
      fofb_cc_regs_toa_ctl_rd_en_o <= fofb_cc_regs_toa_ctl_rd_en_sync1;
    end if;
  end process;


  -- Read next TOA address
  process (fofb_cc_clk_ram_reg_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      fofb_cc_regs_toa_ctl_rd_str_o <= '0';
      fofb_cc_regs_toa_ctl_rd_str_sync0 <= '0';
      fofb_cc_regs_toa_ctl_rd_str_sync1 <= '0';
      fofb_cc_regs_toa_ctl_rd_str_sync2 <= '0';
    elsif rising_edge(fofb_cc_clk_ram_reg_i) then
      fofb_cc_regs_toa_ctl_rd_str_sync0 <= fofb_cc_regs_toa_ctl_rd_str_int;
      fofb_cc_regs_toa_ctl_rd_str_sync1 <= fofb_cc_regs_toa_ctl_rd_str_sync0;
      fofb_cc_regs_toa_ctl_rd_str_sync2 <= fofb_cc_regs_toa_ctl_rd_str_sync1;
      fofb_cc_regs_toa_ctl_rd_str_o <= fofb_cc_regs_toa_ctl_rd_str_sync2 and (not fofb_cc_regs_toa_ctl_rd_str_sync1);
    end if;
  end process;


  -- FOFB CC TOA data
  -- asynchronous std_logic_vector register : FOFB CC TOA data (type RO/WO, fofb_cc_clk_sys_i <-> clk_sys_i)
  process (fofb_cc_clk_sys_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      fofb_cc_regs_toa_data_val_lwb_s0 <= '0';
      fofb_cc_regs_toa_data_val_lwb_s1 <= '0';
      fofb_cc_regs_toa_data_val_lwb_s2 <= '0';
      fofb_cc_regs_toa_data_val_int <= "00000000000000000000000000000000";
    elsif rising_edge(fofb_cc_clk_sys_i) then
      fofb_cc_regs_toa_data_val_lwb_s0 <= fofb_cc_regs_toa_data_val_lwb;
      fofb_cc_regs_toa_data_val_lwb_s1 <= fofb_cc_regs_toa_data_val_lwb_s0;
      fofb_cc_regs_toa_data_val_lwb_s2 <= fofb_cc_regs_toa_data_val_lwb_s1;
      if ((fofb_cc_regs_toa_data_val_lwb_s1 = '1') and (fofb_cc_regs_toa_data_val_lwb_s2 = '0')) then
        fofb_cc_regs_toa_data_val_int <= fofb_cc_regs_toa_data_val_i;
      end if;
    end if;
  end process;


  -- enable FOFB CC RCB module for reading
  -- synchronizer chain for field : enable FOFB CC RCB module for reading (type RW/RO, clk_sys_i <-> fofb_cc_clk_ram_reg_i)
  process (fofb_cc_clk_ram_reg_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      fofb_cc_regs_rcb_ctl_rd_en_o <= '0';
      fofb_cc_regs_rcb_ctl_rd_en_sync0 <= '0';
      fofb_cc_regs_rcb_ctl_rd_en_sync1 <= '0';
    elsif rising_edge(fofb_cc_clk_ram_reg_i) then
      fofb_cc_regs_rcb_ctl_rd_en_sync0 <= fofb_cc_regs_rcb_ctl_rd_en_int;
      fofb_cc_regs_rcb_ctl_rd_en_sync1 <= fofb_cc_regs_rcb_ctl_rd_en_sync0;
      fofb_cc_regs_rcb_ctl_rd_en_o <= fofb_cc_regs_rcb_ctl_rd_en_sync1;
    end if;
  end process;


  -- Read next RCB address
  process (fofb_cc_clk_ram_reg_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      fofb_cc_regs_rcb_ctl_rd_str_o <= '0';
      fofb_cc_regs_rcb_ctl_rd_str_sync0 <= '0';
      fofb_cc_regs_rcb_ctl_rd_str_sync1 <= '0';
      fofb_cc_regs_rcb_ctl_rd_str_sync2 <= '0';
    elsif rising_edge(fofb_cc_clk_ram_reg_i) then
      fofb_cc_regs_rcb_ctl_rd_str_sync0 <= fofb_cc_regs_rcb_ctl_rd_str_int;
      fofb_cc_regs_rcb_ctl_rd_str_sync1 <= fofb_cc_regs_rcb_ctl_rd_str_sync0;
      fofb_cc_regs_rcb_ctl_rd_str_sync2 <= fofb_cc_regs_rcb_ctl_rd_str_sync1;
      fofb_cc_regs_rcb_ctl_rd_str_o <= fofb_cc_regs_rcb_ctl_rd_str_sync2 and (not fofb_cc_regs_rcb_ctl_rd_str_sync1);
    end if;
  end process;


  -- FOFB CC RCB data
  -- asynchronous std_logic_vector register : FOFB CC RCB data (type RO/WO, fofb_cc_clk_sys_i <-> clk_sys_i)
  process (fofb_cc_clk_sys_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      fofb_cc_regs_rcb_data_val_lwb_s0 <= '0';
      fofb_cc_regs_rcb_data_val_lwb_s1 <= '0';
      fofb_cc_regs_rcb_data_val_lwb_s2 <= '0';
      fofb_cc_regs_rcb_data_val_int <= "00000000000000000000000000000000";
    elsif rising_edge(fofb_cc_clk_sys_i) then
      fofb_cc_regs_rcb_data_val_lwb_s0 <= fofb_cc_regs_rcb_data_val_lwb;
      fofb_cc_regs_rcb_data_val_lwb_s1 <= fofb_cc_regs_rcb_data_val_lwb_s0;
      fofb_cc_regs_rcb_data_val_lwb_s2 <= fofb_cc_regs_rcb_data_val_lwb_s1;
      if ((fofb_cc_regs_rcb_data_val_lwb_s1 = '1') and (fofb_cc_regs_rcb_data_val_lwb_s2 = '0')) then
        fofb_cc_regs_rcb_data_val_int <= fofb_cc_regs_rcb_data_val_i;
      end if;
    end if;
  end process;


  -- unused
  -- asynchronous std_logic_vector register : unused (type RO/WO, fofb_cc_clk_sys_i <-> clk_sys_i)
  process (fofb_cc_clk_sys_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      fofb_cc_regs_xy_buff_ctl_unused_lwb_s0 <= '0';
      fofb_cc_regs_xy_buff_ctl_unused_lwb_s1 <= '0';
      fofb_cc_regs_xy_buff_ctl_unused_lwb_s2 <= '0';
      fofb_cc_regs_xy_buff_ctl_unused_int <= "0000000000000000";
    elsif rising_edge(fofb_cc_clk_sys_i) then
      fofb_cc_regs_xy_buff_ctl_unused_lwb_s0 <= fofb_cc_regs_xy_buff_ctl_unused_lwb;
      fofb_cc_regs_xy_buff_ctl_unused_lwb_s1 <= fofb_cc_regs_xy_buff_ctl_unused_lwb_s0;
      fofb_cc_regs_xy_buff_ctl_unused_lwb_s2 <= fofb_cc_regs_xy_buff_ctl_unused_lwb_s1;
      if ((fofb_cc_regs_xy_buff_ctl_unused_lwb_s1 = '1') and (fofb_cc_regs_xy_buff_ctl_unused_lwb_s2 = '0')) then
        fofb_cc_regs_xy_buff_ctl_unused_int <= fofb_cc_regs_xy_buff_ctl_unused_i;
      end if;
    end if;
  end process;


  -- Read XY_BUFF address
  -- asynchronous std_logic_vector register : Read XY_BUFF address (type RW/WO, fofb_cc_clk_ram_reg_i <-> clk_sys_i)
  process (fofb_cc_clk_ram_reg_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      fofb_cc_regs_xy_buff_ctl_addr_lw_s0 <= '0';
      fofb_cc_regs_xy_buff_ctl_addr_lw_s1 <= '0';
      fofb_cc_regs_xy_buff_ctl_addr_lw_s2 <= '0';
      fofb_cc_regs_xy_buff_ctl_addr_o <= "0000000000000000";
      fofb_cc_regs_xy_buff_ctl_addr_load_o <= '0';
      fofb_cc_regs_xy_buff_ctl_addr_int_read <= "0000000000000000";
    elsif rising_edge(fofb_cc_clk_ram_reg_i) then
      fofb_cc_regs_xy_buff_ctl_addr_lw_s0 <= fofb_cc_regs_xy_buff_ctl_addr_lw;
      fofb_cc_regs_xy_buff_ctl_addr_lw_s1 <= fofb_cc_regs_xy_buff_ctl_addr_lw_s0;
      fofb_cc_regs_xy_buff_ctl_addr_lw_s2 <= fofb_cc_regs_xy_buff_ctl_addr_lw_s1;
      if ((fofb_cc_regs_xy_buff_ctl_addr_lw_s2 = '0') and (fofb_cc_regs_xy_buff_ctl_addr_lw_s1 = '1')) then
        if (fofb_cc_regs_xy_buff_ctl_addr_rwsel = '1') then
          fofb_cc_regs_xy_buff_ctl_addr_o <= fofb_cc_regs_xy_buff_ctl_addr_int_write;
          fofb_cc_regs_xy_buff_ctl_addr_load_o <= '1';
        else
          fofb_cc_regs_xy_buff_ctl_addr_load_o <= '0';
          fofb_cc_regs_xy_buff_ctl_addr_int_read <= fofb_cc_regs_xy_buff_ctl_addr_i;
        end if;
      else
        fofb_cc_regs_xy_buff_ctl_addr_load_o <= '0';
      end if;
    end if;
  end process;


  -- FOFB CC XY_BUFF data MSB
  -- asynchronous std_logic_vector register : FOFB CC XY_BUFF data MSB (type RO/WO, fofb_cc_clk_sys_i <-> clk_sys_i)
  process (fofb_cc_clk_sys_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      fofb_cc_regs_xy_buff_data_msb_val_lwb_s0 <= '0';
      fofb_cc_regs_xy_buff_data_msb_val_lwb_s1 <= '0';
      fofb_cc_regs_xy_buff_data_msb_val_lwb_s2 <= '0';
      fofb_cc_regs_xy_buff_data_msb_val_int <= "00000000000000000000000000000000";
    elsif rising_edge(fofb_cc_clk_sys_i) then
      fofb_cc_regs_xy_buff_data_msb_val_lwb_s0 <= fofb_cc_regs_xy_buff_data_msb_val_lwb;
      fofb_cc_regs_xy_buff_data_msb_val_lwb_s1 <= fofb_cc_regs_xy_buff_data_msb_val_lwb_s0;
      fofb_cc_regs_xy_buff_data_msb_val_lwb_s2 <= fofb_cc_regs_xy_buff_data_msb_val_lwb_s1;
      if ((fofb_cc_regs_xy_buff_data_msb_val_lwb_s1 = '1') and (fofb_cc_regs_xy_buff_data_msb_val_lwb_s2 = '0')) then
        fofb_cc_regs_xy_buff_data_msb_val_int <= fofb_cc_regs_xy_buff_data_msb_val_i;
      end if;
    end if;
  end process;


  -- FOFB CC XY_BUFF data LSB
  -- asynchronous std_logic_vector register : FOFB CC XY_BUFF data LSB (type RO/WO, fofb_cc_clk_sys_i <-> clk_sys_i)
  process (fofb_cc_clk_sys_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      fofb_cc_regs_xy_buff_data_lsb_val_lwb_s0 <= '0';
      fofb_cc_regs_xy_buff_data_lsb_val_lwb_s1 <= '0';
      fofb_cc_regs_xy_buff_data_lsb_val_lwb_s2 <= '0';
      fofb_cc_regs_xy_buff_data_lsb_val_int <= "00000000000000000000000000000000";
    elsif rising_edge(fofb_cc_clk_sys_i) then
      fofb_cc_regs_xy_buff_data_lsb_val_lwb_s0 <= fofb_cc_regs_xy_buff_data_lsb_val_lwb;
      fofb_cc_regs_xy_buff_data_lsb_val_lwb_s1 <= fofb_cc_regs_xy_buff_data_lsb_val_lwb_s0;
      fofb_cc_regs_xy_buff_data_lsb_val_lwb_s2 <= fofb_cc_regs_xy_buff_data_lsb_val_lwb_s1;
      if ((fofb_cc_regs_xy_buff_data_lsb_val_lwb_s1 = '1') and (fofb_cc_regs_xy_buff_data_lsb_val_lwb_s2 = '0')) then
        fofb_cc_regs_xy_buff_data_lsb_val_int <= fofb_cc_regs_xy_buff_data_lsb_val_i;
      end if;
    end if;
  end process;


  -- extra code for reg/fifo/mem: FOFB CC RAM for register map
  -- RAM block instantiation for memory: FOFB CC RAM for register map
  fofb_cc_regs_ram_reg_raminst: wbgen2_dpssram
    generic map (
      g_data_width         => 32,
      g_size               => 2048,
      g_addr_width         => 11,
      g_dual_clock         => true,
      g_use_bwsel          => false
    )
    port map (
      clk_a_i              => clk_sys_i,
      clk_b_i              => fofb_cc_clk_ram_reg_i,
      addr_b_i             => fofb_cc_regs_ram_reg_addr_i,
      addr_a_i             => rwaddr_reg(10 downto 0),
      data_b_o             => fofb_cc_regs_ram_reg_data_o,
      rd_b_i               => fofb_cc_regs_ram_reg_rd_i,
      data_b_i             => fofb_cc_regs_ram_reg_data_i,
      wr_b_i               => fofb_cc_regs_ram_reg_wr_i,
      bwsel_b_i            => allones(3 downto 0),
      data_a_o             => fofb_cc_regs_ram_reg_rddata_int(31 downto 0),
      rd_a_i               => fofb_cc_regs_ram_reg_rd_int,
      data_a_i             => wrdata_reg(31 downto 0),
      wr_a_i               => fofb_cc_regs_ram_reg_wr_int,
      bwsel_a_i            => allones(3 downto 0)
    );
  
  rwaddr_reg <= wb_adr_i;
  wb_stall_o <= (not ack_sreg(0)) and (wb_stb_i and wb_cyc_i);
  -- ACK signal generation. Just pass the LSB of ACK counter.
  wb_ack_o <= ack_sreg(0);
end syn;
