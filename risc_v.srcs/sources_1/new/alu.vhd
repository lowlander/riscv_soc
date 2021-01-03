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

entity alu is
    port ( 
        a       : in  std_logic_vector (31 downto 0);
        b       : in  std_logic_vector (31 downto 0);
        r       : out std_logic_vector (31 downto 0);
        opcode  : in  alu_op_type
    );
end alu;

architecture behavioral of alu is
begin

    process (opcode, a, b)
        variable mul    : std_logic_vector(63 downto 0);
        variable mulsu  : std_logic_vector(64 downto 0);
    begin
        
        case opcode is 

            when ALU_OP_NOP =>    r <= (others => '0');
            when ALU_OP_PASS_A => r <= a;
            when ALU_OP_PASS_B => r <= b;
            when ALU_OP_ADDM =>   r <= std_logic_vector( signed(a) + signed(b) ); r(0) <= '0';
            when ALU_OP_ADD =>    r <= std_logic_vector( signed(a) + signed(b) );
            when ALU_OP_SUB =>    r <= std_logic_vector( signed(a) - signed(b) );

            when ALU_OP_SLT =>
                r <= (others => '0');
                if (signed(a) < signed(b)) then
                    r(0) <= '1';
                end if;

            when ALU_OP_SLTU => 
                r <= (others => '0');
                if (unsigned(a) < unsigned(b)) then
                    r(0) <= '1';
                end if;

            when ALU_OP_AND =>  r <= a and b;
            when ALU_OP_OR =>   r <= a or b;
            when ALU_OP_XOR =>  r <= a xor b;
            when ALU_OP_SLL =>  r <= std_logic_vector( shift_left(unsigned(a), to_integer( unsigned( b(4 downto 0) ) ) ) );
            when ALU_OP_SRL =>  r <= std_logic_vector( shift_right(unsigned(a), to_integer( unsigned( b(4 downto 0) ) )) );
            when ALU_OP_SRA =>  r <= std_logic_vector( shift_right(signed(a), to_integer( unsigned( b(4 downto 0) ) )) );

            --
            -- TODO make pipelined mul/div, because this works but takes a lot of time, reducing the max speed of
            -- the clock.
            --
            --when ALU_OP_MUL => mul := std_logic_vector(signed(a) * signed(b)); r <= mul(31 downto 0); 
            --when ALU_OP_MULH => mul := std_logic_vector(signed(a) * signed(b)); r <= mul(63 downto 32);
            --when ALU_OP_MULHSU => mulsu := std_logic_vector(signed(a) * signed('0' & b)); r <= mulsu(63 downto 32);
            --when ALU_OP_MULHU => mul := std_logic_vector(unsigned(a) * unsigned(b)); r <= mul(63 downto 32);
            --when ALU_OP_DIV => r <= std_logic_vector(signed(a) / signed(b));
            --when ALU_OP_DIVU => r <= std_logic_vector(unsigned(a) / unsigned(b));
            --when ALU_OP_REM => r <= std_logic_vector(signed(a) rem signed(b));
            --when ALU_OP_REMU => r <= std_logic_vector(unsigned(a) rem unsigned(b));
       
            when others =>      r <= (others => '-');
 
        end case;
        
    end process;
       
end behavioral;

