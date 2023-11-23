LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY CPU IS
    PORT (
        clk, SD1, SD2, reset, VEC1 : IN STD_LOGIC;
        opcode : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        tcstate : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
        databus : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        ACR_out, W_R, BRC : OUT STD_LOGIC; --JB0510 added BRC as CPU
        output
        ABL_out, ABH_out, DOR, X_out, Y_out, ACC_out, P_out : OUT
        STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END CPU;

ARCHITECTURE rtl OF CPU IS
    SIGNAL ABL, ABH : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL X, Y, ACC, S, AI, BI, ADD, P : unsigned(7 DOWNTO 0);
    SIGNAL PC : unsigned(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL SUMS, I_ADDC, ORS, ANDS, EORS, SRS : STD_LOGIC;
    --signal opcode : std_logic_vector(7 downto 0);
    SIGNAL ACR : STD_LOGIC;
    --signal temp : unsigned(8 downto 0);
    SIGNAL Mask_shortcut : STD_LOGIC;
    --signal counter : unsigned(7 downto 0);
    SIGNAL proceed : STD_LOGIC; --JB0513
BEGIN
    ACR_out <= ACR;
    --ALU Part: Combinational Logic
    PROCESS (SUMS, ORS, ANDS, EORS, SRS, AI, BI, I_ADDC, Mask_shortcut,
        opcode, P, ACR)
        VARIABLE temp : unsigned(8 DOWNTO 0);
        -- variable ACR : std_logic;

    BEGIN
        IF SUMS = '1' THEN
            temp := ('0' & AI) + ('0' & BI) + ("0" & I_ADDC);
            ADD <= temp(7 DOWNTO 0);
            ACR <= temp(8) OR Mask_shortcut;
        ELSIF ORS = '1' THEN
            ADD <= AI OR BI;
            ACR <= '0';
            temp := "000000000";
        ELSIF ANDS = '1' THEN
            ADD <= AI AND BI;
            ACR <= '0';
            temp := "000000000";
        ELSIF EORS = '1' THEN
            ADD <= AI XOR BI;
            ACR <= '0';
            temp := "000000000";
        ELSIF SRS = '1' THEN
            ADD(6 DOWNTO 0) <= BI(7 DOWNTO 1);
            ACR <= BI(0);
            temp := "000000000";
            IF opcode(7 DOWNTO 5) = "010" THEN
                ADD(7) <= '0';
            ELSIF opcode(7 DOWNTO 5) = "011" THEN
                ADD(7) <= P(0);
            ELSE
                ADD <= x"00";
                ACR <= '0';
            END IF;
        ELSE
            ADD <= x"00";
            ACR <= '0';
            temp := "000000000";
        END IF;
    END PROCESS;
    --=====================================================================
    --=====================================================================
    PROCESS (clk, reset)
    BEGIN
        IF rising_edge(clk) THEN --JB0513 reset if statement is put into
            rising_edge(clk)
            IF reset = '1' THEN
                PC <= x"0001";
                ABL <= x"00";
                ABH <= x"00";
                X <= x"00";
                Y <= x"00";
                ACC <= x"11";
                AI <= x"00";
                BI <= x"00";
                S <= x"00";
                DOR <= x"00";
                SUMS <= '0';
                ORS <= '0';
                ANDS <= '0';
                EORS <= '0';
                SRS <= '0';
                I_ADDC <= '0';
                W_R <= '1';
                SUMS <= '1';
                Mask_shortcut <= '0';
                P <= x"00";
                --counter<=x"00";
            ELSIF reset = '0' THEN
                IF opcode = x"00" THEN
                    PC <= PC + 1;
                    ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                    ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                END IF;
                --JB0513 STOP CODE: hex FF
                IF opcode = x"FF" THEN
                    PC <= PC;
                    ABL <= ABL;
                    ABH <= ABH;
                END IF;

                ---------------------------Yu's code starts here----------------------------
                --======================bbb is the only concern=========================
                IF NOT(opcode(1 DOWNTO 0) = "00") THEN --exclude the cc=00 part to avoid overlapping
                    --Address Mode: Absolute; aaa: don't care; cc: don't care.
                    --Timing: T2
                    IF (opcode(4 DOWNTO 2) = "011" AND tcstate(2) = '0') THEN
                        PC <= PC + 1;
                        ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                        ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                        Sums <= '1';
                        AI <= x"00";
                        BI <= unsigned(Databus);
                        I_ADDC <= '0';
                    END IF;
                    --Timing: T3
                    IF (opcode(4 DOWNTO 2) = "011" AND tcstate(3) = '0') THEN
                        PC <= PC;
                        ABL <= STD_LOGIC_VECTOR(ADD);
                        ABH <= databus;
                        SUMS <= '0';
                    END IF;
                    --Address Mode: Zero page, X; aaa: don't care; cc: don't care.
                    --Timing T2
                    IF (opcode(4 DOWNTO 2) = "101" AND tcstate(2) = '0' AND
                        (NOT((opcode(7 DOWNTO 5) = "100" OR opcode(7 DOWNTO 5) = "101") AND opcode(1
                        DOWNTO 0) = "10"))) THEN
                        PC <= PC;
                        ABL <= Databus;
                        ABH <= x"00";
                        AI <= unsigned(X);
                        BI <= unsigned(Databus);
                        Sums <= '1';
                    END IF;
                    --Timing T3
                    IF (opcode(4 DOWNTO 2) = "101" AND tcstate(3) = '0') THEN
                        PC <= PC;
                        ABL <= STD_LOGIC_VECTOR(ADD);
                        ABH <= x"00";
                        SUMS <= '0';
                    END IF;
                    --Address Mode: Absolute X; aaa: don't care; cc: don't care.
                    --Timing T2
                    IF (opcode(4 DOWNTO 2) = "111" AND tcstate(2) = '0' AND
                        (NOT(opcode(7 DOWNTO 5) = "101" AND opcode(1 DOWNTO 0) = "10"))) THEN
                        PC <= PC + 1;
                        ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                        ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                        AI <= unsigned(X);
                        BI <= unsigned(Databus);
                        Sums <= '1';
                        IF opcode(7 DOWNTO 5) = "100" THEN
                            Mask_shortcut <= '1';
                        END IF;
                    END IF;
                    --Timing T3
                    --no page crossing
                    IF (opcode(4 DOWNTO 2) = "111" AND tcstate(3) = '0' AND ACR = '0') THEN
                        PC <= PC;
                        ABL <= STD_LOGIC_VECTOR(ADD);
                        ABH <= Databus;
                        Mask_shortcut <= '0';
                        Sums <= '0';
                    END IF;
                    --page crossing
                    IF (opcode(4 DOWNTO 2) = "111" AND tcstate(3) = '0' AND
                        ACR = '1') THEN
                        PC <= PC;
                        ABL <= STD_LOGIC_VECTOR(ADD);
                        ABH <= x"00";
                        AI <= x"00";
                        BI <= unsigned(Databus);
                        I_ADDC <= '1';
                        Sums <= '1';
                        Mask_shortcut <= '0';
                    END IF;
                    --Timing T4
                    IF (opcode(4 DOWNTO 2) = "111" AND tcstate(4) = '0') THEN
                        PC <= PC;
                        ABL <= ABL;
                        ABH <= STD_LOGIC_VECTOR(ADD);
                        I_ADDC <= '0';
                        SUMS <= '0';
                    END IF;
                    --Address Mode: Zero Page; aaa: don't care; cc: don't care.
                    --Timing T2
                    IF (opcode(4 DOWNTO 2) = "001" AND tcstate(2) = '0') THEN
                        PC <= PC;
                        ABL <= Databus;
                        ABH <= x"00";

                    END IF;
                END IF; --exclude the cc=00 part to avoid overlapping
                --======================bbb is the only concern ends=====================
                --======================bbb and cc=01 are concerned==============================
                --Address Mode: Absolute Y; aaa: don't care; cc: 01
                --Timing T2
                IF (opcode(4 DOWNTO 2) = "110" AND opcode(1 DOWNTO 0) = "01" AND tcstate(2) = '0') THEN
                    PC <= PC + 1;
                    ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                    ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                    AI <= unsigned(Y);
                    BI <= unsigned(Databus);
                    Sums <= '1';
                    IF opcode(7 DOWNTO 5) = "100" THEN
                        Mask_shortcut <= '1';
                    END IF;
                END IF;
                --Timing T3
                --no page crossing
                IF (opcode(4 DOWNTO 2) = "110" AND opcode(1 DOWNTO 0) = "01" AND
                    tcstate(3) = '0' AND ACR = '0') THEN
                    PC <= PC;
                    ABL <= STD_LOGIC_VECTOR(ADD);
                    ABH <= Databus;
                    Sums <= '0';
                    Mask_shortcut <= '1';
                END IF;
                --page crossing
                IF (opcode(4 DOWNTO 2) = "110" AND opcode(1 DOWNTO 0) = "01" AND tcstate(3) = '0' AND ACR = '1') THEN
                    PC <= PC;
                    ABL <= STD_LOGIC_VECTOR(ADD);
                    ABH <= x"00";
                    AI <= x"00";
                    BI <= unsigned(Databus);
                    I_ADDC <= '1';
                    Sums <= '1';
                    Mask_shortcut <= '1';
                END IF;
                --Timing T4
                IF (opcode(4 DOWNTO 2) = "110" AND opcode(1 DOWNTO 0) = "01" AND tcstate(4) = '0') THEN
                    PC <= PC;
                    ABL <= ABL;
                    ABH <= STD_LOGIC_VECTOR(ADD);
                    I_ADDC <= '0';

                    Sums <= '0';
                END IF;
                --Address Mode: (Zero page, X)/Indirect, X; aaa: don't care; cc:
                01
                --T2
                IF (opcode(4 DOWNTO 2) = "000" AND opcode(1 DOWNTO 0) = "01" AND tcstate(2) = '0') THEN
                    PC <= PC;
                    ABH <= x"00";
                    ABL <= Databus;
                    AI <= X;
                    BI <= unsigned(Databus);
                    Sums <= '1';
                END IF;
                --T3
                IF (opcode(4 DOWNTO 2) = "000" AND opcode(1 DOWNTO 0) = "01" AND tcstate(3) = '0') THEN
                    PC <= PC;
                    ABH <= x"00";
                    ABL <= STD_LOGIC_VECTOR(ADD);
                    AI <= x"00";
                    BI <= ADD;
                    I_ADDC <= '1';
                    Sums <= '1';
                    Mask_shortcut <= '1';
                END IF;
                --T4
                IF (opcode(4 DOWNTO 2) = "000" AND opcode(1 DOWNTO 0) = "01" AND tcstate(4) = '0') THEN
                    PC <= PC;
                    ABH <= x"00";
                    ABL <= STD_LOGIC_VECTOR(ADD);
                    AI <= x"00";
                    BI <= unsigned(Databus);
                    Sums <= '1';
                    I_ADDC <= '0';
                    Mask_shortcut <= '0';
                END IF;
                --T5
                IF (opcode(4 DOWNTO 2) = "000" AND opcode(1 DOWNTO 0) = "01" AND tcstate(5) = '0') THEN
                    PC <= PC;
                    ABH <= Databus;
                    ABL <= STD_LOGIC_VECTOR(ADD);
                    Sums <= '0';
                END IF;
                --Address Mode: (Zero page), Y/Indirect, Y; aaa: don't care; cc:
                01
                --T2
                IF (opcode(4 DOWNTO 2) = "100" AND opcode(1 DOWNTO 0) = "01" AND tcstate(2) = '0') THEN
                    PC <= PC;
                    ABH <= x"00";
                    ABL <= Databus;
                    AI <= x"00";
                    BI <= unsigned(Databus);
                    Sums <= '1';
                    I_ADDC <= '1';
                END IF;
                --T3
                IF (opcode(4 DOWNTO 2) = "100" AND opcode(1 DOWNTO 0) = "01" AND tcstate(3) = '0') THEN
                    PC <= PC;
                    ABH <= x"00";
                    ABL <= STD_LOGIC_VECTOR(ADD);
                    AI <= Y;
                    BI <= unsigned(Databus);
                    Sums <= '1';
                    I_ADDC <= '0';
                    IF opcode(7 DOWNTO 5) = "100" THEN
                        Mask_shortcut <= '1';
                    END IF;
                END IF;
                --T4
                --no page crossing
                IF (opcode(4 DOWNTO 2) = "100" AND opcode(1 DOWNTO 0) = "01" AND tcstate(4) = '0' AND ACR = '0') THEN
                    PC <= PC;
                    ABH <= Databus;
                    ABL <= STD_LOGIC_VECTOR(ADD);
                    Mask_shortcut <= '0';
                    Sums <= '0';
                END IF;
                --page crossing
                IF (opcode(4 DOWNTO 2) = "100" AND opcode(1 DOWNTO 0) = "01" AND tcstate(4) = '0' AND ACR = '1') THEN
                    PC <= PC;
                    ABH <= Databus;
                    ABL <= STD_LOGIC_VECTOR(ADD);
                    AI <= x"00";
                    BI <= unsigned(Databus);
                    Sums <= '1';
                    I_ADDC <= '1';
                    Mask_shortcut <= '0';
                END IF;
                --T5
                IF (opcode(4 DOWNTO 2) = "100" AND opcode(1 DOWNTO 0) = "01" AND tcstate(5) = '0') THEN
                    PC <= PC;
                    ABH <= STD_LOGIC_VECTOR(ADD);
                    ABL <= ABL;
                    I_ADDC <= '0';
                    Sums <= '0';
                END IF;
                --======================bbb and cc=01 are concerned ends ==============================
                
                --======================aaa and cc=01 are concerned ===================================
                --Instruction: LDA; aaa: 101; bbb: don't care; cc: 01
                --T0
                IF (opcode(7 DOWNTO 5) = "101" AND opcode(1 DOWNTO 0) = "01" AND tcstate(0) = '0') THEN
                    PC <= PC + 1;
                    ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                    ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                    ACC <= unsigned(Databus);
                END IF;
                --T1
                IF (opcode(7 DOWNTO 5) = "101" AND opcode(1 DOWNTO 0) = "01" AND tcstate(1) = '0') THEN
                    PC <= PC + 1;
                    ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                    ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                    P(7) <= ACC(7);
                    SUMS <= '0';
                    IF ACC = x"00" THEN
                        P(1) <= '1';
                    ELSE
                        P(1) <= '0';
                    END IF;
                END IF;
                --Instruction: ORA; aaa: 000; bbb: don't care; cc: 01
                --T0
                IF (opcode(7 DOWNTO 5) = "000" AND opcode(1 DOWNTO 0) = "01" AND tcstate(0) = '0') THEN
                    PC <= PC + 1;
                    ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                    ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                    AI <= ACC;
                    BI <= unsigned(Databus);
                    ORS <= '1';
                    SUMS <= '0';
                END IF;
                --T1
                IF (opcode(7 DOWNTO 5) = "000" AND opcode(1 DOWNTO 0) = "01" AND tcstate(1) = '0') THEN
                    PC <= PC + 1;
                    ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                    ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                    ACC <= ADD;
                    ORS <= '0';
                    IF ADD(7) = '1' THEN
                        P(7) <= '1';
                    ELSE
                        P(7) <= '0';
                    END IF;
                    IF ADD = x"00" THEN
                        P(1) <= '1';
                    ELSE
                        P(1) <= '0';
                    END IF;
                END IF;
                --Instruction: AND; aaa: 001; bbb: don't care; cc: 01
                --T0
                IF (opcode(7 DOWNTO 5) = "001" AND opcode(1 DOWNTO 0) = "01" AND tcstate(0) = '0') THEN
                    PC <= PC + 1;
                    ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                    ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                    AI <= ACC;
                    BI <= unsigned(Databus);
                    ANDS <= '1';
                    SUMS <= '0';
                END IF;
                --T1
                IF (opcode(7 DOWNTO 5) = "001" AND opcode(1 DOWNTO 0) = "01" AND tcstate(1) = '0') THEN
                    PC <= PC + 1;
                    ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                    ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                    ACC <= ADD;
                    ANDS <= '0';
                    IF ADD(7) = '1' THEN
                        P(7) <= '1';
                    ELSE
                        P(7) <= '0';
                    END IF;
                    IF ADD = x"00" THEN
                        P(1) <= '1';
                    ELSE
                        P(1) <= '0';
                    END IF;
                END IF;
                --Instruction: EOR; aaa: 010; bbb: don't care; cc: 01
                --T0
                IF (opcode(7 DOWNTO 5) = "010" AND opcode(1 DOWNTO 0) = "01" AND
                    tcstate(0) = '0') THEN
                    PC <= PC + 1;
                    ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                    ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                    AI <= ACC;
                    BI <= unsigned(Databus);
                    EORS <= '1';
                    SUMS <= '0';
                END IF;
                IF (opcode(7 DOWNTO 5) = "010" AND opcode(1 DOWNTO 0) = "01" AND
                    tcstate(1) = '0') THEN
                    PC <= PC + 1;
                    ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                    ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                    ACC <= ADD;
                    EORS <= '0';
                    IF ADD(7) = '1' THEN
                        P(7) <= '1';
                    ELSE
                        P(7) <= '0';
                    END IF;
                    IF ADD = x"00" THEN
                        P(1) <= '1';
                    ELSE
                        P(1) <= '0';
                    END IF;
                END IF;
                --Instruction: ADC; aaa: 011; bbb: don't care; cc: 01
                --T0
                IF (opcode(7 DOWNTO 5) = "011" AND opcode(1 DOWNTO 0) = "01" AND
                    tcstate(0) = '0') THEN
                    PC <= PC + 1;
                    ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                    ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                    AI <= ACC;
                    BI <= unsigned(Databus);
                    SUMS <= '1';
                    I_ADDC <= P(0);
                END IF;
                --T1
                IF (opcode(7 DOWNTO 5) = "011" AND opcode(1 DOWNTO 0) = "01" AND
                    tcstate(1) = '0') THEN
                    PC <= PC + 1;
                    ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                    ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                    ACC <= ADD;
                    SUMS <= '0';
                    I_ADDC <= '0';
                    IF ADD(7) = '1' THEN
                        P(7) <= '1';
                    ELSE
                        P(7) <= '0';
                    END IF;
                    IF ADD = x"00" THEN
                        P(1) <= '1';
                    ELSE
                        P(1) <= '0';
                    END IF;
                    IF ACR = '1' THEN
                        P(0) <= '1';
                    ELSE
                        P(0) <= '0';
                    END IF;
                END IF;
                --Instruction: CMP; aaa: 110; bbb: don't care; cc: 01
                --T0
                IF (opcode(7 DOWNTO 5) = "110" AND opcode(1 DOWNTO 0) = "01" AND
                    tcstate(0) = '0') THEN
                    PC <= PC + 1;
                    ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                    ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                    AI <= ACC;
                    BI <= NOT(unsigned(Databus)); --yuchen0513
                    I_ADDC <= '1';
                    SUMS <= '1';
                END IF;
                --T1
                IF (opcode(7 DOWNTO 5) = "110" AND opcode(1 DOWNTO 0) = "01" AND
                    tcstate(1) = '0') THEN
                    PC <= PC + 1;
                    ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                    ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                    --ACC<=ADD; --yuchen0513
                    I_ADDC <= '0';
                    SUMS <= '0';
                    IF ADD(7) = '1' THEN
                        P(7) <= '1';
                    ELSE
                        P(7) <= '0';
                    END IF;
                    IF ADD = x"00" THEN
                        P(1) <= '1';
                    ELSE
                        P(1) <= '0';
                    END IF;
                    P(0) <= ACR;
                END IF;
                --Instruction: SBC; aaa: 111; bbb: don't care; cc: 01
                --T0
                IF (opcode(7 DOWNTO 5) = "111" AND opcode(1 DOWNTO 0) = "01" AND tcstate(0) = '0') THEN
                    PC <= PC + 1;
                    ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                    ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                    AI <= ACC;
                    BI <= unsigned(NOT(Databus));
                    I_ADDC <= P(0);
                    SUMS <= '1';
                END IF;
                --T1
                IF (opcode(7 DOWNTO 5) = "111" AND opcode(1 DOWNTO 0) = "01" AND tcstate(1) = '0') THEN
                    PC <= PC + 1;
                    ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                    ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                    ACC <= ADD;
                    SUMS <= '0';
                    I_ADDC <= '0';
                    IF ADD(7) = '1' THEN
                        P(7) <= '1';
                    ELSE
                        P(7) <= '0';
                    END IF;
                    IF ADD = x"00" THEN
                        P(1) <= '1';
                    ELSE
                        P(1) <= '0';
                    END IF;
                    IF ACR = '0' THEN
                        P(0) <= '1';
                    ELSE
                        P(0) <= '0';
                    END IF;
                END IF;
                --Instruction: STA; aaa: 100; bbb: don't care; cc: 01
                --T0
                IF (opcode(7 DOWNTO 5) = "100" AND opcode(1 DOWNTO 0) = "01" AND tcstate(0) = '0') THEN
                    PC <= PC + 1;
                    ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                    ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                    W_R <= '1';
                END IF;
                --T1
                IF (opcode(7 DOWNTO 5) = "100" AND opcode(1 DOWNTO 0) = "01" AND tcstate(1) = '0') THEN
                    PC <= PC + 1;
                    ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                    ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                END IF;
                --Last cycle, write value to memory
                IF (opcode(7 DOWNTO 5) = "100" AND opcode(1 DOWNTO 0) = "01") THEN
                    IF ((opcode(4 DOWNTO 2) = "000" AND tcstate(5) = '0') --(zero
                        page, X)
                        OR(opcode(4 DOWNTO 2) = "001" AND tcstate(2) = '0') --zero
                        page
                        OR(opcode(4 DOWNTO 2) = "011" AND tcstate(3) = '0') --
                        absolute
                        OR(opcode(4 DOWNTO 2) = "100" AND ((tcstate(4) = '0') OR
                        (tcstate(5) = '0'))) --(zero page), Y
                        OR(opcode(4 DOWNTO 2) = "101" AND tcstate(3) = '0') --zero
                        page, X
                        OR(opcode(4 DOWNTO 2) = "110" AND ((tcstate(3) = '0') OR
                        (tcstate(4) = '0'))) --absolute, Y
                        OR(opcode(4 DOWNTO 2) = "111" AND ((tcstate(3) = '0') OR
                        (tcstate(4) = '0')))) --absolute, X
                        THEN
                        DOR <= STD_LOGIC_VECTOR(ACC);
                        W_R <= '0';
                    END IF;
                END IF;
                --======================aaa and cc=01 are concerned ends == == == == == == == == == == == == == == == =
                
                --======================cc=10 are concerned == == == == == == == == == == == == == == == == == == == == == =
                --STX and LDX address mode special cases
                --1) Address Mode: Zero page, X==> Zero page, Y; Instructions:
                STX AND LDX
                --Timing T2
                IF (opcode(4 DOWNTO 2) = "101" AND tcstate(2) = '0' AND (((opcode(7 DOWNTO 5) = "100" OR opcode(7 DOWNTO 5) = "101") AND opcode(1 DOWNTO 0) = "10")))
                    THEN
                    PC <= PC;
                    ABL <= Databus;
                    ABH <= x"00";
                    AI <= unsigned(Y);
                    BI <= unsigned(Databus);
                    Sums <= '1';
                END IF;
                --2) Address Mode: absolute X==> absolute Y; Instruction: LDX
                --Timing T2
                IF (opcode(4 DOWNTO 2) = "111" AND tcstate(2) = '0' AND ((opcode(7 DOWNTO 5) = "101" AND opcode(1 DOWNTO 0) = "10"))) THEN
                    PC <= PC + 1;
                    ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                    ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                    AI <= unsigned(Y);
                    BI <= unsigned(Databus);
                    Sums <= '1';
                END IF;
                --JB0511 To avoid conflict with Arthy's, avoid hex1>=8 and hex2=A.
                IF opcode(1 DOWNTO 0) = "10" AND NOT(opcode(7) = '1' AND opcode(3 DOWNTO 2) = "10") THEN
                    --For all the instructions in this section (cc=10), T0 and
                    T1 has the same behaviors
                    --T0
                    IF tcstate(0) = '0' THEN
                        PC <= PC + 1;
                        ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                        ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                        W_R <= '1';
                        --LDX needs one more operation
                        IF opcode(7 DOWNTO 5) = "101" THEN
                            X <= unsigned(Databus);
                        END IF;
                    END IF;
                    --T1
                    IF tcstate(1) = '0' THEN
                        PC <= PC + 1;
                        ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                        ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                        --LDX affects the flags
                        IF opcode(7 DOWNTO 5) = "101" THEN
                            IF X(7) = '1' THEN
                                P(7) <= '1';
                            ELSE
                                P(7) <= '0';
                            END IF;
                            IF X = x"00" THEN
                                P(1) <= '1';
                            ELSE
                                P(1) <= '0';
                            END IF;
                        END IF;
                    END IF;
                    --Instruction: ASL; aaa: 000; bbb: don't care; cc: 10
                    --SD1
                    IF (opcode(7 DOWNTO 5) = "000" AND SD1 = '1') THEN
                        PC <= PC;
                        ABH <= ABH;
                        ABL <= ABL;
                        AI <= unsigned(Databus); --JB0511 correct? Why is W_R
                        '0' WHILE Databus => DOR?
                        BI <= unsigned(Databus);
                        DOR <= Databus;
                        SUMS <= '1';
                        W_R <= '0';
                        I_ADDC <= '0';
                    END IF;
                    --Instruction: ROL; aaa: 001; bbb: don't care; cc: 10
                    --SD1
                    IF (opcode(7 DOWNTO 5) = "001" AND SD1 = '1') THEN
                        PC <= PC;
                        ABH <= ABH;
                        ABL <= ABL;
                        AI <= unsigned(Databus);
                        BI <= unsigned(Databus);
                        Sums <= '1';
                        I_ADDC <= P(0);
                        DOR <= Databus;
                        W_R <= '0';
                    END IF;
                    --Instruction: LSR; aaa: 010; bbb: don't care; cc: 10
                    --SD1
                    IF (opcode(7 DOWNTO 5) = "010" AND SD1 = '1') THEN
                        PC <= PC;
                        ABH <= ABH;
                        ABL <= ABL;
                        BI <= unsigned(Databus);
                        AI <= x"00";
                        DOR <= STD_LOGIC_VECTOR(ADD);
                        SUMS <= '0';
                        SRS <= '1';
                        W_R <= '0';
                        --ADD(7)<='0';
                    END IF;
                    --SD2
                    IF (opcode(7 DOWNTO 5) = "010" AND SD2 = '1') THEN
                        PC <= PC;
                        ABH <= ABH;
                        ABL <= ABL;
                        DOR <= STD_LOGIC_VECTOR(ADD);
                        I_ADDC <= '0';
                        W_R <= '0';
                        SRS <= '0';
                        IF ADD = x"00" THEN
                            P(1) <= '1';
                        ELSE
                            P(1) <= '0';
                        END IF;
                        IF ACR = '1' THEN
                            P(0) <= '1';
                        ELSE
                            P(0) <= '0';
                        END IF;
                    END IF;
                    --Instruction: ROR; aaa: 011; bbb: don't care; cc: 10
                    --SD1
                    IF (opcode(7 DOWNTO 5) = "011" AND SD1 = '1') THEN
                        PC <= PC;
                        ABH <= ABH;
                        ABL <= ABL;
                        BI <= unsigned(Databus);
                        AI <= x"00";
                        DOR <= Databus;
                        SRS <= '1';
                        W_R <= '0';
                        SUMS <= '0';
                        --ADD(7)<=P(0);
                    END IF;
                    --Instruction ASL or ROL or ROR
                    --SD2
                    IF ((opcode(7 DOWNTO 5) = "011" OR opcode(7 DOWNTO 5) = "000" OR opcode(7 DOWNTO 5) = "001") AND SD2 = '1') THEN
                        PC <= PC;
                        ABH <= ABH;
                        ABL <= ABL;
                        DOR <= STD_LOGIC_VECTOR(ADD);
                        W_R <= '0';
                        SRS <= '0';
                        SUMS <= '0';
                        IF ADD(7) = '1' THEN
                            P(7) <= '1';
                        ELSE
                            P(7) <= '0';
                        END IF;
                        IF ADD = x"00" THEN
                            P(1) <= '1';
                        ELSE
                            P(1) <= '0';
                        END IF;
                        IF ACR = '1' THEN
                            P(0) <= '1';
                        ELSE
                            P(0) <= '0';
                        END IF;
                    END IF;
                    --Instruction: INC; aaa: 111; bbb: don't care; cc: 10
                    --SD1
                    IF (opcode(7 DOWNTO 5) = "111" AND SD1 = '1') THEN
                        PC <= PC;
                        ABH <= ABH;
                        ABL <= ABL;
                        BI <= unsigned(Databus);
                        AI <= x"00";
                        I_ADDC <= '1';
                        SUMS <= '1';
                        DOR <= Databus;
                        W_R <= '0';
                    END IF;
                    --SD2
                    IF (opcode(7 DOWNTO 5) = "111" AND SD2 = '1') THEN
                        PC <= PC;
                        ABH <= ABH;
                        ABL <= ABL;
                        DOR <= STD_LOGIC_VECTOR(ADD);
                        W_R <= '0';
                        I_ADDC <= '0';
                        SUMS <= '0';
                        IF ADD(7) = '1' THEN
                            P(7) <= '1';
                        ELSE
                            P(7) <= '0';
                        END IF;
                        IF ADD = x"00" THEN
                            P(1) <= '1';
                        ELSE
                            P(1) <= '0';
                        END IF;
                    END IF;
                    --Instruction: DEC; aaa: 110; bbb: don't care; cc: 10
                    --SD1
                    IF (opcode(7 DOWNTO 5) = "110" AND SD1 = '1') THEN
                        PC <= PC;
                        ABH <= ABH;
                        ABL <= ABL;
                        BI <= unsigned(Databus);
                        AI <= x"ff";
                        I_ADDC <= '0';
                        DOR <= Databus;
                        W_R <= '0'; --JB0510 W_R=0 signal should happen at the
                        following cycle, NOT WHEN DOR IS loaded??
                        SUMS <= '1';
                    END IF;
                    --SD2
                    IF (opcode(7 DOWNTO 5) = "110" AND SD2 = '1') THEN
                        PC <= PC;
                        ABH <= ABH;
                        ABL <= ABL;
                        DOR <= STD_LOGIC_VECTOR(ADD);
                        W_R <= '0'; --JB0510 W_R=0 signal should happen at the
                        following cycle, NOT WHEN DOR IS loaded??
                        I_ADDC <= '0';
                        SUMS <= '0';
                        IF ADD(7) = '1' THEN
                            P(7) <= '1';
                        ELSE
                            P(7) <= '0';
                        END IF;
                        IF ADD = x"00" THEN
                            P(1) <= '1';
                        ELSE
                            P(1) <= '0';
                        END IF;
                    END IF;
                    --Instruction: STX; aaa: 100; bbb: don't care; cc: 10
                    --Last cycle, write value to memory
                    IF opcode(7 DOWNTO 5) = "100" THEN
                        IF ((opcode(4 DOWNTO 2) = "001" AND tcstate(2) = '0') --
                            zero page
                            OR(opcode(4 DOWNTO 2) = "011" AND tcstate(3) = '0')
                            --absolute
                            OR(opcode(4 DOWNTO 2) = "101" AND tcstate(3) = '0'))
                            --zero page, Y
                            THEN
                            DOR <= STD_LOGIC_VECTOR(X);
                            W_R <= '0'; --JB0510 W_R=0 signal should happen at
                            the following cycle, NOT WHEN DOR IS loaded??
                        END IF;
                    END IF;
                    --Address mode: accumulator cc:10 --JB0511 this lies inside NOT(hex1 >= 8 AND hex2 = A) TO distinguish from Arthy's.
                    IF opcode(4 DOWNTO 2) = "010" THEN
                        --Instruction: ASL aaa=000
                        --T2+T0
                        IF (opcode(7 DOWNTO 5) = "000" AND tcstate = "111010")
                            THEN
                            PC <= PC;
                            ABL <= ABL;
                            ABH <= ABH;
                            AI <= ACC;
                            BI <= ACC;
                            I_ADDC <= '0';
                            SUMS <= '1';
                        END IF;
                        --Instruction: ROL aaa=001
                        --T2+T0
                        IF (opcode(7 DOWNTO 5) = "001" AND tcstate = "111010")
                            THEN
                            PC <= PC;
                            ABL <= ABL;
                            ABH <= ABH;
                            AI <= ACC;
                            BI <= ACC;
                            I_ADDC <= P(0);
                            SUMS <= '1';
                        END IF;
                        --Instruction: LSR or ROR aaa=010 or 011
                        --T2+T0
                        IF ((opcode(7 DOWNTO 5) = "010" OR opcode(7 DOWNTO
                            5) = "011") AND tcstate = "111010") THEN
                            PC <= PC;
                            ABL <= ABL;
                            ABH <= ABH;
                            BI <= ACC;
                            AI <= x"00";
                            SUMS <= '0';
                            SRS <= '1';
                        END IF;
                        --Instruction: ASL or ROL or LSR or ROR
                        --T1
                        IF tcstate(1) = '0' THEN
                            PC <= PC + 1;
                            ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                            ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                            ACC <= ADD;
                            SUMS <= '0';
                            I_ADDC <= '0'; --JB0512
                            W_R <= '1'; --JB0512
                            SRS <= '0';
                            IF ADD(7) = '1' THEN
                                P(7) <= '1';
                            ELSE
                                P(7) <= '0';
                            END IF;
                            IF ADD = x"00" THEN
                                P(1) <= '1';
                            ELSE
                                P(1) <= '0';
                            END IF;
                            IF ACR = '1' THEN
                                P(0) <= '1';
                            ELSE
                                P(0) <= '0';
                            END IF;
                        END IF;
                    END IF;
                END IF;
                --==cc=10 AND aaa=0xx are concerned ends == == == == == == == == == == == == == == == == == == == == == =
                -------------YU's code starts here-------------------------------
                -----
                -------------JAEBIN's code starts here---------------------------
                ---------
                --cc=00
                IF (opcode(1 DOWNTO 0) = "00") THEN
                    ----------branch: xxy10000---------------------------------
                    --------------
                    IF (opcode(4 DOWNTO 2) = "100") THEN --bbb=100 does not
                        overlab WITH anything ELSE
                        .
                        --T2
                        IF (tcstate(2) = '0') THEN
                            PC <= PC + 1;
                            ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                            ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                            BI <= unsigned(Databus);
                            AI <= PC(7 DOWNTO 0);
                            Sums <= '1';
                        END IF;
                        --T1
                        IF tcstate = "111111" THEN --yuchen0514
                            PC <= PC + 1;
                            ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                            ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                            sums <= '0';
                        END IF;
                        --T3
                        IF (tcstate(3) = '0') THEN
                            ABL <= STD_LOGIC_VECTOR(ADD);
                            PC(7 DOWNTO 0) <= ADD + 1;
                            Sums <= '0';
                        END IF;
                        --T0
                        IF (tcstate(0) = '0') THEN
                            PC(15 DOWNTO 8) <= PC(15 DOWNTO 8) + 1;
                            ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8) + 1);
                        END IF;
                        ----------------branch done--------------------------------
                        ---------
                        -----------interrupts: 0xx00000----------------------------
                        ------------
                        --four total, JSR, RTS, BRK, RTI.
                    ELSIF (opcode(4 DOWNTO 2) = "000" AND opcode(7) = '0') THEN
                        --1/4. JSR abs. hex:20
                        IF (opcode(6 DOWNTO 5) = "01") THEN
                            --T2
                            IF (tcstate(2) = '0') THEN
                                S <= unsigned(Databus);
                                ABL <= STD_LOGIC_VECTOR(S);
                                ABH <= x"01";
                                BI <= S;
                                AI <= x"00";
                                Sums <= '1';
                            END IF;
                            --T3
                            IF (tcstate(3) = '0') THEN
                                ABL <= STD_LOGIC_VECTOR(ADD);
                                ABH <= x"01";
                                DOR <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                                BI <= ADD;
                                AI <= x"ff";
                                Sums <= '1';
                            END IF;
                            --T4
                            IF (tcstate(4) = '0') THEN
                                --Databus<=DOR;
                                W_R <= '0';
                                ABL <= STD_LOGIC_VECTOR(ADD);
                                ABH <= x"01";
                                DOR <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                                BI <= ADD;
                                AI <= x"ff";
                                Sums <= '1';
                            END IF;
                            --T5
                            IF (tcstate(5) = '0') THEN
                                --Databus<=DOR;
                                W_R <= '0';
                                PC <= PC + 1;
                                ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                                ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                                BI <= ADD;
                                AI <= x"00";
                                Sums <= '1';
                            END IF;
                            --T0
                            IF (tcstate(0) = '0') THEN
                                W_R <= '1';
                                ABL <= STD_LOGIC_VECTOR(S);
                                ABH <= Databus;
                                PC <= (unsigned(Databus) & S) + 1;
                                S <= ADD;
                                Sums <= '0';
                            END IF;
                            --T1
                            IF (tcstate(1) = '0') THEN
                                PC <= PC + 1;
                                ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                                ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                                Sums <= '0';
                            END IF;
                        END IF;
                        ----2/4. RTS. hex:60
                        IF (opcode(6 DOWNTO 5) = "11") THEN
                            --T2
                            IF (tcstate(2) = '0') THEN
                                ABL <= STD_LOGIC_VECTOR(S);
                                ABH <= x"01";
                                BI <= S;
                                AI <= x"00";
                                I_ADDC <= '1';
                                Sums <= '1';
                            END IF;
                            --T3
                            IF (tcstate(3) = '0') THEN
                                ABL <= STD_LOGIC_VECTOR(ADD);
                                ABH <= x"01";
                                BI <= ADD;
                                AI <= x"00";
                                I_ADDC <= '1';
                                Sums <= '1';
                            END IF;
                            --T4
                            IF (tcstate(4) = '0') THEN
                                ABL <= STD_LOGIC_VECTOR(ADD);
                                ABH <= x"01";
                                S <= ADD;
                                I_ADDC <= '0';
                                Sums <= '0';
                            END IF;
                            --T5
                            IF (tcstate(5) = '0') THEN
                                ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                                ABH <= Databus;
                                PC <= (unsigned(Databus) & PC(7 DOWNTO 0)) + 1;
                                Sums <= '0';
                            END IF;
                            --T0
                            IF (tcstate(0) = '0') THEN
                                PC <= PC + 1;
                                ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                                ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                                Sums <= '0';
                            END IF;
                            --T1
                            IF (tcstate(1) = '0') THEN
                                PC <= PC + 1;
                                ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                                ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                                Sums <= '0';
                            END IF;
                        END IF;
                        ----4/4. RTI. hex:40
                        IF (opcode(6 DOWNTO 5) = "10") THEN
                            --T2
                            IF (tcstate(2) = '0') THEN
                                ABL <= STD_LOGIC_VECTOR(S);
                                ABH <= x"01";
                                BI <= S;
                                AI <= x"00";
                                I_ADDC <= '1';
                                Sums <= '1';
                            END IF;
                            --T3
                            IF (tcstate(3) = '0') THEN
                                ABL <= STD_LOGIC_VECTOR(ADD);
                                ABH <= x"01";
                                BI <= ADD;
                                AI <= x"00";
                                I_ADDC <= '1';
                                Sums <= '1';
                            END IF;
                            --T4
                            IF (tcstate(4) = '0') THEN
                                P <= unsigned(Databus);
                                ABL <= STD_LOGIC_VECTOR(ADD);
                                ABH <= x"01";
                                BI <= ADD;
                                AI <= x"00";
                                I_ADDC <= '1';
                                Sums <= '1';
                            END i
                            IF (tcstate(5) = '0') THEN
                                PC(7 DOWNTO 0) <= unsigned(Databus);
                                ABL <= STD_LOGIC_VECTOR(ADD);
                                ABH <= x"01";
                                S <= ADD;
                                I_ADDC <= '0';
                                Sums <= '0';
                            END IF;
                            --T0
                            IF (tcstate(0) = '0') THEN
                                ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                                ABH <= Databus;
                                PC <= (unsigned(Databus) & PC(7 DOWNTO 0)) + 1;
                                Sums <= '0';
                            END IF;
                            --T1
                            IF (tcstate(1) = '0') THEN
                                PC <= PC + 1;
                                ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                                ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                                Sums <= '0';
                            END IF;
                        END IF;
                        ---------the rest of cc=00, excluding branch and interrupt----------------
                        --no overlap with Arthy's, because Arthy's only have
                        bbb = 010 AND bbb = 110.
                    ELSE
                        --1.bbb=000 AND aaa=1xx. immediate.
                        IF (opcode(4 DOWNTO 2) = "000" AND opcode(7) = '1') THEN
                            --T0
                            IF (tcstate(2) = '0') THEN
                                PC <= PC + 1;
                                ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                                ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                            END IF;
                            --T1
                            IF (tcstate(1) = '0') THEN
                                PC <= PC + 1;
                                ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                                ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                                Sums <= '0';
                            END IF;
                        END IF;
                        --2.bbb=001. zeropage. common to all aaa within cc=00
                        IF (opcode(4 DOWNTO 2) = "001") THEN
                            --T2
                            IF (tcstate(2) = '0') THEN
                                ABL <= Databus;
                                ABH <= x"00";
                                Sums <= '0';
                            END IF;
                            --both T0 and T1
                            IF (tcstate(0) = '0'OR tcstate(1) = '0') THEN
                                PC <= PC + 1;
                                ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                                ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                                Sums <= '0';
                            END IF;
                        END IF;
                        ---3.bbb=011. absolute. exceptions to JMP ABS(aaa=010)
                        AND JMP IND(aaa = 011)
                        ---exception 1/2: JMP ABS. bbb=011, aaa=010
                        IF (opcode(4 DOWNTO 2) = "011" AND opcode(7 DOWNTO
                            5) = "010") THEN
                            --T2
                            IF (tcstate(2) = '0') THEN
                                ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                                ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                                PC(7 DOWNTO 0) <= unsigned(Databus);
                                Sums <= '0';
                            END IF;
                            --T0
                            IF (tcstate(0) = '0') THEN
                                ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                                ABH <= Databus;
                                PC <= (unsigned(Databus) & PC(7 DOWNTO 0)) + 1;
                                Sums <= '0';
                            END IF;
                            --T1
                            IF (tcstate(1) = '0') THEN
                                PC <= PC + 1;
                                ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                                ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                                Sums <= '0';
                            END IF;
                        END IF;
                        ---exception 2/2: JMP IND. bbb=011, aaa=011
                        IF (opcode(4 DOWNTO 2) = "011" AND opcode(7 DOWNTO
                            5) = "011") THEN
                            --both T2 and T4
                            IF (tcstate(2) = '0' OR tcstate(4) = '0') THEN
                                ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                                ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                                PC(7 DOWNTO 0) <= unsigned(Databus);
                                Sums <= '0';
                            END IF;
                            --both T3 and T0
                            IF (tcstate(3) = '0' AND tcstate(0) = '0') THEN
                                ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                                ABH <= Databus;
                                PC <= (unsigned(Databus) & PC(7 DOWNTO 0)) + 1;
                            END IF;
                            --T1
                            IF (tcstate(1) = '0') THEN
                                PC <= PC + 1;
                                ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                                ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                            END IF;
                        END IF;
                        ---the rest of bbb=011 absolute.
                        IF (opcode(4 DOWNTO 2) = "011" AND NOT(opcode(7 DOWNTO
                            5) = "010") AND NOT(opcode(7 DOWNTO 5) = "011")) THEN
                            --T2
                            IF (tcstate(2) = '0') THEN
                                PC <= PC + 1;
                                ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                                ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                                BI <= unsigned(Databus);
                                AI <= x"00";
                                Sums <= '1';
                            END IF;
                            --T3
                            IF (tcstate(3) = '0') THEN
                                ABH <= Databus;
                                ABL <= STD_LOGIC_VECTOR(ADD);
                                Sums <= '0';
                            END IF;
                            --T0
                            IF (tcstate(0) = '0') THEN
                                PC <= PC + 1;
                                ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                                ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                                Sums <= '0';
                            END IF;
                            --T1
                            IF (tcstate(1) = '0') THEN
                                PC <= PC + 1;
                                ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                                ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                                Sums <= '0';
                            END IF;
                        END IF;
                        ---4.bbb=101. zeropage,X. common to all aaa within
                        cc = 00
                        IF (opcode(4 DOWNTO 2) = "101") THEN
                            --T2
                            IF (tcstate(2) = '0') THEN
                                BI <= unsigned(Databus);
                                AI <= unsigned(X);
                                Sums <= '1';
                            END IF;
                            --T3
                            IF (tcstate(3) = '0') THEN
                                ABL <= STD_LOGIC_VECTOR(ADD);
                                ABH <= x"00";
                                Sums <= '0';
                            END IF;
                            --T0
                            IF (tcstate(0) = '0') THEN
                                PC <= PC + 1;
                                ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                                ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                                Sums <= '0';
                            END IF;
                            --T1
                            IF (tcstate(1) = '0') THEN
                                PC <= PC + 1;
                                ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                                ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                                Sums <= '0';
                            END IF;
                        END IF;
                        ---5.bbb=111. absolute,X. common to all aaa within
                        cc = 00
                        IF (opcode(4 DOWNTO 2) = "111") THEN
                            --T2
                            IF (tcstate(2) = '0') THEN
                                PC <= PC + 1;
                                ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                                ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                                BI <= unsigned(Databus);
                                AI <= unsigned(X);
                                Sums <= '1';
                                IF opcode(7 DOWNTO 5) = "100" THEN
                                    Mask_shortcut <= '1';--Yuchen
                                END IF;
                            END IF;
                            --T3
                            IF (tcstate(3) = '0') THEN
                                ABH <= Databus;
                                ABL <= STD_LOGIC_VECTOR(ADD);
                                BI <= unsigned(Databus);
                                I_ADDC <= ACR;
                                Mask_shortcut <= '0';--Yuchen
                            END IF;
                            --T4
                            IF (tcstate(4) = '0') THEN
                                ABH <= STD_LOGIC_VECTOR(ADD);
                                Sums <= '0';
                            END IF;
                            --T0
                            IF (tcstate(0) = '0') THEN
                                PC <= PC + 1;
                                ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                                ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                                Sums <= '0';
                            END IF;
                            --T1
                            IF (tcstate(1) = '0') THEN
                                PC <= PC + 1;
                                ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                                ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                            END IF;
                        END IF;
                        ------------bbb taken care of. now aaa.---------------
                        ------------------
                        ---1.aaa=101. LDY. common to all bbb within cc=00
                        IF (opcode(7 DOWNTO 5) = "101") THEN
                            --T0
                            IF (tcstate(0) = '0') THEN
                                Y <= unsigned(Databus);
                                BI <= unsigned(Databus);
                                AI <= x"00";
                                Sums <= '1';
                            END IF;
                            --T1
                            IF (tcstate(1) = '0') THEN
                                P(7) <= ADD(7); --JB set N. P is the
                                processor status REGISTER (1 byte)
                                IF ADD = x"00" THEN
                                    P(1) <= '1';
                                ELSE
                                    P(1) <= '0';
                                END IF;
                            END IF;
                        END IF;
                        ---2.aaa=111. CPX. common to all bbb within cc=00
                        IF (opcode(7 DOWNTO 5) = "111") THEN
                            --T0
                            IF (tcstate(0) = '0') THEN
                                BI <= NOT(unsigned(Databus)); --JB0511 need
                                TO invert!!!!!!!!!!!!
                                AI <= unsigned(X);
                                Sums <= '1';
                                I_ADDC <= '1'; --yuchen0513
                            END IF;
                            --T1
                            IF (tcstate(1) = '0') THEN
                                P(7) <= ADD(7);
                                IF ADD = x"00" THEN
                                    P(1) <= '1';
                                ELSE
                                    P(1) <= '0';
                                END IF;
                                P(0) <= ACR;
                                Sums <= '0';
                                I_ADDC <= '0'; --yuchen0513
                            END IF;
                        END IF;
                        ---3.aaa=110. CPY. common to all bbb within cc=00
                        IF (opcode(7 DOWNTO 5) = "110") THEN
                            --T0
                            IF (tcstate(0) = '0') THEN
                                BI <= unsigned(NOT(Databus)); --JB0511 need
                                TO invert!!!!!!!!!!!!
                                AI <= unsigned(Y);
                                Sums <= '1';
                                I_ADDC <= '1'; --yuchen0513
                            END IF;
                            --T1
                            IF (tcstate(1) = '0') THEN
                                P(7) <= ADD(7);
                                IF ADD = x"00" THEN
                                    P(1) <= '1';
                                ELSE
                                    P(1) <= '0';
                                END IF;
                                P(0) <= ACR;
                                Sums <= '0';
                                I_ADDC <= '0'; --yuchen0513
                            END IF;
                        END IF;
                        ---4.aaa=001. BIT. common to all bbb within cc=00
                        IF (opcode(7 DOWNTO 5) = "001") THEN
                            --T0
                            IF (tcstate(0) = '0') THEN
                                BI <= unsigned(Databus);
                                AI <= ACC;
                                Sums <= '1';
                            END IF;
                            --T1
                            IF (tcstate(1) = '0') THEN
                                P(7) <= ADD(7);
                                IF ADD = x"00" THEN
                                    P(1) <= '1';
                                ELSE
                                    P(1) <= '0';
                                END IF;
                                P(0) <= ACR;
                                Sums <= '0';
                            END IF;
                        END IF;
                        ---5.aaa=100. STY. common to all bbb within cc=00
                        IF (opcode(7 DOWNTO 5) = "100") THEN
                            --both T2 and T3
                            IF (tcstate(2) = '0' OR tcstate(3) = '0') THEN --JB
                                Y -> DOR happenes at T2 IN zeropage, AND at T3 IN the rest.
                                DOR <= STD_LOGIC_VECTOR(Y);
                            END IF;
                            --T0
                            IF (tcstate(0) = '0') THEN
                                --Databus<=DOR;
                                W_R <= '0';
                            END IF;
                            --T1
                            IF (tcstate(0) = '0') THEN
                                Sums <= '0';
                                W_R <= '1';
                            END IF;
                        END IF;
                        ----------------------------aaa taken care of.-------------
                        --------------------
                    END IF;
                END IF;
                -----------------------------JAEBIN's code ends here-------------
                -----------------
                --------------------------ARTHY's code starts here--------------------------
                --
                --========================= SINGLE BYTE INSTRUCTIONS == == BEGIN == == == == ==
                --NOP
                IF (opcode(7 DOWNTO 0) = x"EA") THEN
                    --if(tcstate(2) = '0') then --JB0511 deleted "and tcstate(0)= '0'"
                    --PC <= PC; -- this also not required
                    --end if;
                    IF (tcstate(1) = '0') THEN
                        PC <= PC + 1;
                        ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                        ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                    END IF;
                END IF; --NOP ends.
                --PHA/PLA/PHP/PLP
                IF ((opcode(7 DOWNTO 0) = x"48") OR (opcode(7 DOWNTO 0) = x"68")
                    OR (opcode(7 DOWNTO 0) = x"08") OR
                    (opcode(7 DOWNTO 0) = x"28")) THEN --PHA/PLA/PHP/PLP
                    --T2
                    IF (tcstate(2) = '0') THEN
                        PC <= PC - 1; --JB0511 PC-1?????
                        ABL <= STD_LOGIC_VECTOR(S(7 DOWNTO 0));
                        ABH <= x"01";
                        BI <= S;
                        SUMS <= '1';
                        -- Push PHA / PHP
                        IF (opcode(5) = '0') THEN --subtract.
                            AI <= x"ff";
                            W_R <= '0';
                            IF (opcode(6) = '1') THEN
                                -- PHA put the acc onto databus
                                DOR <= STD_LOGIC_VECTOR(ACC);
                            ELSE
                                -- (opcode(6) == '0') then
                                -- PHP put the status reg unto db
                                DOR <= STD_LOGIC_VECTOR(P);
                            END IF;
                            -- Pull PLA / PLP
                        ELSE --sum.
                            AI <= x"01";
                        END IF;
                    END IF;
                    --T3
                    IF (tcstate(3) = '0') THEN -- assume only PLA and PLP get
                        here
                        W_R <= '1'; -- back to read
                        PC <= PC;
                        S <= ADD;
                        SUMS <= '0';
                        ABL <= STD_LOGIC_VECTOR(ADD);
                        ABH <= x"01";
                    END IF;
                    --T0
                    IF (tcstate(0) = '0') THEN
                        ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                        ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                        PC <= PC + 1;
                        --PLA/PLP
                        IF (opcode(5) = '1') THEN
                            --PLA
                            IF (opcode(6) = '1') THEN
                                ACC <= unsigned(Databus);
                                IF (ACC = 0) THEN
                                    P(1) <= '1'; --set zero flag
                                END IF;
                                P(7) <= ACC(7); -- set negative flag
                                --PLP
                            ELSIF (opcode(6) = '0') THEN
                                P <= unsigned(Databus);
                            END IF;
                            --PHA/PHP
                        ELSIF (opcode(5) = '0') THEN
                            --SUBS <= '1'; --JB0511 Subtracts WHAT? Nothing
                            goes IN TO AI OR BI.
                            S <= ADD;
                            W_R <= '1'; -- read
                        END IF;
                    END IF;
                    --T1
                    IF (tcstate(1) = '0') THEN -- PHA/PHP/PLA/PLP
                        ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                        ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                        PC <= PC + 1;
                    END IF;
                END IF; --PHA/PLA/PHP/PLP end.
                -- INX, INY, DEX, DEY
                --1/4 DEX: CA
                IF opcode (7 DOWNTO 0) = x"CA" THEN
                    --T2+T0
                    IF (tcstate(2) = '0') THEN
                        SUMS <= '1';
                        BI <= X;
                        AI <= x"ff";
                    END IF;
                    --T1
                    IF (tcstate(1) = '0') THEN
                        ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                        ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                        PC <= PC + 1;
                        IF (ADD = 0) THEN
                            P(1) <= '1'; --Z flag
                        END IF;
                        P(7) <= ADD(7); --N flag
                        X <= ADD;
                        SUMS <= '0';
                    END IF;
                END IF;
                --2/4 INX: E8
                IF opcode (7 DOWNTO 0) = x"E8" THEN
                    --T2+T0
                    IF (tcstate(2) = '0') THEN
                        SUMS <= '1';
                        BI <= X;
                        AI <= x"01";
                        I_ADDC <= '0'; --yuchen0514
                    END IF;
                    --T1
                    IF (tcstate(1) = '0') THEN
                        ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                        ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                        PC <= PC + 1;
                        IF (ADD = 0) THEN
                            P(1) <= '1'; --Z flag
                        END IF;
                        P(7) <= ADD(7); --N flag
                        X <= ADD;
                        SUMS <= '0';
                        I_ADDC <= '0'; --yuchen0514
                    END IF;
                END IF;
                --3/4 DEY: 88
                IF opcode (7 DOWNTO 0) = x"88" THEN
                    --T2+T0
                    IF (tcstate(2) = '0') THEN
                        SUMS <= '1';
                        BI <= Y;
                        AI <= x"ff";
                    END IF;
                    --T1
                    IF (tcstate(1) = '0') THEN
                        ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                        ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                        PC <= PC + 1;
                        IF (ADD = 0) THEN
                            P(1) <= '1'; --Z flag
                        END IF;
                        P(7) <= ADD(7); --N flag
                        Y <= ADD;
                        SUMS <= '0';
                    END IF;
                END IF;
                --4/4 INY: C8
                IF opcode (7 DOWNTO 0) = x"c8" THEN --yuchen0514
                    --T2+T0
                    IF (tcstate(2) = '0') THEN
                        SUMS <= '1';
                        BI <= Y;
                        AI <= x"01";
                        I_ADDC <= '0'; --yuchen0514
                    END IF;
                    --T1
                    IF (tcstate(1) = '0') THEN
                        ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                        ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                        PC <= PC + 1;
                        IF (ADD = 0) THEN
                            P(1) <= '1'; --Z flag
                        END IF;
                        P(7) <= ADD(7); --N flag
                        Y <= ADD;
                        SUMS <= '0';
                        I_ADDC <= '0'; --yuchen0514
                    END IF;
                END IF;
                -- INX, INY, DEX, DEY ends.
                --Register instructions
                IF opcode(4 DOWNTO 2) = "110" AND opcode(0) = '0' THEN
                    --T2 + T0
                    IF tcstate(2) = '0' THEN --JB0511 deleted "and tcstate(0) ='0'"
                        --PC <= PC;
                        CASE opcode(7 DOWNTO 5)IS
                            WHEN "000" => P(0) <= '0'; -- CLC
                            WHEN "001" => P(0) <= '1'; -- SEC
                            WHEN "010" => P(2) <= '0'; ---CLI
                            WHEN "011" => P(2) <= '1'; -- SEI
                            WHEN "101" => P(6) <= '0'; -- CLV
                            WHEN "110" => P(3) <= '0'; -- CLD
                            WHEN "111" => P(3) <= '1'; -- SED
                            WHEN OTHERS => NULL;
                        END CASE;
                    END IF;
                    --T1
                    IF (tcstate(1) = '0') THEN
                        ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                        ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                        PC <= PC + 1;
                    END IF;
                END IF; --Register instructions end.
                -- Transfer instructions
                IF ((opcode (7 DOWNTO 0) = x"8A") OR (opcode (7 DOWNTO 0) = x"9A")
                    OR
                    (opcode (7 DOWNTO 0) = x"AA") OR (opcode (7 DOWNTO 0) =
                    x"BA") OR
                    (opcode (7 DOWNTO 0) = x"98") OR (opcode (7 DOWNTO 0) =
                    x"A8")) THEN
                    --T2 + T0
                    IF (tcstate(2) = '0') THEN --JB0511 removed "and tcstate(0)='0'"
                        --PC <= PC;
                        IF ((opcode (7 DOWNTO 0)) = x"8A") THEN -- TXA
                            ACC <= X;
                            IF (X = 0) THEN
                                P(1) <= '1';
                            END IF;
                            P(7) <= X(7);
                        END IF;
                        IF ((opcode (7 DOWNTO 0)) = x"9A") THEN --TXS
                            S <= X;
                        END IF;
                        IF ((opcode (7 DOWNTO 0)) = x"AA") THEN -- TAX
                            X <= ACC;
                            IF (ACC = 0) THEN
                                P(1) <= '1';
                            END IF;
                            P(7) <= ACC(7);
                        END IF;
                        IF ((opcode (7 DOWNTO 0)) = x"BA") THEN -- TSX
                            X <= S;
                            IF (S = 0) THEN
                                P(1) <= '1';
                            END IF;
                            P(7) <= S(7);
                        END IF;
                        IF ((opcode (7 DOWNTO 0)) = x"98") THEN --TYA
                            ACC <= Y;
                            IF (Y = 0) THEN
                                P(1) <= '1';
                            END IF;
                            P(7) <= Y(7);
                        END IF;
                        IF ((opcode (7 DOWNTO 0)) = x"A8") THEN -- TAY
                            Y <= ACC; --TAY
                            IF (ACC = 0) THEN
                                P(1) <= '1';
                            END IF;
                            P(7) <= ACC(7);
                        END IF;
                    END IF;
                    --T1
                    IF (tcstate(1) = '0') THEN
                        ABL <= STD_LOGIC_VECTOR(PC(7 DOWNTO 0));
                        ABH <= STD_LOGIC_VECTOR(PC(15 DOWNTO 8));
                        PC <= PC + 1;
                    END IF;
                END IF; -- Transfer instructions end.
                -----------------------------Arthy's code ends here--------------
                ----------------------
            END IF; --clk rising edge
        END IF; --reset
    END PROCESS;

    --branch conditions are judged combinationally so that it can supply information TO TG ON TIME.
    PROCESS (opcode, P)
    BEGIN
        IF (opcode(1 DOWNTO 0) = "00") THEN
            --------------------------------branch: xxy10000-----------
            ------------------------------------
            IF (opcode(4 DOWNTO 2) = "100") THEN --bbb=100 does not
                overlab WITH anything ELSE
                .
                -- xx=00. N flag. P(7)
                IF ((opcode(7 DOWNTO 6) = "00" AND P(7) = opcode(5)) OR -- xx=00. N flag. P(7)
                    (opcode(7 DOWNTO 6) = "01" AND P(6) = opcode(5)) OR -- xx=01. V(O) flag. P(6)
                    (opcode(7 DOWNTO 6) = "10" AND P(0) = opcode(5)) OR -- xx=10. C flag. P(0)
                    (opcode(7 DOWNTO 6) = "11" AND P(1) = opcode(5))) -- xx=11. Z flag. P(1)
                    THEN
                    BRC <= '1';
                ELSE
                    BRC <= '0'; --yuchen 0514
                END IF;
            ELSE
                BRC <= '0'; --yuchen 0514
            END IF;
        ELSE
            BRC <= '0'; --yuchen 0514
        END IF;
    END PROCESS;
    PROCESS (ABH, ABL, ACC, X, Y, P)
    BEGIN
        ABH_out <= ABH;
        ABL_out <= ABL;
        ACC_out <= STD_LOGIC_VECTOR(ACC);
        X_out <= STD_LOGIC_VECTOR(X);
        Y_out <= STD_LOGIC_VECTOR(Y);
        P_out <= STD_LOGIC_VECTOR(P);
    END PROCESS;
END rtl;