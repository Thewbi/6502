package cpu6502.instructions;

public class InstructionDecode {

	/**
	 * How many cycles does the instruction take. Important for returning to state 0
	 * of the state machines
	 * 
	 * @param instruction
	 * @return
	 */
	public int getCycleCount(Instructions instruction) {

		switch (instruction) {

		/** 0x00 */
		case BRK:
			return 2;
			
		/** 0x18 */
		case CLC:
			return 2;
			
		/** 0x38 */
		case SEC:
			return 2;
			
		/** 0x58 */
		case CLI:
			return 2;
			
		/** 0x69 */
		case ADC_IMM:
			return 2;
			
		/** 0x78 */
		case SEI:
			return 2;
			
		/** 0xA0 */
		case LDY_IMM:
			return 2;

		/** 0xA2 */
		case LDX_IMM:
			return 2;
		
		/** 0xA9 */
		case LDA_IMM:
			return 2;

		default:
			throw new RuntimeException("Unknown instruction! " + instruction);
		}
	}

}
