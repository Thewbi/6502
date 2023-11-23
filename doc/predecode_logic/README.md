# Predecode Logic

## Sources

[1] https://retrocomputing.stackexchange.com/questions/4880/6502-what-does-the-predecode-register-exactly-do \
[2] https://www.pagetable.com/?p=39

## Purpose

The databus is connected to the predecode register (!= predecode logic). The predecode register is
connected to the predecode logic.

The predecode register will latch the byte on the databus and store it so that the predecode logic has
a stable input. The byte then goes into the Instruction Register.

The predecode logic has several tasks:

- for one byte instructions it will disable the PC increment because during T1 a new byte is read
from the PC. This new byte contains parameters to the instruction read in T0. For one byte instructions
there is no parameter since the parameter is completely defined by a single byte which is already read.
Therefore reading a parameter byte is suppressed for one byte instructions
- BRK instructions are inserted into the CPU so that interrupts can be handeled at any time.

The predecode logic outputs the instruction to the instruction register.
The timing generation computes the current timing state (T0, T1, T2, ...)

## The decode ROM (PLA)

[2] https://www.pagetable.com/?p=39

The decode ROM (PLA) is connected to the IR and also to the output of the timing generation.
From the instruction stored in the IR and the timing state (T0, T1, T2, ...) it will check if
any of it's lines assert. (To learn how the decode ROM works internally, read [2]).

Every line that asserts leads to a 1 output of the decode ROM (PLA). If not a single line
asserts, the decode ROM (PLA) will output a 0.

The output of the decode ROM (PLA) goes into the Random Control Logic along with a lot of other
inputs.

