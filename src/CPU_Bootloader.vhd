LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY CPU_Bootloader IS
    GENERIC (
        RAM_ADR_WIDTH : INTEGER := 6;
        RAM_SIZE : INTEGER := 64);
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        ce : IN STD_LOGIC;
        scan_memory : IN STD_LOGIC;
        rx : IN STD_LOGIC;
        tx : OUT STD_LOGIC);
END CPU_Bootloader;

ARCHITECTURE Behavioral OF CPU_Bootloader IS

    COMPONENT boot_loader IS
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
    END COMPONENT;

    COMPONENT Control_Unit IS
        GENERIC (RAM_ADR_WIDTH : INTEGER := 6);
        PORT (
            clk : IN STD_LOGIC;
            ce : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            carry : IN STD_LOGIC;
            boot : IN STD_LOGIC;
            data_in : IN STD_LOGIC_VECTOR (15 DOWNTO 0); --STD_LOGIC_VECTOR (15 DOWNTO 0);
            adr : OUT STD_LOGIC_VECTOR (RAM_ADR_WIDTH - 1 DOWNTO 0);
            clear_carry : OUT STD_LOGIC;
            enable_mem : OUT STD_LOGIC;
            load_R1 : OUT STD_LOGIC;
            load_accu : OUT STD_LOGIC;
            load_carry : OUT STD_LOGIC;
            sel_UAL : OUT std_logic_vector(2 downto 0);
            w_mem : OUT STD_LOGIC);
    END COMPONENT;

    COMPONENT UT
        PORT (
            data_in : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
            clk : IN STD_LOGIC;
            ce : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            load_R1 : IN STD_LOGIC;
            load_accu : IN STD_LOGIC;
            load_carry : IN STD_LOGIC;
            init_carry : IN STD_LOGIC;
            sel_UAL : IN STD_LOGIC_vector(2 downto 0);
            data_out : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
            carry : OUT STD_LOGIC);
    END COMPONENT;

    COMPONENT RAM_SP_64_8 IS
        GENERIC (
            NbBits : INTEGER := 16;
            Nbadr : INTEGER := 6);
        PORT (
            add : IN STD_LOGIC_VECTOR ((Nbadr - 1) DOWNTO 0);
            data_in : IN STD_LOGIC_VECTOR ((NbBits - 1) DOWNTO 0);
            r_w : IN STD_LOGIC;
            enable : IN STD_LOGIC;
            clk : IN STD_LOGIC;
            ce : IN STD_LOGIC;
            data_out : OUT STD_LOGIC_VECTOR ((NbBits - 1) DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL UT_data_out : STD_LOGIC_VECTOR (15 DOWNTO 0);
    SIGNAL sig_adr : STD_LOGIC_VECTOR (RAM_ADR_WIDTH - 1 DOWNTO 0);
    SIGNAL carry : STD_LOGIC;
    SIGNAL clear_carry : STD_LOGIC;
    SIGNAL enable_mem : STD_LOGIC;
    SIGNAL load_R1 : STD_LOGIC;
    SIGNAL load_accu : STD_LOGIC;
    SIGNAL load_carry : STD_LOGIC;
    SIGNAL sel_UAL_UT : STD_LOGIC_vector(2 downto 0);
    SIGNAL sel_UAL_UC : STD_LOGIC_vector(2 downto 0);
    SIGNAL w_mem : STD_LOGIC;

    SIGNAL ram_data_in, ram_data_out : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL ram_enable : STD_LOGIC;

    SIGNAL sig_rw : STD_LOGIC;
    SIGNAL sig_ram_enable : STD_LOGIC;
    SIGNAL sig_ram_adr : STD_LOGIC_VECTOR(RAM_ADR_WIDTH - 1 DOWNTO 0);
    SIGNAL sig_ram_in : STD_LOGIC_VECTOR(15 DOWNTO 0);

    SIGNAL boot : STD_LOGIC;
    SIGNAL boot_ram_adr : STD_LOGIC_VECTOR(RAM_ADR_WIDTH - 1 DOWNTO 0);
    SIGNAL boot_ram_in : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL boot_ram_out : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL boot_ram_rw : STD_LOGIC;
    SIGNAL boot_ram_enable : STD_LOGIC;

BEGIN
    UC : Control_unit
    GENERIC MAP(RAM_ADR_WIDTH => RAM_ADR_WIDTH)
    PORT MAP(
        clk => clk,
        ce => ce,
        rst => rst,
        carry => carry,
        boot => boot,
        data_in => ram_data_out,
        adr => sig_adr,
        clear_carry => clear_carry,
        enable_mem => enable_mem,
        load_R1 => load_R1,
        load_accu => load_accu,
        load_carry => load_carry,
        sel_UAL => sel_UAL_UC,
        w_mem => w_mem);

    sel_UAL_UT <=  sel_UAL_UC;

    UT1 : UT PORT MAP(
        data_in => ram_data_out,
        clk => clk,
        ce => ce,
        rst => rst,
        load_R1 => load_R1,
        load_accu => load_accu,
        load_carry => load_carry,
        init_carry => clear_carry,
        sel_UAL => sel_UAL_UT,
        data_out => UT_data_out,
        carry => carry);

    BL : boot_loader GENERIC MAP(
        RAM_ADR_WIDTH => RAM_ADR_WIDTH,
        RAM_SIZE => RAM_SIZE)
    PORT MAP(
        rst => rst,
        clk => clk,
        ce => ce,
        rx => rx,
        tx => tx,
        boot => boot,
        scan_memory => scan_memory,
        ram_out => ram_data_out,
        ram_rw => boot_ram_rw,
        ram_enable => boot_ram_enable,
        ram_adr => boot_ram_adr,
        ram_in => boot_ram_in);

    -- boot controled MUX for RAM signal 
    sig_rw <= boot_ram_rw WHEN boot = '1' ELSE
        w_mem;
    sig_ram_enable <= boot_ram_enable WHEN boot = '1' ELSE
        enable_mem;
    sig_ram_adr <= boot_ram_adr WHEN boot = '1' ELSE
        sig_adr;
    sig_ram_in <= boot_ram_in WHEN boot = '1' ELSE
        UT_data_out;

    UM : RAM_SP_64_8
    GENERIC MAP(
        NbBits => 16,
        Nbadr => RAM_ADR_WIDTH)
    PORT MAP(
        add => sig_ram_adr,
        data_in => sig_ram_in,
        r_w => sig_rw,
        enable => sig_ram_enable,
        clk => clk,
        ce => ce,
        data_out => ram_data_out);

END Behavioral;