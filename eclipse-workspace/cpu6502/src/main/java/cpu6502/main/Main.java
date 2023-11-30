package cpu6502.main;

import cpu6502.instructions.InstructionDecode;
import cpu6502.instructions.Instructions;
import cpu6502.main.components.ArithmeticLogicUnit;
import cpu6502.main.components.Cpu;
import cpu6502.main.components.RandomControlLogic;

public class Main {

	public static void main(String[] args) {
		
		//
		// Code Segment
		//
		
		int idx = 0;
		byte[] codeSegment = new byte[100];
		
		// https://www.pagetable.com/c64ref/6502/?tab=2

		//
		// example code snippets
		//

		// Snippet - LDX and LDY
		//
		// LDX #1
		// LDY #2
		
		// LDX #1 - load x with 1
		codeSegment[idx++] = (byte) 0xA2; // -94
		codeSegment[idx++] = (byte) 0x01; // 1
		// LDY #2 - load y with 2
		codeSegment[idx++] = (byte) 0xA0; // -96
		codeSegment[idx++] = (byte) 0x02; // 2
		
		// Snippet - SEC, CLC - set and clear the carry flag
		//
		// https://www.pagetable.com/c64ref/6502/?tab=2#CLC
		
//		// sec    - set the carry flag (1 -> C)
//		codeSegment[idx++] = (byte) 0x38;
//		// clc    - clear the carry flag (0 -> C)
//		codeSegment[idx++] = (byte) 0x18;
		
		// Snippet - ADC application
		//
		// clc         -- clear the carry flag C
		// lda num1    -- load num1 into the accumulator
		// adc num2    -- perform add with carry and place the result into the accumulator A
		// sta result  -- Store Accumulator in Memory (A -> M)
		// rts         -- return from subroutine
		//
		// ADC #1 - add with carry 1
		//
		// ADC - Add Memory to Accumulator with Carry
		// A + M + C → A, C 
		// (adds accumulator register A and the operand M and the current content of the carry flag C 
		// and place the result back into the accumulator A and set a value in the carry flag C)
		//
		// https://www.righto.com/2012/12/the-6502-overflow-flag-explained.html#:~:text=The%206502%20has%20an%208,binary%2C%20decimal%2C%20and%20hexadecimal.
		// https://retro64.altervista.org/blog/an-introduction-to-6502-math-addiction-subtraction-and-more/
//		codeSegment[idx++] = (byte) 0x69; // -94
//		codeSegment[idx++] = (byte) 0x01; // 1

		//
		// Components
		//

		RandomControlLogic rcl = new RandomControlLogic();

		ArithmeticLogicUnit alu = new ArithmeticLogicUnit();

		InstructionDecode instructionDecode = new InstructionDecode();

		Cpu cpu = new Cpu();
		cpu.reset();
		cpu.codeSegment = codeSegment;

		// bootstrap the CPU
		cpu.pc = 0;
		cpu.ir = 0;
		cpu.adl = cpu.pc & 0xFF;
		cpu.adh = (cpu.pc >> 8) & 0xFF;

		
		// during bootstrapping, the CPU is executing BRK! (See Visual6502)
		cpu.execute = Instructions.BRK;

		// do not load into X and Y registers initially
		cpu.SBX = false;
		cpu.SBY = false;

		// start the next instruction
		cpu.execute = Instructions.fromValue(cpu.ir);

		boolean done = false;
		int cycleCount = 0;
		
		//dump(cycleCount, cpu);
		
		while (!done && cycleCount < 10) {
			
			cpu.fetch = codeSegment[cpu.pc];
			cpu.databus = cpu.fetch;
			
			cpu.databus = codeSegment[cpu.pc];

			if (rcl.state == 1) {

				if (cpu.execute == Instructions.LDX_IMM) {
					// activate input to the X-Register
					cpu.SBX = true;
					if (cpu.SBX) {
						// read current value from SB which is computed by the ALU
						cpu.x = cpu.sb;
					}
				}
				if (cpu.execute == Instructions.LDY_IMM) {
					// activate input to the X-Register
					cpu.SBY = true;
					if (cpu.SBY) {
						// read current value from SB which is computed by the ALU
						cpu.y = cpu.sb;
					}
				}
				//
				// CPU status register
				//
				
				if (cpu.ir5C) {
					// bit 5 of instruction register determines the value of the carry flag
					cpu.carry = (cpu.ir & 0x20) > 0;
					
					cpu.ir5C = false;
				}

				cpu.ir = cpu.databus;

				// next state
				rcl.state++;

				// reset random control logic signals
				cpu.SBX = false;
				cpu.SBY = false;
				cpu.ADDSB7 = false;
				cpu.ADDSB06 = false;
				cpu.SUMS = false;

			} else if (rcl.state == 2) {

				// start the next instruction
				cpu.execute = Instructions.fromValue(cpu.ir);

				// if the state machine is on the last cycle_count of the current instruction
				if (rcl.state == instructionDecode.getCycleCount(cpu.execute)) {

					// add T0 cycle for the next instruction
					rcl.init_state = true;
				}

				if (cpu.execute == Instructions.LDX_IMM) {
					// activate the inputs of the ALU but do not compute the ALU yet
					cpu.ADDSB7 = true;
					cpu.ADDSB06 = true;
					cpu.SUMS = true;
					cpu.DBADD = true;
				}
				if (cpu.execute == Instructions.LDY_IMM) {
					// activate the inputs of the ALU but do not compute the ALU yet
					cpu.ADDSB7 = true;
					cpu.ADDSB06 = true;
					cpu.SUMS = true;
					cpu.DBADD = true;
				}
				if (cpu.execute == Instructions.SEC) {
					// the cpu status register will set the carry flag to the value of bit 5 of the ir
					cpu.ir5C = true;
				}
				if (cpu.execute == Instructions.CLC) {
					// the cpu status register will set the carry flag to the value of bit 5 of the ir
					cpu.ir5C = true;
				}

				// back to state T1
				rcl.state = 1;

			}

			//
			// ALU Logic
			//

			// run ALU logic, read inputs, compute output
			alu.sums = cpu.SUMS;
			alu.aInputRegister = 0;
			if (cpu.DBADD) {
				alu.bInputRegister = cpu.databus;
			}
			alu.compute();

			// output the value from the adder hold register onto the sbus
			if (cpu.ADDSB7 && cpu.ADDSB06) {
				cpu.sb = alu.adderHoldRegister;
			}
			
			

			//
			// increment program counter
			//

			cpu.pc += 1;
			cpu.adl = (byte) (cpu.pc & 0xFF);
			cpu.adh = (byte) ((cpu.pc >> 8) & 0xFF);
			
			//
			// output state
			//
			
			dump(cycleCount, cpu);
			
			//
			// next cycle
			//

			cycleCount++;
		}
		
	}

	private static void dump(int cycle, Cpu cpu) {
		// the - in -4 left aligns the string
		System.out.print("cycle:" + String.format("%1$-4s", cycle));
		cpu.dump();
		
		System.out.println("");
		
	}

}
