
# Instructions

## Sources

[1] https://www.cs.columbia.edu/~sedwards/classes/2013/4840/reports/6502.pdf

## Format
AAABBBCC

AAA---CC   -- is used to identify the type of opcode \
   BBB     -- is used to encode the addressing mode (see table below)

| BBB | Addressing Mode |
|---  |---              |
| 000 | (zero page,X)   |
| 001 | zero page       |
| 010 | #immediate      |
| 011 | absolute        |
| 100 | (zero page),Y   |
| 101 | zero page,X     |
| 110 | absolute,Y      |
| 111 | absolute,X      |

From [1]

1. Recall that we call the last two bits of opcodes cc. From the study, we found:

* any opcodes with cc = 10 are conducting operations on the accumulator register
* any opcodes with cc = 01 are conducting operations on the X index register
* any opcodes with cc = 10 are conducting operations on the Y index register

There are no opcodes which end in “11”

2. Any instructions shared with the same address mode, they will have the exact same behaviors in the datapath in
any cycles except T0 and T1 (for RMW opcodes, SD1 and SD2 have different behaviors too). For example, LDA,
LDY, LDX, INC (absolute) have the same behaviors as we shown in the above table. 

3. Any opcodes, no matter what their address modes are, share the same behaviors in T0 and T1. For example, LDA
with absolute, zero page, zero page indirect and etc share the same data path operations. More specifically, as we
shown in the table below, the data fetched from memory will always be sent into the accumulator in T0; in T1, it
prepares for the next instruction. 



## AND

AND (bitwise AND with accumulator)
Affects Flags: N Z

|MODE        | SYNTAX      | HEX | aaa | bbb | cc  | LEN | TIM |
|---         |---          |---  |---  |---  |---  |---  |---  |
|Immediate   | AND #$44    | $29 | 001 | 010 | 01  | 2   | 2   |
|Zero Page   | AND $44     | $25 | 001 | 001 | 01  | 2   | 3   |
|Zero Page,X | AND $44,X   | $35 | 001 | 101 | 01  | 2   | 4   |
|Absolute    | AND $4400   | $2D | 001 | 011 | 01  | 3   | 4   |
|Absolute,X  | AND $4400,X | $3D | 001 | 111 | 01  | 3   | 4+  |
|Absolute,Y  | AND $4400,Y | $39 | 001 | 110 | 01  | 3   | 4+  |
|Indirect,X  | AND ($44,X) | $21 | 001 | 000 | 01  | 2   | 6   |
|Indirect,Y  | AND ($44),Y | $31 | 001 | 100 | 01  | 2   | 5+  |

+ add 1 cycle if page boundary crossed
