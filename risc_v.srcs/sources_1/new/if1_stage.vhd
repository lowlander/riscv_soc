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
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.riscv.all;

entity if1_stage is
    port ( 
        if1_to_if2_buf_o    : out if1_to_if2_buf_type;
        
        branch_adr_i        : in  std_logic_vector(31 downto 0);
        do_branch_i         : in  std_logic;

        flush_i             : in  std_logic;
        stall_i             : in  std_logic;
        
        ibus_adr_o          : out std_logic_vector(31 downto 0);
    
        clk_i               : in  std_logic;
        rst_i               : in  std_logic
    );
end if1_stage;

architecture behavioral of if1_stage is
    signal if1_to_if2_buf       : if1_to_if2_buf_type;
    signal next_if1_to_if2_buf  : if1_to_if2_buf_type;

    signal pc                   : std_logic_vector(31 downto 0); 
    signal next_pc              : std_logic_vector(31 downto 0); 
    signal pc4                  : std_logic_vector(31 downto 0); 
begin
    pc4 <= pc + 4;

    process(clk_i, rst_i, next_pc)
    begin
        if (rising_edge(clk_i)) then
            if (rst_i = '1') then
                pc <= X"FFFFFFFC";
            else
                pc <= next_pc;          
            end if;
        end if;
    end process;
        
    process(pc, pc4, branch_adr_i, do_branch_i)
    begin
        next_pc <= pc;

        if (do_branch_i = '1') then
            next_pc <= branch_adr_i;
        else
            next_pc <= pc4;
        end if;
    end process;

    process(clk_i, rst_i, next_if1_to_if2_buf)
    begin
        if (rising_edge(clk_i)) then
            if (rst_i = '1') then
                if1_to_if2_buf <= reset_if1_to_if2_buf;
            else
                if1_to_if2_buf <= next_if1_to_if2_buf;         
            end if;
        end if;
    end process;
    
    process(if1_to_if2_buf, pc, pc4, flush_i)
        variable v : if1_to_if2_buf_type;
    begin
        v := if1_to_if2_buf;
                
        v.pc := pc;
        v.pc4 := pc4;
        v.nop := flush_i;

        next_if1_to_if2_buf <= v;
    end process;
    
    ibus_adr_o <= pc;

    if1_to_if2_buf_o <= if1_to_if2_buf;
end behavioral;
