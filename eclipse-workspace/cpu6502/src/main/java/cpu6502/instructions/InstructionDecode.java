package cpu6502.instructions;

public class InstructionDecode {

	/**
	 * How many cycles does the instruction take. Important for returning to state 0 of the state machines
	 * 
	 * @param instruction
	 * @return
	 */
	public int getCycleCount(Instructions instruction) {
		
		switch (instruction) {
		
		case BRK:
			return 2;
			
		case LDX:
			return 2;
			
		case LDY:
			return 2;

		default:
			throw new RuntimeException("Unknown instruction! " + Instructions.getName(Instructions.BRK));
		}
	}

}
