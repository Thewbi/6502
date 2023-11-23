# Timing States

## Timing Generator

The amount of cycles it takes to execute an instruction on the 6502 chip at most, i.e. in
the worst case is encoded in the 6502 instruction itself.

The 6502 has a component called the **predecoder**. The predecor when given the next instruction 
in the instruction register will determine the amount of cycles that the instruction takes by
decoding it from the instruction.

It will pass this information on to the **timing generator** component. The timing generator takes
the amount of cycles and the instruction in the instruction register and it keeps traversing
a internal state machine. This state machine takes different paths based on the instruction
it sees in the instruction register. The state machine inside the timig generator knows three
groups of instructions (Normal, branch and read-modify-write instructions). The three groups
can be used to describe the timing generator more easily and once only for each group.

As the timing generator traverses through it's internal state machine it creates output signals.
Basically, the current state that the machine is in, is it's output signal. (This is the
definition of a Moore state machine, Mealy also takes the intput into consideration). The current
state is the output of the timing generator and the input into the **random control logic**.

The random control logic takes the current timing state and the instruction from the instruction
register and looks up signals for all the control lines inside the 6502 chip. The signals for
all the control lines are stored inside a fixed ROM-chip. The control lines will the configure
the chip so it is ready to execute the instruction that is currently stored in the instruction
register.

The name timing generator is misleading in my opinion since the timing generator does not 
generate a clock signal! It also has nothing to do with a wall clock or any clock! The only
thing that it does it produce an output signal that makes the random control logic perform
the correct steps.

The state machine inside the timing generator is executed for one instruction at a time. There
is no pipelining. When the state machine arrives at one of the end states, that means that
the current instruction has been executed and it is time to execute the next instruction.
In this case the statemachine will return to the start state and fetch the next instruction.

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