----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/09/2021 06:57:40 PM
-- Design Name: 
-- Module Name: word_2_byte - Behavioral
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
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

ENTITY word_2_byte IS
    PORT (
        rst : IN STD_LOGIC;
        clk : IN STD_LOGIC;
        ce : IN STD_LOGIC;
        word_dv : IN STD_LOGIC;
        word : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
        byte_dv : OUT STD_LOGIC;
        byte : OUT STD_LOGIC_VECTOR (7 DOWNTO 0));
END word_2_byte;
ARCHITECTURE Behavioral OF word_2_byte IS

    SIGNAL word_dv_dly, word_dv_dly2 : STD_LOGIC;
    SIGNAL word_reg : STD_LOGIC_VECTOR(15 DOWNTO 0);

BEGIN

    PROCESS (rst, clk)
    BEGIN
        IF (rst = '1') THEN
            word_dv_dly <= '0';
            word_dv_dly2 <= '0';
            word_reg <= (OTHERS => '0');
        ELSIF (rising_edge(clk)) THEN
            word_dv_dly <= word_dv;
            word_dv_dly2 <= word_dv_dly;
            word_reg <= word;
        END IF;
    END PROCESS;

    PROCESS (word_dv_dly, word_dv_dly2, word_reg)
    BEGIN
        IF (word_dv_dly = '1') THEN
            byte <= word_reg(7 DOWNTO 0);
        ELSIF (word_dv_dly2 = '1') THEN
            byte <= word_reg(15 DOWNTO 8);
        ELSE
            byte <= (OTHERS => '0');
        END IF;
    END PROCESS;

    byte_dv <= word_dv_dly OR word_dv_dly2;

END Behavioral;