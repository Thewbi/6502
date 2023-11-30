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
	
	// flags
	public boolean carry;
	public boolean zero;
	public boolean interrupt;
	public boolean decimal;
	public boolean brk;
	public boolean overflow;
	public boolean negative;

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
	public int databus;
	public int sb;
	
	// adder hold register will output to SB
	public boolean ADDSB7;
	public boolean ADDSB06;
	
	// input to the ALU, ALU will perform summation
	public boolean SUMS;
	
	// input to the ALU b input register, when DBADD is true, the ALU b input register will latch the databus (See Dr. Hansons Diagram)
	public boolean DBADD;
	
	// SEC - set carry. For set carry, the random control logic will set the IR5/C signal
	// The status register will read this signal and set the carry flag
	public boolean ir5C;

	public void reset() {
		x = 0;
		y = 0;

		// instruction register
		ir = 0;
		
		// flags
		carry = false;
		zero = true;
		interrupt = true;
		decimal = false;
		brk = true;
		overflow = false;
		negative = false;

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
		
		ir5C = false;
	}

	public void dump() {
		System.out.print(" db:" + String.format("%1$02X", (databus & 0xFF)));
		System.out.print(" Fetch:" + String.format("%1$-6s", Instructions.getNameWithEmptyOption(fetch)));
		System.out.print(" pc:" + String.format("%1$-4s", pc));
		System.out.print(" x:" + Integer.toString(x, 16));
		System.out.print(" y:" + Integer.toString(y, 16));
		System.out.print(" Execute:" + String.format("%1$-6s", Instructions.getName(execute)));
		
		// flags
		System.out.print(" Flags(p):");
		System.out.print(negative ? "N" : "n");
		System.out.print(overflow ? "V" : "v");
		System.out.print("-");
		System.out.print(brk ? "B" : "b");
		System.out.print(decimal ? "D" : "d");
		System.out.print(interrupt ? "I" : "i");
		System.out.print(zero ? "Z" : "z");
		System.out.print(carry ? "C" : "c");
	}

}
