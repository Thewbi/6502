package cpu6502.instructions;

public enum Instructions {

	/** 0x00 */
	BRK(0x00),
	
	/** 0x00 */
	LDX(0xA2),
	
	/** 0x00 */
	LDY(0xA0),

	/** 0xFF */
	UNKNOWN(0xFF);

	private int numVal;

	Instructions(final int numVal) {
		this.numVal = numVal;
	}

	public int getNumVal() {
		return numVal;
	}

	public static String getName(final int numVal) {

		switch (numVal) {

		case 0x00:
			return "BRK";
			
		case 0xA0:
			return "LDY";
			
		case 0xA2:
			return "LDX";

		default:
			// return "UNKNOWN";
			throw new RuntimeException("Unknown instruction! numVal:" + numVal);
		}
	}

	public static String getName(final Instructions instruction) {

		switch (instruction) {

		case BRK:
			return "BRK";
			
		case LDY:
			return "LDY";
			
		case LDX:
			return "LDX";

		default:
			// return "UNKNOWN";
			throw new RuntimeException("Unknown instruction! instruction: " + instruction);
		}
	}

	public static Instructions fromValue(final int numVal) {

		switch (numVal & 0xFF) {

		case 0x00:
			return BRK;
		
		case 0xA0:
			return LDY;
			
		case 0xA2:
			return LDX;

		default:
			throw new RuntimeException("Unknown instruction!");
		}
	}

}
