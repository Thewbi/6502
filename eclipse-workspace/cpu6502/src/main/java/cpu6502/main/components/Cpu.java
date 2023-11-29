package cpu6502.main.components;

import cpu6502.instructions.Instructions;

public class Cpu {

	// x and y register
	//
	// The Index registers X and Y
	// The 6502 has 2 index registers, called X and Y. They are both 8 bits wide and can be used as temporary registers, 
	// or as index pointers in a variety of addressing modes. The index registers can not be used for arithmetic operations.
	public int x;
	public int y;

	// instruction register
	public int ir;

	// program counter
	public int pc;

	// address registers
	public int adl;
	public int adh;

	// enable signal for the x and y register
	public boolean SBX;
	public boolean SBY;

	public byte[] codeSegment;

	public byte fetch;
	//public byte execute;
	public Instructions execute;
	
	// data bus and s bus ???
	public byte databus;
	public int sb;
	
	// adder hold register will output to SB
	public boolean ADDSB7;
	public boolean ADDSB06;
	
	// input to the ALU, ALU will perform summation
	public boolean SUMS;
	
	// input to the ALU b input register, when DBADD is true, the ALU b input register will latch the databus (See Dr. Hansons Diagram)
	public boolean DBADD;

	public void reset() {
		x = 0;
		y = 0;

		// instruction register
		ir = 0;

		// program counter
		pc = 0;

		// address registers
		adl = 0;
		adh = 0;

		// enable signal for the x and y register
		SBX = false;
		SBY = false;
		
		ADDSB7 = false;
		ADDSB06 = false;
		SUMS = false;
		
		DBADD = false;
	}

}
