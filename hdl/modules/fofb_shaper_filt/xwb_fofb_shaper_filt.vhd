--------------------------------------------------------------------------------
-- Title        : FOFB Shaper Filters Wrapper
-- Project      : fofb-ctrl-gw
--------------------------------------------------------------------------------
-- File         : xwb_fofb_shaper_filt.vhd
-- Author       : Guilherme Ricioli <guilherme.riciolic@gmail.com>
-- Company      : CNPEM, LNLS - GIE
-- Platform     : Generic
-- Standard     : VHDL'08
--------------------------------------------------------------------------------
-- Description: Instantiates FOFB shaper filters and exposes coefficients
--              settings on a Wishbone bus.
--------------------------------------------------------------------------------
-- Copyright (c) 2023 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
--------------------------------------------------------------------------------
-- Revisions    :
-- Date         Version  Author              Description
-- 2023-09-28   1.0      guilherme.ricioli   Created
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.fixed_pkg.ALL;
USE ieee.numeric_std.ALL;

LIBRARY work;
USE work.ifc_common_pkg.ALL;
USE work.fofb_ctrl_pkg.ALL;
USE work.wishbone_pkg.ALL;

ENTITY xwb_fofb_shaper_filt IS
  GENERIC (
    -- Number of channels
    g_CHANNELS            : NATURAL;

    -- Number of internal biquads
    -- The order is given by 2*g_NUM_BIQUADS
    g_NUM_BIQUADS         : NATURAL;
    -- Signed fixed-point representation of biquads' coefficients
    g_COEFF_INT_WIDTH     : NATURAL;
    g_COEFF_FRAC_WIDTH    : NATURAL;
    -- Extra bits for biquads' internal arithmetic
    g_ARITH_EXTRA_BITS    : NATURAL;
    -- Extra bits for between-biquads cascade interfaces
    g_IFCS_EXTRA_BITS     : NATURAL;

    -- Wishbone generics
    g_INTERFACE_MODE      : t_wishbone_interface_mode := CLASSIC;
    g_ADDRESS_GRANULARITY : t_wishbone_address_granularity := WORD;
    g_WITH_EXTRA_WB_REG   : BOOLEAN := FALSE
  );
  PORT (
    -- Clock
    clk_i                 : IN  STD_LOGIC;
    -- Reset
    rst_n_i               : IN  STD_LOGIC;

    -- Setpoints array
    sp_arr_i              : IN  t_sp_arr(g_CHANNELS-1 DOWNTO 0);
    -- Setpoints valid array
    sp_valid_arr_i        : IN  STD_LOGIC_VECTOR(g_CHANNELS-1 DOWNTO 0);

    -- Busy flag array
    busy_arr_o            : OUT STD_LOGIC_VECTOR(g_CHANNELS-1 DOWNTO 0);

    -- Filtered setpoints array
    filt_sp_arr_o         : OUT t_sp_arr(g_CHANNELS-1 DOWNTO 0);
    -- Filtered setpoints valid array
    filt_sp_valid_arr_o   : OUT STD_LOGIC_VECTOR(g_CHANNELS-1 DOWNTO 0);

    -- Wishbone interface
    wb_slv_i              : IN  t_wishbone_slave_in;
    wb_slv_o              : OUT t_wishbone_slave_out
  );
END ENTITY xwb_fofb_shaper_filt;

ARCHITECTURE behave OF xwb_fofb_shaper_filt IS
  TYPE t_iir_filts_x_or_y IS ARRAY (NATURAL RANGE <>) of SFIXED;
  TYPE t_fofb_shaper_filt_coeffs IS
    ARRAY (NATURAL RANGE <>) OF t_iir_filt_coeffs;

  TYPE t_wb_fofb_shaper_filt_regs_coeffs_i_ifc IS RECORD
    data  : STD_LOGIC_VECTOR(31 DOWNTO 0);
  END RECORD;
  TYPE t_wb_fofb_shaper_filt_regs_coeffs_o_ifc IS RECORD
    addr  : STD_LOGIC_VECTOR(8 DOWNTO 2);
    data  : STD_LOGIC_VECTOR(31 DOWNTO 0);
    wr    : STD_LOGIC;
  END RECORD;

  TYPE t_wb_fofb_shaper_filt_regs_coeffs_i_ifc_arr IS
    ARRAY (NATURAL RANGE <>) OF t_wb_fofb_shaper_filt_regs_coeffs_i_ifc;
  TYPE t_wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr IS
    ARRAY (NATURAL RANGE <>) OF t_wb_fofb_shaper_filt_regs_coeffs_o_ifc;

  -- Number of bits in Wishbone register interface
  -- +2 to account for BYTE addressing
  CONSTANT c_PERIPH_ADDR_SIZE : NATURAL := 2+2;

  CONSTANT c_MAX_CHANNELS : NATURAL := 12;
  CONSTANT c_MAX_ABI_BIQUADS : NATURAL := 10;

  CONSTANT c_WB_FOFB_SHAPER_FILT_REGS_COEFFS_I_IFC_0s :
    t_wb_fofb_shaper_filt_regs_coeffs_i_ifc := (data => (OTHERS => '0'));
  CONSTANT c_WB_FOFB_SHAPER_FILT_REGS_COEFFS_O_IFC_0s :
    t_wb_fofb_shaper_filt_regs_coeffs_o_ifc := (addr => (OTHERS => '0'),
                                                data => (OTHERS => '0'),
                                                wr => '0');

  -- The signed fixed-point representation of coefficients is aligned to the
  -- left in Wishbone registers
  PURE FUNCTION f_parse_wb_coeff(wb_coeff : STD_LOGIC_VECTOR)
  RETURN SFIXED IS
  BEGIN
    RETURN to_sfixed(wb_coeff(31 DOWNTO
             32-(g_COEFF_INT_WIDTH + g_COEFF_FRAC_WIDTH)), g_COEFF_INT_WIDTH-1,
             -g_COEFF_FRAC_WIDTH);
  END f_parse_wb_coeff;

  SIGNAL iir_filts_x, iir_filts_y : t_iir_filts_x_or_y(g_CHANNELS-1 DOWNTO 0)(
                                      c_SP_WIDTH-1 DOWNTO -1);

  -- Wishbone signals
  SIGNAL wb_slv_adp_in : t_wishbone_master_in;
  SIGNAL wb_slv_adp_out : t_wishbone_master_out;
  SIGNAL resized_addr : STD_LOGIC_VECTOR(c_WISHBONE_ADDRESS_WIDTH-1 DOWNTO 0);
  SIGNAL wb_slave_in : t_wishbone_slave_in_array(0 DOWNTO 0);
  SIGNAL wb_slave_out : t_wishbone_slave_out_array(0 DOWNTO 0);
  -- Extra Wishbone registering stage
  SIGNAL wb_slave_in_d1 : t_wishbone_slave_in_array(0 DOWNTO 0);
  SIGNAL wb_slave_out_d1 : t_wishbone_slave_out_array(0 DOWNTO 0);

  SIGNAL wb_fofb_shaper_filt_regs_coeffs_i_ifc_arr :
    t_wb_fofb_shaper_filt_regs_coeffs_i_ifc_arr(c_MAX_CHANNELS-1 DOWNTO 0) :=
      (OTHERS => c_WB_FOFB_SHAPER_FILT_REGS_COEFFS_I_IFC_0s);
  SIGNAL wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr :
    t_wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(c_MAX_CHANNELS-1 DOWNTO 0) :=
      (OTHERS => c_WB_FOFB_SHAPER_FILT_REGS_COEFFS_O_IFC_0s);

  SIGNAL coeffs : t_fofb_shaper_filt_coeffs(g_CHANNELS-1 DOWNTO 0)(
                    g_NUM_BIQUADS-1 DOWNTO 0)(
                    b0(g_COEFF_INT_WIDTH-1 DOWNTO -g_COEFF_FRAC_WIDTH),
                    b1(g_COEFF_INT_WIDTH-1 DOWNTO -g_COEFF_FRAC_WIDTH),
                    b2(g_COEFF_INT_WIDTH-1 DOWNTO -g_COEFF_FRAC_WIDTH),
                    a1(g_COEFF_INT_WIDTH-1 DOWNTO -g_COEFF_FRAC_WIDTH),
                    a2(g_COEFF_INT_WIDTH-1 DOWNTO -g_COEFF_FRAC_WIDTH));

  SIGNAL biquad_idx : NATURAL RANGE 0 TO c_MAX_ABI_BIQUADS-1 := 0;
  SIGNAL coeff_idx : NATURAL RANGE 0 TO 7 := 0;
BEGIN
  ASSERT g_NUM_BIQUADS <= c_MAX_ABI_BIQUADS
    REPORT "ABI supports up to 20th order filters (i.e. 10 biquads)"
    SEVERITY FAILURE;

  ASSERT g_COEFF_INT_WIDTH > 1 and g_COEFF_FRAC_WIDTH > 1 and
         g_COEFF_INT_WIDTH + g_COEFF_FRAC_WIDTH <= 32
    REPORT "ABI supports at most 32-bits coefficients (g_COEFF_INT_WIDTH + " &
           "g_COEFF_FRAC_WIDTH). Also, the SFIXED type requires each of these" &
           "to be at least 1."
    SEVERITY FAILURE;

  -- NOTE: All wb_fofb_shaper_filt_regs RAM interfaces addresses are
  --       internally connected to same signals. So, pick just one of
  --       them to index the coefficients.
  biquad_idx <= to_integer(UNSIGNED(
    wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(0).addr(8 DOWNTO 5)));
  coeff_idx <= to_integer(UNSIGNED(
    wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(0).addr(4 DOWNTO 2)));

  PROCESS(clk_i) IS
  BEGIN
    -- Each iir_filt has g_NUM_BIQUADS biquads and each of these has 5
    -- associated coefficients (b0, b1, b2, a1 and a2 (a0 = 1)).
    -- wb_fofb_shaper_filt_regs uses dedicated RAM interfaces for accessing the
    -- 5*g_NUM_BIQUADS coefficients of each iir_filt.
    --
    -- The address map is:
    --   For biquad_idx in 0 to g_NUM_BIQUADS-1:
    --     RAM address 0 + 8*{biquad_idx} = b0 of biquad {biquad_idx}
    --     RAM address 1 + 8*{biquad_idx} = b1 of biquad {biquad_idx}
    --     RAM address 2 + 8*{biquad_idx} = b2 of biquad {biquad_idx}
    --     RAM address 3 + 8*{biquad_idx} = a1 of biquad {biquad_idx}
    --     RAM address 4 + 8*{biquad_idx} = a2 of biquad {biquad_idx}
    --     RAM address 5 + 8*{biquad_idx} = unused
    --     RAM address 6 + 8*{biquad_idx} = unused
    --     RAM address 7 + 8*{biquad_idx} = unused
    FOR ch IN 0 TO g_CHANNELS-1
    LOOP
      IF biquad_idx < g_NUM_BIQUADS THEN
        CASE coeff_idx IS
          WHEN 0 =>
            wb_fofb_shaper_filt_regs_coeffs_i_ifc_arr(ch).data <=
              (to_slv(coeffs(ch)(biquad_idx).b0), OTHERS => '0');
          WHEN 1 =>
            wb_fofb_shaper_filt_regs_coeffs_i_ifc_arr(ch).data <=
              (to_slv(coeffs(ch)(biquad_idx).b1), OTHERS => '0');
          WHEN 2 =>
            wb_fofb_shaper_filt_regs_coeffs_i_ifc_arr(ch).data <=
              (to_slv(coeffs(ch)(biquad_idx).b2), OTHERS => '0');
          WHEN 3 =>
            wb_fofb_shaper_filt_regs_coeffs_i_ifc_arr(ch).data <=
              (to_slv(coeffs(ch)(biquad_idx).a1), OTHERS => '0');
          WHEN 4 =>
            wb_fofb_shaper_filt_regs_coeffs_i_ifc_arr(ch).data <=
              (to_slv(coeffs(ch)(biquad_idx).a2), OTHERS => '0');
          WHEN OTHERS =>
        END CASE;
      -- If trying to access biquads that aren't instatiated, return zeros
      ELSE
        wb_fofb_shaper_filt_regs_coeffs_i_ifc_arr(ch).data <= (OTHERS => '0');
      END IF;

      IF rising_edge(clk_i) THEN
        IF rst_n_i = '0' THEN
        ELSE
          IF wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(ch).wr = '1' THEN
            IF biquad_idx < g_NUM_BIQUADS THEN
              CASE coeff_idx IS
                WHEN 0 =>
                  coeffs(ch)(biquad_idx).b0 <= f_parse_wb_coeff(
                    wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(ch).data);
                WHEN 1 =>
                  coeffs(ch)(biquad_idx).b1 <= f_parse_wb_coeff(
                    wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(ch).data);
                WHEN 2 =>
                  coeffs(ch)(biquad_idx).b2 <= f_parse_wb_coeff(
                    wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(ch).data);
                WHEN 3 =>
                  coeffs(ch)(biquad_idx).a1 <= f_parse_wb_coeff(
                    wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(ch).data);
                WHEN 4 =>
                  coeffs(ch)(biquad_idx).a2 <= f_parse_wb_coeff(
                    wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(ch).data);
                WHEN OTHERS =>
              END CASE;
            END IF;
          END IF;
        END IF;
      END IF;
    END LOOP;
  END PROCESS;

  gen_iir_filts : FOR idx IN 0 TO g_CHANNELS-1
    GENERATE
      cmp_iir_filt : iir_filt
        GENERIC MAP (
          g_NUM_BIQUADS       => g_NUM_BIQUADS,
          g_X_INT_WIDTH       => c_SP_WIDTH,
          g_X_FRAC_WIDTH      => 1, -- see note below
          g_COEFF_INT_WIDTH   => g_COEFF_INT_WIDTH,
          g_COEFF_FRAC_WIDTH  => g_COEFF_FRAC_WIDTH,
          g_Y_INT_WIDTH       => c_SP_WIDTH,
          g_Y_FRAC_WIDTH      => 1, -- see note below
          g_ARITH_EXTRA_BITS  => g_ARITH_EXTRA_BITS,
          g_IFCS_EXTRA_BITS   => g_IFCS_EXTRA_BITS
        )
        PORT MAP (
          clk_i               => clk_i,
          rst_n_i             => rst_n_i,
          x_i                 => iir_filts_x(idx),
          x_valid_i           => sp_valid_arr_i(idx),
          coeffs_i            => coeffs(idx)(g_NUM_BIQUADS-1 DOWNTO 0),
          busy_o              => busy_arr_o(idx),
          y_o                 => iir_filts_y(idx),
          y_valid_o           => filt_sp_valid_arr_o(idx)
        );

      -- see note below
      iir_filts_x(idx) <= to_sfixed(sp_arr_i(idx), c_SP_WIDTH-1, -1);
      filt_sp_arr_o(idx) <= to_signed(iir_filts_y(idx), c_SP_WIDTH);

      -- NOTE: SFIXED type must have at least 1 fractionary digit
    END GENERATE gen_iir_filts;

  cmp_wb_fofb_shaper_filt_regs : ENTITY work.wb_fofb_shaper_filt_regs
    PORT MAP (
      rst_n_i                     => rst_n_i,
      clk_i                       => clk_i,
      wb_i                        => wb_slv_adp_out,
      wb_o                        => wb_slv_adp_in,
      ch_0_coeffs_addr_o          => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(0).addr,
      ch_0_coeffs_data_i          => wb_fofb_shaper_filt_regs_coeffs_i_ifc_arr(0).data,
      ch_0_coeffs_data_o          => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(0).data,
      ch_0_coeffs_wr_o            => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(0).wr,
      ch_1_coeffs_addr_o          => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(1).addr,
      ch_1_coeffs_data_i          => wb_fofb_shaper_filt_regs_coeffs_i_ifc_arr(1).data,
      ch_1_coeffs_data_o          => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(1).data,
      ch_1_coeffs_wr_o            => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(1).wr,
      ch_2_coeffs_addr_o          => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(2).addr,
      ch_2_coeffs_data_i          => wb_fofb_shaper_filt_regs_coeffs_i_ifc_arr(2).data,
      ch_2_coeffs_data_o          => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(2).data,
      ch_2_coeffs_wr_o            => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(2).wr,
      ch_3_coeffs_addr_o          => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(3).addr,
      ch_3_coeffs_data_i          => wb_fofb_shaper_filt_regs_coeffs_i_ifc_arr(3).data,
      ch_3_coeffs_data_o          => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(3).data,
      ch_3_coeffs_wr_o            => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(3).wr,
      ch_4_coeffs_addr_o          => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(4).addr,
      ch_4_coeffs_data_i          => wb_fofb_shaper_filt_regs_coeffs_i_ifc_arr(4).data,
      ch_4_coeffs_data_o          => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(4).data,
      ch_4_coeffs_wr_o            => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(4).wr,
      ch_5_coeffs_addr_o          => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(5).addr,
      ch_5_coeffs_data_i          => wb_fofb_shaper_filt_regs_coeffs_i_ifc_arr(5).data,
      ch_5_coeffs_data_o          => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(5).data,
      ch_5_coeffs_wr_o            => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(5).wr,
      ch_6_coeffs_addr_o          => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(6).addr,
      ch_6_coeffs_data_i          => wb_fofb_shaper_filt_regs_coeffs_i_ifc_arr(6).data,
      ch_6_coeffs_data_o          => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(6).data,
      ch_6_coeffs_wr_o            => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(6).wr,
      ch_7_coeffs_addr_o          => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(7).addr,
      ch_7_coeffs_data_i          => wb_fofb_shaper_filt_regs_coeffs_i_ifc_arr(7).data,
      ch_7_coeffs_data_o          => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(7).data,
      ch_7_coeffs_wr_o            => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(7).wr,
      ch_8_coeffs_addr_o          => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(8).addr,
      ch_8_coeffs_data_i          => wb_fofb_shaper_filt_regs_coeffs_i_ifc_arr(8).data,
      ch_8_coeffs_data_o          => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(8).data,
      ch_8_coeffs_wr_o            => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(8).wr,
      ch_9_coeffs_addr_o          => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(9).addr,
      ch_9_coeffs_data_i          => wb_fofb_shaper_filt_regs_coeffs_i_ifc_arr(9).data,
      ch_9_coeffs_data_o          => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(9).data,
      ch_9_coeffs_wr_o            => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(9).wr,
      ch_10_coeffs_addr_o         => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(10).addr,
      ch_10_coeffs_data_i         => wb_fofb_shaper_filt_regs_coeffs_i_ifc_arr(10).data,
      ch_10_coeffs_data_o         => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(10).data,
      ch_10_coeffs_wr_o           => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(10).wr,
      ch_11_coeffs_addr_o         => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(11).addr,
      ch_11_coeffs_data_i         => wb_fofb_shaper_filt_regs_coeffs_i_ifc_arr(11).data,
      ch_11_coeffs_data_o         => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(11).data,
      ch_11_coeffs_wr_o           => wb_fofb_shaper_filt_regs_coeffs_o_ifc_arr(11).wr,
      num_biquads_i               => STD_LOGIC_VECTOR(to_unsigned(g_NUM_BIQUADS, 32)),
      coeffs_fp_repr_int_width_i  => STD_LOGIC_VECTOR(to_unsigned(g_COEFF_INT_WIDTH, 5)),
      coeffs_fp_repr_frac_width_i => STD_LOGIC_VECTOR(to_unsigned(g_COEFF_FRAC_WIDTH, 5))
    );

  -- Extra Wishbone registering stage for ease timing
  -- NOTE: It effectively cuts the bandwidth in half!
  gen_with_extra_wb_reg : IF g_WITH_EXTRA_WB_REG GENERATE
    cmp_register_link : xwb_register_link -- puts a register of delay between
      PORT MAP (                          -- crossbars
        clk_sys_i => clk_i,
        rst_n_i   => rst_n_i,
        slave_i   => wb_slave_in_d1(0),
        slave_o   => wb_slave_out_d1(0),
        master_i  => wb_slave_out(0),
        master_o  => wb_slave_in(0)
      );

      wb_slave_in_d1(0) <= wb_slv_i;
      wb_slv_o          <= wb_slave_out_d1(0);
    ELSE GENERATE
      -- External master connection
      wb_slave_in(0)      <= wb_slv_i;
      wb_slv_o            <= wb_slave_out(0);
    END GENERATE;

  -- Wishbone slave adapter
  cmp_slave_adapter : wb_slave_adapter
    GENERIC MAP (
      g_MASTER_USE_STRUCT   => TRUE,
      g_MASTER_MODE         => PIPELINED,
      -- TODO: it seems that using cheby without wbgen compatibility requires
      -- g_MASTER_GRANULARITY to be byte
      g_MASTER_GRANULARITY  => BYTE,
      g_SLAVE_USE_STRUCT    => FALSE,
      g_SLAVE_MODE          => g_INTERFACE_MODE,
      g_SLAVE_GRANULARITY   => g_ADDRESS_GRANULARITY
    )
    PORT MAP (
      clk_sys_i             => clk_i,
      rst_n_i               => rst_n_i,
      master_i              => wb_slv_adp_in,
      master_o              => wb_slv_adp_out,
      sl_adr_i              => resized_addr,
      sl_dat_i              => wb_slave_in(0).dat,
      sl_sel_i              => wb_slave_in(0).sel,
      sl_cyc_i              => wb_slave_in(0).cyc,
      sl_stb_i              => wb_slave_in(0).stb,
      sl_we_i               => wb_slave_in(0).we,
      sl_dat_o              => wb_slave_out(0).dat,
      sl_ack_o              => wb_slave_out(0).ack,
      sl_rty_o              => wb_slave_out(0).rty,
      sl_err_o              => wb_slave_out(0).err,
      sl_stall_o            => wb_slave_out(0).stall
    );

  gen_wb_slave_in_addr_conn : IF g_ADDRESS_GRANULARITY = WORD GENERATE
    -- By doing this zeroing we avoid the issue related to BYTE -> WORD
    -- conversion slave addressing (possibly performed by the slave adapter
    -- component) in which a bit in the MSB of the peripheral addressing part
    -- (31 DOWNTO c_PERIPH_ADDR_SIZE in our case) is shifted to the internal
    -- register adressing part (c_PERIPH_ADDR_SIZE-1 DOWNTO 0 in our case).
    -- Therefore, possibly changing the these bits!
    resized_addr(c_PERIPH_ADDR_SIZE-1 DOWNTO 0) <=
      wb_slave_in(0).adr(c_PERIPH_ADDR_SIZE-1 DOWNTO 0);
    resized_addr(c_WISHBONE_ADDRESS_WIDTH-1 DOWNTO c_PERIPH_ADDR_SIZE) <=
      (OTHERS => '0');
  ELSE GENERATE
    resized_addr <= wb_slave_in(0).adr;
  END GENERATE;
END ARCHITECTURE behave;
