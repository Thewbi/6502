LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY QuasiTopLevel IS
    PORT (
        CLOCK_50 : STD_LOGIC;
        HEX2, HEX3, HEX4, HEX5, HEX6, HEX7 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0); -- 7-segment displays --(active low)
        SW : IN STD_LOGIC; -- DPDT switches
        SRAM_DQ : INOUT unsigned(15 DOWNTO 0); -- Data bus 16 Bits
        SRAM_ADDR : OUT unsigned(17 DOWNTO 0); -- Address BUS 18 Bits
        SRAM_UB_N, -- High-byte Data Mask
        SRAM_LB_N, -- Low-byte Data Mask
        SRAM_WE_N, -- Write Enable
        SRAM_CE_N, -- Chip Enable
        SRAM_OE_N : OUT STD_LOGIC -- Output Enable
    );
END QuasiTopLevel;

ARCHITECTURE datapath OF QuasiTopLevel IS
    SIGNAL Databus, DOR, ROM_data : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL Addrbus, ROM_address : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL W_R : STD_LOGIC;
    COMPONENT SixFiveO2
        PORT (
            Databus : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            Addrbus : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            DOR : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            reset, clk : IN STD_LOGIC;
            XL, XH, YL, YH, ACCL, ACCH : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
            W_R : OUT STD_LOGIC
        );
    END COMPONENT;
    COMPONENT rom IS
        PORT (
            addr : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;
    COMPONENT SRAMCtrl IS
        PORT (
            reset, clk, W_R : IN STD_LOGIC;
            ROM_data, DOR : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            databus : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            AddressBus : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            ROM_address : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            SRAM_DQ : INOUT unsigned(15 DOWNTO 0);
            SRAM_ADDR : OUT unsigned(17 DOWNTO 0);
            SRAM_UB_N, -- High-byte Data Mask
            SRAM_LB_N, -- Low-byte Data Mask
            SRAM_WE_N, -- Write Enable
            SRAM_CE_N, -- Chip Enable
            SRAM_OE_N : OUT STD_LOGIC -- Output Enable
        );
    END COMPONENT;
BEGIN
    CPUConnect : SixFiveO2 PORT MAP(
        clk => CLOCK_50,
        reset => SW,
        W_R => W_R,
        XH => HEX7,
        XL => HEX6,
        YH => HEX5,
        YL => HEX4,
        ACCH => HEX3,
        ACCL => HEX2,
        Databus => Databus,
        DOR => DOR,
        Addrbus => Addrbus);

    InstructionROM : Rom PORT MAP(
        addr => ROM_address, 
        data => ROM_data);

    MemorySRAM : SRAMCtrl PORT MAP(
        reset => SW, 
        clk => CLOCK_50, 
        W_R => W_R,
        ROM_data => ROM_data, 
        DOR => DOR,
        databus => databus,
        AddressBus => Addrbus, 
        ROM_address => ROM_address,
        SRAM_DQ => SRAM_DQ,
        SRAM_ADDR => SRAM_ADDR,
        SRAM_UB_N => SRAM_UB_N,
        SRAM_LB_N => SRAM_LB_N,
        SRAM_WE_N => SRAM_WE_N,
        SRAM_CE_N => SRAM_CE_N,
        SRAM_OE_N => SRAM_OE_N);
END datapath;