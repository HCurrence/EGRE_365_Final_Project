library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SPI_Control is
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
signal lock : std_logic;

TYPE state_type IS (write_1, write_2, read_X1, read_X2, read_Y1, read_Y2, read_Z1, read_Z2, IDLE, WAIT_STATE, RESET_STATE );
SIGNAL present_state, next_state : state_type;

begin

    clocked : PROCESS(i_clk,reset)
       BEGIN
         IF(reset='0') THEN 
           present_state <= IDLE;
        ELSIF(rising_edge(i_clk)) THEN
          present_state <= next_state;
        END IF;  
     END PROCESS clocked;
 
     nextstate : PROCESS(present_state, start, reset, tx_end)
     
        BEGIN
            CASE present_state is
                WHEN IDLE =>
                    if (reset = '1') then
                        next_state <= RESET_STATE;
                    else
                        if (start = '1') then
                            next_state <= write_1;
                        else 
                            next_state <= present_state;
                        end if;
                    end if;
       --write 1       
                WHEN write_1 =>
                    if (reset = '1') then
                        next_state <= RESET_STATE;
                    else
                        if (tx_end = '1') then
                            next_state <= write_2;
                        else
                            next_state <= present_state;
                        end if;
                     end if;
       --write 2             
                WHEN write_2 =>
                    if (reset = '1') then
                        next_state <= RESET_STATE;
                    else
                        if (tx_end = '1') then
                            next_state <= wait_state;
                        else
                            next_state <= present_state;
                        end if;
                     end if;
                        
                    
      --Wait statement   
      
                  WHEN wait_state =>
                    if (reset = '1') then
                        next_state <= RESET_STATE;
                    else
                        if (start = '1') then
                            next_state <= read_X1;
                        else
                            next_state <= present_state;
                        end if;
                     end if;            
    -- wait until NET_DATA_VALID = '1';             
       
         --read_X0         
                WHEN read_X1 =>
                    if (reset = '1') then
                        next_state <= RESET_STATE;
                    else
                        if (tx_end = '1') then
                            next_state <= read_X2;
                        else
                            next_state <= present_state;
                        end if;
                     end if;   
         --read_X1           
                WHEN read_X2 =>
                    if (reset = '1') then
                        next_state <= RESET_STATE;
                    else
                        if (tx_end = '1') then
                            next_state <= read_Y1;
                        else
                            next_state <= present_state;
                        end if;
                     end if;  
         --read_Y0         
                WHEN read_Y1 =>
                    if (reset = '1') then
                        next_state <= RESET_STATE;
                    else
                        if (tx_end = '1') then
                            next_state <= read_Y2;
                        else
                            next_state <= present_state;
                        end if;
                     end if;  
    
         --read_Y1          
                WHEN read_Y2 =>
                    if (reset = '1') then
                        next_state <= RESET_STATE;
                    else
                        if (tx_end = '1') then
                            next_state <= read_Z1;
                        else
                            next_state <= present_state;
                        end if;
                     end if;      
          --read_Z0         
                WHEN read_Z1 =>
                    if (reset = '1') then
                        next_state <= RESET_STATE;
                    else
                        if (tx_end = '1') then
                            next_state <= read_Z2;
                        else
                            next_state <= present_state;
                        end if;
                     end if;  
         --read_Z1           
                WHEN read_Z2 =>
                    if (reset = '1') then
                        next_state <= RESET_STATE;
                    else
                        if (tx_end = '1') then
                            next_state <= IDLE;
                        else
                            next_state <= present_state;
                        end if;
                     end if;           
     
         --RESET           
                WHEN RESET_STATE =>
                    if (reset = '0') then
                        --next_state <= present_state;
                        next_state<= IDLE;                                                                      
                    else
                        next_state <= present_state;
                    end if;
                WHEN OTHERS =>
        END CASE;
      END PROCESS nextstate;
                 
    output : process(present_state)
    begin
        case(present_state) is
            when others =>
            
        end case;        
    end process output;

    master_stimulus : process
    begin

        if (reset = '0') then
             tx_start <= '0';
             i_data_parallel <= (others => '0');
             xaxis_data <= (others => '0');
             yaxis_data <= (others => '0');
             zaxis_data <= (others => '0');
        else 
            i_data_parallel <= i_data_values(send_data_index);    -- set 1st data on i_data_parallel - see point (1) on slides
            
            wait until start'event and start='1';
            
            for i in 0 to 6 loop
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
       end if;
    end process master_stimulus;


end Behavioral;