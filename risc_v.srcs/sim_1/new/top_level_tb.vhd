library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top_level_tb is
end top_level_tb;

architecture behavioral of top_level_tb is
    component top_level
    port (
        led             : out std_logic_vector(7 downto 0);
        btnc            : in  std_logic;
        btnu            : in  std_logic;
        btnd            : in  std_logic;
        btnl            : in  std_logic;
        btnr            : in  std_logic;
        sw              : in  std_logic_vector(7 downto 0);

        uart_rx_out     : out std_logic;
        uart_tx_in      : in  std_logic;

        clk             : in  std_logic;
        cpu_resetn      : in  std_logic
    );
    end component;

    signal clk          : std_logic;
    signal cpu_resetn   : std_logic;
    signal led          : std_logic_vector(7 downto 0);
    signal btnc         : std_logic;
    signal btnu         : std_logic;
    signal btnd         : std_logic;
    signal btnl         : std_logic;
    signal btnr         : std_logic;
    signal sw           : std_logic_vector(7 downto 0);
    signal uart_tx_in   : std_logic;
    signal uart_rx_out  : std_logic;
begin
    sw <= (others => '0');
    btnc <= '0';
    btnu <= '0';
    btnd <= '0';
    btnl <= '0';
    btnr <= '0';

    uart_tx_in <= '0';

    dut : top_level 
    port map (
        led => led,
        btnc => btnc,
        btnu => btnu,
        btnd => btnd,
        btnl => btnl,
        btnr => btnr,
        sw => sw,
        uart_rx_out => uart_rx_out,
        uart_tx_in => uart_tx_in,
        clk => clk, 
        cpu_resetn => cpu_resetn
    );

    process
    begin
        cpu_resetn <= '0';
        wait for 50ns;
        cpu_resetn <= '1';
        wait;
    end process;

    process
    begin
        clk <= '0';
        wait for 5ns;
        clk <= '1';
        wait for 5ns;    
    end process;

end behavioral;
