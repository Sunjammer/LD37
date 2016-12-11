package vm;

enum Instruction
{
	LDA(v:Value); //Load value into A
	LDX(v:Value); //Load value into X
	LDY(v:Value); //Load value into Y
	STA(v:Value); //Store A at memory
	STX(v:Value); //Store X at memory
	STY(v:Value); //Store Y at memory
  WRM(pos:Value); //Write A to memory at pos
	PHA; //Push A on stack
	PLA; //Pull A from stack
	TAX; // Copy A to X
	TXA; // Copy X to A
	TAY; // Copy A to Y
	TYA; // Copy Y to A
	TXY; // Copy X to Y
	TYX; // Copy Y to X
	
	SUB(v:Value); //Subtract value from A
	ADD(v:Value); //Add value to A

  SLI; //Sleep until interrupt
  SLP(v:Value); //Sleep for N cycles
	
	BNE(a:Value, b:Value, pos:Value); //Branch to pos if a != b
	BEQ(a:Value, b:Value, pos:Value); //Branch to pos if a == b
	BLT(a:Value, b:Value, pos:Value); //Branch to pos if a < b
	BGT(a:Value, b:Value, pos:Value); //Branch to pos if a > b
	
	JMP(v:Value); //Set program counter for next instruction
	JSR(v:Value); //Begin subroutine
	RTS; //Return from subroutine
	RTI; //Return from interrupt

  DMA(v:Value); //Trigger DMA
	
	AND(v:Value); //& v with A and put the result in A
	IOR(v:Value); //| v with A and put the result in A
	XOR(v:Value); //^ v with A and put the result in A
	LSH(v:Value); //Leftshift A by v and put the result in A
	RSH(v:Value); //Rightshift A by v and put the result in A
	
	BRK; //End program
	NOP; //No operation
	
	/* Debug stuff */
	TRC(v:Dynamic); //Print value
	MEM(a:Value, b:Value); //Print memory from A to B
}