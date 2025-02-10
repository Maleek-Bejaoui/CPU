----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.01.2025 10:26:21
-- Design Name: 
-- Module Name: Carry_register - Behavioral
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Carry_register is
    Port ( clk          : in STD_LOGIC;
           rst          : in STD_LOGIC;
           ce           : in STD_LOGIC;
           load_carry   : in STD_LOGIC;
           clear_carry  : in STD_LOGIC;
           carry_in     : in STD_LOGIC;
           carry_out    : out STD_LOGIC);
end Carry_register;

architecture Behavioral of Carry_register is

begin

    process(rst, clk)
        begin
        if(rst = '1') then
            carry_out <= '0';
        elsif(rising_edge(clk)) then
            if(ce = '1') then
                if (load_carry = '1') then 
                    carry_out <= carry_in;
                elsif(clear_carry = '1') then
                    carry_out <= '0';
                end if;
            end if;
        end if;
    end process;
    
end Behavioral;
