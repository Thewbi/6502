
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


Instructions taken from: http://www.6502.org/tutorials/6502opcodes.html

## AND - http://www.6502.org/tutorials/6502opcodes.html#AND

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


## LDX - Load Index X with Memory - http://www.6502.org/tutorials/6502opcodes.html#LDX

|MODE        | SYNTAX      | HEX | aaa | bbb | cc  | LEN | TIM |
|---         |---          |---  |---  |---  |---  |---  |---  |
|Immediate   | LDX #$44    | $A2 | 101 | 000 | 10  | 2   | 2   |
|Zero Page   | LDX $44     | $A6 | 101 | 001 | 10  | 2   | 3   |
|Zero Page,Y | LDX $44,Y   | $B6 | 101 | 101 | 10  | 2   | 4   |
|Absolute    | LDX $4400   | $AE | 101 | 011 | 10  | 3   | 4   |
|Absolute,Y  | LDX $4400,Y | $BE | 101 | 111 | 10  | 3   | 4+  |


+ add 1 cycle if page boundary crossed


## Execution of LDX #1

Let's start the journey with something simple.

```
LDX #1
```

This instruction will load the X-register with the immediate value 1. Go to https://www.masswerk.at/6502/assembler.html
and assemble the application. The outcome is 

```
A2 01
```

A2 is the opcode and 01 the first immediate parameter.

Enter the data A2 01 into Visual 6502 (http://www.visual6502.org/JSSim/expert.html) and reset the CPU. Also click the
Trace more button until all columns are shown.

The CPU has a T0 timing state which is a preparation state in which the CPU prepares the next instruction to execute
while it also executes that current instruction. This is the reason why you often see T0+T2 for example, since the
next instruction is in timing state T0 while the current instruction is in timing state T2.

When the Visual 6502 starts to execute, the current instruction is defined to be BRK. The next instruction is our
LDX. The **Execute** column shows BRK, while the **Fetch** column shows LDX #. The timing state is T1. 
I think that this means that the initial BRK instruction is in timing phase T1. 
The program counter PC points to the address 0000 which is
where the opcode A2 is located. Since the PC points to the address, the address is also present on the data bus (db) 
as you can see in the **db-column**, where the byte A2 shows up.

The next state is T0(LDX) + T2(BRK), which means that LDX is in T0 and at the same time BRK is T2.

The TIME of the LDX instrunction is 2. This means LDX is two cycles long. This means that it has Cycles T0 which is 
it's preparation cycle which is executed along with the last cycle of the predecessor instruction. Then it has
the first real cycle T1. Depending on the following instruction, LDX has a phase T2.

For example, when LDX is followed by LDY, then there will be the phase T0(LDY) + T2(LDX).
This means in this case, LDX constists ot T0, T1 and T2.

If the next instruction is BRK, then the the system transitions through the cycles T2, T3, T4, T5 and so on.

LDX has a cycle T2 as can be seen in the Visual 6502 simulator. For some reason Visual 6502 goes into a loop
consisting of T2(BRK), T3(BRK), T4(BRK), T5(BRK), ... and so on until the CPU starts to execut the LDX instruction
again. I currently do not know why that is.

<table class="logstream" id="logstream"><tbody><tr><td class="header">cycle</td><td class="header">ab</td><td class="header">db</td><td class="header">rw</td><td class="header">Fetch</td><td class="header">pc</td><td class="header">a</td><td class="header">x</td><td class="header">y</td><td class="header">s</td><td class="header">p</td><td class="header">Execute</td><td class="header">State</td><td class="header">ir</td><td class="header">tcstate</td><td class="header">pd</td><td class="header">adl</td><td class="header">adh</td><td class="header">sb</td><td class="header">alu</td><td class="header">alucin</td><td class="header">alua</td><td class="header">alub</td><td class="header">alucout</td><td class="header">aluvout</td><td class="header">dasb</td><td class="header">plaOutputs</td><td class="header">DPControl</td><td class="header">idb</td><td class="header">dor</td><td class="header">irq</td><td class="header">nmi</td><td class="header">res</td></tr><tr><td class="oddcol">0</td><td>0000</td><td class="oddcol">a2</td><td>1</td><td class="oddcol">LDX&nbsp;#</td><td>0000</td><td class="oddcol">aa</td><td>00</td><td class="oddcol">00</td><td>fd</td><td class="oddcol">nv‑BdIZc</td><td>BRK</td><td class="oddcol">T1</td><td>00</td><td class="oddcol">101111</td><td>00</td><td class="oddcol">00</td><td>00</td><td class="oddcol">ff</td><td>00</td><td class="oddcol">0</td><td>ff</td><td class="oddcol">00</td><td>0</td><td class="oddcol">0</td><td>ff</td><td class="oddcol">brk/rti,SUMS</td><td>ADL/ABL,ADH/ABH,SS,DBADD,SBADD,SUMS,#DAA,~DAA,ADDADL,#DSA,~DSA,ADHPCH,ADLPCL,DL/ADH,DL/DB</td><td class="oddcol">00</td><td>00</td><td class="oddcol">1</td><td>1</td><td class="oddcol">1</td></tr><tr><td class="oddcol">0</td><td>0000</td><td class="oddcol">a2</td><td>1</td><td class="oddcol">LDX&nbsp;#</td><td>0000</td><td class="oddcol">aa</td><td>00</td><td class="oddcol">00</td><td>fd</td><td class="oddcol">nv‑BdIZc</td><td>BRK</td><td class="oddcol">T1</td><td>00</td><td class="oddcol">101111</td><td>a2</td><td class="oddcol">01</td><td>00</td><td class="oddcol">ff</td><td>ff</td><td class="oddcol">0</td><td>ff</td><td class="oddcol">00</td><td>0</td><td class="oddcol">0</td><td>ff</td><td class="oddcol">brk/rti,SUMS</td><td>ADL/ABL,ADH/ABH,SUMS,#DAA,~DAA,ADDSB7,ADDSB06,#DSA,~DSA,SBDB,PCHADH,PCLADL</td><td class="oddcol">ff</td><td>00</td><td class="oddcol">1</td><td>1</td><td class="oddcol">1</td></tr><tr><td class="oddrow">1</td><td class="oddrowcol">0001</td><td class="oddrow">31</td><td class="oddrowcol">1</td><td class="oddrow"></td><td class="oddrowcol">0001</td><td class="oddrow">aa</td><td class="oddrowcol">00</td><td class="oddrow">00</td><td class="oddrowcol">fd</td><td class="oddrow">nv‑BdIZc</td><td class="oddrowcol">LDX&nbsp;#</td><td class="oddrow">T0+T2</td><td class="oddrowcol">a2</td><td class="oddrow">010111</td><td class="oddrowcol">a2</td><td class="oddrow">01</td><td class="oddrowcol">00</td><td class="oddrow">ff</td><td class="oddrowcol">ff</td><td class="oddrow">0</td><td class="oddrowcol">ff</td><td class="oddrow">ff</td><td class="oddrowcol">0</td><td class="oddrow">0</td><td class="oddrowcol">ff</td><td class="oddrow">xy,T0‑ldx/tax/tsx,T2,T2‑ADL/ADD,T0,SUMS</td><td class="oddrowcol">ADL/ABL,ADH/ABH,SS,DBADD,SBADD,SUMS,#DAA,~DAA,ADDSB7,ADDSB06,#DSA,~DSA,SBDB,ADHPCH,PCHADH,PCLADL,ADLPCL</td><td class="oddrow">ff</td><td class="oddrowcol">ff</td><td class="oddrow">1</td><td class="oddrowcol">1</td><td class="oddrow">1</td></tr><tr><td class="oddrow">1</td><td class="oddrowcol">0001</td><td class="oddrow">31</td><td class="oddrowcol">1</td><td class="oddrow"></td><td class="oddrowcol">0001</td><td class="oddrow">aa</td><td class="oddrowcol">00</td><td class="oddrow">00</td><td class="oddrowcol">fd</td><td class="oddrow">nv‑BdIZc</td><td class="oddrowcol">LDX&nbsp;#</td><td class="oddrow">T0+T2</td><td class="oddrowcol">a2</td><td class="oddrow">010111</td><td class="oddrowcol">31</td><td class="oddrow">02</td><td class="oddrowcol">00</td><td class="oddrow">ff</td><td class="oddrowcol">fe</td><td class="oddrow">0</td><td class="oddrowcol">ff</td><td class="oddrow">ff</td><td class="oddrowcol">1</td><td class="oddrow">0</td><td class="oddrowcol">ff</td><td class="oddrow">xy,T0‑ldx/tax/tsx,T2,T2‑ADL/ADD,T0,SUMS</td><td class="oddrowcol">ADL/ABL,ADH/ABH,SUMS,#DAA,~DAA,#DSA,~DSA,SBDB,PCHADH,PCLADL,DL/DB</td><td class="oddrow">ff</td><td class="oddrowcol">ff</td><td class="oddrow">1</td><td class="oddrowcol">1</td><td class="oddrow">1</td></tr><tr><td class="oddcol">2</td><td>0002</td><td class="oddcol">00</td><td>1</td><td class="oddcol">BRK</td><td>0002</td><td class="oddcol">aa</td><td>31</td><td class="oddcol">00</td><td>fd</td><td class="oddcol">nv‑BdIzc</td><td>LDX&nbsp;#</td><td class="oddcol">T1</td><td>a2</td><td class="oddcol">101111</td><td>31</td><td class="oddcol">02</td><td>00</td><td class="oddcol">31</td><td>fe</td><td class="oddcol">0</td><td>31</td><td class="oddcol">31</td><td>1</td><td class="oddcol">0</td><td>31</td><td class="oddcol">xy,SUMS</td><td>ADL/ABL,ADH/ABH,SBX,SS,DBADD,SBADD,SUMS,#DAA,~DAA,#DSA,~DSA,SBDB,ADHPCH,PCHADH,PCLADL,ADLPCL,DL/DB</td><td class="oddcol">31</td><td>31</td><td class="oddcol">1</td><td>1</td><td class="oddcol">1</td></tr><tr><td class="oddcol">2</td><td>0002</td><td class="oddcol">00</td><td>1</td><td class="oddcol">BRK</td><td>0002</td><td class="oddcol">aa</td><td>31</td><td class="oddcol">00</td><td>fd</td><td class="oddcol">nv‑BdIzc</td><td>LDX&nbsp;#</td><td class="oddcol">T1</td><td>a2</td><td class="oddcol">101111</td><td>00</td><td class="oddcol">03</td><td>00</td><td class="oddcol">62</td><td>62</td><td class="oddcol">0</td><td>31</td><td class="oddcol">31</td><td>0</td><td class="oddcol">0</td><td>62</td><td class="oddcol">xy,SUMS</td><td>ADL/ABL,ADH/ABH,SUMS,#DAA,~DAA,ADDSB7,ADDSB06,#DSA,~DSA,SBDB,PCHADH,PCLADL</td><td class="oddcol">62</td><td>31</td><td class="oddcol">1</td><td>1</td><td class="oddcol">1</td></tr><tr><td class="oddrow">3</td><td class="oddrowcol">0003</td><td class="oddrow">00</td><td class="oddrowcol">1</td><td class="oddrow"></td><td class="oddrowcol">0003</td><td class="oddrow">aa</td><td class="oddrowcol">31</td><td class="oddrow">00</td><td class="oddrowcol">fd</td><td class="oddrow">nv‑BdIzc</td><td class="oddrowcol">BRK</td><td class="oddrow">T2</td><td class="oddrowcol">00</td><td class="oddrow">110111</td><td class="oddrowcol">00</td><td class="oddrow">03</td><td class="oddrowcol">00</td><td class="oddrow">62</td><td class="oddrowcol">62</td><td class="oddrow">0</td><td class="oddrowcol">62</td><td class="oddrow">62</td><td class="oddrowcol">0</td><td class="oddrow">0</td><td class="oddrowcol">62</td><td class="oddrow">T2,T2‑ADL/ADD,T2‑stack,T2‑stack‑access,T2‑brk,brk/rti,SUMS</td><td class="oddrowcol">ADL/ABL,ADH/ABH,SS,DBADD,SBADD,SUMS,#DAA,~DAA,ADDSB7,ADDSB06,#DSA,~DSA,SBDB,ADHPCH,PCHADH,PCLADL,ADLPCL</td><td class="oddrow">62</td><td class="oddrowcol">62</td><td class="oddrow">1</td><td class="oddrowcol">1</td><td class="oddrow">1</td></tr><tr><td class="oddrow">3</td><td class="oddrowcol">0003</td><td class="oddrow">00</td><td class="oddrowcol">1</td><td class="oddrow"></td><td class="oddrowcol">0003</td><td class="oddrow">aa</td><td class="oddrowcol">31</td><td class="oddrow">00</td><td class="oddrowcol">fd</td><td class="oddrow">nv‑BdIzc</td><td class="oddrowcol">BRK</td><td class="oddrow">T2</td><td class="oddrowcol">00</td><td class="oddrow">110111</td><td class="oddrowcol">00</td><td class="oddrow">fd</td><td class="oddrowcol">01</td><td class="oddrow">ff</td><td class="oddrowcol">c4</td><td class="oddrow">0</td><td class="oddrowcol">62</td><td class="oddrow">62</td><td class="oddrowcol">0</td><td class="oddrow">1</td><td class="oddrowcol">ff</td><td class="oddrow">T2,T2‑ADL/ADD,T2‑stack,T2‑stack‑access,T2‑brk,brk/rti,SUMS</td><td class="oddrowcol">ADL/ABL,ADH/ABH,SADL,SUMS,#DAA,~DAA,#DSA,~DSA,0ADH17,PCHDB</td><td class="oddrow">00</td><td class="oddrowcol">62</td><td class="oddrow">1</td><td class="oddrowcol">1</td><td class="oddrow">1</td></tr><tr><td class="oddcol">4</td><td>01fd</td><td class="oddcol">00</td><td>0</td><td class="oddcol"></td><td>0004</td><td class="oddcol">aa</td><td>31</td><td class="oddcol">00</td><td>fd</td><td class="oddcol">nv‑BdIzc</td><td>BRK</td><td class="oddcol">T3</td><td>00</td><td class="oddcol">111011</td><td>00</td><td class="oddcol">fd</td><td>01</td><td class="oddcol">ff</td><td>c4</td><td class="oddcol">0</td><td>ff</td><td class="oddcol">fd</td><td>0</td><td class="oddcol">1</td><td>ff</td><td class="oddcol">T3‑stack/bit/jmp,T3,brk/rti,SUMS</td><td>ADL/ABL,ADH/ABH,SADL,SS,ADLADD,SBADD,SUMS,#DAA,~DAA,#DSA,~DSA,0ADH17,PCHPCH,PCHDB,#IPC,~IPC,PCLPCL</td><td class="oddcol">00</td><td>00</td><td class="oddcol">1</td><td>1</td><td class="oddcol">1</td></tr><tr><td class="oddcol">4</td><td>01fd</td><td class="oddcol">00</td><td>0</td><td class="oddcol"></td><td>0004</td><td class="oddcol">aa</td><td>31</td><td class="oddcol">00</td><td>fd</td><td class="oddcol">nv‑BdIzc</td><td>BRK</td><td class="oddcol">T3</td><td>00</td><td class="oddcol">111011</td><td>00</td><td class="oddcol">fc</td><td>ff</td><td class="oddcol">ff</td><td>fc</td><td class="oddcol">0</td><td>ff</td><td class="oddcol">fd</td><td>1</td><td class="oddcol">0</td><td>ff</td><td class="oddcol">T3‑stack/bit/jmp,T3,brk/rti,SUMS</td><td>ADL/ABL,SUMS,#DAA,~DAA,ADDADL,#DSA,~DSA,#IPC,~IPC,PCLDB</td><td class="oddcol">04</td><td>00</td><td class="oddcol">1</td><td>1</td><td class="oddcol">1</td></tr><tr><td class="oddrow">5</td><td class="oddrowcol">01fc</td><td class="oddrow">00</td><td class="oddrowcol">0</td><td class="oddrow"></td><td class="oddrowcol">0004</td><td class="oddrow">aa</td><td class="oddrowcol">31</td><td class="oddrow">00</td><td class="oddrowcol">fd</td><td class="oddrow">nv‑BdIzc</td><td class="oddrowcol">BRK</td><td class="oddrow">T4</td><td class="oddrowcol">00</td><td class="oddrow">111101</td><td class="oddrowcol">00</td><td class="oddrow">fc</td><td class="oddrowcol">ff</td><td class="oddrow">ff</td><td class="oddrowcol">fc</td><td class="oddrow">0</td><td class="oddrowcol">ff</td><td class="oddrow">fc</td><td class="oddrowcol">1</td><td class="oddrow">0</td><td class="oddrowcol">ff</td><td class="oddrow">T4‑brk/jsr,T4,brk/rti,T4‑brk,SUMS</td><td class="oddrowcol">ADL/ABL,SS,ADLADD,SBADD,SUMS,#DAA,~DAA,ADDADL,#DSA,~DSA,PCHPCH,#IPC,~IPC,PCLDB,PCLPCL</td><td class="oddrow">04</td><td class="oddrowcol">04</td><td class="oddrow">1</td><td class="oddrowcol">1</td><td class="oddrow">1</td></tr><tr><td class="oddrow">5</td><td class="oddrowcol">01fc</td><td class="oddrow">04</td><td class="oddrowcol">0</td><td class="oddrow"></td><td class="oddrowcol">0004</td><td class="oddrow">aa</td><td class="oddrowcol">31</td><td class="oddrow">00</td><td class="oddrowcol">fd</td><td class="oddrow">nv‑BdIzc</td><td class="oddrowcol">BRK</td><td class="oddrow">T4</td><td class="oddrowcol">00</td><td class="oddrow">111101</td><td class="oddrowcol">04</td><td class="oddrow">fb</td><td class="oddrowcol">ff</td><td class="oddrow">ff</td><td class="oddrowcol">fb</td><td class="oddrow">0</td><td class="oddrowcol">ff</td><td class="oddrow">fc</td><td class="oddrowcol">1</td><td class="oddrow">0</td><td class="oddrowcol">ff</td><td class="oddrow">T4‑brk/jsr,T4,brk/rti,T4‑brk,SUMS</td><td class="oddrowcol">ADL/ABL,SUMS,#DAA,~DAA,ADDADL,#DSA,~DSA,#IPC,~IPC</td><td class="oddrow">34</td><td class="oddrowcol">04</td><td class="oddrow">1</td><td class="oddrowcol">1</td><td class="oddrow">1</td></tr><tr><td class="oddcol">6</td><td>01fb</td><td class="oddcol">00</td><td>0</td><td class="oddcol"></td><td>0004</td><td class="oddcol">aa</td><td>31</td><td class="oddcol">00</td><td>fd</td><td class="oddcol">nv‑BdIzc</td><td>BRK</td><td class="oddcol">T5</td><td>00</td><td class="oddcol">111110</td><td>04</td><td class="oddcol">fb</td><td>ff</td><td class="oddcol">ff</td><td>fb</td><td class="oddcol">0</td><td>ff</td><td class="oddcol">fb</td><td>1</td><td class="oddcol">0</td><td>ff</td><td class="oddcol">T5‑brk,brk/rti,SUMS</td><td>ADL/ABL,SS,ADLADD,SBADD,SUMS,#DAA,~DAA,ADDADL,#DSA,~DSA,PCHPCH,#IPC,~IPC,PCLPCL</td><td class="oddcol">34</td><td>34</td><td class="oddcol">1</td><td>1</td><td class="oddcol">1</td></tr><tr><td class="oddcol">6</td><td>01fb</td><td class="oddcol">34</td><td>0</td><td class="oddcol"></td><td>0004</td><td class="oddcol">aa</td><td>31</td><td class="oddcol">00</td><td>fd</td><td class="oddcol">nv‑BdIzc</td><td>BRK</td><td class="oddcol">T5</td><td>00</td><td class="oddcol">111110</td><td>34</td><td class="oddcol">fe</td><td>ff</td><td class="oddcol">fa</td><td>fa</td><td class="oddcol">0</td><td>ff</td><td class="oddcol">fb</td><td>1</td><td class="oddcol">0</td><td>fa</td><td class="oddcol">T5‑brk,brk/rti,SUMS</td><td>ADL/ABL,ADH/ABH,SUMS,#DAA,~DAA,ADDSB7,ADDSB06,#DSA,~DSA,#IPC,~IPC</td><td class="oddcol">ff</td><td>34</td><td class="oddcol">1</td><td>1</td><td class="oddcol">1</td></tr><tr><td class="oddrow">7</td><td class="oddrowcol">fffe</td><td class="oddrow">00</td><td class="oddrowcol">1</td><td class="oddrow"></td><td class="oddrowcol">0004</td><td class="oddrow">aa</td><td class="oddrowcol">31</td><td class="oddrow">00</td><td class="oddrowcol">fa</td><td class="oddrow">nv‑BdIzc</td><td class="oddrowcol">BRK</td><td class="oddrow"></td><td class="oddrowcol">00</td><td class="oddrow">111111</td><td class="oddrowcol">34</td><td class="oddrow">fe</td><td class="oddrowcol">ff</td><td class="oddrow">fa</td><td class="oddrowcol">fa</td><td class="oddrow">0</td><td class="oddrowcol">00</td><td class="oddrow">ff</td><td class="oddrowcol">1</td><td class="oddrow">0</td><td class="oddrowcol">fa</td><td class="oddrow">brk/rti,SUMS</td><td class="oddrowcol">ADL/ABL,ADH/ABH,SBS,DBADD,0ADD,SUMS,#DAA,~DAA,ADDSB7,ADDSB06,#DSA,~DSA,PCHPCH,#IPC,~IPC,PCLPCL</td><td class="oddrow">ff</td><td class="oddrowcol">ff</td><td class="oddrow">1</td><td class="oddrowcol">1</td><td class="oddrow">1</td></tr><tr><td class="oddrow">7</td><td class="oddrowcol">fffe</td><td class="oddrow">00</td><td class="oddrowcol">1</td><td class="oddrow"></td><td class="oddrowcol">0004</td><td class="oddrow">aa</td><td class="oddrowcol">31</td><td class="oddrow">00</td><td class="oddrowcol">fa</td><td class="oddrow">nv‑BdIzc</td><td class="oddrowcol">BRK</td><td class="oddrow"></td><td class="oddrowcol">00</td><td class="oddrow">111111</td><td class="oddrowcol">00</td><td class="oddrow">ff</td><td class="oddrowcol">ff</td><td class="oddrow">ff</td><td class="oddrowcol">ff</td><td class="oddrow">0</td><td class="oddrowcol">00</td><td class="oddrow">ff</td><td class="oddrowcol">0</td><td class="oddrow">0</td><td class="oddrowcol">ff</td><td class="oddrow">brk/rti,SUMS</td><td class="oddrowcol">ADL/ABL,SUMS,#DAA,~DAA,#DSA,~DSA,#IPC,~IPC,DL/DB</td><td class="oddrow">ff</td><td class="oddrowcol">ff</td><td class="oddrow">1</td><td class="oddrowcol">1</td><td class="oddrow">1</td></tr><tr><td class="oddcol">8</td><td>ffff</td><td class="oddcol">00</td><td>1</td><td class="oddcol"></td><td>0004</td><td class="oddcol">aa</td><td>31</td><td class="oddcol">00</td><td>fa</td><td class="oddcol">nv‑BdIzc</td><td>BRK</td><td class="oddcol">T0</td><td>00</td><td class="oddcol">011111</td><td>00</td><td class="oddcol">ff</td><td>ff</td><td class="oddcol">ff</td><td>ff</td><td class="oddcol">0</td><td>00</td><td class="oddcol">00</td><td>0</td><td class="oddcol">0</td><td>ff</td><td class="oddcol">T0,T0‑brk/rti,brk/rti,SUMS</td><td>ADL/ABL,SS,DBADD,0ADD,SUMS,#DAA,~DAA,#DSA,~DSA,PCHPCH,#IPC,~IPC,PCLPCL,DL/DB</td><td class="oddcol">00</td><td>00</td><td class="oddcol">1</td><td>1</td><td class="oddcol">1</td></tr><tr><td class="oddcol">8</td><td>ffff</td><td class="oddcol">00</td><td>1</td><td class="oddcol"></td><td>0004</td><td class="oddcol">aa</td><td>31</td><td class="oddcol">00</td><td>fa</td><td class="oddcol">nv‑BdIzc</td><td>BRK</td><td class="oddcol">T0</td><td>00</td><td class="oddcol">011111</td><td>00</td><td class="oddcol">00</td><td>ff</td><td class="oddcol">ff</td><td>00</td><td class="oddcol">0</td><td>00</td><td class="oddcol">00</td><td>0</td><td class="oddcol">0</td><td>ff</td><td class="oddcol">T0,T0‑brk/rti,brk/rti,SUMS</td><td>ADL/ABL,ADH/ABH,SUMS,#DAA,~DAA,ADDADL,#DSA,~DSA,#IPC,~IPC,DL/ADH,DL/DB</td><td class="oddcol">ff</td><td>00</td><td class="oddcol">1</td><td>1</td><td class="oddcol">1</td></tr><tr><td class="oddrow">9</td><td class="oddrowcol">0000</td><td class="oddrow">a2</td><td class="oddrowcol">1</td><td class="oddrow">LDX&nbsp;#</td><td class="oddrowcol">0000</td><td class="oddrow">aa</td><td class="oddrowcol">31</td><td class="oddrow">00</td><td class="oddrowcol">fa</td><td class="oddrow">nv‑BdIzc</td><td class="oddrowcol">BRK</td><td class="oddrow">T1</td><td class="oddrowcol">00</td><td class="oddrow">101111</td><td class="oddrowcol">00</td><td class="oddrow">00</td><td class="oddrowcol">00</td><td class="oddrow">ff</td><td class="oddrowcol">00</td><td class="oddrow">0</td><td class="oddrowcol">ff</td><td class="oddrow">00</td><td class="oddrowcol">0</td><td class="oddrow">0</td><td class="oddrowcol">ff</td><td class="oddrow">brk/rti,SUMS</td><td class="oddrowcol">ADL/ABL,ADH/ABH,SS,DBADD,SBADD,SUMS,#DAA,~DAA,ADDADL,#DSA,~DSA,ADHPCH,ADLPCL,DL/ADH,DL/DB</td><td class="oddrow">00</td><td class="oddrowcol">00</td><td class="oddrow">1</td><td class="oddrowcol">1</td><td class="oddrow">1</td></tr><tr><td class="oddrow">9</td><td class="oddrowcol">0000</td><td class="oddrow">a2</td><td class="oddrowcol">1</td><td class="oddrow">LDX&nbsp;#</td><td class="oddrowcol">0000</td><td class="oddrow">aa</td><td class="oddrowcol">31</td><td class="oddrow">00</td><td class="oddrowcol">fa</td><td class="oddrow">nv‑BdIzc</td><td class="oddrowcol">BRK</td><td class="oddrow">T1</td><td class="oddrowcol">00</td><td class="oddrow">101111</td><td class="oddrowcol">a2</td><td class="oddrow">01</td><td class="oddrowcol">00</td><td class="oddrow">ff</td><td class="oddrowcol">ff</td><td class="oddrow">0</td><td class="oddrowcol">ff</td><td class="oddrow">00</td><td class="oddrowcol">0</td><td class="oddrow">0</td><td class="oddrowcol">ff</td><td class="oddrow">brk/rti,SUMS</td><td class="oddrowcol">ADL/ABL,ADH/ABH,SUMS,#DAA,~DAA,ADDSB7,ADDSB06,#DSA,~DSA,SBDB,PCHADH,PCLADL</td><td class="oddrow">ff</td><td class="oddrowcol">00</td><td class="oddrow">1</td><td class="oddrowcol">1</td><td class="oddrow">1</td></tr><tr><td class="oddcol">10</td><td>0001</td><td class="oddcol">31</td><td>1</td><td class="oddcol"></td><td>0001</td><td class="oddcol">aa</td><td>31</td><td class="oddcol">00</td><td>fa</td><td class="oddcol">nv‑BdIzc</td><td>LDX&nbsp;#</td><td class="oddcol">T0+T2</td><td>a2</td><td class="oddcol">010111</td><td>a2</td><td class="oddcol">01</td><td>00</td><td class="oddcol">ff</td><td>ff</td><td class="oddcol">0</td><td>ff</td><td class="oddcol">ff</td><td>0</td><td class="oddcol">0</td><td>ff</td><td class="oddcol">xy,T0‑ldx/tax/tsx,T2,T2‑ADL/ADD,T0,SUMS</td><td>ADL/ABL,ADH/ABH,SS,DBADD,SBADD,SUMS,#DAA,~DAA,ADDSB7,ADDSB06,#DSA,~DSA,SBDB,ADHPCH,PCHADH,PCLADL,ADLPCL</td><td class="oddcol">ff</td><td>ff</td><td class="oddcol">1</td><td>1</td><td class="oddcol">1</td></tr><tr><td class="oddcol">10</td><td>0001</td><td class="oddcol">31</td><td>1</td><td class="oddcol"></td><td>0001</td><td class="oddcol">aa</td><td>31</td><td class="oddcol">00</td><td>fa</td><td class="oddcol">nv‑BdIzc</td><td>LDX&nbsp;#</td><td class="oddcol">T0+T2</td><td>a2</td><td class="oddcol">010111</td><td>31</td><td class="oddcol">02</td><td>00</td><td class="oddcol">ff</td><td>fe</td><td class="oddcol">0</td><td>ff</td><td class="oddcol">ff</td><td>1</td><td class="oddcol">0</td><td>ff</td><td class="oddcol">xy,T0‑ldx/tax/tsx,T2,T2‑ADL/ADD,T0,SUMS</td><td>ADL/ABL,ADH/ABH,SUMS,#DAA,~DAA,#DSA,~DSA,SBDB,PCHADH,PCLADL,DL/DB</td><td class="oddcol">ff</td><td>ff</td><td class="oddcol">1</td><td>1</td><td class="oddcol">1</td></tr><tr><td class="oddrow">11</td><td class="oddrowcol">0002</td><td class="oddrow">00</td><td class="oddrowcol">1</td><td class="oddrow">BRK</td><td class="oddrowcol">0002</td><td class="oddrow">aa</td><td class="oddrowcol">31</td><td class="oddrow">00</td><td class="oddrowcol">fa</td><td class="oddrow">nv‑BdIzc</td><td class="oddrowcol">LDX&nbsp;#</td><td class="oddrow">T1</td><td class="oddrowcol">a2</td><td class="oddrow">101111</td><td class="oddrowcol">31</td><td class="oddrow">02</td><td class="oddrowcol">00</td><td class="oddrow">31</td><td class="oddrowcol">fe</td><td class="oddrow">0</td><td class="oddrowcol">31</td><td class="oddrow">31</td><td class="oddrowcol">1</td><td class="oddrow">0</td><td class="oddrowcol">31</td><td class="oddrow">xy,SUMS</td><td class="oddrowcol">ADL/ABL,ADH/ABH,SBX,SS,DBADD,SBADD,SUMS,#DAA,~DAA,#DSA,~DSA,SBDB,ADHPCH,PCHADH,PCLADL,ADLPCL,DL/DB</td><td class="oddrow">31</td><td class="oddrowcol">31</td><td class="oddrow">1</td><td class="oddrowcol">1</td><td class="oddrow">1</td></tr><tr><td class="oddrow">11</td><td class="oddrowcol">0002</td><td class="oddrow">00</td><td class="oddrowcol">1</td><td class="oddrow">BRK</td><td class="oddrowcol">0002</td><td class="oddrow">aa</td><td class="oddrowcol">31</td><td class="oddrow">00</td><td class="oddrowcol">fa</td><td class="oddrow">nv‑BdIzc</td><td class="oddrowcol">LDX&nbsp;#</td><td class="oddrow">T1</td><td class="oddrowcol">a2</td><td class="oddrow">101111</td><td class="oddrowcol">00</td><td class="oddrow">03</td><td class="oddrowcol">00</td><td class="oddrow">62</td><td class="oddrowcol">62</td><td class="oddrow">0</td><td class="oddrowcol">31</td><td class="oddrow">31</td><td class="oddrowcol">0</td><td class="oddrow">0</td><td class="oddrowcol">62</td><td class="oddrow">xy,SUMS</td><td class="oddrowcol">ADL/ABL,ADH/ABH,SUMS,#DAA,~DAA,ADDSB7,ADDSB06,#DSA,~DSA,SBDB,PCHADH,PCLADL</td><td class="oddrow">62</td><td class="oddrowcol">31</td><td class="oddrow">1</td><td class="oddrowcol">1</td><td class="oddrow">1</td></tr><tr><td class="oddcol">12</td><td>0003</td><td class="oddcol">00</td><td>1</td><td class="oddcol"></td><td>0003</td><td class="oddcol">aa</td><td>31</td><td class="oddcol">00</td><td>fa</td><td class="oddcol">nv‑BdIzc</td><td>BRK</td><td class="oddcol">T2</td><td>00</td><td class="oddcol">110111</td><td>00</td><td class="oddcol">03</td><td>00</td><td class="oddcol">62</td><td>62</td><td class="oddcol">0</td><td>62</td><td class="oddcol">62</td><td>0</td><td class="oddcol">0</td><td>62</td><td class="oddcol">T2,T2‑ADL/ADD,T2‑stack,T2‑stack‑access,T2‑brk,brk/rti,SUMS</td><td>ADL/ABL,ADH/ABH,SS,DBADD,SBADD,SUMS,#DAA,~DAA,ADDSB7,ADDSB06,#DSA,~DSA,SBDB,ADHPCH,PCHADH,PCLADL,ADLPCL</td><td class="oddcol">62</td><td>62</td><td class="oddcol">1</td><td>1</td><td class="oddcol">1</td></tr><tr><td class="oddcol">12</td><td>0003</td><td class="oddcol">00</td><td>1</td><td class="oddcol"></td><td>0003</td><td class="oddcol">aa</td><td>31</td><td class="oddcol">00</td><td>fa</td><td class="oddcol">nv‑BdIzc</td><td>BRK</td><td class="oddcol">T2</td><td>00</td><td class="oddcol">110111</td><td>00</td><td class="oddcol">fa</td><td>01</td><td class="oddcol">ff</td><td>c4</td><td class="oddcol">0</td><td>62</td><td class="oddcol">62</td><td>0</td><td class="oddcol">1</td><td>ff</td><td class="oddcol">T2,T2‑ADL/ADD,T2‑stack,T2‑stack‑access,T2‑brk,brk/rti,SUMS</td><td>ADL/ABL,ADH/ABH,SADL,SUMS,#DAA,~DAA,#DSA,~DSA,0ADH17,PCHDB</td><td class="oddcol">00</td><td>62</td><td class="oddcol">1</td><td>1</td><td class="oddcol">1</td></tr></tbody></table>

The goal of LDX #imm is to load an immediate value into the index register X. If you look at Dr. Hansons diagram, 
the X-Register is called "X INDEX REGISTER (X)" and it is located on the far right. Tt has no direct connection 
to the databus where the immediate value 1 arrives during phase T0+T2 ( or rather T0(LDX) + T2(BRK) )! 

The question is how does the immediate value get from the databus to the index register X?
The answer is that in the case of LDX #imm, the immediate value goes through the ALU into the Adder Hold Register 
(ADD) in phase T0+T2 and from there it goes into the index register X in T1 of the next instruction.

First, in T0+T2, the signal DBADD is output by the Datapath Control (DPControl). In Dr. Hansons diagram, DBADD is
called DB/ADD and it causes the B input register to the ALU to latch data from the data bus.
SBADD (= SB/ADD) is also asserted so that the current value on the SBus (SB) latches into the A input register
of the ALU. The value SUMS is asserted so the ALU computes the sum. For some reason SB must hold the value 00 so that
00 + 01 = 01. This value 01 is output into the ADDER HOLD REGISTER which always latches the output of the ALU even without
any specific signal.

The ADDER HOLD REGISTER is immediately placed onto the SB since the Visual 6502 outputs the signals ADDSB7, ADDSB06
which in Hanson's diagram control the output of the ADDER HOLD REGISTER on the SB.

In the phase T1(LDX) of the next instruction, the signal **SBX** is asserted. In Hanson's diagram **SBX** is called **SB/X** and it probably stands for "load the value on the SB into the index register X". So with the beginning of T1 of the 
LDX instruction, the immediate value 01 is available inside the index X register. 

It is interesting to see that with the end of T1 of the LDX instruction itself, X does store the immediate value loaded!
That means all steps for the LDX command are perform within the two cycles T0 and T1 of LDX.

<table class="logstream" id="logstream"><tbody><tr><td class="header">cycle</td><td class="header">ab</td><td class="header">db</td><td class="header">rw</td><td class="header">Fetch</td><td class="header">pc</td><td class="header">a</td><td class="header">x</td><td class="header">y</td><td class="header">s</td><td class="header">p</td><td class="header">Execute</td><td class="header">State</td><td class="header">ir</td><td class="header">tcstate</td><td class="header">pd</td><td class="header">adl</td><td class="header">adh</td><td class="header">sb</td><td class="header">alu</td><td class="header">alucin</td><td class="header">alua</td><td class="header">alub</td><td class="header">alucout</td><td class="header">aluvout</td><td class="header">dasb</td><td class="header">plaOutputs</td><td class="header">DPControl</td><td class="header">idb</td><td class="header">dor</td><td class="header">irq</td><td class="header">nmi</td><td class="header">res</td></tr><tr><td class="oddcol">0</td><td>0000</td><td class="oddcol">a2</td><td>1</td><td class="oddcol">LDX&nbsp;#</td><td>0000</td><td class="oddcol">aa</td><td>00</td><td class="oddcol">00</td><td>fd</td><td class="oddcol">nv‑BdIZc</td><td>BRK</td><td class="oddcol">T1</td><td>00</td><td class="oddcol">101111</td><td>00</td><td class="oddcol">00</td><td>00</td><td class="oddcol">ff</td><td>00</td><td class="oddcol">0</td><td>ff</td><td class="oddcol">00</td><td>0</td><td class="oddcol">0</td><td>ff</td><td class="oddcol">brk/rti,SUMS</td><td>ADL/ABL,ADH/ABH,SS,DBADD,SBADD,SUMS,#DAA,~DAA,ADDADL,#DSA,~DSA,ADHPCH,ADLPCL,DL/ADH,DL/DB</td><td class="oddcol">00</td><td>00</td><td class="oddcol">1</td><td>1</td><td class="oddcol">1</td></tr><tr><td class="oddcol">0</td><td>0000</td><td class="oddcol">a2</td><td>1</td><td class="oddcol">LDX&nbsp;#</td><td>0000</td><td class="oddcol">aa</td><td>00</td><td class="oddcol">00</td><td>fd</td><td class="oddcol">nv‑BdIZc</td><td>BRK</td><td class="oddcol">T1</td><td>00</td><td class="oddcol">101111</td><td>a2</td><td class="oddcol">01</td><td>00</td><td class="oddcol">ff</td><td>ff</td><td class="oddcol">0</td><td>ff</td><td class="oddcol">00</td><td>0</td><td class="oddcol">0</td><td>ff</td><td class="oddcol">brk/rti,SUMS</td><td>ADL/ABL,ADH/ABH,SUMS,#DAA,~DAA,ADDSB7,ADDSB06,#DSA,~DSA,SBDB,PCHADH,PCLADL</td><td class="oddcol">ff</td><td>00</td><td class="oddcol">1</td><td>1</td><td class="oddcol">1</td></tr><tr><td class="oddrow">1</td><td class="oddrowcol">0001</td><td class="oddrow">01</td><td class="oddrowcol">1</td><td class="oddrow"></td><td class="oddrowcol">0001</td><td class="oddrow">aa</td><td class="oddrowcol">00</td><td class="oddrow">00</td><td class="oddrowcol">fd</td><td class="oddrow">nv‑BdIZc</td><td class="oddrowcol">LDX&nbsp;#</td><td class="oddrow">T0+T2</td><td class="oddrowcol">a2</td><td class="oddrow">010111</td><td class="oddrowcol">a2</td><td class="oddrow">01</td><td class="oddrowcol">00</td><td class="oddrow">ff</td><td class="oddrowcol">ff</td><td class="oddrow">0</td><td class="oddrowcol">ff</td><td class="oddrow">ff</td><td class="oddrowcol">0</td><td class="oddrow">0</td><td class="oddrowcol">ff</td><td class="oddrow">xy,T0‑ldx/tax/tsx,T2,T2‑ADL/ADD,T0,SUMS</td><td class="oddrowcol">ADL/ABL,ADH/ABH,SS,DBADD,SBADD,SUMS,#DAA,~DAA,ADDSB7,ADDSB06,#DSA,~DSA,SBDB,ADHPCH,PCHADH,PCLADL,ADLPCL</td><td class="oddrow">ff</td><td class="oddrowcol">ff</td><td class="oddrow">1</td><td class="oddrowcol">1</td><td class="oddrow">1</td></tr><tr><td class="oddrow">1</td><td class="oddrowcol">0001</td><td class="oddrow">01</td><td class="oddrowcol">1</td><td class="oddrow"></td><td class="oddrowcol">0001</td><td class="oddrow">aa</td><td class="oddrowcol">00</td><td class="oddrow">00</td><td class="oddrowcol">fd</td><td class="oddrow">nv‑BdIZc</td><td class="oddrowcol">LDX&nbsp;#</td><td class="oddrow">T0+T2</td><td class="oddrowcol">a2</td><td class="oddrow">010111</td><td class="oddrowcol">01</td><td class="oddrow">02</td><td class="oddrowcol">00</td><td class="oddrow">ff</td><td class="oddrowcol">fe</td><td class="oddrow">0</td><td class="oddrowcol">ff</td><td class="oddrow">ff</td><td class="oddrowcol">1</td><td class="oddrow">0</td><td class="oddrowcol">ff</td><td class="oddrow">xy,T0‑ldx/tax/tsx,T2,T2‑ADL/ADD,T0,SUMS</td><td class="oddrowcol">ADL/ABL,ADH/ABH,SUMS,#DAA,~DAA,#DSA,~DSA,SBDB,PCHADH,PCLADL,DL/DB</td><td class="oddrow">ff</td><td class="oddrowcol">ff</td><td class="oddrow">1</td><td class="oddrowcol">1</td><td class="oddrow">1</td></tr><tr><td class="oddcol">2</td><td>0002</td><td class="oddcol">00</td><td>1</td><td class="oddcol">BRK</td><td>0002</td><td class="oddcol">aa</td><td>01</td><td class="oddcol">00</td><td>fd</td><td class="oddcol">nv‑BdIzc</td><td>LDX&nbsp;#</td><td class="oddcol">T1</td><td>a2</td><td class="oddcol">101111</td><td>01</td><td class="oddcol">02</td><td>00</td><td class="oddcol">01</td><td>fe</td><td class="oddcol">0</td><td>01</td><td class="oddcol">01</td><td>1</td><td class="oddcol">0</td><td>01</td><td class="oddcol">xy,SUMS</td><td>ADL/ABL,ADH/ABH,SBX,SS,DBADD,SBADD,SUMS,#DAA,~DAA,#DSA,~DSA,SBDB,ADHPCH,PCHADH,PCLADL,ADLPCL,DL/DB</td><td class="oddcol">01</td><td>01</td><td class="oddcol">1</td><td>1</td><td class="oddcol">1</td></tr></tbody></table>

When LDX is followed by another instruction, say LDY, then LDX has the phase T0. This means it is a two cycle instruction
that has the phases T0, T1 and T2. Maybe the preparation step T0 is not counted and the only cycles that are counted
are T1 and T2.

Here is a trace of a LDX instruction followed by a LDY instruction:

```
LDX #1
LDY #2
```

the machine code is (https://www.masswerk.at/6502/assembler.html)

```
0000: A2 01 A0 02
```

<table class="logstream" id="logstream"><tbody><tr><td class="header">cycle</td><td class="header">ab</td><td class="header">db</td><td class="header">rw</td><td class="header">Fetch</td><td class="header">pc</td><td class="header">a</td><td class="header">x</td><td class="header">y</td><td class="header">s</td><td class="header">p</td><td class="header">Execute</td><td class="header">State</td><td class="header">ir</td><td class="header">tcstate</td><td class="header">pd</td><td class="header">adl</td><td class="header">adh</td><td class="header">sb</td><td class="header">alu</td><td class="header">alucin</td><td class="header">alua</td><td class="header">alub</td><td class="header">alucout</td><td class="header">aluvout</td><td class="header">dasb</td><td class="header">plaOutputs</td><td class="header">DPControl</td><td class="header">idb</td><td class="header">dor</td><td class="header">irq</td><td class="header">nmi</td><td class="header">res</td></tr><tr><td class="oddcol">0</td><td>0000</td><td class="oddcol">a2</td><td>1</td><td class="oddcol">LDX&nbsp;#</td><td>0000</td><td class="oddcol">aa</td><td>00</td><td class="oddcol">00</td><td>fd</td><td class="oddcol">nv‑BdIZc</td><td>BRK</td><td class="oddcol">T1</td><td>00</td><td class="oddcol">101111</td><td>00</td><td class="oddcol">00</td><td>00</td><td class="oddcol">ff</td><td>00</td><td class="oddcol">0</td><td>ff</td><td class="oddcol">00</td><td>0</td><td class="oddcol">0</td><td>ff</td><td class="oddcol">brk/rti,SUMS</td><td>ADL/ABL,ADH/ABH,SS,DBADD,SBADD,SUMS,#DAA,~DAA,ADDADL,#DSA,~DSA,ADHPCH,ADLPCL,DL/ADH,DL/DB</td><td class="oddcol">00</td><td>00</td><td class="oddcol">1</td><td>1</td><td class="oddcol">1</td></tr><tr><td class="oddcol">0</td><td>0000</td><td class="oddcol">a2</td><td>1</td><td class="oddcol">LDX&nbsp;#</td><td>0000</td><td class="oddcol">aa</td><td>00</td><td class="oddcol">00</td><td>fd</td><td class="oddcol">nv‑BdIZc</td><td>BRK</td><td class="oddcol">T1</td><td>00</td><td class="oddcol">101111</td><td>a2</td><td class="oddcol">01</td><td>00</td><td class="oddcol">ff</td><td>ff</td><td class="oddcol">0</td><td>ff</td><td class="oddcol">00</td><td>0</td><td class="oddcol">0</td><td>ff</td><td class="oddcol">brk/rti,SUMS</td><td>ADL/ABL,ADH/ABH,SUMS,#DAA,~DAA,ADDSB7,ADDSB06,#DSA,~DSA,SBDB,PCHADH,PCLADL</td><td class="oddcol">ff</td><td>00</td><td class="oddcol">1</td><td>1</td><td class="oddcol">1</td></tr><tr><td class="oddrow">1</td><td class="oddrowcol">0001</td><td class="oddrow">01</td><td class="oddrowcol">1</td><td class="oddrow"></td><td class="oddrowcol">0001</td><td class="oddrow">aa</td><td class="oddrowcol">00</td><td class="oddrow">00</td><td class="oddrowcol">fd</td><td class="oddrow">nv‑BdIZc</td><td class="oddrowcol">LDX&nbsp;#</td><td class="oddrow">T0+T2</td><td class="oddrowcol">a2</td><td class="oddrow">010111</td><td class="oddrowcol">a2</td><td class="oddrow">01</td><td class="oddrowcol">00</td><td class="oddrow">ff</td><td class="oddrowcol">ff</td><td class="oddrow">0</td><td class="oddrowcol">ff</td><td class="oddrow">ff</td><td class="oddrowcol">0</td><td class="oddrow">0</td><td class="oddrowcol">ff</td><td class="oddrow">xy,T0‑ldx/tax/tsx,T2,T2‑ADL/ADD,T0,SUMS</td><td class="oddrowcol">ADL/ABL,ADH/ABH,SS,DBADD,SBADD,SUMS,#DAA,~DAA,ADDSB7,ADDSB06,#DSA,~DSA,SBDB,ADHPCH,PCHADH,PCLADL,ADLPCL</td><td class="oddrow">ff</td><td class="oddrowcol">ff</td><td class="oddrow">1</td><td class="oddrowcol">1</td><td class="oddrow">1</td></tr><tr><td class="oddrow">1</td><td class="oddrowcol">0001</td><td class="oddrow">01</td><td class="oddrowcol">1</td><td class="oddrow"></td><td class="oddrowcol">0001</td><td class="oddrow">aa</td><td class="oddrowcol">00</td><td class="oddrow">00</td><td class="oddrowcol">fd</td><td class="oddrow">nv‑BdIZc</td><td class="oddrowcol">LDX&nbsp;#</td><td class="oddrow">T0+T2</td><td class="oddrowcol">a2</td><td class="oddrow">010111</td><td class="oddrowcol">01</td><td class="oddrow">02</td><td class="oddrowcol">00</td><td class="oddrow">ff</td><td class="oddrowcol">fe</td><td class="oddrow">0</td><td class="oddrowcol">ff</td><td class="oddrow">ff</td><td class="oddrowcol">1</td><td class="oddrow">0</td><td class="oddrowcol">ff</td><td class="oddrow">xy,T0‑ldx/tax/tsx,T2,T2‑ADL/ADD,T0,SUMS</td><td class="oddrowcol">ADL/ABL,ADH/ABH,SUMS,#DAA,~DAA,#DSA,~DSA,SBDB,PCHADH,PCLADL,DL/DB</td><td class="oddrow">ff</td><td class="oddrowcol">ff</td><td class="oddrow">1</td><td class="oddrowcol">1</td><td class="oddrow">1</td></tr><tr><td class="oddcol">2</td><td>0002</td><td class="oddcol">a0</td><td>1</td><td class="oddcol">LDY&nbsp;#</td><td>0002</td><td class="oddcol">aa</td><td>01</td><td class="oddcol">00</td><td>fd</td><td class="oddcol">nv‑BdIzc</td><td>LDX&nbsp;#</td><td class="oddcol">T1</td><td>a2</td><td class="oddcol">101111</td><td>01</td><td class="oddcol">02</td><td>00</td><td class="oddcol">01</td><td>fe</td><td class="oddcol">0</td><td>01</td><td class="oddcol">01</td><td>1</td><td class="oddcol">0</td><td>01</td><td class="oddcol">xy,SUMS</td><td>ADL/ABL,ADH/ABH,SBX,SS,DBADD,SBADD,SUMS,#DAA,~DAA,#DSA,~DSA,SBDB,ADHPCH,PCHADH,PCLADL,ADLPCL,DL/DB</td><td class="oddcol">01</td><td>01</td><td class="oddcol">1</td><td>1</td><td class="oddcol">1</td></tr><tr><td class="oddcol">2</td><td>0002</td><td class="oddcol">a0</td><td>1</td><td class="oddcol">LDY&nbsp;#</td><td>0002</td><td class="oddcol">aa</td><td>01</td><td class="oddcol">00</td><td>fd</td><td class="oddcol">nv‑BdIzc</td><td>LDX&nbsp;#</td><td class="oddcol">T1</td><td>a2</td><td class="oddcol">101111</td><td>a0</td><td class="oddcol">03</td><td>00</td><td class="oddcol">02</td><td>02</td><td class="oddcol">0</td><td>01</td><td class="oddcol">01</td><td>0</td><td class="oddcol">0</td><td>02</td><td class="oddcol">xy,SUMS</td><td>ADL/ABL,ADH/ABH,SUMS,#DAA,~DAA,ADDSB7,ADDSB06,#DSA,~DSA,SBDB,PCHADH,PCLADL</td><td class="oddcol">02</td><td>01</td><td class="oddcol">1</td><td>1</td><td class="oddcol">1</td></tr><tr><td class="oddrow">3</td><td class="oddrowcol">0003</td><td class="oddrow">02</td><td class="oddrowcol">1</td><td class="oddrow"></td><td class="oddrowcol">0003</td><td class="oddrow">aa</td><td class="oddrowcol">01</td><td class="oddrow">00</td><td class="oddrowcol">fd</td><td class="oddrow">nv‑BdIzc</td><td class="oddrowcol">LDY&nbsp;#</td><td class="oddrow">T0+T2</td><td class="oddrowcol">a0</td><td class="oddrow">010111</td><td class="oddrowcol">a0</td><td class="oddrow">03</td><td class="oddrowcol">00</td><td class="oddrow">02</td><td class="oddrowcol">02</td><td class="oddrow">0</td><td class="oddrowcol">02</td><td class="oddrow">02</td><td class="oddrowcol">0</td><td class="oddrow">0</td><td class="oddrowcol">02</td><td class="oddrow">T0‑tay/ldy‑not‑idx,T2,T2‑ADL/ADD,T0,SUMS</td><td class="oddrowcol">ADL/ABL,ADH/ABH,SS,DBADD,SBADD,SUMS,#DAA,~DAA,ADDSB7,ADDSB06,#DSA,~DSA,SBDB,ADHPCH,PCHADH,PCLADL,ADLPCL</td><td class="oddrow">02</td><td class="oddrowcol">02</td><td class="oddrow">1</td><td class="oddrowcol">1</td><td class="oddrow">1</td></tr><tr><td class="oddrow">3</td><td class="oddrowcol">0003</td><td class="oddrow">02</td><td class="oddrowcol">1</td><td class="oddrow"></td><td class="oddrowcol">0003</td><td class="oddrow">aa</td><td class="oddrowcol">01</td><td class="oddrow">00</td><td class="oddrowcol">fd</td><td class="oddrow">nv‑BdIzc</td><td class="oddrowcol">LDY&nbsp;#</td><td class="oddrow">T0+T2</td><td class="oddrowcol">a0</td><td class="oddrow">010111</td><td class="oddrowcol">02</td><td class="oddrow">04</td><td class="oddrowcol">00</td><td class="oddrow">ff</td><td class="oddrowcol">04</td><td class="oddrow">0</td><td class="oddrowcol">02</td><td class="oddrow">02</td><td class="oddrowcol">0</td><td class="oddrow">0</td><td class="oddrowcol">ff</td><td class="oddrow">T0‑tay/ldy‑not‑idx,T2,T2‑ADL/ADD,T0,SUMS</td><td class="oddrowcol">ADL/ABL,ADH/ABH,SUMS,#DAA,~DAA,#DSA,~DSA,SBDB,PCHADH,PCLADL,DL/DB</td><td class="oddrow">ff</td><td class="oddrowcol">02</td><td class="oddrow">1</td><td class="oddrowcol">1</td><td class="oddrow">1</td></tr><tr><td class="oddcol">4</td><td>0004</td><td class="oddcol">00</td><td>1</td><td class="oddcol">BRK</td><td>0004</td><td class="oddcol">aa</td><td>01</td><td class="oddcol">02</td><td>fd</td><td class="oddcol">nv‑BdIzc</td><td>LDY&nbsp;#</td><td class="oddcol">T1</td><td>a0</td><td class="oddcol">101111</td><td>02</td><td class="oddcol">04</td><td>00</td><td class="oddcol">02</td><td>04</td><td class="oddcol">0</td><td>02</td><td class="oddcol">02</td><td>0</td><td class="oddcol">0</td><td>02</td><td class="oddcol">SUMS</td><td>ADL/ABL,ADH/ABH,SBY,SS,DBADD,SBADD,SUMS,#DAA,~DAA,#DSA,~DSA,SBDB,ADHPCH,PCHADH,PCLADL,ADLPCL,DL/DB</td><td class="oddcol">02</td><td>02</td><td class="oddcol">1</td><td>1</td><td class="oddcol">1</td></tr><tr><td class="oddcol">4</td><td>0004</td><td class="oddcol">00</td><td>1</td><td class="oddcol">BRK</td><td>0004</td><td class="oddcol">aa</td><td>01</td><td class="oddcol">02</td><td>fd</td><td class="oddcol">nv‑BdIzc</td><td>LDY&nbsp;#</td><td class="oddcol">T1</td><td>a0</td><td class="oddcol">101111</td><td>00</td><td class="oddcol">05</td><td>00</td><td class="oddcol">04</td><td>04</td><td class="oddcol">0</td><td>02</td><td class="oddcol">02</td><td>0</td><td class="oddcol">0</td><td>04</td><td class="oddcol">SUMS</td><td>ADL/ABL,ADH/ABH,SUMS,#DAA,~DAA,ADDSB7,ADDSB06,#DSA,~DSA,SBDB,PCHADH,PCLADL</td><td class="oddcol">04</td><td>02</td><td class="oddcol">1</td><td>1</td><td class="oddcol">1</td></tr><tr><td class="oddrow">5</td><td class="oddrowcol">0005</td><td class="oddrow">00</td><td class="oddrowcol">1</td><td class="oddrow"></td><td class="oddrowcol">0005</td><td class="oddrow">aa</td><td class="oddrowcol">01</td><td class="oddrow">02</td><td class="oddrowcol">fd</td><td class="oddrow">nv‑BdIzc</td><td class="oddrowcol">BRK</td><td class="oddrow">T2</td><td class="oddrowcol">00</td><td class="oddrow">110111</td><td class="oddrowcol">00</td><td class="oddrow">05</td><td class="oddrowcol">00</td><td class="oddrow">04</td><td class="oddrowcol">04</td><td class="oddrow">0</td><td class="oddrowcol">04</td><td class="oddrow">04</td><td class="oddrowcol">0</td><td class="oddrow">0</td><td class="oddrowcol">04</td><td class="oddrow">T2,T2‑ADL/ADD,T2‑stack,T2‑stack‑access,T2‑brk,brk/rti,SUMS</td><td class="oddrowcol">ADL/ABL,ADH/ABH,SS,DBADD,SBADD,SUMS,#DAA,~DAA,ADDSB7,ADDSB06,#DSA,~DSA,SBDB,ADHPCH,PCHADH,PCLADL,ADLPCL</td><td class="oddrow">04</td><td class="oddrowcol">04</td><td class="oddrow">1</td><td class="oddrowcol">1</td><td class="oddrow">1</td></tr><tr><td class="oddrow">5</td><td class="oddrowcol">0005</td><td class="oddrow">00</td><td class="oddrowcol">1</td><td class="oddrow"></td><td class="oddrowcol">0005</td><td class="oddrow">aa</td><td class="oddrowcol">01</td><td class="oddrow">02</td><td class="oddrowcol">fd</td><td class="oddrow">nv‑BdIzc</td><td class="oddrowcol">BRK</td><td class="oddrow">T2</td><td class="oddrowcol">00</td><td class="oddrow">110111</td><td class="oddrowcol">00</td><td class="oddrow">fd</td><td class="oddrowcol">01</td><td class="oddrow">ff</td><td class="oddrowcol">08</td><td class="oddrow">0</td><td class="oddrowcol">04</td><td class="oddrow">04</td><td class="oddrowcol">0</td><td class="oddrow">0</td><td class="oddrowcol">ff</td><td class="oddrow">T2,T2‑ADL/ADD,T2‑stack,T2‑stack‑access,T2‑brk,brk/rti,SUMS</td><td class="oddrowcol">ADL/ABL,ADH/ABH,SADL,SUMS,#DAA,~DAA,#DSA,~DSA,0ADH17,PCHDB</td><td class="oddrow">00</td><td class="oddrowcol">04</td><td class="oddrow">1</td><td class="oddrowcol">1</td><td class="oddrow">1</td></tr></tbody></table>

## Simulating LDX

The idea is to not simulate the phases phi1 and phi2 of the real 6502 hardware, since some FPGAs do not even have
to parallel clock sources. Therefore the entire design will only simulate the T0+T?, T1, T2, ... phases of the instructions.

### Cycle 0

Very first state.

Initialize CPU:

cpu.x = 0
cpu.y = 0
cpu.ir = 0 // instruction register

cpu.pc = 0 // programm counter
cpu.adl = cpu.pc & 0xFF
cpu.adh = (cpu.pc >> 8) & 0xFF

// this happens in T1
cpu.fetch = instruction_memory[cpu.pc]
databus = cpu.fetch
cpu.execute = BRK (0x00)

// Initialize state machine for BRK.
// Choose the linear state machine. 
// Initial state is T1.
sm.state == T1

// Timing Generator
tg.input = BRK // input is: BRK
tg.cycle_count = 2 // BRK can take more cycles than 2 but if another instruction follow, it takes 2 cycles only????

cpu.pc = cpu.pc + 1
cpu.adl = cpu.pc & 0xFF
cpu.adh = (cpu.pc >> 8) & 0xFF

cpu.SBX = 0
cpu.SBY = 0

// next state (T2)
sm.state++


### Cycle 1, 2, 3, ....

while (!done) {

    cpu.ir = databus
    databus = instruction_memory[cpu.pc]

    // if StateMachine is on the last cycle_count of the current instruction
    if (sm.state == tg.cycle_count) {

        // add T0 cycle for the next instruction
        sm.state_zero = true

        // start the next instruction
        cpu.execute = cpu.fetch

        if (cpu.execute == LDX)
        {
            // activate the inputs of the ALU but do not compute the ALU yet
            cpu.ADDSB7 = 1;
            cpu.ADDSB06 = 1;
            cpu.SUMS = 1;
        }
        if (cpu.execute == LDY)
        {
            // activate the inputs of the ALU but do not compute the ALU yet
            cpu.ADDSB7 = 1;
            cpu.ADDSB06 = 1;
            cpu.SUMS = 1;
        }

        // back to state T1
        sm.state = T1

        // increment program counter
        cpu.pc = cpu.pc + 1
        cpu.adl = cpu.pc & 0xFF
        cpu.adh = (cpu.pc >> 8) & 0xFF

        continue;
    }

    // T1 state
    if (sm.state == T1) {

        // this happens in T1
        cpu.fetch = instruction_memory[cpu.pc]
        databus = cpu.fetch
        //cpu.execute = decode(databus)

        if (cpu.execute == LDX)
        {
            // read inputs compute output
            alu.compute();

            // activate input to the X-Register
            cpu.SBX = 1;

            // read current value from SB that the ALU has output
            x_register.latch_SB();
        }
        if (cpu.execute == LDY)
        {
            // read inputs compute output
            alu.compute();

            // activate input to the Y-Register
            cpu.SBY = 1;

            // read current value from SB that the ALU has output
            y_register.latch_SB();
        }

        // timing generation
        tg.input = decode(databus)
        tg.cycle_count = decode(databus).cycle_count

        // increment program counter
        cpu.pc = cpu.pc + 1
        cpu.adl = cpu.pc & 0xFF
        cpu.adh = (cpu.pc >> 8) & 0xFF

        // next state
        sm.state++

        // reset random control logic signals
        cpu.SBX = 0
        cpu.SBY = 0
        cpu.ADDSB7 = 0;
        cpu.ADDSB06 = 0;
        cpu.SUMS = 0;

        continue;
    }

}


