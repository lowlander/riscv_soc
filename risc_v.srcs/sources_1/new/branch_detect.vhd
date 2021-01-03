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

entity branch_detect is
    port (
        rs1         : in  std_logic_vector(31 downto 0);
        rs2         : in  std_logic_vector(31 downto 0);
        opcode      : in  opcode_type;
        do_branch   : out std_logic
    );
end branch_detect;

architecture Behavioral of branch_detect is

begin

    process (opcode, rs1, rs2)
    begin
            
        case opcode is 

            when OP_BEQ =>
                if (signed(rs1) = signed(rs2)) then
                    do_branch <= '1';
                else
                    do_branch <= '0';
                end if;

            when OP_BNE =>
                if (signed(rs1) /= signed(rs2)) then
                    do_branch <= '1';
                else
                    do_branch <= '0';
                end if;

            when OP_BLT =>
                if (signed(rs1) < signed(rs2)) then
                    do_branch <= '1';
                else
                    do_branch <= '0';
                end if;

            when OP_BLTU =>
                if (unsigned(rs1) < unsigned(rs2)) then
                    do_branch <= '1';
                else
                    do_branch <= '0';
                end if;

            when OP_BGE =>
                if (signed(rs1) >= signed(rs2)) then
                    do_branch <= '1';
                else
                    do_branch <= '0';
                end if;

            when OP_BGEU =>
                if (unsigned(rs1) >= unsigned(rs2)) then
                    do_branch <= '1';
                else
                    do_branch <= '0';
                end if;

            when OP_JAL  =>
                do_branch <= '1';
    
            when OP_JALR =>
                do_branch <= '1';

            when others => do_branch <= '0';
 
        end case;
        
    end process;
    
end behavioral;
