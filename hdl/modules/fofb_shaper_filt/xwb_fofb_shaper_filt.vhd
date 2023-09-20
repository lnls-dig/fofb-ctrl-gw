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
USE work.fofb_shaper_filt_pkg.ALL;
USE work.wb_fofb_shaper_filt_regs_pkg.ALL;
USE work.wishbone_pkg.ALL;

ENTITY xwb_fofb_shaper_filt IS
  GENERIC (
    -- Number of channels
    g_CHANNELS            : NATURAL;

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

  TYPE t_wb_fofb_shaper_filt_regs_ifc_coeffs_val_dat IS
    ARRAY (NATURAL RANGE <>) OF STD_LOGIC_VECTOR(31 downto 0);

  -- Number of bits in Wishbone register interface
  -- +2 to account for BYTE addressing
  CONSTANT c_PERIPH_ADDR_SIZE : NATURAL := 2+2;

  CONSTANT c_MAX_CHANNELS : NATURAL := 12;

  CONSTANT c_NUM_OF_BIQUADS_PER_FILT : NATURAL := (c_MAX_FILT_ORDER + 1)/2;
  CONSTANT c_NUM_OF_COEFFS_PER_FILT : NATURAL := 5*c_NUM_OF_BIQUADS_PER_FILT;

  -- The signed fixed-point representation of coefficients is aligned to the
  -- left in Wishbone registers
  PURE FUNCTION f_parse_wb_coeff(wb_coeff : STD_LOGIC_VECTOR)
  RETURN SFIXED IS
  BEGIN
    RETURN to_sfixed(wb_coeff(31 DOWNTO
             32-(c_COEFF_INT_WIDTH + c_COEFF_FRAC_WIDTH)), c_COEFF_INT_WIDTH-1,
             -c_COEFF_FRAC_WIDTH);
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

  SIGNAL wb_fofb_shaper_filt_regs_ifc_master_in :
    t_wb_fofb_shaper_filt_regs_ifc_master_in;
  SIGNAL wb_fofb_shaper_filt_regs_ifc_master_out :
    t_wb_fofb_shaper_filt_regs_ifc_master_out;
  SIGNAL wb_fofb_shaper_filt_regs_ifc_coeffs_adr : STD_LOGIC_VECTOR(5 DOWNTO 0);
  SIGNAL wb_fofb_shaper_filt_regs_ifc_coeffs_val_dat :
    t_wb_fofb_shaper_filt_regs_ifc_coeffs_val_dat(c_MAX_CHANNELS-1 DOWNTO 0);

  SIGNAL state : NATURAL RANGE 0 TO 2 := 0;
  SIGNAL coeffs : t_fofb_shaper_filt_coeffs(g_CHANNELS-1 DOWNTO 0)(
                    c_NUM_OF_BIQUADS_PER_FILT-1 DOWNTO 0)(
                    b0(c_COEFF_INT_WIDTH-1 DOWNTO -c_COEFF_FRAC_WIDTH),
                    b1(c_COEFF_INT_WIDTH-1 DOWNTO -c_COEFF_FRAC_WIDTH),
                    b2(c_COEFF_INT_WIDTH-1 DOWNTO -c_COEFF_FRAC_WIDTH),
                    a1(c_COEFF_INT_WIDTH-1 DOWNTO -c_COEFF_FRAC_WIDTH),
                    a2(c_COEFF_INT_WIDTH-1 DOWNTO -c_COEFF_FRAC_WIDTH));
BEGIN
  ASSERT c_MAX_FILT_ORDER <= 20
    REPORT "ABI supports up to 20th order filters"
    SEVERITY ERROR;

  ASSERT c_COEFF_INT_WIDTH > 1 and c_COEFF_FRAC_WIDTH > 1 and
         c_COEFF_INT_WIDTH + c_COEFF_FRAC_WIDTH <= 32
    REPORT "ABI supports at most 32-bits coefficients (c_COEFF_INT_WIDTH + " &
           "c_COEFF_FRAC_WIDTH). Also, the SFIXED type requires each of these" &
           "to be at least 1."
    SEVERITY ERROR;

  PROCESS(clk_i) IS
    VARIABLE v_biquad_idx : NATURAL RANGE 0 to c_NUM_OF_BIQUADS_PER_FILT-1 := 0;
    VARIABLE v_coeff_idx : NATURAL RANGE 0 to c_NUM_OF_COEFFS_PER_FILT-1 := 0;
  BEGIN
    IF rising_edge(clk_i) THEN
      IF rst_n_i = '0' THEN
        state <= 0;
        v_coeff_idx := 0;
      ELSE
        CASE state IS
          -- Waits for strobe signal
          WHEN 0 =>
            IF wb_fofb_shaper_filt_regs_ifc_master_out.ctl_eff_coeffs THEN
              state <= 1;
            END IF;
            v_coeff_idx := 0;

          -- Waits for coefficients RAMs' output update
          WHEN 1 =>
            state <= 2;

          -- Effectivates (i.e. updates) coefficients
          -- Each iir_filt has c_NUM_OF_BIQUADS_PER_FILT biquads. Each of these
          -- takes 5 coefficients: b0, b1, b2, a1 and a2 (a0 = 1). Each iir_filt
          -- has a dedicated RAM holding its coefficients. These RAMs are
          -- populated in the following manner:
          --  For biquad_idx in 0 to c_NUM_OF_BIQUADS_PER_FILT-1:
          --    coeffs[0 + 5*{biquad_idx}] = b0 of biquad {biquad_idx}
          --    coeffs[1 + 5*{biquad_idx}] = b1 of biquad {biquad_idx}
          --    coeffs[2 + 5*{biquad_idx}] = b2 of biquad {biquad_idx}
          --    coeffs[3 + 5*{biquad_idx}] = a1 of biquad {biquad_idx}
          --    coeffs[4 + 5*{biquad_idx}] = a2 of biquad {biquad_idx}
          -- RAMs are accessed in parallel.
          WHEN 2 =>
            v_biquad_idx := v_coeff_idx/5;
            FOR ch IN 0 TO g_CHANNELS-1
            LOOP
              CASE v_coeff_idx REM 5 IS
                WHEN 0 =>
                  coeffs(ch)(v_biquad_idx).b0 <= f_parse_wb_coeff(
                    wb_fofb_shaper_filt_regs_ifc_coeffs_val_dat(ch));

                WHEN 1 =>
                  coeffs(ch)(v_biquad_idx).b1 <= f_parse_wb_coeff(
                    wb_fofb_shaper_filt_regs_ifc_coeffs_val_dat(ch));


                WHEN 2 =>
                  coeffs(ch)(v_biquad_idx).b2 <= f_parse_wb_coeff(
                    wb_fofb_shaper_filt_regs_ifc_coeffs_val_dat(ch));

                WHEN 3 =>
                  coeffs(ch)(v_biquad_idx).a1 <= f_parse_wb_coeff(
                    wb_fofb_shaper_filt_regs_ifc_coeffs_val_dat(ch));

                WHEN 4 =>
                  coeffs(ch)(v_biquad_idx).a2 <= f_parse_wb_coeff(
                    wb_fofb_shaper_filt_regs_ifc_coeffs_val_dat(ch));

                WHEN OTHERS =>
              END CASE;
            END LOOP;

            IF v_coeff_idx = c_NUM_OF_COEFFS_PER_FILT-1 THEN
              state <= 0;
            ELSE
              v_coeff_idx := v_coeff_idx + 1;
              state <= 1;
            END IF;
        END CASE;

        -- Addresses coefficients RAMs
        -- The state machine above computes the address and waits a cycle for
        -- output to update
        wb_fofb_shaper_filt_regs_ifc_coeffs_adr <=
          STD_LOGIC_VECTOR(to_unsigned(v_coeff_idx,
            wb_fofb_shaper_filt_regs_ifc_coeffs_adr'LENGTH));
      END IF;
    END IF;
  END PROCESS;

  gen_iir_filts : FOR idx IN 0 TO g_CHANNELS-1
    GENERATE
      cmp_iir_filt : iir_filt
        GENERIC MAP (
          g_MAX_FILT_ORDER    => c_MAX_FILT_ORDER,
          g_X_INT_WIDTH       => c_SP_WIDTH,
          g_X_FRAC_WIDTH      => 1, -- see note below
          g_COEFF_INT_WIDTH   => c_COEFF_INT_WIDTH,
          g_COEFF_FRAC_WIDTH  => c_COEFF_FRAC_WIDTH,
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
          coeffs_i            => coeffs(idx),
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
      clk_i                           => clk_i,
      rst_n_i                         => rst_n_i,
      wb_i                            => wb_slv_adp_out,
      wb_o                            => wb_slv_adp_in,
      wb_fofb_shaper_filt_regs_ifc_i  => wb_fofb_shaper_filt_regs_ifc_master_in,
      wb_fofb_shaper_filt_regs_ifc_o  => wb_fofb_shaper_filt_regs_ifc_master_out
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

  wb_fofb_shaper_filt_regs_ifc_master_in.ch_0_coeffs_adr_i <=
    wb_fofb_shaper_filt_regs_ifc_coeffs_adr;
  wb_fofb_shaper_filt_regs_ifc_master_in.ch_0_coeffs_val_rd_i <= '0';
  wb_fofb_shaper_filt_regs_ifc_master_in.ch_1_coeffs_adr_i <=
    wb_fofb_shaper_filt_regs_ifc_coeffs_adr;
  wb_fofb_shaper_filt_regs_ifc_master_in.ch_1_coeffs_val_rd_i <= '0';
  wb_fofb_shaper_filt_regs_ifc_master_in.ch_2_coeffs_adr_i <=
    wb_fofb_shaper_filt_regs_ifc_coeffs_adr;
  wb_fofb_shaper_filt_regs_ifc_master_in.ch_2_coeffs_val_rd_i <= '0';
  wb_fofb_shaper_filt_regs_ifc_master_in.ch_3_coeffs_adr_i <=
    wb_fofb_shaper_filt_regs_ifc_coeffs_adr;
  wb_fofb_shaper_filt_regs_ifc_master_in.ch_3_coeffs_val_rd_i <= '0';
  wb_fofb_shaper_filt_regs_ifc_master_in.ch_4_coeffs_adr_i <=
    wb_fofb_shaper_filt_regs_ifc_coeffs_adr;
  wb_fofb_shaper_filt_regs_ifc_master_in.ch_4_coeffs_val_rd_i <= '0';
  wb_fofb_shaper_filt_regs_ifc_master_in.ch_5_coeffs_adr_i <=
    wb_fofb_shaper_filt_regs_ifc_coeffs_adr;
  wb_fofb_shaper_filt_regs_ifc_master_in.ch_5_coeffs_val_rd_i <= '0';
  wb_fofb_shaper_filt_regs_ifc_master_in.ch_6_coeffs_adr_i <=
    wb_fofb_shaper_filt_regs_ifc_coeffs_adr;
  wb_fofb_shaper_filt_regs_ifc_master_in.ch_6_coeffs_val_rd_i <= '0';
  wb_fofb_shaper_filt_regs_ifc_master_in.ch_7_coeffs_adr_i <=
    wb_fofb_shaper_filt_regs_ifc_coeffs_adr;
  wb_fofb_shaper_filt_regs_ifc_master_in.ch_7_coeffs_val_rd_i <= '0';
  wb_fofb_shaper_filt_regs_ifc_master_in.ch_8_coeffs_adr_i <=
    wb_fofb_shaper_filt_regs_ifc_coeffs_adr;
  wb_fofb_shaper_filt_regs_ifc_master_in.ch_8_coeffs_val_rd_i <= '0';
  wb_fofb_shaper_filt_regs_ifc_master_in.ch_9_coeffs_adr_i <=
    wb_fofb_shaper_filt_regs_ifc_coeffs_adr;
  wb_fofb_shaper_filt_regs_ifc_master_in.ch_9_coeffs_val_rd_i <= '0';
  wb_fofb_shaper_filt_regs_ifc_master_in.ch_10_coeffs_adr_i <=
    wb_fofb_shaper_filt_regs_ifc_coeffs_adr;
  wb_fofb_shaper_filt_regs_ifc_master_in.ch_10_coeffs_val_rd_i <= '0';
  wb_fofb_shaper_filt_regs_ifc_master_in.ch_11_coeffs_adr_i <=
    wb_fofb_shaper_filt_regs_ifc_coeffs_adr;
  wb_fofb_shaper_filt_regs_ifc_master_in.ch_11_coeffs_val_rd_i <= '0';
  wb_fofb_shaper_filt_regs_ifc_master_in.max_filt_order <=
    STD_LOGIC_VECTOR(to_unsigned(c_MAX_FILT_ORDER,
      wb_fofb_shaper_filt_regs_ifc_master_in.max_filt_order'LENGTH));
  wb_fofb_shaper_filt_regs_ifc_master_in.coeffs_fp_repr_int_width <=
    STD_LOGIC_VECTOR(to_unsigned(c_COEFF_INT_WIDTH,
      wb_fofb_shaper_filt_regs_ifc_master_in.coeffs_fp_repr_int_width'LENGTH));
  wb_fofb_shaper_filt_regs_ifc_master_in.coeffs_fp_repr_frac_width <=
    STD_LOGIC_VECTOR(to_unsigned(c_COEFF_FRAC_WIDTH,
      wb_fofb_shaper_filt_regs_ifc_master_in.coeffs_fp_repr_frac_width'LENGTH));

   wb_fofb_shaper_filt_regs_ifc_coeffs_val_dat(0) <=
    wb_fofb_shaper_filt_regs_ifc_master_out.ch_0_coeffs_val_dat_o;
   wb_fofb_shaper_filt_regs_ifc_coeffs_val_dat(1) <=
    wb_fofb_shaper_filt_regs_ifc_master_out.ch_1_coeffs_val_dat_o;
   wb_fofb_shaper_filt_regs_ifc_coeffs_val_dat(2) <=
    wb_fofb_shaper_filt_regs_ifc_master_out.ch_2_coeffs_val_dat_o;
   wb_fofb_shaper_filt_regs_ifc_coeffs_val_dat(3) <=
    wb_fofb_shaper_filt_regs_ifc_master_out.ch_3_coeffs_val_dat_o;
   wb_fofb_shaper_filt_regs_ifc_coeffs_val_dat(4) <=
    wb_fofb_shaper_filt_regs_ifc_master_out.ch_4_coeffs_val_dat_o;
   wb_fofb_shaper_filt_regs_ifc_coeffs_val_dat(5) <=
    wb_fofb_shaper_filt_regs_ifc_master_out.ch_5_coeffs_val_dat_o;
   wb_fofb_shaper_filt_regs_ifc_coeffs_val_dat(6) <=
    wb_fofb_shaper_filt_regs_ifc_master_out.ch_6_coeffs_val_dat_o;
   wb_fofb_shaper_filt_regs_ifc_coeffs_val_dat(7) <=
    wb_fofb_shaper_filt_regs_ifc_master_out.ch_7_coeffs_val_dat_o;
   wb_fofb_shaper_filt_regs_ifc_coeffs_val_dat(8) <=
    wb_fofb_shaper_filt_regs_ifc_master_out.ch_8_coeffs_val_dat_o;
   wb_fofb_shaper_filt_regs_ifc_coeffs_val_dat(9) <=
    wb_fofb_shaper_filt_regs_ifc_master_out.ch_9_coeffs_val_dat_o;
   wb_fofb_shaper_filt_regs_ifc_coeffs_val_dat(10) <=
    wb_fofb_shaper_filt_regs_ifc_master_out.ch_10_coeffs_val_dat_o;
   wb_fofb_shaper_filt_regs_ifc_coeffs_val_dat(11) <=
    wb_fofb_shaper_filt_regs_ifc_master_out.ch_11_coeffs_val_dat_o;
END ARCHITECTURE behave;
