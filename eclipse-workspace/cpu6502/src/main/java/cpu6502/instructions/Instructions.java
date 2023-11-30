package cpu6502.instructions;

public enum Instructions {

	/** 0x00 */
	BRK(0x00),
	
	/** 0x18 */
	CLC(0x18),
	
	/** 0x69 */
	ADC_IMM(0x69),
	
	/** 0xA2 */
	LDX_IMM(0xA2),
	
	/** 0xA0 */
	LDY_IMM(0xA0),

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

		switch (numVal & 0xFF) {

		case 0x00:
			return "BRK";
			
		case 0x18:
			return "CLC";
			
		case 0x69:
			return "ADC #";
			
		case 0xA0:
			return "LDY #";
			
		case 0xA2:
			return "LDX #";

		default:
			throw new RuntimeException("Unknown instruction! numVal:" + numVal);
		}
	}

	public static String getName(final Instructions instruction) {

		switch (instruction) {

		case BRK:
			return "BRK";
			
		case CLC:
			return "CLC";
			
		case ADC_IMM:
			return "ADC #";
			
		case LDY_IMM:
			return "LDY #";
			
		case LDX_IMM:
			return "LDX #";

		default:
			throw new RuntimeException("Unknown instruction! instruction: " + instruction);
		}
	}

	public static Instructions fromValue(final int numVal) {

		switch (numVal & 0xFF) {

		case 0x00:
			return BRK;
			
		case 0x18:
			return CLC;
			
		case 0x69:
			return ADC_IMM;
		
		case 0xA0:
			return LDY_IMM;
			
		case 0xA2:
			return LDX_IMM;

		default:
			throw new RuntimeException("Unknown instruction!");
		}
	}

}
