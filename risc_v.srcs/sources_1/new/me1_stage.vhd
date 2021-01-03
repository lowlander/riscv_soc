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

entity me1_stage is
    port ( 
        ex_to_me1_buf_i     : in  ex_to_me1_buf_type;
        me1_to_me2_buf_o    : out me1_to_me2_buf_type;
  
        dbus_adr_o          : out std_logic_vector(31 downto 0);
        dbus_dat_o          : out std_logic_vector(31 downto 0);
        dbus_we_o           : out std_logic_vector(3 downto 0);

        stall_i             : in  std_logic;

        fwd_rd_sel_o        : out std_logic_vector(4 downto 0);
        fwd_rd_o            : out std_logic_vector(31 downto 0);

        clk_i               : in  std_logic;
        rst_i               : in  std_logic
    );
end me1_stage;

architecture behavioral of me1_stage is
    signal me1_to_me2_buf          : me1_to_me2_buf_type;
    signal next_me1_to_me2_buf     : me1_to_me2_buf_type;
begin

    process(ex_to_me1_buf_i)
    begin
        if (ex_to_me1_buf_i.nop = '1') then
            dbus_adr_o <= (others => '0');
            dbus_we_o <= "0000";
            dbus_dat_o <= (others => '-');        
        else
            dbus_adr_o <= ex_to_me1_buf_i.alu_res;
            dbus_we_o <= ex_to_me1_buf_i.mem_we;
            dbus_dat_o <= ex_to_me1_buf_i.mem_dat;
        end if;
    end process;

    process(clk_i, rst_i, next_me1_to_me2_buf)
    begin
        if (rising_edge(clk_i)) then
            if (rst_i = '1') then
                me1_to_me2_buf <= reset_me1_to_me2_buf;
            else
                me1_to_me2_buf <= next_me1_to_me2_buf;         
            end if;    
        end if;    
    end process;
    
    process(me1_to_me2_buf, ex_to_me1_buf_i, stall_i)
        variable v : me1_to_me2_buf_type;
    begin
        v := me1_to_me2_buf;
        
        if (stall_i = '0') then
            v.nop := ex_to_me1_buf_i.nop;
            if (ex_to_me1_buf_i.nop = '1') then
                v.pc := (others => '-');
                v.pc4 := (others => '-');
                v.rd_sel := "00000"; 
                v.wb_ctrl     := WB_SEL_NONE;
                v.alu_res := (others => '-');
            else
                v.pc := ex_to_me1_buf_i.pc4;
                v.pc4 := ex_to_me1_buf_i.pc4;
                v.rd_sel := ex_to_me1_buf_i.rd_sel;
                v.wb_ctrl := ex_to_me1_buf_i.wb_ctrl;
                v.alu_res := ex_to_me1_buf_i.alu_res;
            end if;
        end if;

        case v.wb_ctrl is
        when WB_SEL_PC4 => fwd_rd_sel_o <= v.rd_sel; fwd_rd_o <= v.pc4;
        when WB_SEL_ALU_RES => fwd_rd_sel_o <= v.rd_sel; fwd_rd_o <= v.alu_res;
        when others => fwd_rd_sel_o <= "00000"; fwd_rd_o <= (others => '-');
        end case;

        next_me1_to_me2_buf <= v;
    end process;

    me1_to_me2_buf_o <= me1_to_me2_buf;
end behavioral;
