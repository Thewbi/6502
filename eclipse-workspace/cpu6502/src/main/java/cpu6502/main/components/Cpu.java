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
	
	/** the AC register */
	public int a = 0xaa; // why this initial value??? It is copied from Visual6502

	/** instruction register */
	public int ir;
	
	/** address bus registers (high and low) */
	public int abl;
	public int abh;
	
	/** flags */
	/** carry flag */
	public boolean carry;
	/** zero flag */
	public boolean zero;
	/** interrupt flag */
	public boolean interrupt;
	/** decimal flag */
	public boolean decimal;
	/** brk flag */
	public boolean brk;
	/** overflow flag */
	public boolean overflow;
	/** negative flag */
	public boolean negative;

	/** program counter */
	public int pc;
	
	/** these signals control if the PC is placed onto the address lines
	 PC-low to address low */
	public boolean PCL_ADL;
	/** PC-high to address high */
	public boolean PCH_ADH;

	/** address registers (the PC is split and stored into these registers) */
	public int adl;
	public int adh;
	
	/** data output register (dor)
	This register latches the value currently available on the databus in every phase 2
	Since this emulator has no phases, it is assigned db in every state.
	This register is connected to the memory input and output line (d0 - d7) in Dr. Hansons diagram.
    For instructions that access memory such as STA absolute, the value stored in the Accumulator (A) register
	is moved into the dor register and from there is it written into memory at the address stored in 
	adl and adh. Memory addresses are 16 bit even in the 8-bit 6502, therefore adl and adh are used to 
	construct a 16 bit address.
	 * 
	 */
	public int dor = 0;

	// enable signal for the x and y register
	public boolean SBX;
	public boolean SBY;
	
	// AC register latches the value on the sbus
	public boolean SBAC;

	public byte[] codeSegment;

	public byte fetch;
	public Instructions execute;
	
	/** data bus */
	public int databus;
	public int oldDatabus;
	
	/** sbus ??? */
	public int sb = 0xFF; // initial value from visual 6502
	
	/** adder hold register will output to SB
	 */
	public boolean ADDSB7;
	public boolean ADDSB06;
	
	/** input to the ALU, ALU will perform summation
	 */
	public boolean SUMS;
	
	/** input to the ALU b input register, when DBADD is true, the ALU b input register will latch the databus (See Dr. Hansons Diagram)
	 */
	public boolean DBADD;
	public boolean nDBADD;
	
	/** connects the Accumulator to the databus. It this signal is set, the the content of the AC register are available on the
	 * databus */ 
	public boolean ACDB;
	
	/** SEC - set carry and Clear Carry. For set carry, the random control logic will set the IR5/C signal
	 The status register will read this signal and set the carry flag
	 */
	public boolean ir5C;
	
	/** SEC - set interrupt and clear interrupt. For set interrupt and clear interrupt, the random control logic will set the IR5/C signal
	 The status register will read this signal and set the interrupt flag
	 */
	public boolean ir5I;
	
	/** connect databus to sbus*/
	public boolean SBDB;
	
	/** make the Address Bus Low (ABL) register latch the value located on the ADL (Address Data Line???) bus line in Dr. Hansons Diagram
	 This is used to store the absolute address encoded inside a instruction that accesses memory such as (STA #) into
	 the address bus registers (ABL and ABH) so that the CPU learns which memory cell to access
	 */
	public boolean ADL_ABL;
	
	/** make the Address Bus High (ABH) register latch the value located on the ADH (Address Data Line???) bus line in Dr. Hansons Diagram
	 This is used to store the absolute address encoded inside a instruction that accesses memory such as (STA #) into
	the address bus registers (ABL and ABH) so that the CPU learns which memory cell to access
	*/
	public boolean ADH_ABH;
	public boolean DAA;
	
	//public int carryIn;
	

	public void reset() {
		x = 0;
		y = 0;
		
		// the Accumulator (AC) register
		a = 0xaa; // why this initial value??? It is copied from Visual6502

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
		
		abl = 0;
		abh = 0;

		// address registers
		adl = 0;
		adh = 0;
		
		// data output register (dor)
		dor = 0;
		
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
		
		ACDB = false;
		
		ir5C = false;
		ir5I = false;
		
		// direct connection between the data bus and the sbus
		SBDB = false;
		
		ADL_ABL = true;
		ADH_ABH = true;
		
		PCL_ADL = true;
		PCH_ADH = true;
		
		sb = 0xFF; // initial value from visual 6502
		
		DAA = false;
	}

	public void dump() {
		System.out.print(" db:" + String.format("%1$02X", (databus & 0xFF)));
		System.out.print(" sb:" + String.format("%1$02X", (sb & 0xFF)));
		System.out.print(" Fetch:" + String.format("%1$-6s", Instructions.getNameWithEmptyOption(fetch)));
		System.out.print(" pc:" + String.format("%1$-4s", pc));
		System.out.print(" a:" + String.format("%1$02X", (a & 0xFF)));
		System.out.print(" x:" + String.format("%1$02X", (x & 0xFF)));
		System.out.print(" y:" + String.format("%1$02X", (y & 0xFF)));
		// address bus registers (!= adl = address line registers)
		System.out.print(" abl:" + String.format("%1$02X", (abl & 0xFF)));
		System.out.print(" abh:" + String.format("%1$02X", (abh & 0xFF)));
		System.out.print(" dor:" + String.format("%1$02X", (dor & 0xFF)));
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
		
		System.out.print(" DPCtrl: " + (ADDSB7 ? "ADDSB7 " : "") + (ADDSB06 ? "ADDSB06 " : "") + (PCL_ADL ? "PCL_ADL " : "") + (PCH_ADH ? "PCH_ADH " : "") + (ADL_ABL ? "ADL_ABL " : "") + (ADH_ABH ? "ADH_ABH " : "") + (SBX ? "SBX " : "") + (SBY ? "SBY" : "") + (SBAC ? "SBAC" : ""));
	}

}
