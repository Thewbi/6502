package cpu6502.instructions;

public enum Instructions {

	/** 0x00 */
	BRK(0x00),

	/** 0x18 */
	CLC(0x18),

	/** 0x38 */
	SEC(0x38),

	/** 0x69 */
	ADC_IMM(0x69),

	/** 0xA2 */
	LDX_IMM(0xA2),

	/** 0xA0 */
	LDY_IMM(0xA0),
	
	/** 0xA9 */
	LDA_IMM(0xA9),

	/** 0xFF */
	UNKNOWN(0xFF);

	private int numVal;

	Instructions(final int numVal) {
		this.numVal = numVal;
	}

	public int getNumVal() {
		return numVal;
	}

	public static String getNameWithEmptyOption(final int numVal) {
		if (!isInstruction(numVal)) {
			return "";
		}
		return getName(numVal);
	}

	public static boolean isInstruction(int numVal) {
		switch (numVal & 0xFF) {
		case 0x00:
		case 0x18:
		case 0x38:
		case 0x69:
		case 0xA0:
		case 0xA2:
		case 0xA9:
			return true;
		default:
			return false;
		}
	}

	public static String getName(final int numVal) {

		switch (numVal & 0xFF) {

		case 0x00:
			return "BRK";

		case 0x18:
			return "CLC";

		case 0x38:
			return "SEC";

		case 0x69:
			return "ADC #";

		case 0xA0:
			return "LDY #";

		case 0xA2:
			return "LDX #";
			
		case 0xA9:
			return "LDA #";

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

		case SEC:
			return "SEC";

		case ADC_IMM:
			return "ADC #";

		case LDY_IMM:
			return "LDY #";

		case LDX_IMM:
			return "LDX #";
			
		case LDA_IMM:
			return "LDA #";

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

		case 0x38:
			return SEC;

		case 0x69:
			return ADC_IMM;

		case 0xA0:
			return LDY_IMM;

		case 0xA2:
			return LDX_IMM;
			
		case 0xA9:
			return LDA_IMM;

		default:
			throw new RuntimeException("Unknown instruction! numVal: " + numVal);
		}
	}

}
