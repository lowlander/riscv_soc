----------------------------------------------------------------------------------
--
-- Copyright (c) 2021 Erwin Rol <erwin@erwinrol.com>
--
-- SPDX-License-Identifier: MIT
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.riscv.all;

entity forward_unit is
    port ( 
        me1_rd_i        : in  std_logic_vector(31 downto 0);
        me1_rd_sel_i    : in  std_logic_vector(4 downto 0);

        me2_rd_i        : in  std_logic_vector(31 downto 0);
        me2_rd_sel_i    : in  std_logic_vector(4 downto 0);

        wb_rd_i         : in  std_logic_vector(31 downto 0);
        wb_rd_sel_i     : in  std_logic_vector(4 downto 0);
        
        ex_rs1_sel_i    : in  std_logic_vector(4 downto 0);
        ex_rs2_sel_i    : in  std_logic_vector(4 downto 0);

        rs1_fwd_o       : out std_logic_vector(31 downto 0);
        rs1_use_fwd_o   : out std_logic;

        rs2_fwd_o       : out std_logic_vector(31 downto 0);
        rs2_use_fwd_o   : out std_logic;

        clk_i           : in  std_logic;
        rst_i           : in  std_logic
    );
end forward_unit;

architecture behavioral of forward_unit is
begin    
    process(ex_rs1_sel_i, ex_rs2_sel_i, wb_rd_sel_i, me2_rd_sel_i, me1_rd_sel_i, me1_rd_i, wb_rd_i, me2_rd_i)
    begin
        if (ex_rs1_sel_i = "00000") then
            rs1_use_fwd_o <= '0';
            rs1_fwd_o <= (others => '-');
        else
            if (ex_rs1_sel_i = me1_rd_sel_i) then
                rs1_use_fwd_o <= '1';
                rs1_fwd_o <= me1_rd_i;
            elsif (ex_rs1_sel_i = me2_rd_sel_i) then
                rs1_use_fwd_o <= '1';
                rs1_fwd_o <= me2_rd_i;
            elsif (ex_rs1_sel_i = wb_rd_sel_i) then                        
                rs1_use_fwd_o <= '1';
                rs1_fwd_o <= wb_rd_i;
            else
                rs1_use_fwd_o <= '0';
                rs1_fwd_o <= (others => '-');            
            end if;
        end if; 
        
        if (ex_rs2_sel_i = "00000") then
            rs2_use_fwd_o <= '0';
            rs2_fwd_o <= (others => '-');
        else
            if (ex_rs2_sel_i = me1_rd_sel_i) then
                rs2_use_fwd_o <= '1';
                rs2_fwd_o <= me1_rd_i;
            elsif (ex_rs2_sel_i = me2_rd_sel_i) then
                rs2_use_fwd_o <= '1';
                rs2_fwd_o <= me2_rd_i;        
            elsif (ex_rs2_sel_i = wb_rd_sel_i) then                        
                rs2_use_fwd_o <= '1';
                rs2_fwd_o <= wb_rd_i;
            else
                rs2_use_fwd_o <= '0';
                rs2_fwd_o <= (others => '-');            
            end if;
        end if;
    end process;
end behavioral;
