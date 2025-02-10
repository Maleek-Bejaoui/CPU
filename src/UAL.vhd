----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.01.2025 10:26:21
-- Design Name: 
-- Module Name: UAL - Behavioral
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

entity UAL is
    Port (  CE  : in STD_LOGIC;
           sel_UAL: in std_logic_vector(2 downto 0);
           DATA_R1      : in STD_LOGIC_VECTOR (15 downto 0);
           DATA_ACCU    : in STD_LOGIC_VECTOR (15 downto 0);
           DATA_OUT     : out STD_LOGIC_VECTOR (15 downto 0);
           carry        : out STD_LOGIC);
end UAL;

architecture Behavioral of UAL is
    signal R1,ACCU : signed(16 downto 0);
    signal s_out: signed(16 downto 0);
begin
    
        R1(15 downto 0) <= signed(DATA_R1);
        R1(16) <= '0';
        ACCU(15 downto 0)<= signed(DATA_ACCU);
        ACCU(16) <= '0';


    process(DATA_R1, DATA_ACCU, sel_UAL, s_out)
    begin
        if (sel_UAL="000") then
            DATA_OUT <= DATA_R1 NOR DATA_ACCU;
        else
            DATA_OUT <= std_logic_vector(s_out(15 downto 0));
        end if;                
    end process;                

    process(sel_UAL, s_out)
    begin
        if (sel_UAL = "000") then
            carry <= '0';
        elsif (sel_UAL ="010") then
            carry <= s_out(16);
        elsif (sel_UAL="011") then
            if ACCU < R1 then carry <= '1';
            else carry<='0';
            end if;
        end if;                
    end process;                

    process(sel_UAL, R1, ACCU)
    begin
        if (sel_UAL="000") then
            s_out <= (others =>'0');
        elsif (sel_UAL="010") then
            s_out <= R1 + ACCU;
        elsif (sel_UAL="011") then
            s_out <= ACCU - R1; 
                       
        end if;                
    end process;                


end Behavioral;
