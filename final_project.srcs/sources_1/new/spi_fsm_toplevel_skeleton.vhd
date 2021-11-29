-- ******************************************************************** 
--
-- Fle Name: spi_fsm_toplevel.vhd
-- 
-- scope: top level component for mapping onto Digilent Basys4 DDR board
--
-- rev 1.00.2019.10.29
-- 
-- ******************************************************************** 
-- ******************************************************************** 


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_fsm_toplevel is
    Port ( CPU_RESETN : in	STD_LOGIC;						-- Nexys 4 DDR active low reset button
           SYS_CLK    : in	STD_LOGIC;						-- Nexys 4 DDR 100 MHz clock
           LED        : out	STD_LOGIC_VECTOR(15 downto 0);	-- Nexys 4 DDR LEDs
           SW         : in	STD_LOGIC_VECTOR(15 downto 0);  -- Nexys 4 DDR switches
		   SCK        : out STD_LOGIC;						-- SCK to SPI slave
           CS         : out STD_LOGIC;						-- SPI slave chip select
		   MOSI       : out STD_LOGIC;						-- MOSI out to slave
		   MISO       : in  STD_LOGIC);						-- MOSI in from slave
end spi_fsm_toplevel;

architecture Structural of spi_fsm_toplevel is



constant clk_div: postive 100000
begin
--LED17_6 <= i_start_s and SYS_clk;

start_clk;
entity work.clk_divider(behavior)
generic map(
            divider => clk_div)
port map(
         mclk=>SYS_clk,sclk=>i_start_s);


u_spi_controller: spi_controoler

generic map()


end Structural;
