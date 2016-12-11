LD37: "One Room"
# CodePath
Brainstorm: FPS hacking/programming escape game. Navigate and climb a shaft of traps and puzzles to escape to freedom. You can walk, run, jump, and use your hacking tool on machines. The hacking tool gives you a page of assembly code to edit and a matrix of hex numbers to monitor RAM. It's critical to analyse the existing code to understand its functionality and problems, so that it can be edited to perform the task you need to progress. For instance a program might trigger an elevator to rise by setting a value in memory once an interrupt is raised, but the elevator needs to rise higher and only after a delay. Shared memory buses are common. Each machine has its own internal memory, but also a set of mapped external memory controllers, frequently just a few bytes long. For instance, perhaps every door on a floor share a memory block with each byte signifying a door's opened state, letting one door manipulate others etc.

The hacking tool is really just a gun you shoot at a hackable machine to establish a tether and bringing up a coding UI.

## Tech choices
- Haxe to CPP for microcontroller stuff
- Unreal4 for everything else

## Progress:
Simple microcontroller simulation with sleeping, interrupts and DMA: [Check](http://sunjammer.github.io/LD37/CodePath/bin).

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

BNE(b:Value, pos:Value); //Branch to pos if A != b
BEQ(b:Value, pos:Value); //Branch to pos if A == b
BLT(b:Value, pos:Value); //Branch to pos if A < b
BGT(b:Value, pos:Value); //Branch to pos if A > b

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
