----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.01.2025 10:26:21
-- Design Name: 
-- Module Name: R1_register - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity R1_register is
    Port ( clk      : in STD_LOGIC;
           rst      : in STD_LOGIC;
           ce       : in STD_LOGIC;
           load_R1  : in STD_LOGIC;
           data_mem : in STD_LOGIC_VECTOR (15 downto 0);
           data_UAL : out STD_LOGIC_VECTOR (15 downto 0));
end R1_register;

architecture Behavioral of R1_register is

begin

    process(rst, clk)
        begin
        if(rst = '1') then
            data_UAL <= (others => '0');
        elsif(rising_edge(clk)) then
            if(ce = '1') then
                if (load_R1 = '1') then 
                    data_UAL <= data_mem;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
