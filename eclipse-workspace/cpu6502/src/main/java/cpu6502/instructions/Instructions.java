package cpu6502.instructions;

public enum Instructions {

	/** 0x00 */
	BRK(0x00),

	/** 0x18 */
	CLC(0x18),

	/** 0x38 */
	SEC(0x38),
	
	/** 0x58 */
	CLI(0x58),

	/** 0x69 */
	ADC_IMM(0x69),
	
	/** 0x78 */
	SEI(0x78),
	
	/** 0xA0 */
	LDY_IMM(0xA0),

	/** 0xA2 */
	LDX_IMM(0xA2),
	
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
		case 0x00: // BRK
		case 0x18: // CLC
		case 0x38: // SEC
		case 0x58: // CLI
		case 0x69: // ADC_IMM
		case 0x78: // SEI
		case 0xA0: // LDY_IMM
		case 0xA2: // LDX_IMM
		case 0xA9: // LDA_IMM
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
			
		case 0x58:
			return "CLI";

		case 0x69:
			return "ADC #";
			
		case 0x78:
			return "SEI";

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

		/** 0x00 */
		case BRK:
			return "BRK";

		/** 0x18 */
		case CLC:
			return "CLC";

		/** 0x38 */
		case SEC:
			return "SEC";
			
		/** 0x58 */
		case CLI:
			return "CLI";

		/** 0x69 */
		case ADC_IMM:
			return "ADC #";
			
		/** 0x78 */
		case SEI:
			return "SEI";

		/** 0xA0 */
		case LDY_IMM:
			return "LDY #";

		/** 0xA2 */
		case LDX_IMM:
			return "LDX #";
			
		/** 0xA9 */
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
			
		case 0x58:
			return CLI;

		case 0x69:
			return ADC_IMM;
			
		case 0x78:
			return SEI;

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
