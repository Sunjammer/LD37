package vm;

/**
 * @author Andreas Kennedy
 */
typedef Program = { instructions:haxe.ds.Vector<Instruction>, interrupts:Map<Int, Int> };