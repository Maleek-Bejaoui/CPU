----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.01.2025 10:26:21
-- Design Name: 
-- Module Name: Prog_counter - Behavioral
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


entity Prog_counter is
    Port ( ADR_IN    : in STD_LOGIC_VECTOR (5 downto 0);
           ADR_OUT   : out STD_LOGIC_VECTOR (5 downto 0);
           clk       : in STD_LOGIC;
           ce,carry        : in STD_LOGIC;
           rst       : in STD_LOGIC;
           clear_PC  : in STD_LOGIC;
           load_PC   : in STD_LOGIC;
           enable_PC : in STD_LOGIC);
end Prog_counter;

architecture Behavioral of Prog_counter is

signal s_adr_in : unsigned(5 downto 0) ;

begin

    process(clk, rst, enable_PC, load_PC)
        begin
            if (rst = '1') then 
                s_adr_in <= (others => '0');
            elsif rising_edge(clk) then
                if (ce = '1') then
                    if (enable_PC = '1') then
                        if clear_PC = '1' then
                            s_adr_in <= (others => '0');
                       
                        else 
                            s_adr_in <= s_adr_in + 1;
                        end if;
                    elsif(load_PC = '1') then
                            s_adr_in <= unsigned(ADR_IN);
                    end if;
                end if;
            end if;
        end process;

ADR_OUT <= STD_LOGIC_VECTOR(s_adr_in);
                         
end Behavioral;
