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
    g_a_width                      : natural := 32;

    -- Width for input b[k]
    g_b_width                      : natural := 32;

    -- Width for output
    g_c_width                      : natural := 32;

    -- Extra bits for accumulator
    g_extra_width                  : natural := 4
  );
  port (
    -- Core clock
    clk_i                          : in std_logic;

    -- Reset all pipeline stages
    rst_n_i                        : in std_logic;

    -- Clear the accumulator
    clear_acc_i                    : in std_logic;

    -- Data valid input
    valid_i                        : in std_logic;

    -- Time frame end
    time_frame_end_i		       		 : in std_logic;

    -- Input a[k]
    a_i                            : in signed(g_a_width-1 downto 0);

    -- Input b[k]
    b_i                            : in signed(g_b_width-1 downto 0);

    -- Result output
    result_o                       : out signed(g_c_width-1 downto 0);
    result_debug_o                 : out signed(g_c_width-1 downto 0);

	-- Data valid output
    result_valid_end_o						 : out std_logic;
    result_valid_debug_o	         : out std_logic
  );
end dot_prod;

architecture behave of dot_prod is

  -- Registers for input values
  signal a_reg_s                   : signed(g_a_width-1 downto 0)                 := (others =>'0');
  signal b_reg_s                   : signed(g_b_width-1 downto 0)                 := (others =>'0');

  -- Registers for intermediate values
  signal mult_reg_s                : signed(2*g_c_width-1 downto 0)               := (others =>'0');
  signal adder_out_s               : signed(2*g_c_width+g_extra_width-1 downto 0) := (others =>'0');
  signal adder_reg1_s              : signed(2*g_c_width+g_extra_width-1 downto 0) := (others =>'0');
  signal adder_reg2_s              : signed(2*g_c_width+g_extra_width-1 downto 0) := (others =>'0');

  -- Registers for bit valid
  signal valid_reg1_s              : std_logic                                    := '0';
  signal valid_reg2_s              : std_logic                                    := '0';
  signal valid_reg3_s              : std_logic                                    := '0';
  signal valid_reg4_s              : std_logic                                    := '0';
  signal valid_reg5_s              : std_logic                                    := '0';

  -- Registers for the correct DSP48 inference
  signal mult_dsp1_s               : signed(2*g_c_width-1 downto 0)               := (others =>'0');
  signal mult_dsp2_s               : signed(2*g_c_width-1 downto 0)               := (others =>'0');
  signal mult_dsp3_s               : signed(2*g_c_width-1 downto 0)               := (others =>'0');
  signal mult_dsp4_s               : signed(2*g_c_width-1 downto 0)               := (others =>'0');
  signal mult_dsp5_s               : signed(2*g_c_width-1 downto 0)               := (others =>'0');
  signal mult_dsp6_s               : signed(2*g_c_width-1 downto 0)               := (others =>'0');
  signal valid_dsp1_s              : std_logic                                    := '0';
  signal valid_dsp2_s              : std_logic                                    := '0';
  signal valid_dsp3_s              : std_logic                                    := '0';
  signal valid_dsp4_s              : std_logic                                    := '0';
  signal valid_dsp5_s              : std_logic                                    := '0';
  signal valid_dsp6_s              : std_logic                                    := '0';

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
        adder_reg2_s               <= adder_reg1_s;

        -- Store the valid bit in a register
        valid_reg5_s               <= valid_reg4_s;

        -- Store the valid bit output
        result_valid_debug_o       <= valid_reg5_s;

        -- Truncate the output
        result_debug_o             <= resize(adder_reg2_s, result_debug_o'length);

				-- End of the FOFB cycle
        if (time_frame_end_i = '1') then
        	result_o                 <= resize(adder_reg2_s, result_o'length);
        	result_valid_end_o       <= '1';
				else
					result_valid_end_o       <= '0';
        end if;
      end if; -- Reset
    end if; -- Clock
  end process MAC;

end architecture behave;
