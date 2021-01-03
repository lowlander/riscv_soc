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

entity gpio is
    port ( 
        adr_i   : in  std_logic_vector(31 downto 0);
        dat_i   : in  std_logic_vector(31 downto 0);
        dat_o   : out std_logic_vector(31 downto 0);
        we_i    : in  std_logic_vector(3 downto 0);
               
        led_o   : out std_logic_vector(7 downto 0);       
        sw_i    : in std_logic_vector(7 downto 0);       
               
               
        clk_i   : in  std_logic;
        rst_i   : in  std_logic
    );
end gpio;

architecture behavioral of gpio is
    signal led : std_logic_vector(7 downto 0);
    signal next_led : std_logic_vector(7 downto 0);
begin
    led_o <= led;
    
    process(clk_i, rst_i, next_led)
    begin
        if (rising_edge(clk_i)) then
            if (rst_i = '1') then
                led <= (others => '0');
            else
                led <= next_led;
            end if;
        end if;
    end process;

    process(dat_i, we_i, led)
    begin
        next_led <= led;
        if (we_i(0) = '1') then
            next_led <= dat_i(7 downto 0);
        end if;  
    end process;

    dat_o <= X"000000" & sw_i;
end behavioral;
