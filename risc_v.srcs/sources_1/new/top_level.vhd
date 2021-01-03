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

Library UNISIM;
use UNISIM.vcomponents.all;

entity top_level is
    port ( 
        led         : out std_logic_vector(7 downto 0);
        btnc        : in  std_logic;
        btnu        : in  std_logic;
        btnd        : in  std_logic;
        btnl        : in  std_logic;
        btnr        : in  std_logic;
        sw          : in  std_logic_vector(7 downto 0);
        
        uart_rx_out : out std_logic;
        uart_tx_in  : in  std_logic;

        clk         : in  std_logic;
        cpu_resetn  : in  std_logic
    );
end top_level;

architecture behavioral of top_level is
    component soc
    port ( 
        uart_rx_i   : in  std_logic;  
        uart_tx_o   : out std_logic;  

        gpio_led_o  : out std_logic_vector(7 downto 0);       
        gpio_sw_i   : in  std_logic_vector(7 downto 0);       

        clk_i       : in  std_logic;
        rst_i       : in  std_logic
    );
    end component;
    
    signal locked   : std_logic;
    signal clkfb    : std_logic;
    signal rst      : std_logic;
    signal cpu_rst  : std_logic;
    signal cpu_clk  : std_logic;
begin
    rst <= not cpu_resetn;

  MMCME2_ADV_inst : MMCME2_ADV
   generic map (
      BANDWIDTH => "OPTIMIZED",      -- Jitter programming (OPTIMIZED, HIGH, LOW)
      CLKFBOUT_MULT_F => 8.0,        -- Multiply value for all CLKOUT (2.000-64.000).
      CLKFBOUT_PHASE => 0.0,         -- Phase offset in degrees of CLKFB (-360.000-360.000).
      -- CLKIN_PERIOD: Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
      CLKIN1_PERIOD => 10.0,
      CLKIN2_PERIOD => 0.0,
      -- CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for CLKOUT (1-128)
      CLKOUT1_DIVIDE => 1,
      CLKOUT2_DIVIDE => 1,
      CLKOUT3_DIVIDE => 1,
      CLKOUT4_DIVIDE => 1,
      CLKOUT5_DIVIDE => 1,
      CLKOUT6_DIVIDE => 1,
      CLKOUT0_DIVIDE_F => 9.0,       -- Divide amount for CLKOUT0 (1.000-128.000).
      -- CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for CLKOUT outputs (0.01-0.99).
      CLKOUT0_DUTY_CYCLE => 0.5,
      CLKOUT1_DUTY_CYCLE => 0.5,
      CLKOUT2_DUTY_CYCLE => 0.5,
      CLKOUT3_DUTY_CYCLE => 0.5,
      CLKOUT4_DUTY_CYCLE => 0.5,
      CLKOUT5_DUTY_CYCLE => 0.5,
      CLKOUT6_DUTY_CYCLE => 0.5,
      -- CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for CLKOUT outputs (-360.000-360.000).
      CLKOUT0_PHASE => 0.0,
      CLKOUT1_PHASE => 0.0,
      CLKOUT2_PHASE => 0.0,
      CLKOUT3_PHASE => 0.0,
      CLKOUT4_PHASE => 0.0,
      CLKOUT5_PHASE => 0.0,
      CLKOUT6_PHASE => 0.0,
      CLKOUT4_CASCADE => FALSE,      -- Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
      COMPENSATION => "ZHOLD",       -- ZHOLD, BUF_IN, EXTERNAL, INTERNAL
      DIVCLK_DIVIDE => 1,            -- Master division value (1-106)
      -- REF_JITTER: Reference input jitter in UI (0.000-0.999).
      REF_JITTER1 => 0.0,
      REF_JITTER2 => 0.0,
      STARTUP_WAIT => FALSE,         -- Delays DONE until MMCM is locked (FALSE, TRUE)
      -- Spread Spectrum: Spread Spectrum Attributes
      SS_EN => "FALSE",              -- Enables spread spectrum (FALSE, TRUE)
      SS_MODE => "CENTER_HIGH",      -- CENTER_HIGH, CENTER_LOW, DOWN_HIGH, DOWN_LOW
      SS_MOD_PERIOD => 10000,        -- Spread spectrum modulation period (ns) (VALUES)
      -- USE_FINE_PS: Fine phase shift enable (TRUE/FALSE)
      CLKFBOUT_USE_FINE_PS => FALSE,
      CLKOUT0_USE_FINE_PS => FALSE,
      CLKOUT1_USE_FINE_PS => FALSE,
      CLKOUT2_USE_FINE_PS => FALSE,
      CLKOUT3_USE_FINE_PS => FALSE,
      CLKOUT4_USE_FINE_PS => FALSE,
      CLKOUT5_USE_FINE_PS => FALSE,
      CLKOUT6_USE_FINE_PS => FALSE
   )
   port map (
      -- Clock Outputs: 1-bit (each) output: User configurable clock outputs
      CLKOUT0 => cpu_clk,           -- 1-bit output: CLKOUT0
      --CLKOUT0B => CLKOUT0B,         -- 1-bit output: Inverted CLKOUT0
      --CLKOUT1 => CLKOUT1,           -- 1-bit output: CLKOUT1
      --CLKOUT1B => CLKOUT1B,         -- 1-bit output: Inverted CLKOUT1
      --CLKOUT2 => CLKOUT2,           -- 1-bit output: CLKOUT2
      --CLKOUT2B => CLKOUT2B,         -- 1-bit output: Inverted CLKOUT2
      --CLKOUT3 => CLKOUT3,           -- 1-bit output: CLKOUT3
      --CLKOUT3B => CLKOUT3B,         -- 1-bit output: Inverted CLKOUT3
      --CLKOUT4 => CLKOUT4,           -- 1-bit output: CLKOUT4
      --CLKOUT5 => CLKOUT5,           -- 1-bit output: CLKOUT5
      --CLKOUT6 => CLKOUT6,           -- 1-bit output: CLKOUT6
      -- DRP Ports: 16-bit (each) output: Dynamic reconfiguration ports
      --DO => DO,                     -- 16-bit output: DRP data
      --DRDY => DRDY,                 -- 1-bit output: DRP ready
      -- Dynamic Phase Shift Ports: 1-bit (each) output: Ports used for dynamic phase shifting of the outputs
      --PSDONE => PSDONE,             -- 1-bit output: Phase shift done
      -- Feedback Clocks: 1-bit (each) output: Clock feedback ports
      CLKFBOUT => clkfb,         -- 1-bit output: Feedback clock
      --CLKFBOUTB => CLKFBOUTB,       -- 1-bit output: Inverted CLKFBOUT
      -- Status Ports: 1-bit (each) output: MMCM status ports
      --CLKFBSTOPPED => CLKFBSTOPPED, -- 1-bit output: Feedback clock stopped
      --CLKINSTOPPED => CLKINSTOPPED, -- 1-bit output: Input clock stopped
      LOCKED => locked,             -- 1-bit output: LOCK
      -- Clock Inputs: 1-bit (each) input: Clock inputs
      CLKIN1 => clk,             -- 1-bit input: Primary clock
      CLKIN2 => '0', -- CLKIN2,             -- 1-bit input: Secondary clock
      -- Control Ports: 1-bit (each) input: MMCM control ports
      CLKINSEL => '1', -- CLKINSEL,         -- 1-bit input: Clock select, High=CLKIN1 Low=CLKIN2
      PWRDWN => '0', -- PWRDWN,             -- 1-bit input: Power-down
      RST => RST,                   -- 1-bit input: Reset
      -- DRP Ports: 7-bit (each) input: Dynamic reconfiguration ports
      DADDR => (others => '0'), -- DADDR,               -- 7-bit input: DRP address
      DCLK => '0', -- DCLK,                 -- 1-bit input: DRP clock
      DEN => '0', -- DEN,                   -- 1-bit input: DRP enable
      DI => (others => '0'), --DI,                     -- 16-bit input: DRP data
      DWE => '0', --DWE,                   -- 1-bit input: DRP write enable
      -- Dynamic Phase Shift Ports: 1-bit (each) input: Ports used for dynamic phase shifting of the outputs
      PSCLK => '0', -- PSCLK,               -- 1-bit input: Phase shift clock
      PSEN => '0', --PSEN,                 -- 1-bit input: Phase shift enable
      PSINCDEC => '0', --PSINCDEC,         -- 1-bit input: Phase shift increment/decrement
      -- Feedback Clocks: 1-bit (each) input: Clock feedback ports
      CLKFBIN => clkfb            -- 1-bit input: Feedback clock
   );
        
    cpu_rst <= rst or not locked;    
        
    soc_inst : soc 
    port map (
        gpio_led_o =>   led,       
        gpio_sw_i =>    sw,       

        uart_rx_i =>    uart_tx_in,
        uart_tx_o =>    uart_rx_out,
        
        clk_i =>        cpu_clk, 
        rst_i =>        cpu_rst
    );
end behavioral;
