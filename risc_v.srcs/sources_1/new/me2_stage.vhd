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

entity me2_stage is
    port ( 
        me1_to_me2_buf_i    : in  me1_to_me2_buf_type;
        me2_to_wb_buf_o     : out me2_to_wb_buf_type;

        dbus_dat_i          : in  std_logic_vector(31 downto 0);
        dbus_stall_i        : in  std_logic;

        fwd_rd_sel_o        : out std_logic_vector(4 downto 0);
        fwd_rd_o            : out std_logic_vector(31 downto 0);

        stall_o             : out std_logic;
        
        clk_i               : in  std_logic;
        rst_i               : in  std_logic
    );
end me2_stage;

architecture Behavioral of me2_stage is
    signal me2_to_wb_buf          : me2_to_wb_buf_type;
    signal next_me2_to_wb_buf     : me2_to_wb_buf_type;
begin
    process(clk_i, rst_i, next_me2_to_wb_buf)
    begin
        if (rising_edge(clk_i)) then
            if (rst_i = '1') then
                me2_to_wb_buf <= reset_me2_to_wb_buf;
            else
                me2_to_wb_buf <= next_me2_to_wb_buf;         
            end if;    
        end if;    
    end process;
    
    process(me2_to_wb_buf, me1_to_me2_buf_i, dbus_dat_i)
        variable v : me2_to_wb_buf_type;
    begin
        v := me2_to_wb_buf;
        
        v.nop := me1_to_me2_buf_i.nop;

        if (me1_to_me2_buf_i.nop = '1') then
            v.pc := (others => '-');   
            v.pc4 := (others => '-');   
            v.alu_res := (others => '-');
            v.mem := (others => '-');
            v.rd_sel := "00000";
            v.wb_ctrl     := WB_SEL_NONE;
        else
            v.pc := me1_to_me2_buf_i.pc;   
            v.pc4 := me1_to_me2_buf_i.pc4;   
            v.alu_res := me1_to_me2_buf_i.alu_res;
            v.mem := dbus_dat_i;   
            v.rd_sel := me1_to_me2_buf_i.rd_sel;
            v.wb_ctrl := me1_to_me2_buf_i.wb_ctrl;
        end if;
    
        case v.wb_ctrl is
        when WB_SEL_PC4 => fwd_rd_sel_o <= v.rd_sel; fwd_rd_o <= v.pc4;
        when WB_SEL_ALU_RES => fwd_rd_sel_o <= v.rd_sel; fwd_rd_o <= v.alu_res;
        when WB_SEL_MEM => fwd_rd_sel_o <= v.rd_sel; fwd_rd_o <= v.mem;
        when others => fwd_rd_sel_o <= "00000"; fwd_rd_o <= (others => '-');
        end case;
    
        next_me2_to_wb_buf <= v;
    end process;
    
    stall_o <= dbus_stall_i;

    me2_to_wb_buf_o <= me2_to_wb_buf;
end behavioral;
