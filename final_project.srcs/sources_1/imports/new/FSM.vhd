library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FSM is
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
end FSM;

architecture Behavioral of FSM is

-- Constants
constant N          : integer := 16;   -- number of bits send per SPI transaction
constant NO_VECTORS : integer := 8;    -- number of SPI transactions to simulate
constant zero       : std_logic_vector(15 downto 0) := (others => '0');

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

TYPE state_type IS (reset_state, waitend, ready, 
                    write_1, write_1_start, write_1_wait, write_1_out,
                    write_2, write_2_start, write_2_wait, write_2_out,
                    read_1, read_1_start, read_1_wait, read_1_out,
                    read_2, read_2_start, read_2_wait, read_2_out,
                    read_3, read_3_start, read_3_wait, read_3_out,
                    read_4, read_4_start, read_4_wait, read_4_out,
                    read_5, read_5_start, read_5_wait, read_5_out,
                    read_6, read_6_start, read_6_wait, read_6_out);
SIGNAL present_state, next_state : state_type;
signal count_reset : std_logic;
signal counter : integer;

begin

    clocked : PROCESS(i_clk,reset)
       BEGIN
         IF(reset='0') THEN 
           present_state <= reset_state;
        ELSIF(rising_edge(i_clk)) THEN
          present_state <= next_state;
        END IF;  
     END PROCESS clocked;
     
     count : process(tx_end, count_reset, i_clk)
     begin
        if(count_reset = '1') then
            counter <= 1;
        elsif(rising_edge(i_clk)) then
            if(tx_end = '1') then
                counter <= counter + 1;
            end if;
        end if;
     end process count;
     
     send_index : process(i_clk, count_reset, present_state)
     begin
        if(count_reset = '1') then
            send_data_index <= 1;
        elsif(rising_edge(i_clk)) then
            case (present_state) is
                when waitend | ready | write_1 => 
                    send_data_index <= 1;
                when write_2 =>
                    send_data_index <= 2;
                when read_1 =>
                    send_data_index <= 3;
                when read_2 =>
                    send_data_index <= 4;
                when read_3 =>
                    send_data_index <= 5;
                when read_4 =>
                    send_data_index <= 6;
                when read_5 =>
                    send_data_index <= 7;
                when read_6 =>
                    send_data_index <= 8;
                when others =>
                    send_data_index <= send_data_index;
            end case;
        end if;
     end process send_index;
 
     nextstate : PROCESS(present_state, start, reset, tx_end)
        BEGIN
            if (reset = '0') then
                next_state <= RESET_STATE;
                count_reset <= '1';
            else
                case (present_state) is
                    when waitend =>
                        if(start = '0') then
                            next_state <= ready;
                        else
                            next_state <= present_state;
                        end if;
                    when ready => 
                        if(start = '1') then
                            next_state <= write_1;
                        else
                            next_state <= present_state;
                        end if;
                    when write_1 => 
                        next_state <= write_1_start;
                    when write_1_start => 
                        if(tx_end = '0') then
                            next_state <= write_1_wait;
                        else
                            next_state <= present_state;
                        end if;
                    when write_1_wait =>
                        if(tx_end = '1') then
                            next_state <= write_1_out;
                        else
                            next_state <= present_state;
                        end if;
                    when write_1_out =>
                        next_state <= write_2;
                    when write_2 =>
                        next_state <= write_2_start;
                    when write_2_start =>
                        if(tx_end = '0') then
                            next_state <= write_2_wait;
                        else
                            next_state <= present_state;
                        end if;
                    when write_2_wait =>
                        if(tx_end = '1') then
                            next_state <= write_2_out;
                        else
                            next_state <= present_state;
                        end if;
                    when write_2_out =>
                        next_state <= read_1;
                    when read_1 =>
                        next_state <= read_1_start;
                    when read_1_start =>
                        if(tx_end = '0') then
                            next_state <= read_1_wait;
                        else
                            next_state <= present_state;
                        end if;
                    when read_1_wait =>
                        if(tx_end = '1') then
                            next_state <= read_1_out;
                        else
                            next_state <= present_state;
                        end if;
                    when read_1_out =>
                        next_state <= read_2;
                    when read_2 =>
                        next_state <= read_2_start;
                    when read_2_start =>
                        if(tx_end = '0') then
                            next_state <= read_2_wait;
                        else
                            next_state <= present_state;
                        end if;
                    when read_2_wait =>
                        if(tx_end = '1') then
                            next_state <= read_2_out;
                        else
                            next_state <= present_state;
                        end if;
                    when read_2_out =>
                        next_state <= read_3;
                    when read_3 =>
                        next_state <= read_3_start;
                    when read_3_start =>
                        if(tx_end = '0') then
                            next_state <= read_3_wait;
                        else
                            next_state <= present_state;
                        end if;
                    when read_3_wait =>
                        if(tx_end = '1') then
                            next_state <= read_3_out;
                        else
                            next_state <= present_state;
                        end if;
                    when read_3_out =>
                        next_state <= read_4;
                    when read_4 =>
                        next_state <= read_4_start;
                    when read_4_start =>
                        if(tx_end = '0') then
                            next_state <= read_4_wait;
                        else
                            next_state <= present_state;
                        end if;
                    when read_4_wait =>
                        if(tx_end = '1') then
                            next_state <= read_4_out;
                        else
                            next_state <= present_state;
                        end if;
                    when read_4_out =>
                        next_state <= read_5;
                    when read_5 =>
                        next_state <= read_5_start;
                    when read_5_start =>
                        if(tx_end = '0') then
                            next_state <= read_5_wait;
                        else
                            next_state <= present_state;
                        end if;
                    when read_5_wait =>
                        if(tx_end = '1') then
                            next_state <= read_5_out;
                        else
                            next_state <= present_state;
                        end if;
                    when read_5_out =>
                        next_state <= read_6;
                    when read_6 =>
                        next_state <= read_6_start;
                    when read_6_start =>
                        if(tx_end = '0') then
                            next_state <= read_6_wait;
                        else
                            next_state <= present_state;
                        end if;
                    when read_6_wait =>
                        if(tx_end = '1') then
                            next_state <= read_6_out;
                        else
                            next_state <= present_state;
                        end if;
                    when read_6_out =>
                        next_state <= waitend;
                    when reset_state =>
                        if(reset = '1') then
                            count_reset <= '0';
                            next_state <= waitend;
                        else
                            next_state <= present_state;
                        end if;
                    when others =>
                        
                end case;
            end if;
      END PROCESS nextstate;
      
      --change state outputs
      output : process(present_state, i_clk, send_data_index)
      begin
        case (present_state) is
            when waitend | ready | reset_state =>
                i_data_parallel <= (others => 'X');
                tx_start <= '0';
            when write_1 => 
                i_data_parallel <= i_data_values(send_data_index);
                tx_start <= '0';
            when write_1_start => 
                tx_start <= '1';
            when write_1_wait =>
                tx_start <= '0';
            when write_2 =>
                i_data_parallel <= i_data_values(send_data_index);
                tx_start <= '0';
            when write_2_start =>
                tx_start <= '1';
            when write_2_wait =>
                tx_start <= '0';
            when read_1 =>
                i_data_parallel <= i_data_values(send_data_index);
                tx_start <= '0';
            when read_1_start =>
                tx_start <= '1';
            when read_1_wait =>
                tx_start <= '0';
            when read_2 =>
                i_data_parallel <= i_data_values(send_data_index);
                tx_start <= '0';
            when read_2_start =>
                tx_start <= '1';
            when read_2_wait =>
                tx_start <= '0';
            when read_3 =>
                i_data_parallel <= i_data_values(send_data_index);
                tx_start <= '0';
            when read_3_start =>
                tx_start <= '1';
            when read_3_wait =>
                tx_start <= '0';
            when read_4 =>
                i_data_parallel <= i_data_values(send_data_index);
                tx_start <= '0';
            when read_4_start =>
                tx_start <= '1';
            when read_4_wait =>
                tx_start <= '0';
            when read_5 =>
                i_data_parallel <= i_data_values(send_data_index);
                tx_start <= '0';
            when read_5_start =>
                tx_start <= '1';
            when read_5_wait =>
                tx_start <= '0';
            when read_6 =>
                i_data_parallel <= i_data_values(send_data_index);
                tx_start <= '0';
            when read_6_start =>
                tx_start <= '1';
            when read_6_wait =>
                tx_start <= '0';
            when others =>
                i_data_parallel <= (others => 'X');
                tx_start <= '0';
        end case;
      
    end process output;
    
    --change state outputs
    outData : process(present_state, i_clk)
    begin
        if (rising_edge(i_clk)) then
            case (present_state) is
                    when read_1_out =>
                        xaxis_data(7 downto 0) <= o_data_parallel(7 downto 0);
                        yaxis_data <= (others => '0');
                        zaxis_data <= (others => '0');
                    when read_2_out =>
                        xaxis_data(15 downto 8) <= o_data_parallel(7 downto 0);
                        yaxis_data <= (others => '0');
                        zaxis_data <= (others => '0');
                    when read_3_out =>
                        yaxis_data(7 downto 0) <= o_data_parallel(7 downto 0);
                        xaxis_data <= (others => '0');
                        zaxis_data <= (others => '0');
                    when read_4_out =>
                        yaxis_data(15 downto 8) <= o_data_parallel(7 downto 0);
                        xaxis_data <= (others => '0');
                        zaxis_data <= (others => '0');
                    when read_5_out =>
                        zaxis_data(7 downto 0) <= o_data_parallel(7 downto 0);
                        xaxis_data <= (others => '0');
                        yaxis_data <= (others => '0');
                    when read_6_out =>
                        zaxis_data(15 downto 8) <= o_data_parallel(7 downto 0);
                        xaxis_data <= (others => '0');
                        yaxis_data <= (others => '0');
                    when reset_state =>
                        xaxis_data <= (others => '0');
                        yaxis_data <= (others => '0');
                        zaxis_data <= (others => '0');
                    when others =>
                        
                end case;
        end if;
    end process outData;

end Behavioral;
