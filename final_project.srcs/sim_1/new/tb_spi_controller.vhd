
-- ******************************************************************** 
--
-- Fle Name: tb_spi_controller.vhd
-- 
-- scope: test bench for spi_controller.vjd
--
-- rev 1.00.2019.10.26.2019
-- 
-- ******************************************************************** 
-- ******************************************************************** 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_spi_controller is
end tb_spi_controller;

architecture rtl of tb_spi_controller is

component spi_controller
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

component FSM
  port ( start : in std_logic;                              -- clock_divider
         reset : in std_logic;                              -- reset
         tx_end : in std_logic;                             -- o_tx_end
         o_data_parallel: in std_logic_vector(15 downto 0); -- o_data_parallel
         i_clk : in std_logic;                              -- clock
         tx_start : out std_logic;                          -- i_tx_start
         i_data_parallel : out std_logic_vector(15 downto 0); --i_data_parallel
         xaxis_data : out std_logic_vector(15 downto 0);    -- x data out
         yaxis_data : out std_logic_vector(15 downto 0);    -- y data out
         zaxis_data : out std_logic_vector(15 downto 0));   -- z data out


end component;

constant N          : integer := 16;   -- number of bits send per SPI transaction
constant NO_VECTORS : integer := 8;    -- number of SPI transactions to simulate
constant CLK_DIV    : integer := 100;  -- input clock divider to generate output serial clock; o_sclk frequency = i_clk/(2*CLK_DIV)

type output_value_array is array (1 to NO_VECTORS) of std_logic_vector(N-1 downto 0);

constant i_data_values : output_value_array := (std_logic_vector(to_unsigned(16#2C08#,N)),
                                                std_logic_vector(to_unsigned(16#2D08#,N)),
                                                std_logic_vector(to_unsigned(16#B201#,N)),
                                                std_logic_vector(to_unsigned(16#B302#,N)),
                                                std_logic_vector(to_unsigned(16#B403#,N)),
                                                std_logic_vector(to_unsigned(16#B504#,N)),
                                                std_logic_vector(to_unsigned(16#B605#,N)),
                                                std_logic_vector(to_unsigned(16#B706#,N)));

constant o_data_values : output_value_array := (std_logic_vector(to_unsigned(16#00A1#,N)),
                                                std_logic_vector(to_unsigned(16#00B2#,N)),
                                                std_logic_vector(to_unsigned(16#0032#,N)),
                                                std_logic_vector(to_unsigned(16#0033#,N)),
                                                std_logic_vector(to_unsigned(16#0034#,N)),
                                                std_logic_vector(to_unsigned(16#0035#,N)),
                                                std_logic_vector(to_unsigned(16#0036#,N)),
                                                std_logic_vector(to_unsigned(16#0037#,N)));

signal o_data_index    : integer := 1;
signal i_data_index    : integer := 1;
signal send_data_index : integer := 1;
signal count_fall      : integer := 0;
signal count_rise      : integer := 0;
signal sys_clk_sig     : STD_LOGIC := '0';		-- start system clock at '0'
signal cpu_resetn_sig  : STD_LOGIC := '1';		-- default for reset signal is '1'
signal sck_sig         : STD_LOGIC;
signal cs_sig          : STD_LOGIC;
signal mosi_sig        : STD_LOGIC;
signal miso_sig        : STD_LOGIC;
signal tx_start_s        : std_logic := '0';  -- default idle
signal tx_end_s          : std_logic;
signal o_data_parallel_s : STD_LOGIC_VECTOR(15 downto 0);
signal i_data_parallel_s : STD_LOGIC_VECTOR(15 downto 0);

signal x_data_out : STD_LOGIC_VECTOR(15 downto 0);
signal y_data_out : STD_LOGIC_VECTOR(15 downto 0);
signal z_data_out : STD_LOGIC_VECTOR(15 downto 0);

signal slow_clk : std_logic;
signal i_rstb : std_logic := '1';

signal master_data_received : std_logic_vector(N-1 downto 0);  -- data sent by the master and received by the slave
signal slave_data_sent      : std_logic_vector(N-1 downto 0);  -- data sent by the slave and received by the master

 
begin


DUT : spi_controller
  generic map(
	N                     => N,
	CLK_DIV               => CLK_DIV)
  port map(
	i_clk                       => sys_clk_sig,
	i_rstb                      => i_rstb,
	i_tx_start                  => tx_start_s,
	o_tx_end                    => tx_end_s,
	i_data_parallel             => i_data_parallel_s,
	o_data_parallel             => o_data_parallel_s,
	o_sclk                      => sck_sig,
	o_ss                        => cs_sig,
	o_mosi                      => mosi_sig,
	i_miso                      => miso_sig);
			  

-- master clock and reset signals
sys_clk_sig <= not sys_clk_sig after 5 ns;

reset_process : process
begin
    --if (cpu_resetn_sig = '1') then
        wait for 10 ns;
        cpu_resetn_sig <= '0';
        i_rstb  <= '0';
        wait for 10 ns;
        cpu_resetn_sig <= '1';
        i_rstb  <= '1';
        wait;
    --end if;
end process reset_process;


clk_divider : entity work.clock_divider(behavior)
  generic map(CLK_FREQ => 100) -- input clock frequency in Hz
  port map(mclk => sys_clk_sig,
           sclk => slow_clk);


DUT2 : FSM
  port map(
	start                       => slow_clk,
	reset                       => i_rstb,
	tx_end                  	=> tx_end_s,
	o_data_parallel             => o_data_parallel_s,
	i_clk                       => sys_clk_sig,
	tx_start					=> tx_start_s,
	i_data_parallel				=> i_data_parallel_s,
	xaxis_data					=> x_data_out,
	yaxis_data					=> y_data_out,
	zaxis_data					=> z_data_out);
	
-- Simulation of an SPI slave replying to the master
-- slave places proper vector from o_data_values onto miso_sig
-- on falling edge of sck_sig

spi_slave_sim : process(sck_sig, cpu_resetn_sig)
begin
	if(cpu_resetn_sig='0') then
		o_data_index      <= 1;			-- initialize to first input vector
		slave_data_sent   <= o_data_values(1);
		miso_sig      <= '0';
		count_fall  <= 0;
	else
		if(falling_edge(sck_sig)) then
			if(cs_sig='0') then
				count_fall     <= count_fall+1;
				slave_data_sent   <= std_logic_vector(shift_left(unsigned(slave_data_sent),1));
				miso_sig      <= slave_data_sent(N-1) after 63 ns;
			else
				count_fall     <= 0;
			end if;
			if(count_fall = 16) then
			  count_fall <= 1;
			  if(o_data_index = NO_VECTORS) then
			    o_data_index <= 1;
			    slave_data_sent <= std_logic_vector(shift_left(unsigned(o_data_values(1)),1));
				miso_sig      <= o_data_values(1)(N-1) after 63 ns;
			  else
			    o_data_index <= o_data_index + 1;
			    slave_data_sent   <= std_logic_vector(shift_left(unsigned(o_data_values(o_data_index+1)),1));
				miso_sig      <= o_data_values(o_data_index+1)(N-1) after 63 ns;
			  end if;
			end if;
		end if;
	end if;
end process spi_slave_sim;

-- this process monitors the SPI master to ensure that its sending out
-- the proper values on mosi_sig on the rising edge of sck_sig

spi_master_monitor : process(sck_sig, cpu_resetn_sig)
  begin
	if(cpu_resetn_sig='0') then
		i_data_index      <= 1;			-- initialize to first input vector
		master_data_received   <= std_logic_vector(to_unsigned(16#00#,N));
		count_rise  <= 0;
    else
		if(rising_edge(sck_sig)) then
			if(cs_sig='0' and count_rise < 16) then
				master_data_received   <= master_data_received(N-2 downto 0)&mosi_sig;
				count_rise     <= count_rise+1;
		    elsif(cs_sig='0' and count_rise = 16) then
			   assert master_data_received(14 downto 0) = i_data_values(i_data_index)(14 downto 0)
               report "ERROR - incorrect value on master_data_received"
               severity error;
               count_rise <= 1;
               master_data_received   <= std_logic_vector(to_unsigned(16#00#,N));
               if(i_data_index < NO_VECTORS) then
                 i_data_index <= i_data_index+1;                 -- point to next vector
               else
                 i_data_index <= 1;                              -- point to first vector
               end if;
			else
				count_rise     <= 1;
			end if;
		end if;
	end if;
end process spi_master_monitor;

end rtl;
