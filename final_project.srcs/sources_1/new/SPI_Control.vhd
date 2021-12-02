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

TYPE state_type IS (READ_WRITE, IDLE, WAIT_STATE, RESET_STATE );
SIGNAL present_state, next_state : state_type;
signal count_reset : std_logic;
signal counter : integer;
signal read_write_state : std_logic := '0';

begin

    clocked : PROCESS(i_clk,reset)
       BEGIN
         IF(reset='0') THEN 
           present_state <= RESET_STATE;
        ELSIF(rising_edge(i_clk)) THEN
          present_state <= next_state;
        END IF;  
     END PROCESS clocked;
     
     count : process(tx_end, count_reset, i_clk)
     variable zero : std_logic_vector(15 downto 0) := (others => '0');
     begin
        if(count_reset = '1') then
            counter <= 1;
        elsif(rising_edge(i_clk)) then
            if(tx_end = '1') then
                counter <= counter + 1;
            end if;
        end if;
     end process count;
     
     send_index : process(i_clk, tx_end, count_reset, present_state)
     variable zero : std_logic_vector(15 downto 0) := (others => '0');
     begin
        if(count_reset = '1') then
            send_data_index <= 1;
        elsif(rising_edge(i_clk)) then
            if(present_state = READ_WRITE and tx_end = '1') then
                send_data_index <= send_data_index + 1;					-- increment to next value
                if(send_data_index >= 8) then
                    send_data_index <= 8;
                end if;  
            elsif (present_state = WAIT_STATE or present_state = IDLE) then
                send_data_index <= 1;		    						-- rei_clk at the beginning
            end if;
        end if;
     end process send_index;
 
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
                        if (counter >= 9) then
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
                   next_state <= IDLE;
        END CASE;
      END PROCESS nextstate;
                 
    output : process(present_state, i_clk, send_data_index)
    begin
        case(present_state) is
            when IDLE =>
                i_data_parallel <= i_data_values(send_data_index);
                tx_start <= '0';
                 
            when READ_WRITE => 
                tx_start <= '0';
            
                i_data_parallel <= i_data_values(send_data_index);      -- set next data on i_data_parallel

                tx_start <= '1';										-- i_clk transaction
                
            when WAIT_STATE =>
                tx_start <= '0';
                i_data_parallel <= i_data_values(send_data_index);
                
            when others =>
                 tx_start <= 'X';
                 i_data_parallel <= (others => 'X');

        end case;        
    end process output;

    outData : process(present_state, i_clk)
    begin
        if (rising_edge(i_clk)) then
            case(present_state) is
                when IDLE =>
                     xaxis_data <= (others => 'X');
                     yaxis_data <= (others => 'X');
                     zaxis_data <= (others => 'X');
                     
                when READ_WRITE => 
                    if(read_write_state = '1') then
                        if(counter = 1 or counter = 2) then
                            xaxis_data <= (others => '0');
                            yaxis_data <= (others => '0');
                            zaxis_data <= (others => '0');
                        elsif(counter = 3) then
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
                
                when WAIT_STATE =>
                    xaxis_data <= (others => 'X');
                    yaxis_data <= (others => 'X');
                    zaxis_data <= (others => 'X');
                    
                when others =>
                    xaxis_data <= (others => 'Z');
                    yaxis_data <= (others => 'Z');
                    zaxis_data <= (others => 'Z');
            end case;
        end if;
    end process outData;

end Behavioral;