library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SPI_Control is
  port ( start : in std_logic;                              -- clock_divider
         reset : in std_logic;                              -- reset
         tx_end : in std_logic;                             -- o_tx_end
         o_data_parallel: in std_logic_vector(15 downto 0); -- o_data_parallel
         clk : out std_logic;                               -- i_clk
         rstb : out std_logic;                              -- i_rstb?
         tx_start : out std_logic;                          -- i_tx_start
         i_data_parallel : out std_logic_vector(15 downto 0); --i_data_parallel
         xaxis_data : out std_logic_vector(15 downto 0);    -- x data out
         yaxis_data : out std_logic_vector(15 downto 0);    -- y data out
         zaxis_data : out std_logic_vector(15 downto 0));   -- z data out
end SPI_Control;

architecture Behavioral of SPI_Control is

begin


end Behavioral;
