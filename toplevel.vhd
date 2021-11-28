
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity spi_fsm_toplevel is
    Port (
        CLK100MHZ     : in  STD_LOGIC;
		  CPU_RESETN    : in  STD_LOGIC;
		  SYS_CLK       : in  STD_LOGIC;
		  LED           : out STD_LOGIC_VECTOR(15 downto 0));                                       
		  SW            : in  STD_LOGIC_VECTOR(15 downto 0));
		  SCK           : out STD_LOGIC;
		  CS            : in  STD_LOGIC;
        MOSI          : out STD_LOGIC;
        MISO          : in STD_LOGIC;
end spi_fsm_toplevel;

architecture structural of spi_fsm_toplevel is

--internal signals 
signal reset_sig :  std_logic;
signal clk :        std_logic;
signal in1 :        std_logic;
signal in2 :        std_logic;
signal in3 :        std_logic;
signal in4 :        std_logic;
signal activate :   std_logic;

begin
    
reset_sig <= not(CPU_RESETN);


CPU_RESETN : ENTITY 

CLK_DIV : ENTITY work.clock_divider(behavior)
                       PORT MAP(mclk => CLK100MHZ, sclk => clk);
                                        

UP_DEB : ENTITY work.SwitchDebouncer(behavioral)
                       PORT MAP(clk => CLK100MHZ, reset => reset_sig, 
                                switchIn => BTNU, switchOut => in1);

                                                    
                       

  
end structural;