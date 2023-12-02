package cpu6502.instructions;

public class InstructionDecode {

	/**
	 * How many cycles does the instruction take. Important for returning to state 0
	 * of the state machines.
	 * 
	 * The instructions with bitpatterns xxx010x1, 1xx000x0 and xxxx10x0 except 0xx01000 are two cycle instructions -- https://www.nesdev.org/wiki/Visual6502wiki/6502_State_Machine
	 * 
	 * @param instruction
	 * @return
	 */
	public static int getCycleCount(Instructions instruction) {

		switch (instruction) {

		/** 0x00 */
		case BRK:
			return 7;
			
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
			
		/** 0x8D */
		case STA_ABS:
			return 4;
			
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
