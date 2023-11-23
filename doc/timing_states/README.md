# Timing States

## Sources

[1] http://forum.6502.org/viewtopic.php?f=8&t=4625
[2] https://www.witwright.com/DonPub/DSH_6502_ComputerArch.pdf
[3] https://www.nesdev.org/wiki/6502_cycle_times

## Timing Generator

The amount of cycles it takes to execute an instruction on the 6502 chip at most, i.e. in
the worst case is encoded in the 6502 instruction itself.

The 6502 has a component called the **predecode logic**. The predeco logic, when given the 
next instruction from the predecode register, will determine the amount of cycles that the 
instruction takes. (How does it know that?). This information is called **TZPRE** in Dr.
Donald Hanson's block diagram according to [1]. TZPRE = "TZERO PREDECODER".
Meaning that TZPRE is one of the states of the timing generator, T0, T1, T2, T3, T4 and T5.
If the timing generator hits that state in the state machine, it is supposed to return to
state T0 because then the instruction execution of the instruction is done! This is required
since especially the state machine for normal instructions is applied to all normal instructions.
Normal instructions exists in various lengths. Some take 3, 4, 5, 6 or 7 steps. The 
state machine has to know when the normal instruction is done.

The original table stored inside the predecode logic is not known to me, but I think it is
possible to use one of the tables that describe how many cycles each opcode takes to execute.
One very usable table is [3]. It has one mnemonic per row and columns for all addressing modes.
The cells contains the cycle count and a + means that there is an extra cycle when page crossing
takes place. Using this table, the predecode logic TZPRE could be implemented in an emulator.

It will pass this information on to the **timing generator** component. The timing generator takes
the amount of cycles (or the state that is the terminating state) and the instruction in the instruction 
register and it keeps traversing a internal state machine. This state machine takes different paths based on the instruction
it sees in the instruction register. The state machine inside the timig generator knows three
groups of instructions (Normal, branch and read-modify-write instructions). The three groups
can be used to describe the timing generator more easily and once only for each group.

As the timing generator traverses through it's internal state machine it creates output signals.
Basically, the current state that the machine is in, is it's output signal. 
(This is the definition of a Moore state machine, Mealy also takes the intput into consideration). 
The current state of the state machine is then combined into a 6 bit information. The 6 bit are
a one hot combination of the states T0, T1, T2, T3, T4 and T5 of the state machine. The machine
is only in one of those states at any point in time, this is the reason why the encoding is one hot.

This 6 bit information is the output of the timing generator and one of the inputs into the 
**decode ROM (PLA)**. The decode ROM (PLA) is a large table. It has 130 rows, called lines and
each line is 21 bits wide. each line checks the six bits from the time generator and other bits
from the instruction register, i.e. the opcode. When a line is activated by the input bits, then 
the decode ROM (PLA) will output a 1, if no line activates it will output a 0. The output of the
decode ROM (PLA) is one input into the **random control logic**.

The random control logic takes the current timing state and the instruction from the instruction
register and produces signals for all the control lines inside the 6502 chip. The signals for
all the control lines are stored inside a fixed ROM-chip. The control lines will then configure
the chip so it is ready to execute the instruction that is currently stored in the instruction
register.

The random control logic also feeds back some data into the timing generator. I have not yet
figured out what that information does exactly.

The name timing generator is misleading in my opinion since the timing generator does not 
generate a clock signal! There is a clock in the 6502 which drives the entire system but that
clock has nothing to do with the timing generator. The timing generator also has nothing to do 
with a wall clock or any clock! The only thing that it does it produce an output signal that 
makes the random control logic perform the correct steps.

The state machine inside the timing generator is executed for one instruction at a time. There
is no pipelining. When the state machine arrives at one of the end states, that means that
the current instruction has been executed and it is time to execute the next instruction.
In this case the statemachine will return to the start state and fetch the next instruction.

## Normal, Linear instructions

Sources:
[1] https://www.cs.columbia.edu/~sedwards/classes/2013/4840/reports/6502.pdf

For normal instructions, the timing generator traverses a state machine that is very linear.

It uses the amount of max cycles from the predecoder to know when to return to state T0.
It needs the max cycle information as this information differs from instruction to instruction.
The longest instructions take seven cycles. The smallest instructions take two cycles.
One byte instructions even waste the T1 cycle because a second byte is loaded in T1 but 
completely ignored. T0 and T1 are always executed.

Also interesting: for one byte instructions, the PC is **not** incremented during T0! 
The predecode-logic makes sure that the PC remains how it was after retrieveing a one 
byte instruction. During T1, the same byte is then read again and ignored. In T1, the
PC is finally incremented and the next real instruction is read. For instructions that
are not one byte, the second byte is a parameter or something and therefore it is ok
to increment PC and read another byte. For one byte instructions it is not ok.

As such there is a transition from all the states back to T0.
T0 and T1 are always executed for every instruction.

There is one branch in the state machine which is taken when there is no page crossing.

The state machine for normal instructions is displayed in [1] and reproduced here:
In order to not clutter the diagram, the return transitions that go back to T0 are not drawn.

```
----------------------------> T0 <-----
|                             |       |
|                             ↓       |
|                             T1      |
|                             |       | (amount of cycles minus one) used up 
|                             ↓       | and no page crossing
|                             T2      |
|                             ...     |
|                             ↓       |
|                             T??? ---- 
| amount of cycles used up    |
| and page crossing           ↓
----------------------------- T???
```

## Branch Instructions

Sources:
[1] https://www.cs.columbia.edu/~sedwards/classes/2013/4840/reports/6502.pdf
[2] https://www.nesdev.org/wiki/Visual6502wiki/6502_State_Machine

The state machine for branch-instructions is different from the state machines for non-branch instructions
such as normal and read-modify-write. The other state machines always return to the state T0 to execute the 
next instruction when they have finished executing the current instruction.

The difference with the state machine for branches is that the state machine for branches knows three 
cases in total. It returns to T1 to start the next instruction, if the branch is not taken. It returns to
T1 for the next instruction, when the branch is taken without a page crossing. It does in fact return
to T0 for the next instruction in case 3 which is defined by a branch that is taken but **with** a page 
crossing.

The state machine for branch instructions is displayed in [1] and reproduced here:

```
branch taken with pagecross
----------------------------> T0
|                             |
|                             ↓
|  -------------------------> T1 <------
|  | branch taken w/o         |        | branch not taken
|  | pagecross                ↓        |
|  |                          T2_b -----
|  |                          |
|  |                          ↓
---+------------------------- T3_b                    
```

The reason why branch instructions skip T0 in case 1 and case 2 is that the microcode for the branch
instructions performs some sort of branch prediction in that it fetches the instruction at the branch
address (when the branch is taken) and it also fetches the address at the address when the branch 
is not taken. It does not know yet if the branch is taken or not, but is has loaded both instructions.
Therefore T0 is not needed any more since T0 has the task of fetching an instruction but that job is 
already done! Case 3 is the only case, where the prefetched instructions are both invalid (since there
is a jump to another page and the 6502 can not load data from other pages apparently wihtout changing ???)

**Question:** what happens if a branch jumps directly onto another branch? If there is no T0 executed, are
instructions still prefetched?
**Answer:** yes, see the table below. The prefetch takes place in T2 and T3 so skipping T0 has no effect
on the prefetching.

The information that instructions are prefetched is taken from [2].

```
Tn  address bus     data bus         comments
--------------------------------------------------------
T0  PC              branch opcode    fetch opcode
T1  PC + 1          offset           fetch offset
T2  PC + 2          next opcode      fetch for branch not taken
T3  PC + 2 + off    next opcode      fetch for branch taken, same page (w/o carry)
T0  PC + 2 + off    next opcode      fetch for branch taken, other page (with carry)

(T3/T4 or just T4 are left away if branch not taken or no page crossing).
```

## Output of the timing logic

Source:
[1] https://www.nesdev.org/wiki/Visual6502wiki/6502_Timing_States
[2] https://www.pagetable.com/?p=39

The timing logic will output 6 bits to the predecode logic (PAL). These six bits
are the timing states T0, T+, T2, T3, T4, and T5 whereas only one of those bits
is set to a 1 since the state machine is only in one of those states at any point.

In the document [2] these states are called T6 T5 T4 T3 T2 T1.