LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

-- TG stands for timing generator
ENTITY TG IS
    PORT (
        clk : IN STD_LOGIC;
        cycle_number : IN unsigned(3 DOWNTO 0);
        RMW : IN STD_LOGIC; --read-modify-write instruction
        ACR : IN STD_LOGIC; --carry in from ALU
        BRC : IN STD_LOGIC; --branch flag
        reset : IN STD_LOGIC;
        tcstate : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
        SYNC, SD1, SD2 : OUT STD_LOGIC;
        VEC1 : OUT STD_LOGIC
    );
END TG;

ARCHITECTURE rtl OF TG IS
    -- Build an enumerated type for the state machine
    --type state_type is (s0, s1, s2, s3);
    TYPE state_type IS (T0, T1F_T1, T2_T0, T2_3, T2_4, T3_4, T2_5, T3_5,
        T4_5,
        T2_6, T3_6, T4_6, T5_6, T2_7, T3_7,
        T4_7, T5_7, T6_7,
        T2_B, T3_B, T1F,
        T2_RMW5, T3_RMW5, T4_RMW5, T2_RMW6,
        T3_RMW6, T4_RMW6, T5_RMW6,
        T2_RMW7, T3_RMW7, T4_RMW7_a,
        T5_RMW7_a, T6_RMW7_a,
        T4_RMW7_b, T5_RMW7_b);
    -- Register to hold the current state
    SIGNAL state : state_type;
BEGIN
    -- Logic to advance to the next state
    PROCESS (clk, reset)
    BEGIN
        IF reset = '1' THEN
            state <= T1F_T1; --yuchen0513
        ELSIF (rising_edge(clk)) THEN
            CASE state IS
                WHEN T0 =>
                    state <= T1F_T1;
                WHEN T1F_T1 =>
                    IF RMW = '0' THEN --not read-modify-write instruction
                        IF cycle_number = 2 THEN
                            state <= T2_T0;
                        ELSIF cycle_number = 3 THEN
                            state <= T2_3;
                        ELSIF cycle_number = 4 THEN
                            state <= T2_4;
                        ELSIF cycle_number = 5 THEN
                            state <= T2_5;
                        ELSIF cycle_number = 6 THEN
                            state <= T2_6;
                        ELSIF cycle_number = 7 THEN
                            state <= T2_7;
                        ELSIF cycle_number = 0 THEN --input =0 stands FOR the branch instruction
                            state <= T2_B;
                        ELSIF cycle_number = 1 THEN
                            state <= T1F_T1; --yuchen0513
                        END IF;
                    ELSIF RMW = '1' THEN --read-modify-write instruction
                        IF cycle_number = 2 THEN
                            state <= T2_T0;
                        ELSIF cycle_number = 5 THEN
                            state <= T2_RMW5;
                        ELSIF cycle_number = 6 THEN
                            state <= T2_RMW6;
                        ELSIF cycle_number = 7 THEN
                            state <= T2_RMW7;
                        END IF;
                    END IF;
                WHEN T2_T0 =>
                    state <= T1F_T1;
                WHEN T2_3 =>
                    state <= T0;
                WHEN T2_4 =>
                    state <= T3_4;
                WHEN T3_4 =>
                    state <= T0;
                WHEN T2_5 =>
                    state <= T3_5;
                WHEN T3_5 =>
                    IF ACR = '1' THEN --judge page crossing or not
                        state <= T4_5;
                    ELSE
                        state <= T0;
                    END IF;
                WHEN T4_5 =>
                    state <= T0;
                WHEN T2_6 =>
                    state <= T3_6;
                WHEN T3_6 =>
                    state <= T4_6;
                WHEN T4_6 =>
                    IF ACR = '1' THEN --judge page crossing or not
                        state <= T5_6;
                    ELSE
                        state <= T0;
                    END IF;
                WHEN T5_6 =>
                    state <= T0;
                WHEN T2_7 =>
                    state <= T3_7;
                WHEN T3_7 =>
                    state <= T4_7;
                WHEN T4_7 =>
                    state <= T5_7;
                WHEN T5_7 =>
                    state <= T6_7;
                WHEN T6_7 =>
                    state <= T0;
                WHEN T2_B =>
                    IF BRC = '1' THEN
                        state <= T3_B;
                    ELSE
                        state <= T1F;
                    END IF;
                WHEN T3_B =>
                    IF ACR = '1' THEN --judge page crossing or not
                        state <= T0;
                    ELSE
                        state <= T1F;
                    END IF;
                WHEN T1F =>
                    IF cycle_number = 2 THEN
                        state <= T2_T0;
                    ELSIF cycle_number = 3 THEN
                        state <= T2_3;
                    ELSIF cycle_number = 4 THEN
                        state <= T2_4;
                    ELSIF cycle_number = 5 THEN
                        state <= T2_5;
                    ELSIF cycle_number = 6 THEN
                        state <= T2_6;
                    ELSIF cycle_number = 7 THEN
                        state <= T2_7;
                    ELSIF cycle_number = 0 THEN --input =0 stands FOR the branch instruction
                        state <= T2_B;
                    END IF;
                    --Read-modify-write instruction
                WHEN T2_RMW5 =>
                    state <= T3_RMW5;
                WHEN T3_RMW5 =>
                    state <= T4_RMW5;
                WHEN T4_RMW5 =>
                    state <= T0;
                WHEN T2_RMW6 =>
                    state <= T3_RMW6;
                WHEN T3_RMW6 =>
                    state <= T4_RMW6;
                WHEN T4_RMW6 =>
                    state <= T5_RMW6;
                WHEN T5_RMW6 =>
                    state <= T0;
                WHEN T2_RMW7 =>
                    state <= T3_RMW7;
                WHEN T3_RMW7 =>
                    IF ACR = '1' THEN
                        state <= T4_RMW7_a; --page crossing
                    ELSE
                        state <= T4_RMW7_b; --no page crossing
                    END IF;
                WHEN T4_RMW7_a =>
                    state <= T5_RMW7_a;
                WHEN T5_RMW7_a =>
                    state <= T6_RMW7_a;
                WHEN T6_RMW7_a =
                    state <= T0;
                WHEN T4_RMW7_b =>
                    state <= T5_RMW7_b;
                WHEN T5_RMW7_b =>
                    state <= T0;
                WHEN OTHERS =>
                    state <= T0;
            END CASE;
        END IF;
    END PROCESS;
    -- Output depends solely on the current state
    PROCESS (state)
    BEGIN
        CASE state IS
            WHEN T0 =>
                tcstate <= "111110";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '0';
            WHEN T1F_T1 =>
                tcstate <= "111101";
                SYNC <= '1';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '0';
            WHEN T2_T0 =>
                tcstate <= "111010";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '0';
            WHEN T2_3 =>
                tcstate <= "111011";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '0';
            WHEN T2_4 =>
                tcstate <= "111011";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '0';
            WHEN T3_4 =>
                tcstate <= "110111";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '0';
            WHEN T2_5 =>
                tcstate <= "111011";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '0';
            WHEN T3_5 =>
                tcstate <= "110111";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '0';
            WHEN T4_5 =>
                tcstate <= "101111";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '0';
            WHEN T2_6 =>
                tcstate <= "111011";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '0';
            WHEN T3_6 =>
                tcstate <= "110111";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '0';
            WHEN T4_6 =>
                tcstate <= "101111";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '0';
            WHEN T5_6 =>
                tcstate <= "011111";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '0';
            WHEN T2_7 =>
                tcstate <= "111011";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '0';
            WHEN T3_7 =>
                tcstate <= "110111";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '0';
            WHEN T4_7 =>
                tcstate <= "101111";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '0';
            WHEN T5_7 =>
                tcstate <= "011111";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '0';
            WHEN T6_7 =>
                tcstate <= "111111";
                SYNC <= '0';
                VEC1 <= '1';
                SD1 <= '0';
                SD2 <= '0';
            WHEN T2_B =>
                tcstate <= "111011";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '0';
            WHEN T3_B =>
                tcstate <= "110111";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '0';
            WHEN T1F =>
                tcstate <= "111111";
                SYNC <= '1';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '0';
            WHEN T2_RMW5 =>
                tcstate <= "111011";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '0';
            WHEN T3_RMW5 =>
                tcstate <= "110111";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '1';
                SD2 <= '0';
            WHEN T4_RMW5 =>
                tcstate <= "101111";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '1';
            WHEN T2_RMW6 =>
                tcstate <= "111011";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '0';
            WHEN T3_RMW6 =>
                tcstate <= "110111";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '0';
            WHEN T4_RMW6 =>
                tcstate <= "101111";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '1';
                SD2 <= '0';
            WHEN T5_RMW6 =>
                tcstate <= "011111";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '1';
            WHEN T2_RMW7 =>
                tcstate <= "111011";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '0';
            WHEN T3_RMW7 =>
                tcstate <= "110111";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '0';
            WHEN T4_RMW7_a =>
                tcstate <= "101111";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '0';
            WHEN T5_RMW7_a =>
                tcstate <= "011111";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '1';
                SD2 <= '0';
            WHEN T6_RMW7_a =>
                tcstate <= "111111";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '1';
            WHEN T4_RMW7_b =>
                tcstate <= "101111";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '1';
                SD2 <= '0';
            WHEN T5_RMW7_b =>
                tcstate <= "011111";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '1';
            WHEN OTHERS =>
                tcstate <= "111110";
                SYNC <= '0';
                VEC1 <= '0';
                SD1 <= '0';
                SD2 <= '0';
        END CASE;
    END PROCESS;
END rtl;