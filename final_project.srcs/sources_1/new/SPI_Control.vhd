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

TYPE state_type IS (READ_WRITE, IDLE, WAIT_STATE, RESET_STATE );
SIGNAL present_state, next_state : state_type;
signal count_reset : std_logic;
signal counter : integer range 1 to 9;
signal read_write_state : std_logic := '0';

begin

    clocked : PROCESS(i_clk,reset)
       BEGIN
         IF(reset='0') THEN 
           present_state <= IDLE;
        ELSIF(rising_edge(i_clk)) THEN
          present_state <= next_state;
        END IF;  
     END PROCESS clocked;
     
     count : process(i_clk, count_reset, present_state)
     begin
        if(count_reset = '1') then
            counter <= 1;
        elsif(rising_edge(i_clk)) then
            counter <= counter + 1;
            if(present_state = READ_WRITE) then
                send_data_index <= send_data_index + 1;					-- increment to next value
                if(send_data_index >= 8) then
                    send_data_index <= 8;
                end if;            
            elsif (present_state = WAIT_STATE or present_state = IDLE) then
                send_data_index <= 1;		    						-- rei_clk at the beginning
            end if;
        end if;
     end process count;
 
     nextstate : PROCESS(present_state, start, reset, tx_end)
        BEGIN
            CASE present_state is
                WHEN IDLE =>
                    read_write_state <= '0';
                    if (reset = '0') then
                        next_state <= RESET_STATE;
                        count_reset <= '1';
                    else
                        if (start = '1') then
                            
                            next_state <= READ_WRITE;
                            count_reset <= '1';
                        else 
                            next_state <= present_state;
                        end if;
                    end if;
       --for reading and writing data       
                WHEN READ_WRITE =>
                    if (reset = '0') then
                        next_state <= RESET_STATE;
                        count_reset <= '1';
                    else
                        count_reset <= '0';
                        if (counter >= 8) then
                            if(read_write_state = '0') then
                                next_state <= WAIT_STATE;
                            else
                                next_state <= IDLE;
                            end if;
                        else
                            next_state <= present_state;
                        end if;
                     end if;
       --waiting            
                WHEN WAIT_STATE =>
                    if (reset = '0') then
                        next_state <= RESET_STATE;
                        count_reset <= '1';
                    else
                        if (start = '1') then
                            next_state <= READ_WRITE;
                            count_reset <= '1';
                            read_write_state <= '1';
                        else
                            next_state <= present_state;
                        end if;
                     end if;
         --RESET           
                WHEN RESET_STATE =>
                    if (reset = '0') then
                        next_state <= RESET_STATE;
                        count_reset <= '0'; 
                        read_write_state <= '0';                                                                     
                    else
                        next_state <= IDLE;
                    end if;
                WHEN OTHERS =>
        END CASE;
      END PROCESS nextstate;
                 
    output : process(present_state, i_clk, send_data_index)
    begin
        -- write_1, write_2, read_X1, read_X2, read_Y1, read_Y2, read_Z1, read_Z2, IDLE, WAIT_STATE, RESET_STATE 
        case(present_state) is
            when IDLE =>
                 i_data_parallel <= i_data_values(send_data_index);
                 tx_start <= '0';
                 
            when READ_WRITE => 
                tx_start <= '0';
                
                if(read_write_state = '1') then
                    if(counter = 3) then
                        xaxis_data <= std_logic_vector(resize(unsigned(o_data_parallel(7 downto 0)), 16));
                    elsif(counter = 4) then
                        xaxis_data <= std_logic_vector(resize(unsigned(o_data_parallel(15 downto 8)), 16));
                    elsif(counter = 5) then
                        yaxis_data <= std_logic_vector(resize(unsigned(o_data_parallel(7 downto 0)), 16));
                    elsif(counter = 6) then
                        yaxis_data <= std_logic_vector(resize(unsigned(o_data_parallel(15 downto 8)), 16));
                    elsif(counter = 7) then
                        zaxis_data <= std_logic_vector(resize(unsigned(o_data_parallel(7 downto 0)), 16));
                    elsif(counter = 8) then
                        zaxis_data <= std_logic_vector(resize(unsigned(o_data_parallel(15 downto 8)), 16));
                    end if;
                end if;
            
                i_data_parallel <= i_data_values(send_data_index);      -- set next data on i_data_parallel

                tx_start <= '1';										-- i_clk transaction
                
            when WAIT_STATE =>
                tx_start <= '0';
                i_data_parallel <= i_data_values(send_data_index);
                
            when others =>
                 tx_start <= '0';
                 i_data_parallel <= (others => '0');
                 xaxis_data <= (others => '0');
                 yaxis_data <= (others => '0');
                 zaxis_data <= (others => '0');
        end case;        
    end process output;


end Behavioral;