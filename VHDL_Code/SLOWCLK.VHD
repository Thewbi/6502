LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

--the delay settings has been changed to enable efficient simulations.
--25 bits for ~1/3sec
--26 bits for slower

ENTITY slowclk IS
    PORT (
        clkin : IN STD_LOGIC;
        clkout : OUT STD_LOGIC
    );
END slowclk;
ARCHITECTURE imp OF slowclk IS
    SIGNAL cur : STD_LOGIC := '0';
    SIGNAL count : unsigned(12 DOWNTO 0) := (OTHERS => '0');
BEGIN
    detect : PROCESS (clkin)
    BEGIN
        IF rising_edge(clkin) THEN
            count <= count + 1;
            IF count(12) = '1' THEN
                count <= (OTHERS => '0'); -- reset count.
                cur <= NOT(cur);
                clkout <= cur;
            END IF;
        END IF;
    END PROCESS detect;
END imp;