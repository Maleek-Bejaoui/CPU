----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.01.2025 10:26:21
-- Design Name: 
-- Module Name: Accu_register - Behavioral
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

entity Accu_register is
    Port (  clk         : in STD_LOGIC;
            ce          : in STD_LOGIC;
            rst         : in STD_LOGIC;
            load_ACCU   : in STD_LOGIC;
            DATA_IN     : in STD_LOGIC_VECTOR (15 downto 0);
            DATA_OUT    : out STD_LOGIC_VECTOR (15 downto 0));
end Accu_register;

architecture Behavioral of Accu_register is

begin

    process(rst, clk)
        begin
        if(rst = '1') then
            DATA_OUT <= (others => '0');
        elsif(rising_edge(clk)) then
            if(ce = '1') then
                if (load_ACCU = '1') then 
                    DATA_OUT <= DATA_IN;
                end if;
            end if;
        end if;
    end process;
    
end Behavioral;
