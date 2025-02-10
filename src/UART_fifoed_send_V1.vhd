----------------------------------------------------------------------------------
--
-- UART_fifoed_send_V1
-- Version 1.1
-- 
-- V1.1 : Written by Yannick Bornat (2016/04/20)
--       - build from UART_send v1.1, named to fit the same version number
--
-- Sends chars on the UART line, has a built-in fifo to accept char inputs while
-- sending an older char
-- during character send, busy output bit is set to '1' and the module ignores inputs.
-- works at 100MHz with 115.200kbps transfer rate
--
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY UART_fifoed_send IS
   GENERIC (
      fifo_size : INTEGER := 4096;
      fifo_almost : INTEGER := 4090;
      drop_oldest_when_full : BOOLEAN := False;
      asynch_fifo_full : BOOLEAN := True;
      baudrate : INTEGER := 921600; -- [bps]
      clock_frequency : INTEGER := 100000000 -- [Hz]
   );
   PORT (
      clk_100MHz : IN STD_LOGIC;
      reset : IN STD_LOGIC;
      dat_en : IN STD_LOGIC;
      dat : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
      TX : OUT STD_LOGIC;
      fifo_empty : OUT STD_LOGIC;
      fifo_afull : OUT STD_LOGIC;
      fifo_full : OUT STD_LOGIC
   );
END UART_fifoed_send;

ARCHITECTURE Behavioral OF UART_fifoed_send IS

   TYPE t_fifo IS ARRAY (0 TO fifo_size - 1) OF STD_LOGIC_VECTOR (7 DOWNTO 0);

   SIGNAL cnt : INTEGER RANGE 0 TO 1023; -- counter to divide clock events
   SIGNAL top : STD_LOGIC; -- strobe to make state machine progress
   SIGNAL shift : STD_LOGIC_VECTOR (8 DOWNTO 0); -- UART shift register
   SIGNAL nbbits : INTEGER RANGE 0 TO 15; -- remaining number of bits to transfer
   SIGNAL FIFO : t_fifo; -- array to store elements in fifo
   SIGNAL read_index : INTEGER RANGE 0 TO fifo_size - 1; -- points to the next element to read from FIFO
   SIGNAL write_index : INTEGER RANGE 0 TO fifo_size - 1; -- points to the next free room in FIFO array
   SIGNAL n_elements : INTEGER RANGE 0 TO fifo_size; -- number of elements in FIFO

   ALIAS clk IS clk_100MHz;

BEGIN

   top <= '1' WHEN cnt = 0 ELSE
      '0';
   TX <= shift(0);

   fifo_empty <= '1' WHEN n_elements = 0 ELSE
      '0';
   fifo_afull <= '1' WHEN n_elements >= fifo_almost ELSE
      '0';
   fifo_full <= '1' WHEN n_elements = fifo_size OR
      (asynch_fifo_full AND dat_en = '1' AND nbbits < 12 AND n_elements = fifo_size - 1) ELSE
      '0';
   -- if user manages fifo_full in asynchronous to prevent writing, asserting fifo_full on write will create
   -- an synchronous loop (ring oscillator), but if not, we must assert as soon as possible to avoid loosing
   -- data

   PROCESS (clk)
   BEGIN
      IF clk'event AND clk = '1' THEN
         IF reset = '1' THEN
            cnt <= 0;
         ELSIF nbbits >= 12 OR cnt = 0 THEN
            cnt <= INTEGER(real(clock_frequency)/real(baudrate)) - 1; -- (100MHz /  115200bps) - 1
         ELSE
            cnt <= cnt - 1;
         END IF;
      END IF;
   END PROCESS;

   PROCESS (clk)
   BEGIN
      IF clk'event AND clk = '1' THEN
         IF reset = '1' THEN
            shift <= "111111111";
            nbbits <= 12;
         ELSIF nbbits >= 12 THEN
            -- this state waits for data to send
            IF n_elements > 0 THEN -- data present in fifo
               shift <= FIFO(read_index) & '0';
               nbbits <= 9;
            END IF;
         ELSE
            -- this part actually sends the bits
            IF top = '1' THEN
               shift <= '1' & shift(8 DOWNTO 1);
               IF nbbits = 0 THEN
                  nbbits <= 15;
               ELSE
                  nbbits <= nbbits - 1;
               END IF;
            END IF;

         END IF;
      END IF;
   END PROCESS;
   PROCESS (clk)
   BEGIN
      IF clk'event AND clk = '1' THEN
         IF reset = '1' THEN
            read_index <= 0;
         ELSIF (n_elements > 0 AND nbbits >= 12) OR (dat_en = '1' AND n_elements = fifo_size AND drop_oldest_when_full) THEN
            -- conditions to increase read_index :
            --    * sending ready, and fifo not empty
            --    * writing element to FIFO with FIFO full, and prefering to loose oldest element rather than
            --      droping new element written
            IF read_index = fifo_size - 1 THEN
               read_index <= 0;
            ELSE
               read_index <= read_index + 1;
            END IF;
         END IF;
      END IF;
   END PROCESS;
   PROCESS (clk)
   BEGIN
      IF clk'event AND clk = '1' THEN
         IF reset = '1' THEN
            n_elements <= 0;
         ELSIF dat_en = '1' THEN
            -- user wants to write data
            IF n_elements = 0 THEN
               -- if FIFO is empty, elements must first be written into the array
               -- so it will not be read instantly (default array behavior is "read before write"
               -- while performing the two operations in the same clock cycle) 
               n_elements <= 1;
            ELSIF nbbits < 12 AND n_elements < fifo_size THEN
               -- we only increase the number of elements if there is still room in the array and
               -- if there is no simultaneous read
               n_elements <= n_elements + 1;
            END IF;
         ELSIF n_elements > 0 AND nbbits >= 12 THEN
            -- no data written, we decrease element number if sending new element (sending ready and
            -- element present in fifo)
            n_elements <= n_elements - 1;
         END IF;
      END IF;
   END PROCESS;
   PROCESS (clk)
   BEGIN
      IF clk'event AND clk = '1' THEN
         IF reset = '1' THEN
            write_index <= 0;
         ELSIF dat_en = '1' AND (n_elements < fifo_size OR drop_oldest_when_full) THEN
            -- dat_en = '1' means, user wants to write a new element in fifo, we do it provided
            -- fifo is not full or user prefers loosing oldest element rather than giving up writing
            IF write_index = fifo_size - 1 THEN
               write_index <= 0;
            ELSE
               write_index <= write_index + 1;
            END IF;
            -- by the way, we also write data in array :)
            FIFO(write_index) <= dat;
         END IF;
      END IF;
   END PROCESS;
END Behavioral;