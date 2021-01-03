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

entity dbus is
    port ( 
        hart_adr_i      : in  std_logic_vector(31 downto 0);
        hart_dat_i      : in  std_logic_vector(31 downto 0);
        hart_dat_o      : out std_logic_vector(31 downto 0);
        hart_we_i       : in  std_logic_vector(3 downto 0);
        hart_stall_o    : out std_logic;
               
        ram_adr_o       : out std_logic_vector(31 downto 0);
        ram_dat_o       : out std_logic_vector(31 downto 0);
        ram_dat_i       : in  std_logic_vector(31 downto 0);
        ram_we_o        : out std_logic_vector(3 downto 0);

        gpio_adr_o      : out std_logic_vector(31 downto 0);
        gpio_dat_o      : out std_logic_vector(31 downto 0);
        gpio_dat_i      : in  std_logic_vector(31 downto 0);
        gpio_we_o       : out std_logic_vector(3 downto 0);

        uart_adr_o      : out std_logic_vector(31 downto 0);
        uart_dat_o      : out std_logic_vector(31 downto 0);
        uart_dat_i      : in  std_logic_vector(31 downto 0);
        uart_we_o       : out std_logic_vector(3 downto 0);

        clk_i           : in  std_logic;
        rst_i           : in  std_logic
    );
end dbus;

architecture behavioral of dbus is
    signal adr : std_logic_vector(31 downto 0);
begin
    hart_stall_o <= '0';

    process(clk_i, rst_i, hart_adr_i) 
    begin
        if (rising_edge(clk_i)) then
            if (rst_i = '1') then
                adr <= (others => '1');
            else
                adr <= hart_adr_i;
            end if;
        end if;
    end process;

    process(hart_adr_i, hart_we_i, hart_dat_i)
    begin
        ram_adr_o <= (others => '-');
        ram_we_o <= "0000";   
        ram_dat_o <= (others => '-');
    
        gpio_adr_o <= (others => '-');
        gpio_we_o <= "0000";   
        gpio_dat_o <= (others => '-');

        uart_adr_o <= (others => '-');
        uart_we_o <= "0000";   
        uart_dat_o <= (others => '-');

        case hart_adr_i(31 downto 16) is

        when X"0000" => 
            ram_adr_o <= hart_adr_i;
            ram_we_o <= hart_we_i;   
            ram_dat_o <= hart_dat_i;
            
        when X"1000" => 
            gpio_adr_o <= hart_adr_i;
            gpio_we_o <= hart_we_i;   
            gpio_dat_o <= hart_dat_i;

        when X"2000" => 
            uart_adr_o <= hart_adr_i;
            uart_we_o <= hart_we_i;   
            uart_dat_o <= hart_dat_i;

        when others => null;

        end case;    
    
    end process;  

    process(adr, ram_dat_i, gpio_dat_i, uart_dat_i)
    begin
        hart_dat_o <= (others => '-');
        
        case adr(31 downto 16) is

        when X"0000" => 
            hart_dat_o <= ram_dat_i;   
            
        when X"1000" => 
            hart_dat_o <= gpio_dat_i;   

        when X"2000" => 
            hart_dat_o <= uart_dat_i;   

        when others => null;

        end case;    
    
    end process;  

end behavioral;
