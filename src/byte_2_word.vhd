----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/09/2021 06:37:26 PM
-- Design Name: 
-- Module Name: byte_2_word - Behavioral
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
USE IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

ENTITY byte_2_word IS
    PORT (
        rst : IN STD_LOGIC;
        clk : IN STD_LOGIC;
        ce : IN STD_LOGIC;
        byte_dv : IN STD_LOGIC;
        byte : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
        word_dv : OUT STD_LOGIC;
        word : OUT STD_LOGIC_VECTOR (15 DOWNTO 0));
END byte_2_word;

ARCHITECTURE Behavioral OF byte_2_word IS

    SIGNAL byte_reg, byte_reg2 : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL byte_dv_dly : STD_LOGIC;
    SIGNAL byte_count : unsigned(1 DOWNTO 0);

BEGIN
    PROCESS (rst, clk)
    BEGIN
        IF (rst = '1') THEN
            byte_reg <= (OTHERS => '0');
            byte_reg2 <= (OTHERS => '0');
        ELSIF (rising_edge(clk)) THEN
            IF (ce = '1') THEN
                IF (byte_dv = '1') THEN
                    byte_reg <= byte;
                    byte_reg2 <= byte_reg;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    PROCESS (rst, clk)
    BEGIN
        IF (rst = '1') THEN
            byte_dv_dly <= '0';
        ELSIF (rising_edge(clk)) THEN
            IF (ce = '1') THEN
                byte_dv_dly <= byte_dv;
            END IF;
        END IF;
    END PROCESS;

    PROCESS (rst, clk)
    BEGIN
        IF (rst = '1') THEN
            byte_count <= (OTHERS => '0');
        ELSIF (rising_edge(clk)) THEN
            IF (ce = '1') THEN
                IF (byte_dv = '1') THEN
                    byte_count <= byte_count + to_unsigned(1, 2);
                END IF;
            END IF;
        END IF;
    END PROCESS;

    word_dv <= '1' WHEN (byte_count(0) = '0' AND byte_dv_dly = '1') ELSE
        '0';
    word <= byte_reg & byte_reg2;
END Behavioral;