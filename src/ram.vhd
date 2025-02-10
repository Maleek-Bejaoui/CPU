----------------------------------------------------------------------------------
-- Company: ENSEIRB MATMECA
-- Engineer: Léa KELEKE MALHERBE FAVIER
-- 
-- Create Date: 16.01.2025 10:26:21
-- Design Name: 
-- Module Name: RAM - Behavioral
-- Project Name: CPU
-- Target Devices: 
-- Tool Versions: 
-- Description: Ce fichier va servir a écrire la RAM de notre fichier donc toute les
--              adresses et valeurs associées. Donc 64 adresses codés sur 6 bits avec 
--              des adresses qui contiennent 16 bits.
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

entity RAM_SP_64_8 is
        GENERIC (
            NbBits  : INTEGER := 16;
            Nbadr   : INTEGER := 6);
        PORT (
            add         : IN STD_LOGIC_VECTOR ((Nbadr - 1) DOWNTO 0);
            data_in     : IN STD_LOGIC_VECTOR ((NbBits - 1) DOWNTO 0);
            r_w         : IN STD_LOGIC;
            enable      : IN STD_LOGIC;
            clk         : IN STD_LOGIC;
            ce          : IN STD_LOGIC;
            data_out    : OUT STD_LOGIC_VECTOR ((NbBits - 1) DOWNTO 0));
end RAM_SP_64_8;

architecture Behavioral of RAM_SP_64_8 is

TYPE ram_type IS ARRAY (0 TO 63) OF STD_LOGIC_VECTOR( (NbBits - 1) DOWNTO 0);
  SIGNAL memory : ram_type;

begin

  process (clk)
  begin
    if (clk'event and clk = '1') then
        if ce = '1' then
            if enable = '1' then 
                if r_w = '0' then -- mode de lecture
                    data_out <= memory(to_integer(unsigned(add)));
                else  -- mode ecriture
                    memory(to_integer(unsigned(add))) <= data_in;
                end if;
            end if;
        end if;
    end if;
  end process;

end Behavioral;
