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
    Port ( CPU_RESETN : in  STD_LOGIC;                      -- Nexys 4 DDR active low reset button
           SYS_CLK    : in  STD_LOGIC;                      -- Nexys 4 DDR 100 MHz clock
           LED        : out STD_LOGIC_VECTOR(15 downto 0);  -- Nexys 4 DDR LEDs
           SW         : in  STD_LOGIC_VECTOR(15 downto 0);  -- Nexys 4 DDR switches
           SCK        : out STD_LOGIC;                      -- SCK to SPI slave
           CS         : out STD_LOGIC;                      -- SPI slave chip select
           MOSI       : out STD_LOGIC;                      -- MOSI out to slave
           MISO       : in  STD_LOGIC);                     -- MOSI in from slave
end spi_fsm_toplevel;

architecture Structural of spi_fsm_toplevel is

component spi_controller is
generic(
    N                     : integer := 8;      -- number of bit to serialize
    CLK_DIV               : integer := 100 );  -- input clock divider to generate output serial clock; o_sclk frequency = i_clk/(2*CLK_DIV)
 port (
    i_clk                       : in  std_logic;
    i_rstb                      : in  std_logic;
    i_tx_start                  : in  std_logic;  -- start TX on serial line
    o_tx_end                    : out std_logic;  -- TX data completed; o_data_parallel available
    i_data_parallel             : in  std_logic_vector(N-1 downto 0);  -- data to send
    o_data_parallel             : out std_logic_vector(N-1 downto 0);  -- received data
    o_sclk                      : out std_logic;
    o_ss                        : out std_logic;
    o_mosi                      : out std_logic;
    i_miso                      : in  std_logic);
end component;

component F_SM is
  port ( -- Inputs --
         start : in std_logic;                              -- from clock_divider
         reset : in std_logic;                              -- i_rstb
         tx_end : in std_logic;                             -- o_tx_end
         o_data_parallel: in std_logic_vector(15 downto 0); -- o_data_parallel
         i_clk : in std_logic;                              -- input clock
         -- Outputs --
         tx_start : out std_logic;                          -- i_tx_start
         i_data_parallel : out std_logic_vector(15 downto 0); --i_data_parallel
         xaxis_data : out std_logic_vector(15 downto 0);    -- x data out
         yaxis_data : out std_logic_vector(15 downto 0);    -- y data out
         zaxis_data : out std_logic_vector(15 downto 0));   -- z data out
end component;

component clock_divider is
  GENERIC(CLK_FREQ : positive := 100_000_000); -- input clock frequency in Hz
  PORT(mclk : IN  std_logic;
       sclk : OUT std_logic);
END component;

constant N          : integer := 16; 
--SIGNALS
signal o_data_parallel_s:std_logic_vector(N-1 downto 0);
signal i_data_parallel_s:std_logic_vector(N-1 downto 0);
signal i_tx_start_s:std_logic;
signal o_tx_end_s:std_logic;
signal X:std_logic_vector(N-1 downto 0);
signal Y:std_logic_vector(N-1 downto 0);
Signal Z :std_logic_vector(N-1 downto 0);
Signal clk: std_logic;

BEGIN





SPI: ENTITY work.spi_controller(rtl)
Generic MAP(
N=>N)
PORT MAP(
        i_clk  => SYS_CLK,                    
        i_rstb =>CPU_RESETN,         
        i_tx_start =>i_tx_start_s,      
        o_tx_end =>o_tx_end_s,
        i_data_parallel => i_data_parallel_s(N-1 downto 0), 
        o_data_parallel => o_data_parallel_s(N-1 downto 0),       
        o_sclk  => SCK,                
        o_ss   =>CS,                 
        o_mosi =>MOSI,                  
        i_miso => MISO);              
   

CLK_DIV: ENTITY work.clock_divider(behavior)
PORT MAP(
       mclk => SYS_CLK,
       sclk => clk);

FSM: ENTITY work.FSM(Behavioral)
PORT MAP(
         start => clk,
         reset => CPU_RESETN,
         tx_end => o_tx_end_s,
         o_data_parallel => o_data_parallel_s(N-1 downto 0),
         i_clk => SYS_CLK,
         -- Outputs --
         tx_start => i_tx_start_s,
         i_data_parallel => i_data_parallel_s,
         xaxis_data => LED(15 downto 0),
         yaxis_data => Y,
         zaxis_data => Z );


end Structural;
