----------------------------------------------------------------------------------
--
-- UART_recv_
-- Version 1.2b
-- Written by Yannick Bornat (2014/01/27)
-- Updated by Yannick Bornat (2014/05/12) : output is now synchronous
-- Updated by Yannick Bornat (2014/06/10) :
--    V1.1 : totally rewritten 
--       reception is now more reliable
--       for 3Mbps @50MHz, it is safer to use 1.5 or 2 stop bits.
-- Updated by Yannick Bornat (2014/08/04) :
--    V1.2 : Added slow values for instrumentation compatibility
-- Updated by Yannick Bornat (2015/08/21) :
--    V1.2b : Simplified to fit ENSEIRB-MATMECA lab sessions requirements
--
-- Receives a char on the UART line
-- dat_en is set for one clock period when a char is received 
-- dat must be read at the same time
-- Designed for 100MHz clock, reset is active high
-- transfer rate is 115 200kbps
--
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY UART_recv IS
   PORT (
      clk : IN STD_LOGIC;
      reset : IN STD_LOGIC;
      rx : IN STD_LOGIC;
      dat : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
      dat_en : OUT STD_LOGIC);
END UART_recv;

ARCHITECTURE Behavioral OF UART_recv IS

   TYPE t_fsm IS (idle, zero_as_input, wait_next_bit, bit_sample, bit_received, wait_stop_bit, last_bit_is_zero);
   -- idle            : the normal waiting state (input should always be 1)
   -- zero_as_input   : we received a '1' in input but it may be noise
   -- wait_next_bit   : we just received an input that remained unchanged for 1/4 of the bit period, we wait for 3/4 to finish timeslot
   -- bit_sample      : we wait for a bit to last at least 1/4 of the period without changing
   -- bit_received    : a bit was received during 1/4 of period, so it is valid
   -- wait_stop_bit   : the last bit was a stop, we wait for it to finish (1/2 of period)
   -- last_bit_is_zero: well last bit was not a stop, we wait for a 1 that lasts a full period...

   SIGNAL state : t_fsm := idle;
   SIGNAL nbbits : INTEGER RANGE 0 TO 8 := 0;
   SIGNAL cnt : INTEGER RANGE 0 TO 1023;
   SIGNAL rxi : STD_LOGIC := '1';
   SIGNAL ref_bit : STD_LOGIC;
   SIGNAL shift : STD_LOGIC_VECTOR (7 DOWNTO 0);

   CONSTANT quarter : INTEGER RANGE 0 TO 255 := 216;
   CONSTANT half : INTEGER RANGE 0 TO 511 := 433;
   CONSTANT three_quarters : INTEGER RANGE 0 TO 1023 := 643;
   CONSTANT full : INTEGER RANGE 0 TO 1023 := 867; -- (100MHz /  115200bps) - 1

BEGIN

   -- we fisrt need to sample the input signal
   PROCESS (clk)
   BEGIN
      IF clk'event AND clk = '1' THEN
         rxi <= rx;
      END IF;
   END PROCESS;

   -- the FSM of the module...
   PROCESS (clk)
   BEGIN
      IF rising_edge(clk) THEN
         IF reset = '1' THEN
            state <= idle;
         ELSE
            CASE state IS
               WHEN idle => IF rxi = '0' THEN
                  state <= zero_as_input;
            END IF;
            WHEN zero_as_input => IF rxi = '1' THEN
            state <= idle;
         ELSIF cnt = 0 THEN
            state <= wait_next_bit;
         END IF;
         WHEN wait_next_bit => IF cnt = 0 THEN
         state <= bit_sample;
      END IF;
      WHEN bit_sample => IF cnt = 0 THEN
      state <= bit_received;
   END IF;
   WHEN bit_received => IF nbbits < 8 THEN
   state <= wait_next_bit;
ELSIF ref_bit = '1' THEN
   state <= wait_stop_bit;
ELSE
   state <= last_bit_is_zero;
END IF;
WHEN wait_stop_bit => IF rxi = '0' THEN
state <= last_bit_is_zero;
ELSIF cnt = 0 THEN
state <= idle;
END IF;
WHEN last_bit_is_zero => IF cnt = 0 THEN
state <= idle;
END IF;
END CASE;
END IF;
END IF;
END PROCESS;

-- here we manage the counter 
PROCESS (clk)
BEGIN
   IF rising_edge(clk) THEN
      IF reset = '1' THEN
         cnt <= quarter;
      ELSE
         CASE state IS
            WHEN idle => cnt <= quarter;
            WHEN zero_as_input => IF cnt = 0 THEN
               cnt <= three_quarters; -- transition, we prepare the next waiting time
            ELSE
               cnt <= cnt - 1;
         END IF;
         WHEN wait_next_bit => IF cnt = 0 THEN
         cnt <= quarter; -- transition, we prepare the next waiting time
      ELSE
         cnt <= cnt - 1;
      END IF;
      WHEN bit_sample => IF ref_bit /= rxi THEN
      cnt <= quarter; -- if bit change, we restart the counter
   ELSE
      cnt <= cnt - 1;
   END IF;
   WHEN bit_received => IF nbbits < 8 THEN
   cnt <= three_quarters;
ELSIF ref_bit = '0' THEN
   cnt <= full;
ELSE
   cnt <= half;
END IF;
WHEN wait_stop_bit => cnt <= cnt - 1;
WHEN last_bit_is_zero => IF rxi = '0' THEN
cnt <= full;
ELSE
cnt <= cnt - 1;
END IF;
END CASE;
END IF;
END IF;
END PROCESS;

-- we now manage the reference bit that should remain constant for 1/4 period during bit_sample
-- we affect ref_bit in both wait_next_bit (so that we arrive in bit_sample with initialized value)
-- and in bit_sample because if different, we consider each previous value as a mistake, and if equal
-- it has no consequence...
PROCESS (clk)
BEGIN
   IF rising_edge(clk) THEN
      IF state = wait_next_bit OR state = bit_sample THEN
         ref_bit <= rxi;
      END IF;
   END IF;
END PROCESS;
-- output (shift) register
PROCESS (clk)
BEGIN
   IF rising_edge(clk) THEN
      IF state = bit_sample AND cnt = 0 AND nbbits < 8 THEN
         shift <= ref_bit & shift (7 DOWNTO 1);
      END IF;
   END IF;
END PROCESS;
-- nbbits management
PROCESS (clk)
BEGIN
   IF rising_edge(clk) THEN
      IF state = idle THEN
         nbbits <= 0;
      ELSIF state = bit_received THEN
         nbbits <= nbbits + 1;
      END IF;
   END IF;
END PROCESS;

-- outputs
PROCESS (clk)
BEGIN
   IF rising_edge(clk) THEN
      IF reset = '1' THEN
         dat_en <= '0';
      ELSIF state = wait_stop_bit AND cnt = 0 THEN
         dat_en <= '1';
         dat <= shift;
      ELSE
         dat_en <= '0';
      END IF;
   END IF;
END PROCESS;


end behavioral;
