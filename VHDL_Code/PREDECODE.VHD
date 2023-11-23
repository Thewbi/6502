LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

-- Predecode has to look at the instruction and determine how many cycles
-- the instruction takes (cycle_number). This information is required in 
-- the timing generator since the timing generator has to know when it has 
-- to return to it's start state while executing the state machine for 
-- instructions.
--
-- Some instructions take more cycles than others, which means that the
-- state machine is executed along a varying amount of states based on
-- which instruction is executed.

ENTITY Predecode IS
    PORT (
        databus : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        reset : IN STD_LOGIC;
        cycle_number : OUT unsigned(3 DOWNTO 0);
        Instruction : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        RMW : OUT STD_LOGIC);
END Predecode;

ARCHITECTURE rtl OF Predecode IS
BEGIN
    PROCESS (databus, reset)
    BEGIN
        IF reset = '1' THEN
            cycle_number <= x"1"; --yuchen0513
            Instruction <= x"00";
            RMW <= '0';
        ELSE
            Instruction <= databus;
            RMW <= '0';

            IF databus = x"FF" THEN
                cycle_number <= x"1";

                -- ============================== cc=01 section ==================================
                -- AND, ...
            ELSIF databus(1 DOWNTO 0) = "01" THEN
                IF databus(4 DOWNTO 0) = "00001" THEN -- (zero page, X) with cc = 01
                    cycle_number <= x"6";
                    RMW <= '0';
                ELSIF databus(4 DOWNTO 0) = "00101" THEN -- zero page with cc = 01
                    cycle_number <= x"3";
                    RMW <= '0';
                ELSIF databus(4 DOWNTO 0) = "01001" THEN -- #immediate with cc = 01
                    cycle_number <= x"2";
                    RMW <= '0';
                ELSIF databus(4 DOWNTO 0) = "01101" THEN -- absolute with cc = 01
                    cycle_number <= x"4";
                    RMW <= '0';
                ELSIF databus(4 DOWNTO 0) = "10001" THEN -- (zero page), Y with cc = 01
                    cycle_number <= x"6";
                    RMW <= '0';
                ELSIF databus(4 DOWNTO 0) = "10101" THEN -- zero page, X with cc = 01
                    cycle_number <= x"4";
                    RMW <= '0';
                ELSIF databus(4 DOWNTO 0) = "11001" THEN -- absolute, Y with cc = 01
                    cycle_number <= x"5";
                    RMW <= '0';
                ELSIF databus(4 DOWNTO 0) = "11101" THEN -- absolute, X with cc = 01
                    cycle_number <= x"5";
                    RMW <= '0';
                ELSE
                    cycle_number <= x"1"; --JB0513
                    RMW <= '0';
                END IF;
                -- ============================== cc=01 section ends ==============================

                -- ============================== cc=10 section ==================================
            ELSIF databus(1 DOWNTO 0) = "10" THEN
                --Arthy's code, hex XA: 1xxx1010
                IF databus(7) = '1' AND databus(3 DOWNTO 2) = "10" THEN
                    RMW <= '0';
                    cycle_number <= x"2"; --JB0511. check if wrong.
                    --Yu's code below..
                    --STX, LDX (non read-modify-write code)
                ELSIF databus(7 DOWNTO 6) = "10" AND NOT(databus(3 DOWNTO 2) = "10") THEN -- ************ arthy
                    RMW <= '0';
                    IF databus(4 DOWNTO 2) = "000" THEN --immediate
                        cycle_number <= x"2";
                    ELSIF databus(4 DOWNTO 2) = "001" THEN --zero page
                        cycle_number <= x"3";
                    ELSIF databus(4 DOWNTO 2) = "010" THEN --accumulator ************ arthy
                        cycle_number <= x"2";
                    ELSIF databus(4 DOWNTO 2) = "011" THEN --absolute
                        cycle_number <= x"4";
                    ELSIF databus(4 DOWNTO 2) = "101" THEN --zero page, X/Y
                        cycle_number <= x"4";
                    ELSIF databus(4 DOWNTO 2) = "111" THEN --absolute, X/Y
                        cycle_number <= x"5";
                    ELSE
                        cycle_number <= x"0";
                        RMW <= '0';
                    END IF;
                    --6 read-modify-write instructions
                ELSIF databus(4 DOWNTO 2) = "010" THEN --accumulator
                    cycle_number <= x"2";
                    RMW <= '0';
                ELSE
                    RMW <= '1';
                    IF databus(4 DOWNTO 2) = "001" THEN
                        cycle_number <= x"5";
                        --zero page
                    ELSIF databus(4 DOWNTO 2) = "011" THEN
                        cycle_number <= x"6"; --absolute
                    ELSIF databus(4 DOWNTO 2) = "101" THEN
                        cycle_number <= x"6"; --zero page, X/Y
                    ELSIF databus(4 DOWNTO 2) = "111" THEN
                        cycle_number <= x"7"; --absolute, X/Y
                    ELSE
                        cycle_number <= x"1"; --yuchen0513
                    END IF;
                END IF;
                -- ============================== cc=10 section ends ==================================

                -- ============================== cc=00 section ==================================
            ELSIF databus(1 DOWNTO 0) = "00" THEN
                IF databus(4 DOWNTO 2) = "000" AND databus(7) = '0' THEN --
                    interrupts
                    IF databus(6 DOWNTO 5) = "00" THEN --BRK
                        -- cycle_number<=x"7"; --JB need to define VEC separately!
                        cycle_number <= x"1"; --yuchen0513
                        RMW <= '0';
                    ELSE --JSR, RTS, RTI
                        cycle_number <= x"6";
                        RMW <= '0';
                    END IF;
                ELSE -- among cc=00, all other than interrupts
                    --Arthy's hex: X8 codes fit here.
                    IF databus(3 DOWNTO 2) = "10" THEN
                        RMW <= '0';
                        IF databus(7 DOWNTO 4) = "0000" THEN
                            cycle_number <= x"3";
                        ELSIF databus(7 DOWNTO 4) = "0010" THEN
                            cycle_number <= x"4";
                        ELSIF databus(7 DOWNTO 4) = "0100" THEN
                            cycle_number <= x"3";
                        ELSIF databus(7 DOWNTO 4) = "0110" THEN
                            cycle_number <= x"4";
                        ELSE
                            cycle_number <= x"2";
                        END IF;
                        --end of Arthy's X8 codes.
                    ELSIF databus(4 DOWNTO 2) = "100" THEN --branch
                        cycle_number <= x"0"; -- 2 for no branch, 3 for branch, 4 FOR branch w / page crossing. JB0510 : zero.
                        --BRC <= '1'; JB0510 commented out. BRC value IS determined by CPU IN cycle T2.
                        RMW <= '0';
                        --else cycle_number<=x"0"; RMW <= '0';
                        --end if;
                    ELSIF databus(4 DOWNTO 2) = "000" THEN --immediate
                        cycle_number <= x"2";
                        RMW <= '0';
                        --else cycle_number<=x"0"; RMW <= '0';
                        --end if;
                    ELSIF databus(4 DOWNTO 2) = "001" THEN --zeropage
                        cycle_number <= x"3";
                        RMW <= '0';
                        --else cycle_number<=x"0"; RMW <= '0';
                        --end if;
                    ELSIF databus(4 DOWNTO 2) = "011" AND databus(7 DOWNTO 5) = "010" THEN -- absolute, JMP abs
                        cycle_number <= x"3";
                        RMW <= '0';
                    ELSIF databus(4 DOWNTO 2) = "011" AND databus(7 DOWNTO 5) = "011" THEN -- absolute, JMP ind
                        cycle_number <= x"5";
                        RMW <= '0';
                    ELSIF databus(4 DOWNTO 2) = "011" AND NOT(databus(7 DOWNTO 6) = "01") THEN --rest of all absolutes
                        cycle_number <= x"4";
                        RMW <= '0';
                        --else cycle_number<=x"0"; RMW <= '0';
                        --end if;
                    ELSIF databus(4 DOWNTO 2) = "101" THEN --zeropage,X
                        cycle_number <= x"4";
                        RMW <= '0';
                        --else cycle_number<=x"0"; RMW <= '0';
                        --end if;
                    ELSIF databus(4 DOWNTO 2) = "111" THEN --absolute,X
                        cycle_number <= x"5"; --could be 4 w/o page
                        crossing
                        RMW <= '0';
                    ELSE
                        cycle_number <= x"1";
                        RMW <= '0'; --yuchen0513
                    END IF;
                END IF;
            ELSE
                cycle_number <= x"1";
                RMW <= '0';
            END IF;
            -- ============================== cc=01 section ends ==================================

        END IF;
    END PROCESS;
END rtl;