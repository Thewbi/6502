package cpu6502.main.components;

public class ArithmeticLogicUnit {
	
	public byte aInputRegister;
	public byte bInputRegister;
	
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

	public void compute() {
		if (sums) {
			adderHoldRegister = aInputRegister + bInputRegister;
			sums = false;
		}
	}

}
