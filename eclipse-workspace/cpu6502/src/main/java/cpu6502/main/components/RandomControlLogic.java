package cpu6502.main.components;

import cpu6502.instructions.InstructionDecode;
import cpu6502.instructions.Instructions;

public class RandomControlLogic {

	public RandomControlLogicState state = RandomControlLogicState.T1;

//	public boolean init_state;

	public RandomControlLogic() {
		state = RandomControlLogicState.T1;
		// init_state = false;
	}

	public void transitionToNextState(Instructions instruction) {

		int cycleCount = InstructionDecode.getCycleCount(instruction);

//		// if the state machine is on the last cycle_count of the current instruction
//		if (state == ) {
//
//			// add T0 cycle for the next instruction
//			rcl.init_state = true;
//		}

		switch (state) {

		case T0:
			state = RandomControlLogicState.T1;
			break;

		case T0_T2:
			state = RandomControlLogicState.T1;
			break;

		case T1:
			if (2 == cycleCount) {
				state = RandomControlLogicState.T0_T2;
			} else {
				state = RandomControlLogicState.T2;
			}
			break;

		case T2:
			if (3 == cycleCount) {
				state = RandomControlLogicState.T0;
			}
			break;

		case T3:
			if (4 == cycleCount) {
				state = RandomControlLogicState.T0;
			}
			break;

		default:
			throw new RuntimeException("Unknown state: " + state);

		}

	}

	public void dump() {
		switch (state) {

		case T0:
			System.out.print(String.format("%1$-6s", "T0"));
			break;

		case T0_T2:
			System.out.print(String.format("%1$-6s", "T0_T2"));
			break;

		case T1:
			System.out.print(String.format("%1$-6s", "T1"));
			break;

		case T2:
			System.out.print(String.format("%1$-6s", "T2"));
			break;

		case T3:
			System.out.print(String.format("%1$-6s", "T3"));
			break;

		default:
			throw new RuntimeException("Unknown state: " + state);

		}
		
	}

}
