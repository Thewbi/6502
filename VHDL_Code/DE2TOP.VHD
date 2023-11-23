--
-- DE2 top-level module
--
-- Stephen A. Edwards, Columbia University, sedwards@cs.columbia.edu
--
-- From an original by Terasic Technology, Inc.
-- (DE2_TOP.v, part of the DE2 system board CD supplied by Altera)
--
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY DE2_TOP IS
    PORT (
        -- Clocks
        CLOCK_27, -- 27 MHz
        CLOCK_50, -- 50 MHz
        EXT_CLOCK : IN STD_LOGIC; -- External Clock

        -- Buttons and switches
        KEY : IN STD_LOGIC_VECTOR(3 DOWNTO 0); -- Push buttons
        SW : IN STD_LOGIC_VECTOR(17 DOWNTO 0); -- DPDT switches

        -- LED displays 
        HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0); -- 7-segment displays -- (active low)
        LEDG : OUT STD_LOGIC_VECTOR(8 DOWNTO 0); -- Green LEDs (active high)
        LEDR : OUT STD_LOGIC_VECTOR(17 DOWNTO 0); -- Red LEDs (active high)

        -- RS-232 interface
        UART_TXD : OUT STD_LOGIC; -- UART transmitter
        UART_RXD : IN STD_LOGIC; -- UART receiver

        -- IRDA interface
        IRDA_TXD : OUT STD_LOGIC; -- IRDA Transmitter
        IRDA_RXD : IN STD_LOGIC; -- IRDA Receiver

        -- SDRAM
        DRAM_DQ : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0); -- Data Bus
        DRAM_ADDR : OUT STD_LOGIC_VECTOR(11 DOWNTO 0); -- Address Bus
        DRAM_LDQM, -- Low-byte Data Mask
        DRAM_UDQM, -- High-byte Data Mask
        DRAM_WE_N, -- Write Enable
        DRAM_CAS_N, -- Column Address Strobe
        DRAM_RAS_N, -- Row Address Strobe
        DRAM_CS_N, -- Chip Select
        DRAM_BA_0, -- Bank Address 0
        DRAM_BA_1, -- Bank Address 0
        DRAM_CLK, -- Clock
        DRAM_CKE : OUT STD_LOGIC; -- Clock Enable

        -- FLASH
        FL_DQ : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- Data bus
        FL_ADDR : OUT STD_LOGIC_VECTOR(21 DOWNTO 0); -- Address bus
        FL_WE_N, -- Write Enable
        FL_RST_N, -- Reset
        FL_OE_N, -- Output Enable
        FL_CE_N : OUT STD_LOGIC; -- Chip Enable

        -- SRAM
        SRAM_DQ : INOUT unsigned(15 DOWNTO 0); -- Data bus 16 Bits
        SRAM_ADDR : OUT unsigned(17 DOWNTO 0); -- Address bus 18 Bits
        SRAM_UB_N, -- High-byte Data Mask
        SRAM_LB_N, -- Low-byte Data Mask
        SRAM_WE_N, -- Write Enable
        SRAM_CE_N, -- Chip Enable
        SRAM_OE_N : OUT STD_LOGIC; -- Output Enable

        -- USB controller
        OTG_DATA : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0); -- Data bus
        OTG_ADDR : OUT STD_LOGIC_VECTOR(1 DOWNTO 0); -- Address
        OTG_CS_N, -- Chip Select
        OTG_RD_N, -- Write
        OTG_WR_N, -- Read
        OTG_RST_N, -- Reset
        OTG_FSPEED, -- USB Full Speed, 0 = Enable, Z =
        Disable
        OTG_LSPEED : OUT STD_LOGIC; -- USB Low Speed, 0 = Enable, Z =
        Disable
        OTG_INT0, -- Interrupt 0
        OTG_INT1, -- Interrupt 1
        OTG_DREQ0, -- DMA Request 0
        OTG_DREQ1 : IN STD_LOGIC; -- DMA Request 1
        OTG_DACK0_N, -- DMA Acknowledge 0
        OTG_DACK1_N : OUT STD_LOGIC; -- DMA Acknowledge 1

        -- 16 X 2 LCD Module
        LCD_ON, -- Power ON/OFF
        LCD_BLON, -- Back Light ON/OFF
        LCD_RW, -- Read/Write Select, 0 = Write, 1 = Read
        LCD_EN, -- Enable
        LCD_RS : OUT STD_LOGIC; -- Command/Data Select, 0 = Command, 1 =
        Data
        LCD_DATA : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- Data bus 8 bits

        -- SD card interface
        SD_DAT : IN STD_LOGIC; -- SD Card Data SD pin 7 "DAT 0/DataOut"
        SD_DAT3 : OUT STD_LOGIC; -- SD Card Data 3 SD pin 1 "DAT 3/nCS"
        SD_CMD : OUT STD_LOGIC; -- SD Card Command SD pin 2 "CMD/DataIn"
        SD_CLK : OUT STD_LOGIC; -- SD Card Clock SD pin 5 "CLK"

        -- USB JTAG link
        TDI, -- CPLD -> FPGA (data in)
        TCK, -- CPLD -> FPGA (clk)
        TCS : IN STD_LOGIC; -- CPLD -> FPGA (CS)
        TDO : OUT STD_LOGIC; -- FPGA -> CPLD (data out)

        -- I2C bus
        I2C_SDAT : INOUT STD_LOGIC; -- I2C Data
        I2C_SCLK : OUT STD_LOGIC; -- I2C Clock

        -- PS/2 port
        PS2_DAT, -- Data
        PS2_CLK : IN STD_LOGIC; -- Clock

        -- VGA output
        VGA_CLK, -- Clock
        VGA_HS, -- H_SYNC
        VGA_VS, -- V_SYNC
        VGA_BLANK, -- BLANK
        VGA_SYNC : OUT STD_LOGIC; -- SYNC
        VGA_R, -- Red[9:0]
        VGA_G, -- Green[9:0]
        VGA_B : OUT unsigned(9 DOWNTO 0); -- Blue[9:0]

        -- Ethernet Interface
        ENET_DATA : INOUT unsigned(15 DOWNTO 0); -- DATA bus 16 Bits
        ENET_CMD, -- Command/Data Select, 0 = Command, 1 = Data
        ENET_CS_N, -- Chip Select
        ENET_WR_N, -- Write
        ENET_RD_N, -- Read
        ENET_RST_N, -- Reset
        ENET_CLK : OUT STD_LOGIC; -- Clock 25 MHz
        ENET_INT : IN STD_LOGIC; -- Interrupt

        -- Audio CODEC
        AUD_ADCLRCK : INOUT STD_LOGIC; -- ADC LR Clock
        AUD_ADCDAT : IN STD_LOGIC; -- ADC Data
        AUD_DACLRCK : INOUT STD_LOGIC; -- DAC LR Clock
        AUD_DACDAT : OUT STD_LOGIC; -- DAC Data
        AUD_BCLK : INOUT STD_LOGIC; -- Bit-Stream Clock
        AUD_XCK : OUT STD_LOGIC; -- Chip Clock

        -- Video Decoder
        TD_DATA : IN STD_LOGIC_VECTOR(7 DOWNTO 0); -- Data bus 8 bits
        TD_HS, -- H_SYNC
        TD_VS : IN STD_LOGIC; -- V_SYNC
        TD_RESET : OUT STD_LOGIC; -- Reset

        -- General-purpose I/O
        GPIO_0, -- GPIO Connection 0
        GPIO_1 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0) -- GPIO Connection 1
    );

END DE2_TOP;

ARCHITECTURE datapath OF DE2_TOP IS
    SIGNAL Databus, DOR, ROM_data, X, Y : STD_LOGIC_VECTOR(7 DOWNTO 0); --yuchen0514
    SIGNAL Addrbus, ROM_address : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL W_R : STD_LOGIC;
    SIGNAL reset : STD_LOGIC; --JB0513
    SIGNAL Sclk : STD_LOGIC; --JB0513
    SIGNAL clk25 : STD_LOGIC := '0'; --yuchen0514
    
    COMPONENT SixFiveO2
        PORT (
            Databus : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            Addrbus : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            DOR, P, X_Reg_out, Y_Reg_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            reset, clk : IN STD_LOGIC;
            XL, XH, YL, YH, ACCL, ACCH : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
            W_R : OUT STD_LOGIC);
    END COMPONENT;
    
    COMPONENT rom IS
        PORT (
            addr : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
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
    
    COMPONENT debounce --JB0513
        PORT (
            clk, resetsw : IN STD_LOGIC;
            resetout : OUT STD_LOGIC
        );
    END COMPONENT debounce;
    
    COMPONENT slowclk --JB0513
        PORT (
            clkin : IN STD_LOGIC;
            clkout : OUT STD_LOGIC
        );
    END COMPONENT slowclk;
    
    COMPONENT de2_vga_raster IS

        PORT (
            reset : IN STD_LOGIC;
            clk : IN STD_LOGIC; -- Should be 25.125 MHz
            center : IN STD_LOGIC_VECTOR(15 DOWNTO 0) := X"f0f0"; -- circle center

            VGA_CLK, -- Clock
            VGA_HS, -- H_SYNC
            VGA_VS, -- V_SYNC
            VGA_BLANK, -- BLANK
            VGA_SYNC : OUT STD_LOGIC; -- SYNC
            VGA_R, -- Red[9:0]
            VGA_G, -- Green[9:0]
            VGA_B : OUT unsigned(9 DOWNTO 0) -- Blue[9:0]
        );
    END COMPONENT;
BEGIN

    --HEX2 <= (others => '1');
    HEX1 <= (OTHERS => '1');
    HEX0 <= (OTHERS => '1'); -- Rightmost
    LEDG(8) <= '0';
    LEDR <= (OTHERS => '0');
    LCD_ON <= '1';
    LCD_BLON <= '1';
    LCD_RW <= '1';
    LCD_EN <= '0';
    LCD_RS <= '0';
    SD_DAT3 <= '1';
    SD_CMD <= '1';
    SD_CLK <= '1';
    UART_TXD <= '0';
    DRAM_ADDR <= (OTHERS => '0');
    DRAM_LDQM <= '0';
    DRAM_UDQM <= '0';
    DRAM_WE_N <= '1';
    DRAM_CAS_N <= '1';
    DRAM_RAS_N <= '1';
    DRAM_CS_N <= '1';
    DRAM_BA_0 <= '0';
    DRAM_BA_1 <= '0';
    DRAM_CLK <= '0';
    DRAM_CKE <= '0';
    FL_ADDR <= (OTHERS => '0');
    FL_WE_N <= '1';
    FL_RST_N <= '0';
    FL_OE_N <= '1';
    FL_CE_N <= '1';
    OTG_ADDR <= (OTHERS => '0');
    OTG_CS_N <= '1';
    OTG_RD_N <= '1';
    OTG_RD_N <= '1';
    OTG_WR_N <= '1';
    OTG_RST_N <= '1';
    OTG_FSPEED <= '1';
    OTG_LSPEED <= '1';
    OTG_DACK0_N <= '1';
    OTG_DACK1_N <= '1';
    TDO <= '0';
    I2C_SCLK <= '0';
    IRDA_TXD <= '0';
    ENET_CMD <= '0';
    ENET_CS_N <= '1';
    ENET_WR_N <= '1';
    ENET_RD_N <= '1';
    ENET_RST_N <= '1';
    ENET_CLK <= '0';
    AUD_DACDAT <= '0';
    AUD_XCK <= '0';
    TD_RESET <= '0';
    -- Set all bidirectional ports to tri-state
    DRAM_DQ <= (OTHERS => 'Z');
    FL_DQ <= (OTHERS => 'Z');
    OTG_DATA <= (OTHERS => 'Z');
    LCD_DATA <= (OTHERS => 'Z');
    I2C_SDAT <= 'Z';
    ENET_DATA <= (OTHERS => 'Z');
    AUD_ADCLRCK <= 'Z';
    AUD_DACLRCK <= 'Z';
    AUD_BCLK <= 'Z';
    GPIO_0 <= (OTHERS => 'Z');
    GPIO_1 <= (OTHERS => 'Z');

    --JB0513: port map below changed to fit in debounce
    debouncecode : debounce PORT MAP(
        clk => CLOCK_50, resetsw => SW(17),
        resetout => reset); --JB0513
    slowclkcode : slowclk PORT MAP(clkin => CLOCK_50, clkout => Sclk); --JB0513
    CPUConnect : SixFiveO2 PORT MAP(
        clk => Sclk, reset => reset, W_R => W_R, XH => HEX7,
        XL => HEX6, YH => HEX5, YL => HEX4, ACCH => HEX3, ACCL => HEX2,
        X_Reg_out => X,
        Y_Reg_out => Y, Databus => Databus, DOR => DOR, Addrbus => Addrbus, P => LEDG(7
        DOWNTO 0));
    InstructionROM : Rom PORT MAP(addr => ROM_address, data => ROM_data);
    MemorySRAM : SRAMCtrl PORT MAP(
        reset => reset, clk => Sclk, W_R => W_R,
        ROM_data => ROM_data, DOR => DOR,
        databus => databus,
        AddressBus => Addrbus, ROM_address => ROM_address,
        SRAM_DQ => SRAM_DQ,
        SRAM_ADDR => SRAM_ADDR,
        SRAM_UB_N => SRAM_UB_N,
        SRAM_LB_N => SRAM_LB_N,
        SRAM_WE_N => SRAM_WE_N,
        SRAM_CE_N => SRAM_CE_N,
        SRAM_OE_N => SRAM_OE_N);
    VGAClock :
    PROCESS (CLOCK_50)
    BEGIN
        IF rising_edge(CLOCK_50) THEN
            clk25 <= NOT clk25;
        END IF;
    END PROCESS;
    VGA : de2_vga_raster PORT MAP(
        reset => reset, clk => clk25,
        VGA_CLK => VGA_CLK,
        VGA_HS => VGA_HS,
        VGA_VS => VGA_VS,
        VGA_BLANK =>
        VGA_BLANK,
        VGA_SYNC => VGA_SYNC,
        VGA_R => VGA_R,
        VGA_G => VGA_G,
        VGA_B => VGA_B,
        center(15 DOWNTO 8)
        => X,
        center(7 DOWNTO
        0) => Y
    );
END datapath;