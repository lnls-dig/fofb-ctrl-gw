--------------------------------------------------------------------------------
-- Title        : Testbench for the FOFB Shaper Filters Wrapper
--------------------------------------------------------------------------------
-- Author       : Guilherme Ricioli <guilherme.riciolic@gmail.com>
-- Company      : CNPEM, LNLS - GIE
-- Platform     : Simulation
-- Standard     : VHDL'08
--------------------------------------------------------------------------------
-- Description  :
--------------------------------------------------------------------------------
-- Copyright (c) 2023 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
--------------------------------------------------------------------------------
-- Revisions    :
-- Date         Version  Author              Description
-- 2023-09-26   1.0      guilherme.ricioli   Created
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.fixed_pkg.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_1164.ALL;

LIBRARY std;
USE std.env.finish;
USE std.textio.ALL;

LIBRARY work;
USE work.fofb_ctrl_pkg.ALL;
USE work.fofb_shaper_filt_pkg.ALL;
USE work.fofb_tb_pkg.ALL;
USE work.sim_wishbone.ALL;
USE work.wishbone_pkg.ALL;
USE work.wb_fofb_shaper_filt_regs_consts_pkg.ALL;

ENTITY xwb_fofb_shaper_filt_tb IS
  GENERIC (
    -- Number of channels
    g_CHANNELS              : NATURAL := 12;

    -- File containing filters' coefficients
    g_TEST_COEFFS_FILENAME  : STRING := "../fofb_shaper_filt_coeffs.dat";
    -- File containing the values for x and the expected values for y
    g_TEST_X_Y_FILENAME     : STRING := "../fofb_shaper_filt_x_y.dat";

    -- Extra bits for biquads' internal arithmetic
    g_ARITH_EXTRA_BITS      : NATURAL := 0;
    -- Extra bits for between-biquads cascade interfaces
    g_IFCS_EXTRA_BITS       : NATURAL := 4
  );
END ENTITY xwb_fofb_shaper_filt_tb;

ARCHITECTURE test OF xwb_fofb_shaper_filt_tb IS
  CONSTANT c_NUM_OF_BIQUADS_PER_FILT : NATURAL := (c_MAX_FILT_ORDER + 1)/2;
  CONSTANT c_NUM_OF_COEFFS_PER_FILT : NATURAL := 5*c_NUM_OF_BIQUADS_PER_FILT;
  CONSTANT c_SYS_CLOCK_FREQ : NATURAL := 100_000_000;

  SIGNAL clk : STD_LOGIC := '0';
  SIGNAL rst_n : STD_LOGIC := '1';
  SIGNAL busy_arr : STD_LOGIC_VECTOR(g_CHANNELS-1 DOWNTO 0);
  SIGNAL sp_arr, filt_sp_arr : t_sp_arr(g_CHANNELS-1 DOWNTO 0);
  SIGNAL sp_valid_arr, filt_sp_valid_arr :
    STD_LOGIC_VECTOR(g_CHANNELS-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL wb_slave_i : t_wishbone_slave_in;
  SIGNAL wb_slave_o : t_wishbone_slave_out;

BEGIN
  f_gen_clk(c_SYS_CLOCK_FREQ, clk);

  PROCESS
    FILE fin : TEXT;
    VARIABLE lin : LINE;
    VARIABLE v_wb_addr : NATURAL := 0;
    VARIABLE v_wb_dat : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    VARIABLE v_coeff : REAL;
    VARIABLE v_x_or_y : INTEGER;
  BEGIN
    init(wb_slave_i);
    f_wait_cycles(clk, 10);

    rst_n <= '0';
    f_wait_cycles(clk, 10);
    rst_n <= '1';
    f_wait_cycles(clk, 1);

    -- Reads maximum filter order
    read32_pl(clk, wb_slave_i, wb_slave_o,
      c_WB_FOFB_SHAPER_FILT_REGS_MAX_FILT_ORDER_ADDR, v_wb_dat);

    ASSERT to_integer(UNSIGNED(v_wb_dat)) = c_MAX_FILT_ORDER
      REPORT
        "UNEXPECTED MAXIMUM FILTER ORDER: "
        & NATURAL'image(to_integer(UNSIGNED(v_wb_dat)))
        & " (EXPECTED: "
        & NATURAL'image(c_MAX_FILT_ORDER) & ")"
      SEVERITY ERROR;

    -- Read coefficients' fixed-point representation
    read32_pl(clk, wb_slave_i, wb_slave_o,
      c_WB_FOFB_SHAPER_FILT_REGS_COEFFS_FP_REPR_ADDR, v_wb_dat);

    ASSERT to_integer(UNSIGNED(v_wb_dat(
      c_WB_FOFB_SHAPER_FILT_REGS_COEFFS_FP_REPR_FRAC_WIDTH_OFFSET-1 DOWNTO
      c_WB_FOFB_SHAPER_FILT_REGS_COEFFS_FP_REPR_INT_WIDTH_OFFSET))) =
      c_COEFF_INT_WIDTH
      REPORT
        "UNEXPECTED COEFFICIENTS' INTEGER WIDTH: "
        & NATURAL'image(to_integer(UNSIGNED(v_wb_dat(
          c_WB_FOFB_SHAPER_FILT_REGS_COEFFS_FP_REPR_FRAC_WIDTH_OFFSET-1 DOWNTO
          c_WB_FOFB_SHAPER_FILT_REGS_COEFFS_FP_REPR_INT_WIDTH_OFFSET))))
        & " (EXPECTED: "
        & NATURAL'image(c_COEFF_INT_WIDTH) & ")"
      SEVERITY ERROR;

    -- TODO: +4 hardcoded
    ASSERT to_integer(UNSIGNED(v_wb_dat(
      c_WB_FOFB_SHAPER_FILT_REGS_COEFFS_FP_REPR_FRAC_WIDTH_OFFSET+4 DOWNTO
      c_WB_FOFB_SHAPER_FILT_REGS_COEFFS_FP_REPR_FRAC_WIDTH_OFFSET))) =
      c_COEFF_FRAC_WIDTH
      REPORT
        "UNEXPECTED COEFFICIENTS' FRACTIONARY WIDTH: "
        & NATURAL'image(to_integer(UNSIGNED(v_wb_dat(
          c_WB_FOFB_SHAPER_FILT_REGS_COEFFS_FP_REPR_FRAC_WIDTH_OFFSET+4 DOWNTO
          c_WB_FOFB_SHAPER_FILT_REGS_COEFFS_FP_REPR_FRAC_WIDTH_OFFSET))))
        & " (EXPECTED: "
        & NATURAL'image(c_COEFF_FRAC_WIDTH) & ")"
      SEVERITY ERROR;

    -- Load filter coefficients
    file_open(fin, g_TEST_COEFFS_FILENAME, read_mode);
    FOR ch_idx IN 0 TO g_CHANNELS-1
    LOOP
      v_wb_addr := c_WB_FOFB_SHAPER_FILT_REGS_CH_ADDR +
        ch_idx*c_WB_FOFB_SHAPER_FILT_REGS_CH_0_SIZE;

      readline(fin, lin);
      FOR coeff_idx IN 0 TO c_NUM_OF_COEFFS_PER_FILT-1
      LOOP
        read(lin, v_coeff);
        -- The signed fixed-point representation of coefficients is aligned to
        -- the left in Wishbone registers
        v_wb_dat := (
          31 DOWNTO 32-(c_COEFF_INT_WIDTH + c_COEFF_FRAC_WIDTH) =>
            to_slv(to_sfixed(v_coeff, c_COEFF_INT_WIDTH-1,
            -c_COEFF_FRAC_WIDTH)),
          OTHERS => '0');
        write32_pl(clk, wb_slave_i, wb_slave_o, v_wb_addr, v_wb_dat);

        v_wb_addr := v_wb_addr + c_WB_FOFB_SHAPER_FILT_REGS_CH_0_COEFFS_SIZE;
      END LOOP;
    END LOOP;
    file_close(fin);

    -- Effectivate (update) filter coefficients
    v_wb_dat := (c_WB_FOFB_SHAPER_FILT_REGS_CTL_EFF_COEFFS_OFFSET => '1',
      OTHERS => '0');
    write32_pl(clk, wb_slave_i, wb_slave_o, c_WB_FOFB_SHAPER_FILT_REGS_CTL_ADDR,
      v_wb_dat);

    -- Wait for coefficients to be effectivated
    -- Coefficients RAMs are accessed in parallel and each of the
    -- c_NUM_OF_COEFFS_PER_FILT coefficients takes 2 cycles for being
    -- effectivated. The +1 is accounting for the command detection cycle.
    f_wait_cycles(clk, 2*c_NUM_OF_COEFFS_PER_FILT+1);

    file_open(fin, g_TEST_X_Y_FILENAME, read_mode);
    WHILE NOT endfile(fin)
    LOOP
      readline(fin, lin);

      FOR ch_idx IN 0 TO g_CHANNELS-1
      LOOP
        read(lin, v_x_or_y);
        sp_arr(ch_idx) <= to_signed(v_x_or_y, sp_arr(ch_idx)'LENGTH);
        f_wait_clocked_signal(clk, busy_arr(0), '0');
        sp_valid_arr(ch_idx) <= '1';
      END LOOP;
      f_wait_cycles(clk, 1);

      FOR ch_idx IN 0 TO g_CHANNELS-1
      LOOP
        sp_valid_arr(ch_idx) <= '0';
      END LOOP;
      f_wait_clocked_signal(clk, filt_sp_valid_arr(0), '1');

      FOR ch_idx IN 0 TO g_CHANNELS-1
      LOOP
        read(lin, v_x_or_y);
        IF ABS(REAL(to_integer(filt_sp_arr(ch_idx)))/REAL(v_x_or_y) - 1.0) >
          0.01 THEN
          REPORT
            "TOO LARGE ERROR (> 1%): "
            & INTEGER'image(to_integer(filt_sp_arr(ch_idx)))
            & " (EXPECTED: "
            & INTEGER'image(v_x_or_y) & ")"
          SEVERITY ERROR;
        END IF;
      END LOOP;
    END LOOP;
    file_close(fin);

    REPORT "SUCCESS!"
    SEVERITY NOTE;

    finish;
  END PROCESS;

  UUT : xwb_fofb_shaper_filt
    GENERIC MAP (
      g_CHANNELS            => g_CHANNELS,
      g_ARITH_EXTRA_BITS    => g_ARITH_EXTRA_BITS,
      g_IFCS_EXTRA_BITS     => g_IFCS_EXTRA_BITS,
      g_INTERFACE_MODE      => PIPELINED,
      g_ADDRESS_GRANULARITY => BYTE,
      g_WITH_EXTRA_WB_REG   => FALSE
    )
    PORT MAP (
      clk_i                 => clk,
      rst_n_i               => rst_n,
      sp_arr_i              => sp_arr,
      sp_valid_arr_i        => sp_valid_arr,
      busy_arr_o            => busy_arr,
      filt_sp_arr_o         => filt_sp_arr,
      filt_sp_valid_arr_o   => filt_sp_valid_arr,
      wb_slv_i              => wb_slave_i,
      wb_slv_o              => wb_slave_o
    );
END ARCHITECTURE test;
