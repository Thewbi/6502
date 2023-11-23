----------------------------------------------------------------------------
---
--
-- Simple VGA raster display
--
-- Stephen A. Edwards
-- sedwards@cs.columbia.edu
--
----------------------------------------------------------------------------
---
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY de2_vga_raster IS

    PORT (
        reset : IN STD_LOGIC;
        clk : IN STD_LOGIC; -- Should be 25.125 MHz
        center : IN STD_LOGIC_VECTOR(15 DOWNTO 0) := X"f0f0"; -- circle center
        --chipselect : in std_logic;
        --write : in std_logic;
        --address : in std_logic_vector(17 downto 0);
        --readdata : out std_logic_vector(15 downto 0);
        --writedata : in std_logic_vector(15 downto 0);
        VGA_CLK, -- Clock
        VGA_HS, -- H_SYNC
        VGA_VS, -- V_SYNC
        VGA_BLANK, -- BLANK
        VGA_SYNC : OUT STD_LOGIC; -- SYNC
        VGA_R, -- Red[9:0]
        VGA_G, -- Green[9:0]
        VGA_B : OUT unsigned(9 DOWNTO 0) -- Blue[9:0]
    );
END de2_vga_raster;
ARCHITECTURE rtl OF de2_vga_raster IS

    -- Video parameters
    CONSTANT HTOTAL : INTEGER := 800;
    CONSTANT HSYNC : INTEGER := 96;
    CONSTANT HBACK_PORCH : INTEGER := 48;
    CONSTANT HACTIVE : INTEGER := 640;
    CONSTANT HFRONT_PORCH : INTEGER := 16;

    CONSTANT VTOTAL : INTEGER := 525;
    CONSTANT VSYNC : INTEGER := 2;
    CONSTANT VBACK_PORCH : INTEGER := 33;
    CONSTANT VACTIVE : INTEGER := 480;
    CONSTANT VFRONT_PORCH : INTEGER := 10;
    --constant RECTANGLE_HSTART : integer := 100;
    --constant RECTANGLE_HEND : integer := 240;
    --constant RECTANGLE_VSTART : integer := 100;
    --constant RECTANGLE_VEND : integer := 180;

    -- Signals related to ball drawing
    CONSTANT RADIUS : INTEGER := 10; --radius of the ball
    CONSTANT Hinitial : INTEGER := 400; --initial x value of the center of the ball
    CONSTANT Vinitial : INTEGER := 263; --initial y value of the center of the ball

    -- Signals for the video controller
    SIGNAL Hcount : unsigned(9 DOWNTO 0); -- Horizontal position (0-800)
    SIGNAL Vcount : unsigned(9 DOWNTO 0); -- Vertical position (0-524)
    SIGNAL EndOfLine, EndOfField : STD_LOGIC;
    SIGNAL vga_hblank, vga_hsync, vga_vblank, vga_vsync : STD_LOGIC; -- Sync. signals
    SIGNAL rectangle_h, rectangle_v, rectangle : STD_LOGIC; -- rectangle area

    -- signal center_in : unsigned(31 downto 0) := X"008000c0";
BEGIN
    -- Horizontal and vertical counters
    HCounter : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF reset = '1' THEN
                Hcount <= (OTHERS => '0');
            ELSIF EndOfLine = '1' THEN
                Hcount <= (OTHERS => '0');
            ELSE
                Hcount <= Hcount + 1;
            END IF;
        END IF;
    END PROCESS HCounter;
    EndOfLine <= '1' WHEN Hcount = HTOTAL - 1 ELSE
        '0';

    VCounter : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF reset = '1' THEN
                Vcount <= (OTHERS => '0');
            ELSIF EndOfLine = '1' THEN
                IF EndOfField = '1' THEN
                    Vcount <= (OTHERS => '0');
                ELSE
                    Vcount <= Vcount + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS VCounter;
    EndOfField <= '1' WHEN Vcount = VTOTAL - 1 ELSE
        '0';
    -- State machines to generate HSYNC, VSYNC, HBLANK, and VBLANK
    HSyncGen : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF reset = '1' OR EndOfLine = '1' THEN
                vga_hsync <= '1';
            ELSIF Hcount = HSYNC - 1 THEN
                vga_hsync <= '0';
            END IF;
        END IF;
    END PROCESS HSyncGen;

    HBlankGen : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF reset = '1' THEN
                vga_hblank <= '1';
            ELSIF Hcount = HSYNC + HBACK_PORCH THEN
                vga_hblank <= '0';
            ELSIF Hcount = HSYNC + HBACK_PORCH + HACTIVE THEN
                vga_hblank <= '1';
            END IF;
        END IF;
    END PROCESS HBlankGen;
    VSyncGen : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF reset = '1' THEN
                vga_vsync <= '1';
            ELSIF EndOfLine = '1' THEN
                IF EndOfField = '1' THEN
                    vga_vsync <= '1';
                ELSIF Vcount = VSYNC - 1 THEN
                    vga_vsync <= '0';
                END IF;
            END IF;
        END IF;
    END PROCESS VSyncGen;
    VBlankGen : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF reset = '1' THEN
                vga_vblank <= '1';
            ELSIF EndOfLine = '1' THEN
                IF Vcount = VSYNC + VBACK_PORCH - 1 THEN
                    vga_vblank <= '0';
                ELSIF Vcount = VSYNC + VBACK_PORCH + VACTIVE - 1 THEN
                    vga_vblank <= '1';
                END IF;
            END IF;
        END IF;
    END PROCESS VBlankGen;
    BallGen : PROCESS (clk)
        VARIABLE distance_square : INTEGER;
        VARIABLE distance_H : INTEGER;
        VARIABLE distance_V : INTEGER;
    BEGIN
        IF rising_edge (clk) THEN
            distance_H := ABS(TO_INTEGER(Hcount) - 3 * TO_INTEGER(unsigned(center(7 DOWNTO 0))) - 144);
            distance_V := ABS(TO_INTEGER(Vcount) - 3 * TO_INTEGER(unsigned(center(15 DOWNTO 8))) - 35);
            -- distance_H := abs(TO_INTEGER(Hcount)- Hinitial);
            -- distance_V := abs(TO_INTEGER(Vcount)- Vinitial);
            distance_square := (distance_H * distance_H) + (distance_V * distance_V);
            IF reset = '1' THEN
                rectangle_h <= '0';
                rectangle_v <= '0';
            ELSIF distance_square < RADIUS * RADIUS THEN
                rectangle_h <= '1';
                rectangle_v <= '1';
            ELSE
                rectangle_h <= '0';
                rectangle_v <= '0';
            END IF;
        END IF;
    END PROCESS BallGen;
    rectangle <= rectangle_h AND rectangle_v;
    -- Registered video signals going to the video DAC
    VideoOut : PROCESS (clk, reset)
    BEGIN
        IF reset = '1' THEN
            VGA_R <= "0000000000";
            VGA_G <= "0000000000";
            VGA_B <= "0000000000";
        ELSIF clk'event AND clk = '1' THEN
            IF rectangle = '1' THEN --color of ball
                VGA_R <= "1111111111";
                VGA_G <= "0000000000";
                VGA_B <= "1111111111";
            ELSIF vga_hblank = '0' AND vga_vblank = '0' THEN
                VGA_R <= "0111011100"; --color of background
                VGA_G <= "1110000000";
                VGA_B <= "1110111000";
            ELSE
                VGA_R <= "0000000000";
                VGA_G <= "0000000000";
                VGA_B <= "0000000000";
            END IF;
        END IF;
    END PROCESS VideoOut;
    VGA_CLK <= clk;
    VGA_HS <= NOT vga_hsync;
    VGA_VS <= NOT vga_vsync;
    VGA_SYNC <= '0';
    VGA_BLANK <= NOT (vga_hsync OR vga_vsync);
END rtl;