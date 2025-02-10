library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

entity UT is
    Port(clk , rst,  ce : in STD_LOGIC;
    sel_UAL : in std_logic_vector(2 downto 0);
    carry: out std_logic;
    data_in: in std_logic_vector(15 downto 0);
    data_out: out std_logic_vector(15 downto 0);
    load_R1,load_ACCU,load_carry, init_carry: in std_logic
    );
end entity UT;


architecture Behavioral of UT is


component R1_register is
    Port ( clk      : in STD_LOGIC;
           rst      : in STD_LOGIC;
           ce       : in STD_LOGIC;
           load_R1  : in STD_LOGIC;
           data_mem : in STD_LOGIC_VECTOR (15 downto 0);
           data_UAL : out STD_LOGIC_VECTOR (15 downto 0));
end component R1_register;


component UAL is
    Port ( ce   : in STD_LOGIC;
           sel_UAL : in std_logic_vector(2 downto 0);
           DATA_R1      : in STD_LOGIC_VECTOR (15 downto 0);
           DATA_ACCU    : in STD_LOGIC_VECTOR (15 downto 0);
           DATA_OUT     : out STD_LOGIC_VECTOR (15 downto 0);
           carry        : out STD_LOGIC);
end component UAL;

component Accu_register is
    Port (  clk         : in STD_LOGIC;
            ce          : in STD_LOGIC;
            rst         : in STD_LOGIC;
            load_ACCU   : in STD_LOGIC;
            DATA_IN     : in STD_LOGIC_VECTOR (15 downto 0);
            DATA_OUT    : out STD_LOGIC_VECTOR (15 downto 0));
end component Accu_register;

component Carry_register is
    Port ( clk          : in STD_LOGIC;
           rst          : in STD_LOGIC;
           ce           : in STD_LOGIC;
           load_carry   : in STD_LOGIC;
           clear_carry  : in STD_LOGIC;
           carry_in     : in STD_LOGIC;
           carry_out    : out STD_LOGIC);
end component Carry_register;

signal R1_out, UAL_out, ACCU_out : std_logic_vector(15 downto 0);
signal carry_in: std_logic;


begin
    uut3 :  R1_register Port map( clk => clk,
               rst => rst,
               ce => ce,
               load_R1=> load_R1,
               data_mem => data_in,
               data_UAL => R1_out);

    uut2 : UAL Port map( sel_UAL => sel_UAL,    
               DATA_R1  => R1_out,
               ce => ce,
               DATA_ACCU => ACCU_out,
               DATA_OUT => UAL_OUT,
               carry => carry_in);
    uut1 : Carry_register Port map( clk => clk,
               rst=> rst,
               ce=> ce,
               load_carry=> load_carry  ,
               clear_carry => init_carry,
               carry_in => carry_in,
               carry_out => carry);
            
           
    uut0 : Accu_register Port map(  clk  => clk,
                ce  => ce,
                rst => rst,
                load_ACCU=> load_ACCU,
                DATA_IN => UAL_OUT,
                DATA_OUT => ACCU_out);
                
   process(ACCU_out)
   begin
    data_out<= ACCU_out;
    end process;
         
end architecture Behavioral;