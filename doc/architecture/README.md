# Architecture

## Sources

[1] https://www.nesdev.org/obelisk-6502-guide/architecture.html

## Overview

- 8 bit CPU
- 16 bit address bus --> 64 Kb of memory addressable
- little endian system, expects data to be stored in memory least significant byte first
- zero page: $0000-$00FF (256 byte), quicker instructions, indirect memory access
- second page: $0100-$01FF (256 byte), contains the stack of 256 byte, the stack cannot be placed anywhere else!
- last 6 bytes of memory $FFFA to $FFFF have to contain the addresses of:
  - the non-maskable interrupt handler ($FFFA/B), 
  - the power on reset location ($FFFC/D) and 
  - the BRK/interrupt request handler ($FFFE/F) respectively.
- no special hardware support (memory mapping of hardware is used)

## Registers

- Program Counter: 16 bit, points to the instruction to execute
- Stack Pointer: 8 bit, points to the lower 8 bits of the free location on the stack.
- Accumulator: 8 bit
- Index Register X: 8 bit
- Index Register Y: 8 bit
- Processor Status: 8 bit