----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.01.2025 10:48:29
-- Design Name: 
-- Module Name: UC - Behavioral
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

ENTITY Control_Unit IS
    GENERIC (RAM_ADR_WIDTH : INTEGER := 6);
        PORT (
            clk         : IN STD_LOGIC;
            ce          : IN STD_LOGIC;
            rst         : IN STD_LOGIC;
            carry       : IN STD_LOGIC;
            boot        : IN STD_LOGIC;
            data_in     : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
            adr         : OUT STD_LOGIC_VECTOR (RAM_ADR_WIDTH - 1 DOWNTO 0);
            clear_carry : OUT STD_LOGIC;
            enable_mem  : OUT STD_LOGIC;
            load_R1     : OUT STD_LOGIC;
            load_accu   : OUT STD_LOGIC;
            load_carry  : OUT STD_LOGIC;
            sel_UAL     : OUT std_logic_vector(2 downto 0);
            w_mem       : OUT STD_LOGIC);
END Control_Unit;

architecture Behavioral of Control_Unit is


component FSM is
    Port ( clk          : in STD_LOGIC;
           ce           : in STD_LOGIC;
           rst          : in STD_LOGIC;
           code_op      : in STD_LOGIC_VECTOR (2 downto 0);
           carry        : in STD_LOGIC;
           boot         : in STD_LOGIC;
           clear_PC     : out STD_LOGIC;
           enable_PC    : out STD_LOGIC;
           load_PC      : out STD_LOGIC;
           load_RI      : out STD_LOGIC;
           sel_ADR      : out STD_LOGIC;
           load_R1      : out STD_LOGIC;
           load_ACCU    : out STD_LOGIC;
           sel_UAL      : OUT std_logic_vector(2 downto 0);
           clear_carry  : out STD_LOGIC;
           load_carry   : out STD_LOGIC;
           enable_mem   : out STD_LOGIC;
           W_mem        : out STD_LOGIC);
end component;

component Prog_counter is
    Port ( ADR_IN    : in STD_LOGIC_VECTOR (5 downto 0);
           ADR_OUT   : out STD_LOGIC_VECTOR (5 downto 0);
           clk       : in STD_LOGIC;
           ce, carry        : in STD_LOGIC;
           rst       : in STD_LOGIC;
           clear_PC  : in STD_LOGIC;
           load_PC   : in STD_LOGIC;
           enable_PC : in STD_LOGIC);
end component;

component Ins_register is
    Port ( clk      : in STD_LOGIC;
           rst      : in STD_LOGIC;
           ce       : in STD_LOGIC;
           data     : in STD_LOGIC_VECTOR (15 downto 0);
           load_RI  : in STD_LOGIC;
           code_op  : out STD_LOGIC_VECTOR (2 downto 0);
           ADR_RI : out STD_LOGIC_VECTOR (5 downto 0));
end component;


signal code_op      : STD_LOGIC_VECTOR (2 downto 0);
signal clear_PC     : STD_LOGIC;
signal enable_PC    : STD_LOGIC;
signal load_PC      : STD_LOGIC;
signal load_RI      : STD_LOGIC;
signal sel_ADR      : STD_LOGIC;
signal ADR_RI       : STD_LOGIC_VECTOR(5 downto 0);
signal ADR_OUT      : STD_LOGIC_VECTOR(5 downto 0);
signal sig_adr      : STD_LOGIC_VECTOR(5 downto 0);


begin

    RI : Ins_register
    Port map(   clk => clk,
                rst => rst,
                ce => ce,
                data => data_in,
                load_RI => load_RI,
                code_op => code_op,
                ADR_RI => ADR_RI);
    
    PC : Prog_counter
    Port map(   ADR_IN => ADR_RI,
                ADR_OUT => ADR_OUT,
                ce => ce,
                carry => carry,
                clk => clk,
                rst => rst,
                clear_PC => clear_PC,
                load_PC => load_PC,
                enable_PC => enable_PC );
    
    P_FSM :  FSM   
    Port map (  clk => clk,
                ce => ce,
                rst => rst,
                code_op => code_op,
                carry => carry,
                clear_PC => clear_PC,
                boot => boot,
                enable_PC => enable_PC,
                load_PC => load_PC,
                load_RI => load_RI,
                sel_ADR => sel_ADR,
                load_R1 => load_R1,
                load_ACCU => load_ACCU,
                sel_UAL => sel_UAL, 
                clear_carry => clear_carry,
                load_carry  => load_carry,
                enable_mem => enable_mem,
                W_mem => w_mem);   
       
sig_adr <= ADR_RI WHEN sel_adr = '1' ELSE
    ADR_OUT;
    
adr <= sig_adr; 
    

end Behavioral;
