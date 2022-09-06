-------------------------------------------------------------------------------
-- Title      : Dot product module
-------------------------------------------------------------------------------
-- Author     : Melissa Aguiar
-- Company    : CNPEM LNLS-DIG
-- Platform   : FPGA-generic
-- Standard   : VHDL 2008
-------------------------------------------------------------------------------
-- Description: Calculates de dot product of two vectors
-------------------------------------------------------------------------------
-- Copyright (c) 2020-2022 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author                Description
-- 2021-08-11  1.0      melissa.aguiar        Created
-- 2022-08-22  2.0      augusto.fraga         Refactored using VHDL 2008
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;

library work;
use work.dot_prod_pkg.all;

entity dot_prod is
  generic (
    -- Integer width for input a[k]
    g_A_INT_WIDTH                  : natural := 7;

    -- Fractionary width for input a[k]
    g_A_FRAC_WIDTH                 : natural := 10;

    -- Integer width for input b[k]
    g_B_INT_WIDTH                  : natural := 7;

    -- Fractionary width for input b[k]
    g_B_FRAC_WIDTH                 : natural := 10;

    -- Extra bits for accumulator
    g_ACC_EXTRA_WIDTH              : natural := 4;

    -- Use registered inputs
    g_REG_INPUTS                   : boolean := false;

    -- Number of multiplier pipeline stages
    g_MULT_PIPELINE_STAGES         : natural := 1;

    -- Number of accumulator pipeline stages
    g_ACC_PIPELINE_STAGES          : natural := 1
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

    -- Input a[k]
    a_i                            : in sfixed(g_A_INT_WIDTH downto -g_A_FRAC_WIDTH);

    -- Input b[k]
    b_i                            : in sfixed(g_B_INT_WIDTH downto -g_B_FRAC_WIDTH);

    -- No ongoing operations, all pipeline stages idle
    idle_o                         : out std_logic;

    -- Result output
    result_o                       : out sfixed(g_A_INT_WIDTH + g_B_INT_WIDTH + g_ACC_EXTRA_WIDTH + 1
                                                downto
                                                -(g_A_FRAC_WIDTH + g_B_FRAC_WIDTH))
  );
end dot_prod;

architecture behave of dot_prod is

  constant c_t_mult_res_int_width : natural := g_A_INT_WIDTH + g_B_INT_WIDTH + 1;
  constant c_t_mult_res_frac_width : natural := g_A_FRAC_WIDTH + g_B_FRAC_WIDTH;
  constant c_t_acc_int_width : natural := g_A_INT_WIDTH + g_B_INT_WIDTH + g_ACC_EXTRA_WIDTH + 1;
  constant c_t_acc_frac_width : natural := g_A_FRAC_WIDTH + g_B_FRAC_WIDTH;
  type t_mult_res_arr is array (natural range <>) of sfixed(c_t_mult_res_int_width downto -c_t_mult_res_frac_width);
  -- Can't use result_o'subtype here due to a Vivado 2018.3 bug that complains
  -- that about acc_pipe as if it was a unconstrained array
  type t_acc_arr is array (natural range <>) of sfixed(c_t_acc_int_width downto -c_t_acc_frac_width);

  -- Registers for input values
  signal a_reg_s                   : a_i'subtype;
  signal b_reg_s                   : b_i'subtype;
  signal ab_reg_valid              : std_logic;

  -- Registers for intermediate values
  signal mult_res_pipe             : t_mult_res_arr(g_MULT_PIPELINE_STAGES-1 downto 0);
  signal mult_res_pipe_valid       : std_logic_vector(g_MULT_PIPELINE_STAGES-1 downto 0);

  signal acc_pipe                  : t_acc_arr(g_ACC_PIPELINE_STAGES-1 downto 0);
  signal acc_pipe_valid            : std_logic_vector(g_ACC_PIPELINE_STAGES-1 downto 0);
begin

  -- Is idle if all pipeline stages are themselves idle
  -- TODO: This logic wastes an extra clock cycle due to acc_pipe last
  -- element
  idle_o <= not(or(ab_reg_valid & mult_res_pipe_valid & acc_pipe_valid));

  p_dot_product : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        -- Clear all registers
        a_reg_s                    <= (others => '0');
        b_reg_s                    <= (others => '0');
        mult_res_pipe              <= (others => (others => '0'));
        mult_res_pipe_valid        <= (others => '0');
        acc_pipe                   <= (others => (others => '0'));
        acc_pipe_valid             <= (others => '0');
        ab_reg_valid               <= '0';
      elsif (clear_acc_i = '1') then
        -- Clear the accumulator and pipeline valid bits
        mult_res_pipe_valid        <= (others => '0');
        acc_pipe_valid             <= (others => '0');
        acc_pipe                   <= (others => (others => '0'));
      else
        if g_REG_INPUTS then
          -- Store the a_i and b_i inputs in a register
          a_reg_s                    <= a_i;
          b_reg_s                    <= b_i;
          mult_res_pipe(0)           <= a_reg_s * b_reg_s;
          ab_reg_valid               <= valid_i;
          mult_res_pipe_valid(0)     <= ab_reg_valid;
        else
          -- Multiply a_i and b_i directly
          mult_res_pipe(0)           <= a_i * b_i;
          mult_res_pipe_valid(0)     <= valid_i;
        end if;

        -- Add more intermediate registers to the multiply result
        if g_MULT_PIPELINE_STAGES > 1 then
          for i in 1 to g_MULT_PIPELINE_STAGES-1 loop
            mult_res_pipe_valid(i) <= mult_res_pipe_valid(i - 1);
            mult_res_pipe(i) <= mult_res_pipe(i - 1);
          end loop;
        end if;

        -- Pass pipeline valid
        acc_pipe_valid(0) <= mult_res_pipe_valid(g_MULT_PIPELINE_STAGES-1);

        if (mult_res_pipe_valid(g_MULT_PIPELINE_STAGES-1) = '1') then
          -- Store accumulation result in a register
          acc_pipe(0) <= resize(acc_pipe(0) + mult_res_pipe(g_MULT_PIPELINE_STAGES-1), c_t_acc_int_width, -c_t_acc_frac_width);
        end if;

        -- Add more intermediate registers to the accumulator sum result
        if g_ACC_PIPELINE_STAGES > 1 then
          for i in 1 to g_ACC_PIPELINE_STAGES-1 loop
            acc_pipe_valid(i) <= acc_pipe_valid(i - 1);
            acc_pipe(i) <= acc_pipe(i - 1);
          end loop;
        end if;

      end if; -- Reset
    end if; -- Clock

    -- Result is the last register of the accumulator pipeline array
    result_o <= acc_pipe(g_ACC_PIPELINE_STAGES-1);
  end process p_dot_product;

end architecture behave;
