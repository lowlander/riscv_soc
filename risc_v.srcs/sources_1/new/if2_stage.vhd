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

entity if2_stage is
    port ( 
        if1_to_if2_buf_i    : in if1_to_if2_buf_type;

        if2_to_id_buf_o     : out if2_to_id_buf_type;
     
        flush_i             : in  std_logic;
        stall_i             : in  std_logic;

        ibus_dat_i          : in  std_logic_vector(31 downto 0);
        ibus_stall_i        : in  std_logic;

        clk_i               : in  std_logic;
        rst_i               : in  std_logic
    );
end if2_stage;

architecture behavioral of if2_stage is
    signal if2_to_id_buf        : if2_to_id_buf_type;
    signal next_if2_to_id_buf   : if2_to_id_buf_type;
begin
    process(clk_i, rst_i, next_if2_to_id_buf)
    begin
        if (rising_edge(clk_i)) then
            if (rst_i = '1') then
                if2_to_id_buf <= reset_if2_to_id_buf;
            else
                if2_to_id_buf <= next_if2_to_id_buf;         
            end if;
        end if;       
    end process;
    
    process(if2_to_id_buf, if1_to_if2_buf_i, ibus_dat_i, ibus_stall_i, flush_i)
        variable v : if2_to_id_buf_type;
    begin
        v := if2_to_id_buf;
        
        v.pc := if1_to_if2_buf_i.pc; 
        v.pc4 := if1_to_if2_buf_i.pc4;
        if (flush_i = '1' or if1_to_if2_buf_i.nop = '1' or ibus_stall_i = '1') then
            v.instr := NOP_INSTR; 
            v.nop := '1';
        else
            v.instr := ibus_dat_i;         
            v.nop := '0';
        end if;

        next_if2_to_id_buf <= v;
    end process;

    if2_to_id_buf_o <= if2_to_id_buf;

end behavioral;
