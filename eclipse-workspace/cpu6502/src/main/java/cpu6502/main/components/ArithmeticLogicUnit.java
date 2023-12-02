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

	public void compute(/*int accumulator, */int carry_in) {
		
		//System.out.println("sums: " + sums + " alua: " + String.format("%1$02X", (aInputRegister & 0xFF)) + " alub: " + String.format("%1$02X", (bInputRegister & 0xFF)));
		if (sums) {
			
			//int accumulatorTemp = (accumulator & 0xFF);
			int carryTemp = (carry_in & 0xFF);
			adderHoldRegister = /*accumulatorTemp + */aInputRegister + bInputRegister + carryTemp;
			sums = false;
		}
	}

}
