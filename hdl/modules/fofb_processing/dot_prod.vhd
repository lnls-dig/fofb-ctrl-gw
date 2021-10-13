-------------------------------------------------------------------------------
-- Title      :  Dot product module
-------------------------------------------------------------------------------
-- Author     :  Melissa Aguiar
-- Company    :  CNPEM LNLS-DIG
-- Platform   :  FPGA-generic
-------------------------------------------------------------------------------
-- Description:  Dot product module for the Fast Orbit Feedback
-------------------------------------------------------------------------------
-- Copyright (c) 2020 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2021-08-11  1.0      melissa.aguiar        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
-- Dot product package
use work.dot_prod_pkg.all;

entity dot_prod is
  generic(
    -- Width for input a[k]
    g_A_WIDTH                      : natural := 32;

    -- Width for input b[k]
    g_B_WIDTH                      : natural := 32;

    -- Width for output
    g_C_WIDTH                      : natural := 16;

    -- Fixed point representation for output
    g_OUT_FIXED                    : natural := 26;

    -- Extra bits for accumulator
    g_EXTRA_WIDTH                  : natural := 4
  );
  port(
    -- Core clock
    clk_i                          : in std_logic;

    -- Reset all pipeline stages
    rst_n_i                        : in std_logic;

    -- Clear the accumulator
    clear_acc_i                    : in std_logic;

    -- Data valid input
    valid_i                        : in std_logic;

    -- Time frame end
    time_frame_end_i               : in std_logic;

    -- Input a[k]
    a_i                            : in signed(g_A_WIDTH-1 downto 0);

    -- Input b[k]
    b_i                            : in signed(g_B_WIDTH-1 downto 0);

    -- Result output
    result_o                       : out signed(g_C_WIDTH-1 downto 0);
    result_debug_o                 : out signed(g_C_WIDTH-1 downto 0);

	-- Data valid output
    result_valid_end_o             : out std_logic;
    result_valid_debug_o           : out std_logic
  );
end dot_prod;

architecture behave of dot_prod is

  constant c_REGS_MSB              : natural                        := 2 * g_A_WIDTH + g_EXTRA_WIDTH - 1;
  signal result_s                  : signed(g_C_WIDTH-1 downto 0)   := (others =>'0');

  -- Registers for input values
  signal a_reg_s                   : signed(g_A_WIDTH-1 downto 0)   := (others =>'0');
  signal b_reg_s                   : signed(g_B_WIDTH-1 downto 0)   := (others =>'0');

  -- Registers for intermediate values
  signal mult_reg_s                : signed(2*g_A_WIDTH-1 downto 0) := (others =>'0');
  signal adder_out_s               : signed(c_REGS_MSB downto 0)    := (others =>'0');
  signal adder_reg1_s              : signed(c_REGS_MSB downto 0)    := (others =>'0');
  signal adder_reg2_s              : signed(c_REGS_MSB-g_OUT_FIXED downto 0)
                                                                    := (others =>'0');

  -- Registers for bit valid
  signal valid_reg1_s              : std_logic                      := '0';
  signal valid_reg2_s              : std_logic                      := '0';
  signal valid_reg3_s              : std_logic                      := '0';
  signal valid_reg4_s              : std_logic                      := '0';
  signal valid_reg5_s              : std_logic                      := '0';

  -- Registers for the correct DSP48 inference
  signal mult_dsp1_s               : signed(2*g_A_WIDTH-1 downto 0) := (others =>'0');
  signal mult_dsp2_s               : signed(2*g_A_WIDTH-1 downto 0) := (others =>'0');
  signal mult_dsp3_s               : signed(2*g_A_WIDTH-1 downto 0) := (others =>'0');
  signal mult_dsp4_s               : signed(2*g_A_WIDTH-1 downto 0) := (others =>'0');
  signal mult_dsp5_s               : signed(2*g_A_WIDTH-1 downto 0) := (others =>'0');
  signal mult_dsp6_s               : signed(2*g_A_WIDTH-1 downto 0) := (others =>'0');
  signal valid_dsp1_s              : std_logic                      := '0';
  signal valid_dsp2_s              : std_logic                      := '0';
  signal valid_dsp3_s              : std_logic                      := '0';
  signal valid_dsp4_s              : std_logic                      := '0';
  signal valid_dsp5_s              : std_logic                      := '0';
  signal valid_dsp6_s              : std_logic                      := '0';

  function vector_OR(x : std_logic_vector)
    return std_logic
  is
    constant len : integer := x'length;
    constant mid : integer := len / 2;
    alias y : std_logic_vector(len-1 downto 0) is x;
  begin
    if len = 1
    then return y(0);
    else return vector_OR(y(len-1 downto mid)) or
                vector_OR(y(mid-1 downto 0));
    end if;
  end vector_OR;

  function vector_AND(x : std_logic_vector)
    return std_logic
  is
    constant len : integer := x'length;
    constant mid : integer := len / 2;
    alias y : std_logic_vector(len-1 downto 0) is x;
  begin
    if len = 1
    then return y(0);
    else return vector_AND(y(len-1 downto mid)) and
                vector_AND(y(mid-1 downto 0));
    end if;
  end vector_AND;

  function f_replicate(x : std_logic; len : natural)
    return std_logic_vector
  is
    variable v_ret : std_logic_vector(len-1 downto 0) := (others => x);
  begin
    return v_ret;
  end f_replicate;

  function f_saturate(x : std_logic_vector; x_new_msb : natural)
    return std_logic_vector
  is
    constant x_old_msb : natural := x'left;
    variable v_is_in_range : std_logic;
    variable v_x_sat : std_logic_vector(x_new_msb downto 0);
  begin
    -- Check if signed overflow (all bits 0) or signed underflow (all bits 1)
    v_is_in_range := (not vector_OR(x(x_old_msb downto x_new_msb)) or
                (vector_AND(x(x_old_msb downto x_new_msb))));

    if v_is_in_range = '1' then
      -- just drop the redundant MSB bits
      v_x_sat := x(x_new_msb downto 0);
    else
      -- saturate negative 10...0 or positive 01...1
      v_x_sat := x(x_old_msb) & f_replicate(not x(x_old_msb), x_new_msb);
    end if;

    return v_x_sat;
  end f_saturate;

begin

  MAC : process (clk_i)
  begin
    if (rising_edge(clk_i)) then
      if rst_n_i = '0' then
        -- Clear all registers
        a_reg_s                    <= (others => '0');
        b_reg_s                    <= (others => '0');
        mult_reg_s                 <= (others => '0');
        adder_out_s                <= (others => '0');
        adder_reg1_s               <= (others => '0');
        adder_reg2_s               <= (others => '0');
        valid_reg1_s               <= '0';
        valid_reg2_s               <= '0';
        valid_reg3_s               <= '0';
        valid_reg4_s               <= '0';
        valid_reg5_s               <= '0';
        mult_dsp1_s                <= (others => '0');
        mult_dsp2_s                <= (others => '0');
        mult_dsp3_s                <= (others => '0');
        mult_dsp4_s                <= (others => '0');
        mult_dsp5_s                <= (others => '0');
        mult_dsp6_s                <= (others => '0');
        valid_dsp1_s               <= '0';
        valid_dsp2_s               <= '0';
        valid_dsp3_s               <= '0';
        valid_dsp4_s               <= '0';
        valid_dsp5_s               <= '0';
        valid_dsp6_s               <= '0';

      elsif (clear_acc_i = '1') then
        -- Clear data from accumulator
        adder_out_s                <= (others => '0');
        adder_reg1_s               <= (others => '0');
        adder_reg2_s               <= (others => '0');

      else
        -- Store the inputs in a register
        a_reg_s                    <= a_i;
        b_reg_s                    <= b_i;

        -- Store the valid bit in a register
        valid_reg1_s               <= valid_i;

        -- Store multiplication result in a register (it's necessary to use 6 pipeline stages)
        mult_dsp1_s                <= a_reg_s * b_reg_s;
        mult_dsp2_s                <= mult_dsp1_s;
        mult_dsp3_s                <= mult_dsp2_s;
        mult_dsp4_s                <= mult_dsp3_s;
        mult_dsp5_s                <= mult_dsp4_s;
        mult_dsp6_s                <= mult_dsp5_s;

        mult_reg_s                 <= mult_dsp6_s;

        -- Store the valid bit in a register for the 6 pipeline stages
        valid_dsp1_s               <= valid_reg1_s;
        valid_dsp2_s               <= valid_dsp1_s;
        valid_dsp3_s               <= valid_dsp2_s;
        valid_dsp4_s               <= valid_dsp3_s;
        valid_dsp5_s               <= valid_dsp4_s;
        valid_dsp6_s               <= valid_dsp5_s;

        valid_reg2_s               <= valid_dsp6_s;

        if (valid_reg2_s = '1') then
          -- Store accumulation result in a register
          adder_out_s              <= adder_out_s + mult_reg_s;
        end if;

        -- Store the valid bit in a register
        valid_reg3_s               <= valid_reg2_s;

        -- Register the accumulation to fully pipeline the DSP cascade
        adder_reg1_s               <= adder_out_s;

        -- Store the valid bit in a register
        valid_reg4_s               <= valid_reg3_s;

        -- Register the accumulation to fully pipeline the DSP cascade
        adder_reg2_s               <= adder_reg1_s(c_REGS_MSB downto g_OUT_FIXED);

        -- Store the valid bit in a register
        valid_reg5_s               <= valid_reg4_s;

        -- Store the valid bit output
        result_valid_debug_o       <= valid_reg5_s;

        -- Truncate the output
        result_debug_o             <= result_s;

				-- End of the FOFB cycle
        if (time_frame_end_i = '1') then
          result_o                 <= result_s;
          result_valid_end_o       <= '1';
        else
          result_valid_end_o       <= '0';
        end if;
      end if; -- Reset
    end if; -- Clock
  end process MAC;

  result_s                         <= signed(f_saturate(std_logic_vector(adder_reg2_s), g_C_WIDTH-1));

end architecture behave;
