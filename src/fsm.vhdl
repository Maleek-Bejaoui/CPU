----------------------------------------------------------------------------------
-- Company: ENSEIRB MATMECA
-- Engineer: Léa KELEKE MALHERBE FAVIER
-- 
-- Create Date: 16.01.2025 10:26:21
-- Design Name: 
-- Module Name: FSM - Behavioral
-- Project Name: CPU
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

entity FSM is
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
           sel_UAL      : out std_logic_vector(2 downto 0);
           clear_carry  : out STD_LOGIC;
           load_carry   : out STD_LOGIC;
           enable_mem   : out STD_LOGIC;
           W_mem        : out STD_LOGIC);
end FSM;

architecture Behavioral of FSM is

type STATE_TYPE IS (init, fetch_ins, fetch_ins_dly, decode, fetch_op, fetch_op_dly,exe_nor_add,exe_jcc, store, store_dly);
    signal current_state : STATE_TYPE;
    signal next_state    : STATE_TYPE;

begin

    REG : process(rst, clk)
        begin
        if(rst = '1') then
            current_state <= init;
        elsif(rising_edge(clk)) then
            if(ce = '1') then
                if (boot='0') then
                    current_state <= next_state;
                elsif (boot='1') then
                    current_state <= init;
                end if;
            end if;
        end if;
    end process;

    N_STATE : process(current_state, code_op, boot)
        begin
            case current_state is
                when init =>
                    if boot = '1' then 
                        next_state <= init;
                    else 
                        next_state <= fetch_ins;
                    end if;
                
                when fetch_ins =>
                    next_state <= fetch_ins_dly;
                    
                when fetch_ins_dly =>
                    next_state <= decode;
                    
                when decode =>
                    if (code_op = "100") then
                        next_state <= store;
                    elsif (code_op = "110") then
                        next_state <= exe_jcc;
                    elsif (code_op = "000" or code_op = "010" or code_op = "011") then
                        next_state <= fetch_op; 
                    end if;
                    
                when store =>
                    next_state <= store_dly;
                    
                when store_dly =>
                    next_state <= fetch_ins;
                    
                when exe_jcc =>
                    next_state <= fetch_ins;
                    
                when fetch_op =>
                    next_state <= fetch_op_dly;
                    
                when fetch_op_dly =>
                    next_state <= exe_nor_add;
                    
                when exe_nor_add =>
                    next_state <= fetch_ins;
                    
                end case;
        end process;  
        
        
    STATE_OUT : process(current_state)
        begin
            case current_state is 
                when init =>   clear_PC     <= '1';
                               enable_PC    <= '0';
                               load_PC      <= '0';
                               load_RI      <= '0';
                               sel_ADR      <= '0';
                               load_R1      <= '0';
                               load_ACCU    <= '0';
                               sel_UAL      <= "111";
                               clear_carry  <= '1';
                               load_carry   <= '0';
                               enable_mem   <= '0';
                               W_mem        <= '0';
                               
                when fetch_ins =>  clear_PC     <= '0';
                                   enable_PC    <= '0';
                                   load_PC      <= '0';
                                   load_RI      <= '0';
                                   sel_ADR      <= '0';
                                   load_R1      <= '0';
                                   load_ACCU    <= '0';
                                   sel_UAL      <= "111";
                                   clear_carry  <= '0';
                                   load_carry   <= '0';
                                   enable_mem   <= '1';
                                   W_mem        <= '0';

                when fetch_ins_dly =>  clear_PC     <= '0';
                                       enable_PC    <= '0';
                                       load_PC      <= '0';
                                       load_RI      <= '1';
                                       sel_ADR      <= '0';
                                       load_R1      <= '0';
                                       load_ACCU    <= '0';
                                       sel_UAL      <= "111";
                                       clear_carry  <= '0';
                                       load_carry   <= '0';
                                       enable_mem   <= '1';
                                       W_mem        <= '0';
                               
                when decode => clear_PC     <= '0';
                               enable_PC    <= '0';
                               load_PC      <= '0';
                               load_RI      <= '0';
                               sel_ADR      <= '1';
                               load_R1      <= '0';
                               load_ACCU    <= '0';
                               sel_UAL      <= "111";
                               clear_carry  <= '0';
                               load_carry   <= '0';
                               enable_mem   <= '0';
                               W_mem        <= '0';
                               
                when fetch_op =>   clear_PC     <= '0';
                                   enable_PC    <= '0';
                                   load_PC      <= '0';
                                   load_RI      <= '0';
                                   sel_ADR      <= '1';
                                   load_R1      <= '1';
                                   load_ACCU    <= '0';
                                   sel_UAL      <= "111";
                                   clear_carry  <= '0';
                                   load_carry   <= '0';
                                   enable_mem   <= '1';
                                   W_mem        <= '0';
                               
                when fetch_op_dly =>   clear_PC     <= '0';
                                       enable_PC    <= '0';
                                       load_PC      <= '0';
                                       load_RI      <= '0';
                                       sel_ADR      <= '1';
                                       load_R1      <= '1';
                                       load_ACCU    <= '0';
                                       sel_UAL      <= "111";
                                       clear_carry  <= '0';
                                       load_carry   <= '0';
                                       enable_mem   <= '0';
                                       W_mem        <= '0';    
                                       
                when exe_nor_add => clear_PC    <= '0';
                                   enable_PC    <= '1';
                                   load_PC      <= '0';
                                   load_RI      <= '0';
                                   sel_ADR      <= '1';
                                   load_R1      <= '0';
                                   load_ACCU    <= '1';
                                   sel_UAL      <= code_op;
                                   clear_carry  <= '0';
                                   load_carry   <= code_op(1);
                                   enable_mem   <= '0';
                                   W_mem        <= '0';                                                                  
                               
                when exe_jcc => clear_PC    <= '0';
                               enable_PC    <= carry;
                               load_PC      <= not carry;
                               load_RI      <= '1';
                               sel_ADR      <= '1';
                               load_R1      <= '0';
                               load_ACCU    <= '0';
                               sel_UAL      <= "111";
                               clear_carry  <= carry;
                               load_carry   <= '0';
                               enable_mem   <= '0';
                               W_mem        <= '0';       
                               
                when store =>  clear_PC     <= '0';
                               enable_PC    <= '0';
                               load_PC      <= '0';
                               load_RI      <= '0';
                               sel_ADR      <= '1';
                               load_R1      <= '0';
                               load_ACCU    <= '0';
                               sel_UAL      <= "111";
                               clear_carry  <= '0';
                               load_carry   <= '0';
                               enable_mem   <= '1';
                               W_mem        <= '1'; 
                               
                when store_dly =>  clear_PC     <= '0';
                                   enable_PC    <= '1';
                                   load_PC      <= '0';
                                   load_RI      <= '0';
                                   sel_ADR      <= '1';
                                   load_R1      <= '0';
                                   load_ACCU    <= '0';
                                   sel_UAL      <= "111";
                                   clear_carry  <= '0';
                                   load_carry   <= '0';
                                   enable_mem   <= '1';
                                   W_mem        <= '0';       
            end case;
        end process;                                                                                             
                                                                                                                                                                
end Behavioral;
