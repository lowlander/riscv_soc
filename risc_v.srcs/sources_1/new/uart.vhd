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

entity uart is
    port ( 
        adr_i   : in  std_logic_vector(31 downto 0);
        dat_i   : in  std_logic_vector(31 downto 0);
        dat_o   : out std_logic_vector(31 downto 0);
        we_i    : in  std_logic_vector(3 downto 0);
            
        rx_i    : in  std_logic;  
        tx_o    : out std_logic;  
               
        clk_i   : in  std_logic;
        rst_i   : in  std_logic
    );
end uart;

architecture behavioral of uart is

begin

    --
    -- Dummy, does nothing yet
    --
    process(clk_i, rst_i, dat_i, we_i)
    begin
        if (we_i(0) = '1') then
            tx_o <= '0';
        else
            tx_o <= '0';
        end if;
    end process;
    
    dat_o <= (others => '0');

end behavioral;
