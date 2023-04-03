-- Do not edit.  Generated on Thu Apr 06 14:13:12 2023 by guilherme.ricioli
-- With Cheby 1.4.0 and these options:
--  -i wb_fofb_sys_id_regs.cheby --hdl vhdl --gen-hdl wb_fofb_sys_id_regs.vhd --doc html --gen-doc doc/wb_fofb_sys_id_regs.html --gen-c wb_fofb_sys_id_regs.h --consts-style vhdl-ohwr --gen-consts ../../../sim/regs/wb_fofb_sys_id_regs_consts_pkg.vhd


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wishbone_pkg.all;

entity wb_fofb_sys_id_regs is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_i                 : in    t_wishbone_slave_in;
    wb_o                 : out   t_wishbone_slave_out;

    -- Maximum number of BPM positions that can be flatenized per axis

    bpm_pos_flatenizer_max_num_cte_i : in    std_logic_vector(15 downto 0);

    -- Together with max_num_cte, defines the range of BPM position
    -- indexes being flatenized, which is given by
    -- [base_bpm_id, base_bpm_id + max_num_cte) -> BPM x positions; and
    -- [base_bpm_id + 256, base_bpm_id + 256 + max_num_cte) -> BPM y
    -- positions. The valid range of this register is [0, 255].
    -- Note that only the P2P BPM positions are being driven to
    -- flatenizer cores.

    bpm_pos_flatenizer_base_bpm_id_o : out   std_logic_vector(7 downto 0)
  );
end wb_fofb_sys_id_regs;

architecture syn of wb_fofb_sys_id_regs is
  signal adr_int                        : std_logic_vector(2 downto 2);
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal bpm_pos_flatenizer_base_bpm_id_reg : std_logic_vector(7 downto 0);
  signal bpm_pos_flatenizer_base_bpm_id_wreq : std_logic;
  signal bpm_pos_flatenizer_base_bpm_id_wack : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(2 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_sel_d0                      : std_logic_vector(3 downto 0);
begin

  -- WB decode signals
  adr_int <= wb_i.adr(2 downto 2);
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

  -- Register bpm_pos_flatenizer_max_num_cte

  -- Register bpm_pos_flatenizer_base_bpm_id
  bpm_pos_flatenizer_base_bpm_id_o <= bpm_pos_flatenizer_base_bpm_id_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        bpm_pos_flatenizer_base_bpm_id_reg <= "00000000";
        bpm_pos_flatenizer_base_bpm_id_wack <= '0';
      else
        if bpm_pos_flatenizer_base_bpm_id_wreq = '1' then
          bpm_pos_flatenizer_base_bpm_id_reg <= wr_dat_d0(7 downto 0);
        end if;
        bpm_pos_flatenizer_base_bpm_id_wack <= bpm_pos_flatenizer_base_bpm_id_wreq;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, bpm_pos_flatenizer_base_bpm_id_wack) begin
    bpm_pos_flatenizer_base_bpm_id_wreq <= '0';
    case wr_adr_d0(2 downto 2) is
    when "0" =>
      -- Reg bpm_pos_flatenizer_max_num_cte
      wr_ack_int <= wr_req_d0;
    when "1" =>
      -- Reg bpm_pos_flatenizer_base_bpm_id
      bpm_pos_flatenizer_base_bpm_id_wreq <= wr_req_d0;
      wr_ack_int <= bpm_pos_flatenizer_base_bpm_id_wack;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (adr_int, rd_req_int, bpm_pos_flatenizer_max_num_cte_i, bpm_pos_flatenizer_base_bpm_id_reg) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case adr_int(2 downto 2) is
    when "0" =>
      -- Reg bpm_pos_flatenizer_max_num_cte
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0(15 downto 0) <= bpm_pos_flatenizer_max_num_cte_i;
      rd_dat_d0(31 downto 16) <= (others => '0');
    when "1" =>
      -- Reg bpm_pos_flatenizer_base_bpm_id
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0(7 downto 0) <= bpm_pos_flatenizer_base_bpm_id_reg;
      rd_dat_d0(31 downto 8) <= (others => '0');
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
