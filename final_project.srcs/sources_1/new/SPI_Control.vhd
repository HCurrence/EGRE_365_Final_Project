library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SPI_Control is
  port ( start : in std_logic;                              -- clock_divider
         reset : in std_logic;                              -- reset
         tx_end : in std_logic;                             -- o_tx_end
         o_data_parallel: in std_logic_vector(7 downto 0); -- o_data_parallel
         i_clk : in std_logic;  -- temp: input clock
         clk : out std_logic;                               -- i_clk
         rstb : out std_logic;                              -- i_rstb?
         tx_start : out std_logic;                          -- i_tx_start
         i_data_parallel : out std_logic_vector(7 downto 0); --i_data_parallel
         xaxis_data : out std_logic_vector(15 downto 0);    -- x data out
         yaxis_data : out std_logic_vector(15 downto 0);    -- y data out
         zaxis_data : out std_logic_vector(15 downto 0));   -- z data out
end SPI_Control;

architecture Behavioral of SPI_Control is

--procedures
procedure waitclocks(signal clock : std_logic;
                       N : INTEGER) is
	begin
		for i in 1 to N loop
			wait until clock'event and clock='0';	-- wait on falling edge
		end loop;
end waitclocks;

-- Constants
constant N          : integer := 16;   -- number of bits send per SPI transaction
constant NO_VECTORS : integer := 8;    -- number of SPI transactions to simulate

type output_value_array is array (1 to NO_VECTORS) of std_logic_vector(N-1 downto 0);
constant i_data_values : output_value_array := (std_logic_vector(to_unsigned(16#2C08#,N)),
                                                std_logic_vector(to_unsigned(16#2D08#,N)),
                                                std_logic_vector(to_unsigned(16#B201#,N)),
                                                std_logic_vector(to_unsigned(16#B302#,N)),
                                                std_logic_vector(to_unsigned(16#B403#,N)),
                                                std_logic_vector(to_unsigned(16#B504#,N)),
                                                std_logic_vector(to_unsigned(16#B605#,N)),
                                                std_logic_vector(to_unsigned(16#B706#,N)));

--Signals
signal send_data_index : integer := 1;

begin

    reset_process : process
    begin
        rstb <= '1';
        waitclocks(i_clk, 200000);							-- activate rstb - see point (2) on slides
        rstb  <= '0';
        waitclocks(i_clk, 200000);
        rstb  <= '1';
    end process reset_process;

    master_stimulus : process
    begin

        i_data_parallel <= i_data_values(send_data_index);    -- set 1st data on i_data_parallel - see point (1) on slides
        
        wait until start'event and start='1';
        
        for i in 0 to 7 loop
            tx_start <= '1';										-- i_clk transaction
            waitclocks(i_clk, 2);
            tx_start <= '0';	            
        
            wait until tx_end'event and tx_end='1';				    -- wait until SPI controller signals done with transaction
            send_data_index <= send_data_index + 1;					-- increment to next value
            waitclocks(i_clk, 1);
            i_data_parallel <= i_data_values(send_data_index);      -- set next data on i_data_parallel
            waitclocks(i_clk, 4);
        end loop;
    
        tx_start <= '1';										-- i_clk 8th transaction
        waitclocks(i_clk, 2);
        tx_start <= '0';										-- 8th transaction i_clked
    
        wait until tx_end'event and tx_end='1';				-- wait until SPI controller signals done with 8th transaction
        
                                                                ------------------------------------------------------------------
    
        waitclocks(i_clk, 20000);							-- wait a "long time" to i_clk a 2nd set of transactions - see point (21) on slides
        send_data_index <= 1;		    						-- rei_clk at the beginning
        waitclocks(i_clk, 1);
        i_data_parallel <= i_data_values(send_data_index);
        waitclocks(i_clk, 4);
        
        
        for i in 0 to 6 loop
            tx_start <= '1';										-- i_clk transaction
            waitclocks(i_clk, 2);
            tx_start <= '0';										-- transaction i_clked
        
        
            wait until tx_end'event and tx_end='1';				-- wait until SPI controller signals done with transaction
            send_data_index <= send_data_index + 1;					-- increment to next value
            waitclocks(i_clk, 1);
            i_data_parallel <= i_data_values(send_data_index);
            waitclocks(i_clk, 4);
        end loop;
    
        tx_start <= '1';										-- i_clk 8th transaction
        waitclocks(i_clk, 2);
        tx_start <= '0';										-- 8th transaction i_clked
    
        wait until tx_end'event and tx_end='1';				-- wait until SPI controller signals done with 8th transaction
    
        wait until start'event and start='1';
    
        wait; 													-- stop the process to avoid an infinite loop
    
    end process master_stimulus;


end Behavioral;
