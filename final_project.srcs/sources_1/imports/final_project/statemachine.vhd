
library IEEE;
use IEEE.std_logic_1164.all;
ENTITY state_machine is
  PORT(clk              : IN  std_logic;
       rst              : IN  std_logic;
       start            : IN  std_logic;
       counter          : IN  integer;
       lock_ctrl        : OUT  std_logic);
END state_machine;
ARCHITECTURE behavior OF state_machine IS
  TYPE state_type IS (write_1,write_2, read_X1, read_X2, read_Y1, read_Y2, read_Z1, read_Z2, IDLE, RESET,WAIT_STATE );
  SIGNAL present_state, next_state : state_type;
  
BEGIN
 clocked : PROCESS(clk,rst)
   BEGIN
     IF(rst='0') THEN 
       present_state <= IDLE;
    ELSIF(rising_edge(clk)) THEN
      present_state <= next_state;
    END IF;  
 END PROCESS clocked;
 
 nextstate : PROCESS(present_state,start,counter)
 
    BEGIN
        CASE present_state is
            WHEN IDLE =>
                --lock_ctrl <= '0';
                if (start = '1') then
                    next_state <= write_1;
                else 
                    next_state <= present_state;
                end if;
   --write 1            
            WHEN write_1 =>
                if (rst = '1') then
                    next_state <= RESET;
                else
                    if (counter = 1) then
                        next_state <= write_2;
                    else
                        next_state <= present_state;
                    end if;
                 end if;
   --write 2             
            WHEN write_2 =>
                if (rst = '1') then
                    next_state <= RESET;
                else
                    if (counter = 2) then
                        next_state <= wait_state;
                    else
                        next_state <= present_state;
                    end if;
                 end if;
                    
                
  --Wait statement   
  
              WHEN wait_state =>
                if (rst = '1') then
                    next_state <= RESET;
                else
                    if (start = '1') then
                        next_state <= read_X1;
                    else
                        next_state <= present_state;
                    end if;
                 end if;            
-- wait until NET_DATA_VALID = '1';             
   
     --read_X1         
            WHEN read_X1 =>
                if (rst = '1') then
                    next_state <= RESET;
                else
                    if (counter = 3) then
                        next_state <= read_X2;
                    else
                        next_state <= present_state;
                    end if;
                 end if;   
     --read_X2           
            WHEN read_X2 =>
                if (rst = '1') then
                    next_state <= RESET;
                else
                    if (counter = 4) then
                        next_state <= read_Y1;
                    else
                        next_state <= present_state;
                    end if;
                 end if;  
     --read_Y1         
            WHEN read_Y1 =>
                if (rst = '1') then
                    next_state <= RESET;
                else
                    if (counter = 5) then
                        next_state <= read_Y2;
                    else
                        next_state <= present_state;
                    end if;
                 end if;  

     --read_Y2           
            WHEN read_Y2 =>
                if (rst = '1') then
                    next_state <= RESET;
                else
                    if (counter = 6) then
                        next_state <= read_Z1;
                    else
                        next_state <= present_state;
                    end if;
                 end if;      
      --read_Z1         
            WHEN read_Z1 =>
                if (rst = '1') then
                    next_state <= RESET;
                else
                    if (counter = 7) then
                        next_state <= read_Z2;
                    else
                        next_state <= present_state;
                    end if;
                 end if;  
     --read_Z2           
            WHEN read_Z2 =>
                if (rst = '1') then
                    next_state <= RESET;
                else
                    if (counter = 8) then
                        next_state <= IDLE;
                    else
                        next_state <= present_state;
                    end if;
                 end if;           
 
     --RESET           
            WHEN RESET =>
                if (rst = '0') then
                    --next_state <= present_state;
                    next_state<= IDLE;                                                                      
                else
                    next_state <= present_state;
                end if;
            WHEN OTHERS =>
    END CASE;
  END PROCESS nextstate;
  
END ARCHITECTURE behavior;