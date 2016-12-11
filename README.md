# LD37
Ludum Dare 37




```Haxe
/**
 * Microcontroller spec:
 * 1mhz processor
 * 128 bytes of work ram (8 bit ints) :
   * 0 : accumulator
   * 1 : register X
   * 2 : register Y
   * 3 : program counter
   * 4 : stack pointer
   * 112-128 : stack (16 bytes)
 *
 * "Cheap" DMA (only pay cycles for the mem access)
  * Blit data from/to memory blocks
  * Configured by setting 4 bytes of work ram
  * 1. config byte of 2 4bit ints for source map / destination map
  * 2. Source offset
  * 3. Source length
  * 4. Destination offset
 * Implementations can offer readwritable IO using DMA maps or RAM mappings
 * Interrupt handlers are bound by labelled instructions prefixed with IRQ (hardware specific)
 */

/**
 * Syntax:
 * 	INSTRUCTION ARG0 ... ARGN
 * 	;Comment
 * 	alias word value
 *  label:
 *  int values only unless TRC which can print a single string
 * 	int value prefix with # is a memory address
 *  int value prefix with ## is a rom address
 * 	int value prefix with @ is a relative program counter offset
 * 	A, X and Y reference registers/"fastmem"
 * 	A is accumulator, generally used for arithmetic results
 */


LDA(v:Value); //Load value into A
LDX(v:Value); //Load value into X
LDY(v:Value); //Load value into Y
STA(v:Value); //Store A at memory
STX(v:Value); //Store X at memory
STY(v:Value); //Store Y at memory
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
AND(v:Value); //& v with A and put the result in A
IOR(v:Value); //| v with A and put the result in A
XOR(v:Value); //^ v with A and put the result in A
LSH(v:Value); //Leftshift A by v and put the result in A
RSH(v:Value); //Rightshift A by v and put the result in A

BNE(a:Value, b:Value, pos:Value); //Branch to pos if a != b
BEQ(a:Value, b:Value, pos:Value); //Branch to pos if a == b
BLT(a:Value, b:Value, pos:Value); //Branch to pos if a < b
BGT(a:Value, b:Value, pos:Value); //Branch to pos if a > b

SLI; //Sleep until interrupt
SLP(v:Value); //Sleep for N cycles

JMP(v:Value); //Set program counter for next instruction
JSR(v:Value); //Begin subroutine
RTS; //Return from subroutine
RTI; //Return from interrupt

DMA(v:Value); //Trigger DMA (weirdness abounds)

BRK; //End program
NOP; //No operation

/* Debug stuff */
OUT(v:Dynamic); //Print value
MEM(a:Value, b:Value); //Print memory range from A to B
```