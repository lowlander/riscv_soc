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

entity soc is
    port (
        uart_rx_i   : in  std_logic;  
        uart_tx_o   : out std_logic;  

        gpio_led_o  : out std_logic_vector(7 downto 0);       
        gpio_sw_i   : in  std_logic_vector(7 downto 0);       
        
        clk_i       : in  std_logic;
        rst_i       : in  std_logic
    );
end soc;

architecture behavioral of soc is
    component ibus 
    port ( 
        hart_adr_i      : in  std_logic_vector(31 downto 0);
        hart_dat_o      : out std_logic_vector(31 downto 0);
        
        hart_stall_o    : out std_logic;
       
        ram_adr_o       : out std_logic_vector(31 downto 0);
        ram_dat_i       : in  std_logic_vector(31 downto 0);
      
        clk_i           : in  std_logic;
        rst_i           : in  std_logic
    );
    end component;
    
    component dbus 
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
    end component;

    component ram is
    port ( 
        dbus_adr_i      : in  std_logic_vector(31 downto 0);
        dbus_dat_i      : in  std_logic_vector(31 downto 0);
        dbus_dat_o      : out std_logic_vector(31 downto 0);
        dbus_we_i       : in  std_logic_vector(3 downto 0);
               
        ibus_adr_i      : in  std_logic_vector(31 downto 0);
        ibus_dat_o      : out std_logic_vector(31 downto 0);

        clk_i           : in  std_logic;
        rst_i           : in  std_logic
    );
    end component;

    component gpio is
    port ( 
        adr_i           : in  std_logic_vector(31 downto 0);
        dat_i           : in  std_logic_vector(31 downto 0);
        dat_o           : out std_logic_vector(31 downto 0);
        we_i            : in  std_logic_vector(3 downto 0);
        
        led_o           : out std_logic_vector(7 downto 0);       
        sw_i            : in  std_logic_vector(7 downto 0);       

        clk_i           : in  std_logic;
        rst_i           : in  std_logic
    );
    end component;

    component uart is
    port ( 
        adr_i           : in  std_logic_vector(31 downto 0);
        dat_i           : in  std_logic_vector(31 downto 0);
        dat_o           : out std_logic_vector(31 downto 0);
        we_i            : in  std_logic_vector(3 downto 0);
        
        rx_i            : in  std_logic;  
        tx_o            : out std_logic;  

        clk_i           : in  std_logic;
        rst_i           : in  std_logic
    );
    end component;

    component hart
    port ( 
        dbus_adr_o      : out std_logic_vector(31 downto 0);
        dbus_dat_i      : in  std_logic_vector(31 downto 0);
        dbus_dat_o      : out std_logic_vector(31 downto 0);
        dbus_we_o       : out std_logic_vector(3 downto 0);
        dbus_stall_i    : in  std_logic;
               
        ibus_adr_o      : out std_logic_vector(31 downto 0);
        ibus_dat_i      : in  std_logic_vector(31 downto 0);
        ibus_stall_i    : in  std_logic;

        clk_i           : in  std_logic;
        rst_i           : in  std_logic
    );
    end component;

    signal hart_to_dbus_adr     : std_logic_vector(31 downto 0);
    signal dbus_to_hart_dat     : std_logic_vector(31 downto 0);
    signal hart_to_dbus_dat     : std_logic_vector(31 downto 0);
    signal hart_to_dbus_we      : std_logic_vector(3 downto 0);
    signal dbus_to_hart_stall   : std_logic;
               
    signal hart_to_ibus_adr     : std_logic_vector(31 downto 0);
    signal ibus_to_hart_dat     : std_logic_vector(31 downto 0);
    signal ibus_to_hart_stall   : std_logic;

    signal ibus_to_ram_adr      : std_logic_vector(31 downto 0);
    signal ram_to_ibus_dat      : std_logic_vector(31 downto 0);

    signal dbus_to_ram_adr      : std_logic_vector(31 downto 0);
    signal dbus_to_ram_dat      : std_logic_vector(31 downto 0);
    signal ram_to_dbus_dat      : std_logic_vector(31 downto 0);
    signal dbus_to_ram_we       : std_logic_vector(3 downto 0);

    signal dbus_to_gpio_adr     : std_logic_vector(31 downto 0);
    signal dbus_to_gpio_dat     : std_logic_vector(31 downto 0);
    signal gpio_to_dbus_dat     : std_logic_vector(31 downto 0);
    signal dbus_to_gpio_we      : std_logic_vector(3 downto 0);

    signal dbus_to_uart_adr     : std_logic_vector(31 downto 0);
    signal dbus_to_uart_dat     : std_logic_vector(31 downto 0);
    signal uart_to_dbus_dat     : std_logic_vector(31 downto 0);
    signal dbus_to_uart_we      : std_logic_vector(3 downto 0);
begin
    ibus_inst : ibus 
    port map ( 
        hart_adr_i =>   hart_to_ibus_adr,
        hart_dat_o =>   ibus_to_hart_dat,
        
        hart_stall_o => ibus_to_hart_stall,
       
        ram_adr_o =>    ibus_to_ram_adr,
        ram_dat_i =>    ram_to_ibus_dat,
      
        clk_i =>        clk_i,
        rst_i =>        rst_i
    );
    
    dbus_inst : dbus 
    port map ( 
        hart_adr_i =>   hart_to_dbus_adr,
        hart_dat_i =>   hart_to_dbus_dat,
        hart_dat_o =>   dbus_to_hart_dat,
        hart_we_i =>    hart_to_dbus_we,
        
        hart_stall_o => dbus_to_hart_stall,
        
        ram_adr_o =>    dbus_to_ram_adr,
        ram_dat_o =>    dbus_to_ram_dat,
        ram_dat_i =>    ram_to_dbus_dat,
        ram_we_o =>     dbus_to_ram_we,

        gpio_adr_o =>   dbus_to_gpio_adr,
        gpio_dat_o =>   dbus_to_gpio_dat,
        gpio_dat_i =>   gpio_to_dbus_dat,
        gpio_we_o =>    dbus_to_gpio_we,

        uart_adr_o =>   dbus_to_uart_adr,
        uart_dat_o =>   dbus_to_uart_dat,
        uart_dat_i =>   uart_to_dbus_dat,
        uart_we_o =>    dbus_to_uart_we,

        clk_i =>        clk_i,
        rst_i =>        rst_i
    );

    ram_inst : ram
    port map ( 
        dbus_adr_i =>   dbus_to_ram_adr,
        dbus_dat_i =>   dbus_to_ram_dat,
        dbus_dat_o =>   ram_to_dbus_dat,
        dbus_we_i =>    dbus_to_ram_we,
               
        ibus_adr_i =>   ibus_to_ram_adr,
        ibus_dat_o =>   ram_to_ibus_dat,

        clk_i =>        clk_i,
        rst_i =>        rst_i
    );

    gpio_inst : gpio
    port map ( 
        adr_i =>        dbus_to_gpio_adr,
        dat_i =>        dbus_to_gpio_dat,
        dat_o =>        gpio_to_dbus_dat,
        we_i =>         dbus_to_gpio_we,

        led_o =>        gpio_led_o,
        sw_i =>         gpio_sw_i,
               
        clk_i =>        clk_i,
        rst_i =>        rst_i
    );

    uart_inst : uart
    port map ( 
        adr_i =>        dbus_to_uart_adr,
        dat_i =>        dbus_to_uart_dat,
        dat_o =>        uart_to_dbus_dat,
        we_i =>         dbus_to_uart_we,
        
        tx_o =>         uart_tx_o,
        rx_i =>         uart_rx_i,
               
        clk_i =>        clk_i,
        rst_i =>        rst_i
    );

    hart_inst : hart 
    port map (
        dbus_adr_o =>   hart_to_dbus_adr,
        dbus_dat_i =>   dbus_to_hart_dat,
        dbus_dat_o =>   hart_to_dbus_dat,
        dbus_we_o =>    hart_to_dbus_we,
        dbus_stall_i => dbus_to_hart_stall,
               
        ibus_adr_o =>   hart_to_ibus_adr,
        ibus_dat_i =>   ibus_to_hart_dat,
        ibus_stall_i => ibus_to_hart_stall,

        clk_i =>        clk_i, 
        rst_i =>        rst_i
    );
end behavioral;
