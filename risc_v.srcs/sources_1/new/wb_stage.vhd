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

entity wb_stage is
    port ( 
        me2_to_wb_buf_i : in  me2_to_wb_buf_type;

        rd_sel_o        : out std_logic_vector(4 downto 0);
        rd_o            : out std_logic_vector(31 downto 0);
        rd_we_o         : out std_logic;

        fwd_rd_sel_o    : out std_logic_vector(4 downto 0);
        fwd_rd_o        : out std_logic_vector(31 downto 0);

        clk_i           : in  std_logic;
        rst_i           : in  std_logic
    );
end wb_stage;

architecture behavioral of wb_stage is
begin    
    process(me2_to_wb_buf_i)
        variable rd     : std_logic_vector(31 downto 0);
        variable rd_sel : std_logic_vector(4 downto 0);
        variable rd_we  : std_logic;
    begin
        if (me2_to_wb_buf_i.nop = '1') then
            rd := (others => '-');
            rd_we := '0';
            rd_sel := "00000";
        else
        
            case me2_to_wb_buf_i.wb_ctrl is
            when WB_SEL_NONE =>     rd := (others => '-');          rd_we := '0';   rd_sel := "00000";
            when WB_SEL_PC4 =>      rd := me2_to_wb_buf_i.pc4;      rd_we := '1';   rd_sel := me2_to_wb_buf_i.rd_sel;
            when WB_SEL_MEM =>      rd := me2_to_wb_buf_i.mem;      rd_we := '1';   rd_sel := me2_to_wb_buf_i.rd_sel;
            when WB_SEL_ALU_RES =>  rd := me2_to_wb_buf_i.alu_res;  rd_we := '1';   rd_sel := me2_to_wb_buf_i.rd_sel;
            when others =>          rd := (others => '-');          rd_we := '0';   rd_sel := "00000";
            end case;
            
        end if;

        fwd_rd_sel_o <= rd_sel; 
        fwd_rd_o <= rd; 
        
        rd_o <= rd;
        rd_sel_o <= rd_sel;
        rd_we_o <= rd_we;
    end process;

end behavioral;
