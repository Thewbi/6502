package cpu6502.main;

import cpu6502.instructions.InstructionDecode;
import cpu6502.instructions.Instructions;
import cpu6502.main.components.ArithmeticLogicUnit;
import cpu6502.main.components.Cpu;
import cpu6502.main.components.RandomControlLogic;
import cpu6502.main.components.RandomControlLogicState;

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
		// LDA #3

//		// LDX #1 - load x with 1
//		codeSegment[idx++] = (byte) 0xA2; // -94
//		codeSegment[idx++] = (byte) 0x01; // 1
//		// LDY #2 - load y with 2
//		codeSegment[idx++] = (byte) 0xA0; // -96
//		codeSegment[idx++] = (byte) 0x02; // 2
//		// LDA #3 - load a with 3
//		codeSegment[idx++] = (byte) 0xA9; // 
//		codeSegment[idx++] = (byte) 0x03; // 3

		// Snippet - SEC, CLC - set and clear the carry flag
		//
		// https://www.pagetable.com/c64ref/6502/?tab=2#CLC

//		// sec    - set the carry flag (1 -> C)
//		codeSegment[idx++] = (byte) 0x38;
//		// clc    - clear the carry flag (0 -> C)
//		codeSegment[idx++] = (byte) 0x18;

		// Snippet - ADC application
		//
		// clc -- clear the carry flag C
		// lda num1 -- load num1 into the accumulator
		// adc num2 -- perform add with carry and place the result into the accumulator
		// A
		// sta result -- Store Accumulator in Memory (A -> M)
		// rts -- return from subroutine
		//
		// ADC #1 - add with carry 1
		//
		// ADC - Add Memory to Accumulator with Carry
		// A + M + C → A, C
		// (adds accumulator register A and the operand M and the current content of the
		// carry flag C
		// and place the result back into the accumulator A and set a value in the carry
		// flag C)
		//
		// https://www.righto.com/2012/12/the-6502-overflow-flag-explained.html#:~:text=The%206502%20has%20an%208,binary%2C%20decimal%2C%20and%20hexadecimal.
		// https://retro64.altervista.org/blog/an-introduction-to-6502-math-addiction-subtraction-and-more/

//		// clc    - clear the carry flag (0 -> C)
//		codeSegment[idx++] = (byte) 0x18;
//
//		// LDA #3 - load a with 1
//		codeSegment[idx++] = (byte) 0xA9; // 
//		codeSegment[idx++] = (byte) 0x01; // 1
//		
//		// adc 2
//		codeSegment[idx++] = (byte) 0x69;
//		codeSegment[idx++] = (byte) 0x02; // 2

		// Snippet - Set and clear interrupt disable flag I
		//
		// CLI - Clear Interrupt Disable -
		// https://www.pagetable.com/c64ref/6502/?tab=2#CLI
		// Operation: 0 → I
		// This instruction initializes the interrupt disable to a 0.

		// SEI - Set Interrupt Disable -
		// https://www.pagetable.com/c64ref/6502/?tab=2#SEI
		// Operation: 1 -> I
		// initializes the interrupt disable to a 1

//		// CLI
//		codeSegment[idx++] = (byte) 0x58;
//		// SEI
//		codeSegment[idx++] = (byte) 0x78;
		
		// Snippet - https://skilldrick.github.io/easy6502/
		//
		// LDA #$01
		// STA $0200
		// LDA #$05
		// STA $0201
		// LDA #$08
		// STA $0202
		//
		// a9 01 8d 00 02 
		// a9 05 8d 01 02 
		// a9 08 8d 02 02
		
		// LDA #3 - load a with 1
		codeSegment[idx++] = (byte) 0xA9; // LDA_IMM
		codeSegment[idx++] = (byte) 0x01; // 1
		
		// STA $0200
		codeSegment[idx++] = (byte) 0x8d; // STA
		codeSegment[idx++] = (byte) 0x00; // 00
		codeSegment[idx++] = (byte) 0x02; // 02

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

		boolean pcIncrement = true;

		boolean done = false;
		int cycleCount = 0;

		boolean dump = false;

		while (!done && cycleCount < 10) {

			dump = true;

			//
			// ALU Logic
			//

			// run ALU logic, read inputs, compute output
			alu.sums = cpu.SUMS;
			alu.aInputRegister = 0;
			if (cpu.DBADD) {
				alu.bInputRegister = cpu.databus;
			}
			alu.compute(cpu.a);

			// output the value from the adder hold register onto the sbus
			if (cpu.ADDSB7 && cpu.ADDSB06) {
				cpu.sb = alu.adderHoldRegister;
			}

			//
			// CPU status register
			//

			if (cpu.ir5C) {
				// bit 5 of instruction register determines the value of the carry flag
				cpu.carry = (cpu.ir & 0x20) > 0;
				cpu.ir5C = false;
			}
			if (cpu.ir5I) {
				// bit 5 of instruction register determines the value of the carry flag
				cpu.interrupt = (cpu.ir & 0x20) > 0;
				cpu.ir5I = false;
			}

			cpu.databus = codeSegment[cpu.pc];

//			rcl.init_state = false;

			//if ((rcl.state == RandomControlLogicState.T1) || (rcl.state == RandomControlLogicState.T0_T2)) {
			if (rcl.state == RandomControlLogicState.T1) {

				cpu.fetch = codeSegment[cpu.pc];

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
				if (cpu.execute == Instructions.LDA_IMM) {

					// activate input to the AC-Register
					cpu.SBAC = true;
					if (cpu.SBAC) {
						// read current value from SB
						cpu.a = cpu.sb;
					}
				}
//				if (cpu.execute == Instructions.ADC_IMM) {
//					// activate input to the AC-Register
//					cpu.SBAC = true;
//					if (cpu.SBAC) {
//						// read current value from SB
//						cpu.a = cpu.sb;
//					}
//				}

				cpu.ir = cpu.databus;
				
				
				
				
				//
				// output state (before reseting the signals)
				//

				if (dump) {
					dump(cycleCount, rcl, cpu);
					dump = false;
				}
				
				
				
				
				//
				// advance to the next state
				//

				// next state
				//rcl.state++;
				
				//rcl.transitionToNextState(cpu.execute);
				rcl.transitionToNextState(Instructions.fromValue(cpu.ir));
				

				

				// reset data path / random control logic signals
				cpu.SBX = false;
				cpu.SBY = false;
				cpu.SBAC = false;
				cpu.ADDSB7 = false;
				cpu.ADDSB06 = false;

				// reset PLA signals
				cpu.SUMS = false;

			} else if (rcl.state == RandomControlLogicState.T2) {

				executeT2(cpu);
				
				//
				// output state (before reseting the signals)
				//

				if (dump) {
					dump(cycleCount, rcl, cpu);
					dump = false;
				}
				
				//
				// State Machine
				//

				rcl.transitionToNextState(cpu.execute);
			} 
			else if (rcl.state == RandomControlLogicState.T0_T2)
			{
				executeT2(cpu);
				
				// for these instructions the PC does not increment to spread out a one byte
				// instruction over two cycles without incorrectly fetching the second byte
				// that does not exist for one byte instructions!
				if ((cpu.execute == Instructions.SEC) || (cpu.execute == Instructions.CLC)
						|| (cpu.execute == Instructions.SEI) || (cpu.execute == Instructions.CLI)) {
					pcIncrement = false;
				}
				
				//
				// output state
				//

				if (dump) {
					dump(cycleCount, rcl, cpu);
					dump = false;
				}

				//
				// State Machine
				//
				
				rcl.transitionToNextState(cpu.execute);
			}

//			// state T0
//			//if (rcl.init_state) {
//			if (rcl.state == RandomControlLogicState.T0_T2) {
//				
//				// for these instructions the PC does not increment to spread out a one byte
//				// instruction over two cycles without incorrectly fetching the second byte
//				// that does not exist for one byte instructions!
//				if ((cpu.execute == Instructions.SEC) || (cpu.execute == Instructions.CLC)
//						|| (cpu.execute == Instructions.SEI) || (cpu.execute == Instructions.CLI)) {
//					pcIncrement = false;
//				}
//
//				//
//				// output state (before reseting the signals)
//				//
//
//				if (dump) {
//					dump(cycleCount, rcl, cpu);
//					dump = false;
//				}
//			}

			//
			// increment program counter
			//

			if (pcIncrement) {
				cpu.pc += 1;
				cpu.adl = (byte) (cpu.pc & 0xFF);
				cpu.adh = (byte) ((cpu.pc >> 8) & 0xFF);
			}

			pcIncrement = true;

			//
			// next cycle
			//

			cycleCount++;
		}

	}

	private static void executeT2(Cpu cpu) {
		
		
		
		if (cpu.execute == Instructions.ADC_IMM) {
			// activate input to the AC-Register
			cpu.SBAC = true;
			if (cpu.SBAC) {
				// read current value from SB
				cpu.a = cpu.sb;
			}
		}
			
			
			
			
		cpu.fetch = (byte) 0xFF;

		// start the next instruction
		cpu.execute = Instructions.fromValue(cpu.ir);

//		// if the state machine is on the last cycle_count of the current instruction
//		if (rcl.state == instructionDecode.getCycleCount(cpu.execute)) {
//
//			// add T0 cycle for the next instruction
//			rcl.init_state = true;
//		}
		
		//rcl.transitionToNextState(cpu.execute);

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
		if (cpu.execute == Instructions.LDA_IMM) {
			// activate the inputs of the ALU but do not compute the ALU yet
			cpu.ADDSB7 = true;
			cpu.ADDSB06 = true;
			cpu.SUMS = true;
			cpu.DBADD = true;
		}
		if (cpu.execute == Instructions.ADC_IMM) {
			// activate the inputs of the ALU but do not compute the ALU yet
			cpu.ADDSB7 = true;
			cpu.ADDSB06 = true;
			cpu.SUMS = true;
			cpu.DBADD = true;
		}
		if (cpu.execute == Instructions.SEC) {
			// the cpu status register will set the carry flag to the value of bit 5 of the
			// ir
			cpu.ir5C = true;
		}
		if (cpu.execute == Instructions.CLC) {
			// the cpu status register will set the carry flag to the value of bit 5 of the
			// ir
			cpu.ir5C = true;
		}
		if (cpu.execute == Instructions.CLI) {
			// the cpu status register will set the interrupt flag to the value of bit 5 of the
			// ir
			cpu.ir5I = true;
		}
		if (cpu.execute == Instructions.SEI) {
			// the cpu status register will set the interrupt flag to the value of bit 5 of the
			// ir
			cpu.ir5I = true;
		}
	}

	private static void dump(int cycle, RandomControlLogic rcl, Cpu cpu) {
		// the - in -4 left aligns the string
		System.out.print("cycle:" + String.format("%1$-4s", cycle));
		
		rcl.dump();
		
		cpu.dump();

		System.out.println("");

	}

}
