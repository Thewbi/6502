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
	
	// the AC register
	public int a;

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
	
	// AC register latches the value on the sbus
	public boolean SBAC;

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
	
	// SEC - set carry and Clear Carry. For set carry, the random control logic will set the IR5/C signal
	// The status register will read this signal and set the carry flag
	public boolean ir5C;
	
	// SEC - set interrupt and clear interrupt. For set interrupt and clear interrupt, the random control logic will set the IR5/C signal
	// The status register will read this signal and set the interrupt flag
	public boolean ir5I;
	
	// connect databus to sbus
	public boolean SBDB;

	public void reset() {
		x = 0;
		y = 0;
		
		// the Accumulator (AC) register
		a = 0;

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
		
		//
		// PLA
		//
		
		SUMS = false;
		
		//
		// Datapath Control (DPCtrl, DPControl aka. Random Control Logic) Signals
		//
		// Imagine a CPU of any sort be a toolbox of individual hardware components 
		// that float around in the electronic silicon void. The sum of all these
		// components is called the datapath. Dr. Hansons has displayed the datapath
		// on the right hand side of his diagram. https://www.witwright.com/DonPub/6502-Block-Diagram.pdf
		//
		// When a instruction appears on the databus, 
		// the microcode of the CPU has to wire up the correct components
		// in it's toolbox/datapath to produce a configuration of the CPU on the fly that is 
		// capable of correctly executing the instruction! It has to enable the correct
		// bus lines and registers and ALU inputs and outputs and memory addresses so that
		// the instruction is executed. Then the configuration is forgotten and the cycle
		// repeat for the next instruction where the CPU is again configured differently 
		// to adapt to the next requirements. A CPU is not a fixed machine, it is a flexible
		// fabric that is shaped to adept to the current instruction. 
		//
		// The Datapath Control is the sum of all signals that can be used to configure 
		// the datapath. Dr. Hanson has display the PLA and the Random Control Logic which
		// shape the Datapath Control on the left-hand side of his diagram. https://www.witwright.com/DonPub/6502-Block-Diagram.pdf
		//
		// The names of the signals are choosen to be the same as in the visual 6502 emulator http://www.visual6502.org/JSSim/expert.html
		// because it is easier to debug the CPU by comparing it to the visual 6502 which is a real running machine than comparing
		// it to Dr.Hansons Diagramm which is only a static picture of the architecture.
		// 

		// enable signal for the x and y register
		// Hanson: SB/X, Visual6502: SBX
		SBX = false;
		// Hanson: SB/Y, Visual6502: SBY
		SBY = false;
		
		// sbus into accumulator register AC
		//
		// AC register latches the value on the sbus
		// Hanson: AC/SB, Visual6502: SBAC
		SBAC = false;
		
		// Adder Hold Register onto the SB (sbus)
		//
		// which bits go from the Adder Hold Register which will store the output of an ALU operation onto the sbus.
		// The 6502 allows the user to transfer any combination of bit(7) and the group of bits (6-0)
		// from the Adder Hold Register over onto the sbus. I do not know how this is used to our benefit just yet!
		ADDSB7 = false;
		ADDSB06 = false;
		
		DBADD = false;
		
		ir5C = false;
		ir5I = false;
		
		// direct connection between the data bus and the sbus
		SBDB = false;
	}

	public void dump() {
		System.out.print(" db:" + String.format("%1$02X", (databus & 0xFF)));
		System.out.print(" Fetch:" + String.format("%1$-6s", Instructions.getNameWithEmptyOption(fetch)));
		System.out.print(" pc:" + String.format("%1$-4s", pc));
		System.out.print(" a:" + Integer.toString(a, 16));
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
		
		System.out.print(String.format("%1$-20s", (" PLA: " + (SUMS ? "SUMS" : ""))));
		
		System.out.print(" DPCtrl: " + (SBX ? "SBX " : "") + (SBY ? "SBY" : "") + (SBAC ? "SBAC" : ""));
	}

}
