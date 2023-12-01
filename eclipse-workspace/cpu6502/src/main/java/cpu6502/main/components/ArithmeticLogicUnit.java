package cpu6502.main.components;

public class ArithmeticLogicUnit {
	
	public int aInputRegister;
	public int bInputRegister;
	
	public boolean sums;
	public boolean ands;
	public boolean eors;
	public boolean ors;
	public boolean srs;
	
	public int adderHoldRegister;
	
	public ArithmeticLogicUnit()
	{
		aInputRegister = 0;
		bInputRegister = 0;
	}

	public void compute(int accumulator) {
		if (sums) {
			adderHoldRegister = accumulator + aInputRegister + bInputRegister;
			sums = false;
		}
	}

}
