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

library UNISIM;
use UNISIM.VComponents.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;

entity ibus is
    port ( 
        hart_adr_i      : in  std_logic_vector(31 downto 0);
        hart_dat_o      : out std_logic_vector(31 downto 0);
        hart_stall_o    : out std_logic;
      
        ram_adr_o       : out std_logic_vector(31 downto 0);
        ram_dat_i       : in  std_logic_vector(31 downto 0);
       
        clk_i           : in  std_logic;
        rst_i           : in  std_logic
    );
end ibus;

architecture behavioral of ibus is
begin
    ram_adr_o <= hart_adr_i;

    hart_stall_o <= '0';
    
    hart_dat_o <= ram_dat_i;
end behavioral;
