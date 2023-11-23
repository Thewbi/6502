LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY SixFiveO2 IS
    PORT (
        Databus : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        Addrbus : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        DOR, P, X_Reg_out, Y_Reg_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        reset, clk : IN STD_LOGIC;
        XL, XH, YL, YH, ACCL, ACCH : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        W_R : OUT STD_LOGIC);
END SixFiveO2;

ARCHITECTURE imp OF SixFiveO2 IS
    SIGNAL instruction, opcode : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL tcstate : STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL cycle_number : unsigned(3 DOWNTO 0);
    SIGNAL BRC, ACR, RMW, SYNC, SD1, SD2, VEC1 : STD_LOGIC;
    --signal DOR, databus : std_logic_vector(7 downto 0);
    --signal Addrbus: std_logic_vector(15 downto 0);
    SIGNAL ACC_Reg, X_Reg, Y_Reg : STD_LOGIC_VECTOR(7 DOWNTO 0);
    COMPONENT Predecode
        PORT (
            databus : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            reset : IN STD_LOGIC;
            cycle_number : OUT unsigned(3 DOWNTO 0);
            Instruction : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            RMW : OUT STD_LOGIC);
    END COMPONENT;
    COMPONENT DFlipFlop
        PORT (
            input : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            enable : IN STD_LOGIC;
            clk : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            output : OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
    END COMPONENT;
    COMPONENT TG
        PORT (
            clk : IN STD_LOGIC;
            cycle_number : IN unsigned(3 DOWNTO 0);
            RMW : IN STD_LOGIC; --read-modify-write instruction
            ACR : IN STD_LOGIC; --carry in from ALU
            BRC : IN STD_LOGIC; --branch flag
            reset : IN STD_LOGIC;
            tcstate : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
            SYNC, SD1, SD2 : OUT STD_LOGIC;
            VEC1 : OUT STD_LOGIC);
    END COMPONENT;
    COMPONENT CPU
        PORT (
            clk, SD1, SD2, reset, VEC1 : IN STD_LOGIC;
            opcode : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            tcstate : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
            databus : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            ACR_out, W_R, BRC : OUT STD_LOGIC;
            ABL_out, ABH_out, DOR, X_out, Y_out, ACC_out, P_out : OUT
            STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;
    --component Memory
    -- port (
    -- clk, reset : in std_logic;
    -- we : in std_logic;
    -- address : in std_logic_vector(15 downto 0);
    -- di : in std_logic_vector(7 downto 0);
    -- do : out std_logic_vector(7 downto 0)
    -- );
    --end component;
    COMPONENT hex7seg
        PORT (
            input : IN STD_LOGIC_VECTOR(3 DOWNTO 0); -- A number
            output : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)); -- Just bits
    END COMPONENT;
BEGIN
    PredecodeLogic : Predecode PORT MAP(
        databus => databus, reset => reset,
        cycle_number => cycle_number, Instruction => Instruction, RMW => RMW);

    IR : DFlipFlop PORT MAP(
        input => instruction, enable => SYNC, clk => clk,
        reset => reset, output => opcode);

    Timing : TG PORT MAP(
        clk => clk, cycle_number => cycle_number, RMW => RMW, ACR => ACR,
        BRC => BRC, reset => reset, tcstate => tcstate, SYNC => SYNC, SD1 => SD1, SD2 => SD2,
        VEC1 => VEC1);

    Core : CPU PORT MAP(
        BRC => BRC, clk => clk, SD1 => SD1, SD2 => SD2, VEC1 => VEC1,
        reset => reset, opcode => opcode, tcstate => tcstate, databus => databus,
        ABL_out => Addrbus(7 DOWNTO 0),
        ABH_out => Addrbus(15 DOWNTO 8), DOR => DOR, ACR_out => ACR,
        W_R => W_R, X_out => X_Reg, Y_out => Y_Reg, ACC_out => ACC_Reg, P_out => P);

    --Mem: Memory port map(clk=>clk, reset=>reset, we=>W_R, address=>Addrbus, di => DOR, do => databus);

    XHDis : hex7seg PORT MAP(input => X_Reg(7 DOWNTO 4), output => XH);

    XLDis : hex7seg PORT MAP(input => X_Reg(3 DOWNTO 0), output => XL);

    YHDis : hex7seg PORT MAP(input => Y_Reg(7 DOWNTO 4), output => YH);

    YLDis : hex7seg PORT MAP(input => Y_Reg(3 DOWNTO 0), output => YL);

    ACCHDis : hex7seg PORT MAP(input => ACC_Reg(7 DOWNTO 4), output => ACCH);

    ACCLDis : hex7seg PORT MAP(input => ACC_Reg(3 DOWNTO 0), output => ACCL);

    PROCESS (X_Reg, Y_Reg)
    BEGIN
        X_Reg_out <= X_Reg;
        Y_Reg_out <= Y_Reg;
    END PROCESS;
END imp;