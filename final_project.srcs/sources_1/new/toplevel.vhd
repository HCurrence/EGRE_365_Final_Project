
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity spi_fsm_toplevel is
    Port (
		  CPU_RESETN    : in  STD_LOGIC;  -- Nexys 4 DDR active low reset
		  SYS_CLK       : in  STD_LOGIC;  -- Nexys 4 DDR 100 MHZ clk
		  LED           : out STD_LOGIC_VECTOR(15 downto 0)); -- Nexys 4 DDR LEDs                                    
		  SW            : in  STD_LOGIC_VECTOR(15 downto 0)); -- Nexys 4 DDR Swtiches
		  SCK           : out STD_LOGIC;
		  CS            : in  STD_LOGIC;
        MOSI          : out STD_LOGIC;  --clip select
        MISO          : in STD_LOGIC;
end spi_fsm_toplevel;

architecture structural of spi_fsm_toplevel is

--internal signals 
signal SCK_SIG          :  std_logic;
signal CS_SIG           :  std_logic;
signal MOSI_SIG         :  std_logic;
signal MISO_SIG         :  std_logic;


begin
    
SCK_SIG <= CPU_RESETN;



CLK_DIV : ENTITY work.clock_divider(behavior)
                       PORT MAP(mclk => SYS_CLK);
                                        



                                                    
                       

  
end structural;