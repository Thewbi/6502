LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

-- Provides the unsigned type
ENTITY hex7seg IS
    PORT (
        input : IN STD_LOGIC_VECTOR(3 DOWNTO 0); -- A number
        output : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)); -- Just bits
END hex7seg;
ARCHITECTURE combinational OF hex7seg IS
BEGIN
    WITH input SELECT output <=
        "1000000" WHEN x"0",
        "1111001" WHEN x"1",
        "0100100" WHEN x"2",
        "0110000" WHEN x"3",
        "0011001" WHEN x"4",
        "0010010" WHEN x"5",
        "0000010" WHEN x"6",
        "1111000" WHEN x"7",
        "0000000" WHEN x"8",
        "0010000" WHEN x"9",
        "0001000" WHEN x"A",
        "0000011" WHEN x"B",
        "1000110" WHEN x"C",
        "0100001" WHEN x"D",
        "0000110" WHEN x"E",
        "0001110" WHEN x"F",
        "XXXXXXX" WHEN OTHERS
        ;
END combinational;