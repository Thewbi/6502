LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY SRAMCtrl IS
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
END SRAMCtrl;

ARCHITECTURE rtl OF SRAMCtrl IS
    --signal address : unsigned(15 downto 0):=x"0000";
    SIGNAL counter1 : unsigned(3 DOWNTO 0) := x"0";
BEGIN
    PROCESS (reset, clk, W_R, ROM_data, DOR, AddressBus, SRAM_DQ)
        VARIABLE address : unsigned(15 DOWNTO 0) := x"0000";
    BEGIN
        SRAM_ADDR(17 DOWNTO 16) <= "00";
        SRAM_CE_N <= '0';
        SRAM_LB_N <= '0';
        SRAM_UB_N <= '1';
        IF reset = '1' THEN
            SRAM_WE_N <= '0';
            SRAM_OE_N <= '1';
            databus <= (OTHERS => '0');
            IF rising_edge(clk) THEN
                IF (counter1 = x"0" OR counter1 = x"1") THEN
                    counter1 <= counter1 + 1;
                ELSE
                    counter1 <= counter1;
                END IF;
                --to make sure that address=x"0000" is written
                correctly
                IF (counter1 = x"0" OR counter1 = x"1") THEN
                    address := address;
                ELSIF address = x"ffff" THEN
                    address := x"0000";
                ELSE
                    address := address + 1;
                END IF;
            END IF;
            IF address(15 DOWNTO 8) = x"00" THEN
                SRAM_DQ(7 DOWNTO
                0) <= unsigned(ROM_data);
                --elsif address(15 downto 0)=x"fffe" then SRAM_DQ(7
                DOWNTO 0) <= x"fd";
                --elsif address(15 downto 0)=x"ffff" then SRAM_DQ(7
                DOWNTO 0) <= x"ff";
            ELSE
                SRAM_DQ(7 DOWNTO 0) <= x"00";
            END IF;
            --SRAM_DQ(15 downto 8)<=x"00";
            SRAM_ADDR(15 DOWNTO 0) <= address;
            ROM_address <= STD_LOGIC_VECTOR(address);
        ELSE
            SRAM_WE_N <= W_R;
            SRAM_OE_N <= NOT (W_R);
            SRAM_ADDR(15 DOWNTO 0) <= unsigned(AddressBus);
            IF W_R = '0' THEN
                SRAM_DQ(7 DOWNTO 0) <= unsigned(DOR);
                databus <= (OTHERS => '0');
            ELSE
                SRAM_DQ(7 DOWNTO 0) <= (OTHERS => 'Z');
                databus <= STD_LOGIC_VECTOR(SRAM_DQ(7 DOWNTO 0));
            END IF;
            ROM_address <= (OTHERS => '0');
        END IF;
    END PROCESS;
END rtl;