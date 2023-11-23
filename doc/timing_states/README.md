= Timing States =

== Branch Instructions ==

Sources:
[1] https://www.cs.columbia.edu/~sedwards/classes/2013/4840/reports/6502.pdf
[2] https://www.nesdev.org/wiki/Visual6502wiki/6502_State_Machine

The state machine for branch-instructions is different from the state machines for non-branch instructions.
The other state machines always return to the state T0 to execute the next instruction when they have
finished executing the current instruction.

The difference with the state machine for branches is that the state machine for branches knows three 
cases in total. It returns to T1 to start the next instruction, if the branch is not taken. It returns to
T1 for the next instruction, when the branch is taken without a page crossing. It does in fact return
to T0 for the next instruction in case 3 which is defined by a branch that is taken but with a page crossing.

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

Question: what happens if a branch jumps directly onto another branch? If there is no T0 executed, are
instructions still prefetched?
Answer: yes, see the table below. The prefetch takes place in T2 and T3 so skipping T0 has no effect
on the prefetching.

The information that instructions are prefetched is taken from [2].

```
Tn  address bus     data bus         comments
--------------------------------------------------------
T0  PC              branch opcode    fetch opcode
T1  PC + 1          offset           fetch offset
T2  PC + 2          next opcode      fetch for branch not taken
T3  PC + 2 + off    next opcode      fetch for branch taken, same page
    (w/o carry)
T0  PC + 2 + off    next opcode      fetch for branch taken, other page
    (with carry)

(T3/T4 or just T4 are left away if branch not taken or no
page crossing).
```