----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.01.2025 10:26:21
-- Design Name: 
-- Module Name: Ins_register - Behavioral
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

entity Ins_register is
    Port ( clk      : in STD_LOGIC;
           rst      : in STD_LOGIC;
           ce       : in STD_LOGIC;
           data     : in STD_LOGIC_VECTOR (15 downto 0);
           load_RI  : in STD_LOGIC;
           code_op  : out STD_LOGIC_VECTOR (2 downto 0);
           ADR_RI : out STD_LOGIC_VECTOR (5 downto 0));
end Ins_register;

architecture Behavioral of Ins_register is

-- Dans le cas ou ca ne marche pas dans l'autre cas 
--signal s_code_op : STD_LOGIC_VECTOR (1 downto 0);
signal s_data_out : STD_LOGIC_VECTOR (15 downto 0) ;

begin

    process(rst, clk)
        begin
        if(rst = '1') then
            --code_op <= (others => '0');
            s_data_out <= (others => '0');
            
        elsif(rising_edge(clk)) then
            if (ce = '1') then
                if(load_RI = '1') then
                    --code_op <= data(15 downto 14);
                    --ADR_RI <= data(5 downto 0);
                    s_data_out <= data;
                end if;
            end if;
        end if;
    end process;
code_op <= s_data_out(15 downto 13);
ADR_RI <= s_data_out(5 downto 0);

end Behavioral;
