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

entity register_file is
    port ( 
        rs1_o       : out std_logic_vector(31 downto 0);
        rs2_o       : out std_logic_vector(31 downto 0);
        rd_i        : in  std_logic_vector(31 downto 0);
        rs1_sel_i   : in  std_logic_vector( 4 downto 0);
        rs2_sel_i   : in  std_logic_vector( 4 downto 0);
        rd_sel_i    : in  std_logic_vector( 4 downto 0);
        rd_we_i     : in  std_logic;
        clk_i       : in  std_logic;
        rst_i       : in  std_logic
    );
end register_file;

architecture behavioral of register_file is
    type reg_file_t is array (0 to 31) of std_logic_vector(31 downto 0);

    signal reg_file         : reg_file_t;
begin
    rs1_o <= reg_file(to_integer(unsigned(rs1_sel_i)));
    rs2_o <= reg_file(to_integer(unsigned(rs2_sel_i)));

    process(reg_file, clk_i, rst_i, rd_sel_i, rd_i)
    begin
        if( rising_edge(clk_i) ) then
            if (rst_i = '1') then
                for reg_nr in 0 to 31 loop
                    reg_file(reg_nr) <= (others => '0');
                end loop;

                reg_file(2) <= X"00000100"; -- SP
                reg_file(3) <= X"00000000"; -- GP
            else
                if (rd_we_i = '1') then
                    if (rd_sel_i = "00000") then
                        reg_file(0) <= (others => '0');
                    else
                        reg_file(TO_INTEGER(unsigned(rd_sel_i))) <= rd_i;
                    end if;
                end if;
            end if;
        end if;
     end process;
          
end behavioral;
