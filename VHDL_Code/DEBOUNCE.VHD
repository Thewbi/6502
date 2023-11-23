LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

--the delay settings has been changed to enable efficient simulations.
--original settings for the board: 24 bits for 'count'
--new settings for simulation: 7 bits for 'count'
ENTITY debounce IS
    PORT (
        clk, resetsw : IN STD_LOGIC;
        resetout : OUT STD_LOGIC
    );
END debounce;
ARCHITECTURE imp OF debounce IS
    SIGNAL count : unsigned(23 DOWNTO 0) := (OTHERS => '0');
    SIGNAL rout_buf : STD_LOGIC := '0';
BEGIN
    detect : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            --0 to 1 transition of resetsw
            IF rout_buf = '0' AND resetsw = '1' THEN
                count <= count + 1;
                IF count(23) = '1' THEN
                    rout_buf <= '1';
                    resetout <= '1';
                    count <= (OTHERS => '0'); -- reset count.
                END IF;
            END IF;
            --1 to 0 transition of resetsw
            IF rout_buf = '1' AND resetsw = '0' THEN
                count <= count + 1;
                IF count(23) = '1' THEN
                    rout_buf <= '0';
                    resetout <= '0';
                    count <= (OTHERS => '0'); -- reset count.
                END IF;
            END IF;
        END IF;
    END PROCESS detect;
END imp;