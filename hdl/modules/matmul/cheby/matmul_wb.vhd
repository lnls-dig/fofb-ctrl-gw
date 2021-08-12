-- Do not edit.  Generated on Thu Aug 12 14:42:04 2021 by mel
-- With Cheby 1.5.dev0 and these options:
--  --gen-hdl -i matmul_wb.cheby


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity matmul_wb is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_cyc_i             : in    std_logic;
    wb_stb_i             : in    std_logic;
    wb_adr_i             : in    std_logic_vector(3 downto 2);
    wb_sel_i             : in    std_logic_vector(3 downto 0);
    wb_we_i              : in    std_logic;
    wb_dat_i             : in    std_logic_vector(31 downto 0);
    wb_ack_o             : out   std_logic;
    wb_err_o             : out   std_logic;
    wb_rty_o             : out   std_logic;
    wb_stall_o           : out   std_logic;
    wb_dat_o             : out   std_logic_vector(31 downto 0);

    -- REG ram_coeff_dat
    ram_coeff_dat_o      : out   std_logic_vector(31 downto 0);

    -- REG ram_coeff_addr
    ram_coeff_addr_o     : out   std_logic_vector(31 downto 0);

    -- REG ram
    ram_write_enable_o   : out   std_logic;
    ram_wr_o             : out   std_logic
  );
end matmul_wb;

architecture syn of matmul_wb is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal ram_coeff_dat_reg              : std_logic_vector(31 downto 0);
  signal ram_coeff_dat_wreq             : std_logic;
  signal ram_coeff_dat_wack             : std_logic;
  signal ram_coeff_addr_reg             : std_logic_vector(31 downto 0);
  signal ram_coeff_addr_wreq            : std_logic;
  signal ram_coeff_addr_wack            : std_logic;
  signal ram_write_enable_reg           : std_logic;
  signal ram_wreq                       : std_logic;
  signal ram_wack                       : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(3 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_sel_d0                      : std_logic_vector(3 downto 0);
begin

  -- WB decode signals
  wb_en <= wb_cyc_i and wb_stb_i;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_rip <= '0';
      else
        wb_rip <= (wb_rip or (wb_en and not wb_we_i)) and not rd_ack_int;
      end if;
    end if;
  end process;
  rd_req_int <= (wb_en and not wb_we_i) and not wb_rip;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_wip <= '0';
      else
        wb_wip <= (wb_wip or (wb_en and wb_we_i)) and not wr_ack_int;
      end if;
    end if;
  end process;
  wr_req_int <= (wb_en and wb_we_i) and not wb_wip;

  ack_int <= rd_ack_int or wr_ack_int;
  wb_ack_o <= ack_int;
  wb_stall_o <= not ack_int and wb_en;
  wb_rty_o <= '0';
  wb_err_o <= '0';

  -- pipelining for wr-in+rd-out
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rd_ack_int <= '0';
        wr_req_d0 <= '0';
      else
        rd_ack_int <= rd_ack_d0;
        wb_dat_o <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_adr_d0 <= wb_adr_i;
        wr_dat_d0 <= wb_dat_i;
        wr_sel_d0 <= wb_sel_i;
      end if;
    end if;
  end process;

  -- Register ram_coeff_dat
  ram_coeff_dat_o <= ram_coeff_dat_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ram_coeff_dat_reg <= "00000000000000000000000000000000";
        ram_coeff_dat_wack <= '0';
      else
        if ram_coeff_dat_wreq = '1' then
          ram_coeff_dat_reg <= wr_dat_d0;
        end if;
        ram_coeff_dat_wack <= ram_coeff_dat_wreq;
      end if;
    end if;
  end process;

  -- Register ram_coeff_addr
  ram_coeff_addr_o <= ram_coeff_addr_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ram_coeff_addr_reg <= "00000000000000000000000000000000";
        ram_coeff_addr_wack <= '0';
      else
        if ram_coeff_addr_wreq = '1' then
          ram_coeff_addr_reg <= wr_dat_d0;
        end if;
        ram_coeff_addr_wack <= ram_coeff_addr_wreq;
      end if;
    end if;
  end process;

  -- Register ram
  ram_write_enable_o <= ram_write_enable_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ram_write_enable_reg <= '0';
        ram_wack <= '0';
      else
        if ram_wreq = '1' then
          ram_write_enable_reg <= wr_dat_d0(0);
        end if;
        ram_wack <= ram_wreq;
      end if;
    end if;
  end process;
  ram_wr_o <= ram_wack;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, ram_coeff_dat_wack, ram_coeff_addr_wack, ram_wack) begin
    ram_coeff_dat_wreq <= '0';
    ram_coeff_addr_wreq <= '0';
    ram_wreq <= '0';
    case wr_adr_d0(3 downto 2) is
    when "00" =>
      -- Reg ram_coeff_dat
      ram_coeff_dat_wreq <= wr_req_d0;
      wr_ack_int <= ram_coeff_dat_wack;
    when "01" =>
      -- Reg ram_coeff_addr
      ram_coeff_addr_wreq <= wr_req_d0;
      wr_ack_int <= ram_coeff_addr_wack;
    when "10" =>
      -- Reg ram
      ram_wreq <= wr_req_d0;
      wr_ack_int <= ram_wack;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int, ram_coeff_dat_reg, ram_coeff_addr_reg, ram_write_enable_reg) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case wb_adr_i(3 downto 2) is
    when "00" =>
      -- Reg ram_coeff_dat
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= ram_coeff_dat_reg;
    when "01" =>
      -- Reg ram_coeff_addr
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= ram_coeff_addr_reg;
    when "10" =>
      -- Reg ram
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0(0) <= ram_write_enable_reg;
      rd_dat_d0(31 downto 1) <= (others => '0');
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
