package cpu6502.main;

import cpu6502.instructions.InstructionDecode;
import cpu6502.instructions.Instructions;
import cpu6502.main.components.ArithmeticLogicUnit;
import cpu6502.main.components.Cpu;
import cpu6502.main.components.RandomControlLogic;

public class Main {

	public static void main(String[] args) {

		System.out.println("Test");
		
		//
		// Code Segment
		//

		// LDX #1
		// LDY #2
		int idx = 0;
		byte[] codeSegment = new byte[100];
		// LDX #1
		codeSegment[idx++] = (byte) 0xA2; // -94
		codeSegment[idx++] = (byte) 0x01; // 1
		// LDY #2
		codeSegment[idx++] = (byte) 0xA0; // -96
		codeSegment[idx++] = (byte) 0x02; // 2
		
		//
		// Components
		//
		
		RandomControlLogic rcl = new RandomControlLogic();
		
		ArithmeticLogicUnit alu = new ArithmeticLogicUnit();
		
		// the instruction decode PAL knows how many cycle each instruction has
		InstructionDecode instructionDecode = new InstructionDecode();

		Cpu cpu = new Cpu();
		cpu.reset();
		cpu.codeSegment = codeSegment;

		// bootstrap the CPU
		cpu.pc = 0;
		cpu.ir = 0;
		cpu.adl = cpu.pc & 0xFF;
		cpu.adh = (cpu.pc >> 8) & 0xFF;

		// this happens in T1
		cpu.fetch = codeSegment[cpu.pc];
		cpu.databus = cpu.fetch;
		// during bootstrapping, the CPU is executing BRK! (See Visual6502)
		cpu.execute = Instructions.BRK;
		
		// do not load into X and Y registers initially
		cpu.SBX = false;
		cpu.SBY = false;
		
		// start the next instruction
        cpu.execute = Instructions.fromValue(cpu.ir);
		
		boolean done = false;
		int cycleCount = 0;
		while (!done && cycleCount < 5)
		{
			cpu.databus = codeSegment[cpu.pc];
			
	        if (rcl.state == 2) {
	        	
	        	// start the next instruction
		        cpu.execute = Instructions.fromValue(cpu.ir);
		        
				// if the state machine is on the last cycle_count of the current instruction
			    if (rcl.state == instructionDecode.getCycleCount(cpu.execute)) {
	
			        // add T0 cycle for the next instruction
			    	rcl.init_state = true;
			    }

		        if (cpu.execute == Instructions.LDX)
		        {
		            // activate the inputs of the ALU but do not compute the ALU yet
		            cpu.ADDSB7 = true;
		            cpu.ADDSB06 = true;
		            cpu.SUMS = true;
		            cpu.DBADD = true;
		        }
		        if (cpu.execute == Instructions.LDY)
		        {
		            // activate the inputs of the ALU but do not compute the ALU yet
		            cpu.ADDSB7 = true;
		            cpu.ADDSB06 = true;
		            cpu.SUMS = true;
		            cpu.DBADD = true;
		        }
		        
		        // read inputs, compute output
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

		        // back to state T1
		        rcl.state = 1;
		        
		    } else if (rcl.state == 1) {

		        // this happens in T1
		        cpu.fetch = codeSegment[cpu.pc];
		        cpu.databus = cpu.fetch;

		        if (cpu.execute == Instructions.LDX)
		        {
		            // activate input to the X-Register
		            cpu.SBX = true;
		            if (cpu.SBX) {
		            	// read current value from SB which is computed by the ALU
		            	cpu.x = cpu.sb;
		            }
		        }
		        if (cpu.execute == Instructions.LDY)
		        {
		            // activate input to the X-Register
		            cpu.SBY = true;
		            if (cpu.SBY) {
		            	// read current value from SB which is computed by the ALU
		            	cpu.y = cpu.sb;
		            }
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
		        
		    }
	        
	        // increment program counter
	        cpu.pc += 1;
	        cpu.adl = (byte)(cpu.pc & 0xFF);
	        cpu.adh = (byte)((cpu.pc >> 8) & 0xFF);

	        // next cycle
		    cycleCount++;
		}

	}

}
