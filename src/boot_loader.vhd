LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY boot_loader IS
    GENERIC (
        RAM_ADR_WIDTH : INTEGER := 6;
        RAM_SIZE : INTEGER := 64);
    PORT (
        rst : IN STD_LOGIC;
        clk : IN STD_LOGIC;
        ce : IN STD_LOGIC;
        rx : IN STD_LOGIC;
        tx : OUT STD_LOGIC;
        boot : OUT STD_LOGIC;
        scan_memory : IN STD_LOGIC;
        ram_out : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        ram_rw : OUT STD_LOGIC;
        ram_enable : OUT STD_LOGIC;
        ram_adr : OUT STD_LOGIC_VECTOR(RAM_ADR_WIDTH - 1 DOWNTO 0);
        ram_in : OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
END boot_loader;

ARCHITECTURE Behavioral OF boot_loader IS

    COMPONENT UART_recv IS
        PORT (
            clk : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            rx : IN STD_LOGIC;
            dat : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
            dat_en : OUT STD_LOGIC);
    END COMPONENT;

    COMPONENT byte_2_word IS
        PORT (
            rst : IN STD_LOGIC;
            clk : IN STD_LOGIC;
            ce : IN STD_LOGIC;
            byte_dv : IN STD_LOGIC;
            byte : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
            word_dv : OUT STD_LOGIC;
            word : OUT STD_LOGIC_VECTOR (15 DOWNTO 0));
    END COMPONENT;

    COMPONENT word_2_byte IS
        PORT (
            rst : IN STD_LOGIC;
            clk : IN STD_LOGIC;
            ce : IN STD_LOGIC;
            word_dv : IN STD_LOGIC;
            word : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
            byte_dv : OUT STD_LOGIC;
            byte : OUT STD_LOGIC_VECTOR (7 DOWNTO 0));
    END COMPONENT;

    COMPONENT UART_fifoed_send IS
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
    END COMPONENT;

    SIGNAL rx_byte, tx_byte : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL rx_data_valid, rx_data_valid_dly, tx_data_valid : STD_LOGIC;
    SIGNAL rx_word_valid : STD_LOGIC;

    SIGNAL rx_byte_reg, rx_byte_reg2 : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL rx_word : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL byte_count : unsigned(1 DOWNTO 0);
    SIGNAL rx_byte_count : unsigned(RAM_ADR_WIDTH - 1 DOWNTO 0);
    SIGNAL enable_rx_byte_counter : STD_LOGIC;
    SIGNAL init_byte_counter : STD_LOGIC;

    TYPE t_state IS (INIT, WAIT_RX_BYTE, INCR_RX_BYTE_COUNTER, WRITE_RX_BYTE, WAIT_SCAN_MEM, READ_TX_BYTE, INCR_TX_BYTE_COUNTER, ENABLE_TX, WAIT_8K_CYCLE, OVER);
    SIGNAL current_state, future_state : t_state;

    SIGNAL tx_cycle_count : unsigned(14 DOWNTO 0);
    SIGNAL init_tx_cycle_count, tx_cycle_count_over : STD_LOGIC;
    SIGNAL tx_data_valid_dly : STD_LOGIC;
    SIGNAL tx_word_valid : STD_LOGIC;

BEGIN

    ram_adr <= STD_LOGIC_VECTOR(rx_byte_count);
    ram_in <= rx_word;

    inst_uart_recv : UART_recv
    PORT MAP(
        clk => clk,
        reset => rst,
        rx => rx,
        dat => rx_byte,
        dat_en => rx_data_valid);

    inst_uart_send : UART_fifoed_send
    GENERIC MAP(
        fifo_size => 4,
        fifo_almost => 2,
        drop_oldest_when_full => false,
        asynch_fifo_full => true,
        baudrate => 115200,
        clock_frequency => 100000000)
    PORT MAP(
        clk_100MHz => clk,
        reset => rst,
        dat_en => tx_word_valid,
        dat => tx_byte,
        TX => tx,
        fifo_empty => OPEN,
        fifo_afull => OPEN,
        fifo_full => OPEN);
    ---------------------
    -- rx_byte_register
    ---------------------

    b2w : byte_2_word
    PORT MAP(
        rst => rst,
        clk => clk,
        ce => ce,
        byte_dv => rx_data_valid,
        byte => rx_byte,
        word_dv => rx_word_valid,
        word => rx_word);
    ---------------------
    -- rx_byte_counter
    ---------------------

    PROCESS (rst, clk)
    BEGIN
        IF (rst = '1') THEN
            rx_byte_count <= (OTHERS => '0');
        ELSIF (rising_edge(clk)) THEN
            IF (ce = '1') THEN
                IF (init_byte_counter = '1') THEN
                    rx_byte_count <= (OTHERS => '0');
                ELSIF (enable_rx_byte_counter = '1') THEN
                    IF (rx_byte_count = to_unsigned(RAM_SIZE - 1, RAM_ADR_WIDTH)) THEN
                        rx_byte_count <= (OTHERS => '0');
                    ELSE
                        rx_byte_count <= rx_byte_count + to_unsigned(1, RAM_ADR_WIDTH);
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    w2b : word_2_byte
    PORT MAP(
        rst => rst,
        clk => clk,
        ce => ce,
        word_dv => tx_data_valid,
        word => ram_out,
        byte_dv => tx_word_valid,
        byte => tx_byte);

    ---------------------
    -- tx_cycle_counter
    ---------------------

    PROCESS (rst, clk)
    BEGIN
        IF (rst = '1') THEN
            tx_cycle_count <= (OTHERS => '0');
        ELSIF (rising_edge(clk)) THEN
            IF (ce = '1') THEN
                IF (init_tx_cycle_count = '1') THEN
                    tx_cycle_count <= (OTHERS => '0');
                    tx_cycle_count_over <= '0';
                ELSIF (tx_cycle_count = to_unsigned(18000, 15)) THEN
                    tx_cycle_count_over <= '1';
                    tx_cycle_count <= (OTHERS => '0');
                ELSE
                    tx_cycle_count <= tx_cycle_count + to_unsigned(1, 15);
                    tx_cycle_count_over <= '0';
                END IF;
            END IF;
        END IF;
    END PROCESS;

    ---------------------
    -- fsm
    ---------------------

    state_register : PROCESS (rst, clk)
    BEGIN
        IF (rst = '1') THEN
            current_state <= INIT;
        ELSIF (rising_edge (clk)) THEN
            IF (ce = '1') THEN
                current_state <= future_state;
            END IF;
        END IF;
    END PROCESS;

    next_state_compute : PROCESS (current_state, rx_word_valid, rx_byte_count, scan_memory, tx_cycle_count_over)
    BEGIN
        CASE current_state IS
            WHEN INIT =>
                future_state <= WAIT_RX_BYTE;
            WHEN WAIT_RX_BYTE =>
                IF (rx_word_valid = '1') THEN
                    future_state <= WRITE_RX_BYTE;
                ELSE
                    future_state <= WAIT_RX_BYTE;
                END IF;
            WHEN WRITE_RX_BYTE =>
                IF (rx_byte_count = to_unsigned(RAM_SIZE - 1, RAM_ADR_WIDTH)) THEN
                    future_state <= WAIT_SCAN_MEM;
                ELSE
                    future_state <= INCR_RX_BYTE_COUNTER;
                END IF;
            WHEN INCR_RX_BYTE_COUNTER =>
                future_state <= WAIT_RX_BYTE;
            WHEN WAIT_SCAN_MEM =>
                IF (scan_memory = '1') THEN
                    future_state <= READ_TX_BYTE;
                ELSE
                    future_state <= WAIT_SCAN_MEM;
                END IF;
            WHEN INCR_TX_BYTE_COUNTER =>
                future_state <= WAIT_8K_CYCLE;
            WHEN WAIT_8K_CYCLE =>
                IF (tx_cycle_count_over = '0') THEN
                    future_state <= WAIT_8K_CYCLE;
                ELSE
                    future_state <= READ_TX_BYTE;
                END IF;
            WHEN READ_TX_BYTE =>
                future_state <= ENABLE_TX;
            WHEN ENABLE_TX =>
                IF (rx_byte_count = to_unsigned(RAM_SIZE - 1, RAM_ADR_WIDTH)) THEN
                    future_state <= OVER;
                ELSE
                    future_state <= INCR_TX_BYTE_COUNTER;
                END IF;
            WHEN OVER =>
                future_state <= OVER;
        END CASE;
    END PROCESS;
    output_compute : PROCESS (current_state)
    BEGIN
        CASE current_state IS
            WHEN INIT =>
                ram_rw <= '0';
                ram_enable <= '1';
                tx_data_valid <= '0';
                enable_rx_byte_counter <= '0';
                boot <= '1';
                init_byte_counter <= '1';
                init_tx_cycle_count <= '1';
            WHEN WAIT_RX_BYTE =>
                ram_rw <= '0';
                ram_enable <= '1';
                tx_data_valid <= '0';
                enable_rx_byte_counter <= '0';
                boot <= '1';
                init_byte_counter <= '0';
                init_tx_cycle_count <= '1';
            WHEN WRITE_RX_BYTE =>
                ram_rw <= '1';
                ram_enable <= '1';
                tx_data_valid <= '0';
                enable_rx_byte_counter <= '0';
                boot <= '1';
                init_byte_counter <= '0';
                init_tx_cycle_count <= '1';
            WHEN INCR_RX_BYTE_COUNTER =>
                ram_rw <= '0';
                ram_enable <= '1';
                tx_data_valid <= '0';
                enable_rx_byte_counter <= '1';
                boot <= '1';
                init_byte_counter <= '0';
                init_tx_cycle_count <= '1';
            WHEN WAIT_SCAN_MEM =>
                ram_rw <= '0';
                ram_enable <= '1';
                tx_data_valid <= '0';
                enable_rx_byte_counter <= '0';
                boot <= '0';
                init_byte_counter <= '1';
                init_tx_cycle_count <= '1';
            WHEN READ_TX_BYTE =>
                ram_rw <= '0';
                ram_enable <= '1';
                tx_data_valid <= '0';
                enable_rx_byte_counter <= '0';
                boot <= '1';
                init_byte_counter <= '0';
                init_tx_cycle_count <= '1';
            WHEN ENABLE_TX =>
                ram_rw <= '0';
                ram_enable <= '1';
                tx_data_valid <= '1';
                enable_rx_byte_counter <= '0';
                boot <= '1';
                init_byte_counter <= '0';
                init_tx_cycle_count <= '1';
            WHEN INCR_TX_BYTE_COUNTER =>
                ram_rw <= '0';
                ram_enable <= '1';
                tx_data_valid <= '0';
                enable_rx_byte_counter <= '1';
                boot <= '1';
                init_byte_counter <= '0';
                init_tx_cycle_count <= '1';
            WHEN WAIT_8K_CYCLE =>
                ram_rw <= '0';
                ram_enable <= '1';
                tx_data_valid <= '0';
                enable_rx_byte_counter <= '0';
                boot <= '1';
                init_byte_counter <= '0';
                init_tx_cycle_count <= '0';
            WHEN OVER =>
                ram_rw <= '0';
                ram_enable <= '1';
                tx_data_valid <= '0';
                enable_rx_byte_counter <= '0';
                boot <= '0';
                init_byte_counter <= '0';
                init_tx_cycle_count <= '1';
        END CASE;
    END PROCESS;

END Behavioral;