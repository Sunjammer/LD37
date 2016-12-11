package vm;
import haxe.ds.Vector;
/**
 * ...
 * @author Andreas Kennedy
 */
class Machine {
  static inline var MEMSIZE = 128;
  static inline var STACK_OFFSET = MEMSIZE-16;
  public static inline var CLOCK_RATE = 1000;

  public var name(default, null):String;
  public var cycleCount(default, null):Int;
  public var program(default, null):Program;

  public var RAM:Vector<Int>;
  public var ROM(get,set):Vector<Int>;
  public var MEMCTRL(default, null):Array<Vector<Int>>;
  var A(get, set):Int;
  var X(get, set):Int;
  var Y(get, set):Int;
  var pc(get, set):Int;
  var stack(get, set):Int;
  var workLoad:Int;
  var prevWorkLoad:Int;

  inline function get_ROM(){
    return MEMCTRL[1];
  }
  inline function set_ROM(vec:Vector<Int>){
    return MEMCTRL[1] = vec;
  }

  inline function get_A() {
    return RAM[0];
  }
  inline function set_A(v:Int):Int {
    return RAM[0] = v;
  }

  inline function get_X() {
    return RAM[1];
  }
  inline function set_X(v:Int):Int {
    return writeMem(1, v);
  }

  inline function get_Y() {
    return RAM[2];
  }
  inline function set_Y(v:Int):Int {
    return writeMem(2, v);
  }

  inline function get_pc() {
    return RAM[3];
  }
  inline function set_pc(v:Int):Int {
    return writeMem(3, v);
  }

  inline function get_stack() {
    return RAM[4];
  }
  inline function set_stack(v:Int):Int {
    return writeMem(4, v);
  }

  inline function writeMem(p:Int, value:Int):Int {
    return RAM[p] = value;// cast Math.max(0, Math.min(255, value));
  }

  inline function readMem(p:Int):Int{
    return RAM[p];
  }

  public function new(name:String) {
    this.name = name;
    RAM = new Vector<Int>(MEMSIZE);
    MEMCTRL = [RAM];
    reset();
  }

  public function load(prog:Program) {
    program = prog;
  }

  public function isRunning():Bool {
    return pc != -1;
  }

  inline function getValue(v:Value):Int {
    return switch (v) {
      case Relative(v):
        pc + (v-1);
      case Const(v):
        v;
      case Location(l, ram):
        workLoad += 1;
        ram ? RAM[l] : ROM[l];
      case AReg:
        A;
      case XReg:
        X;
      case YReg:
        Y;
    }
  }

  public function reset() {
    workLoad = prevWorkLoad = 0;
    for (i in 0...MEMSIZE)
      RAM[i] = 0;
  }

  function printMem(a:Int = 0, b:Int = MEMSIZE, hex:Bool = true) {
    trace("Memory:");
    for (i in a...b) {
      var str = "\t" + i + "\t";
      str += hex ? "0x"+StringTools.hex(RAM[i], 2) : cast RAM[i];
      trace(str);
    }
  }

  function pushStack(v:Int) {
    if (STACK_OFFSET + stack + 1 > MEMSIZE) throw "Stack overflow";
    workLoad++;
    RAM[STACK_OFFSET + stack] = v;
    stack++;
  }
  function popStack():Int {
    workLoad++;
    if (stack == 0) return 0;
    return RAM[STACK_OFFSET + (stack -= 1)];
  }

  public function step(instruction:Instruction):Int {
    pc++;
    workLoad += 1; //Every instruction has a base cost of 1 + number of operands
    /*
     * Reading from memory adds a cost of 1
     * Writing to memory adds a cost of 1
     */
    switch (instruction) {
      case LDA(v):
        workLoad += 1;
        A = getValue(v);
      case LDX(v):
        workLoad += 1;
        X = getValue(v);
      case LDY(v):
        workLoad += 1;
        Y = getValue(v);
      case STA(v):
        workLoad += 1;
        writeMem(getValue(v), A);
      case STX(v):
        workLoad += 1;
        writeMem(getValue(v), X);
      case STY(v):
        workLoad += 1;
        writeMem(getValue(v), Y);
      case TAX:
        X = A;
      case TXA:
        A = X;
      case TAY:
        Y = A;
      case TYA:
        A = Y;
      case TXY:
        Y = X;
      case TYX:
        X = Y;
      case SLP(v):
        workLoad += getValue(v);
      case SLI:
        pc--;
        workLoad = -1;
      case WRM(pos):
        workLoad += 1;
        writeMem(getValue(pos), A);
      case SUB(v):
        workLoad += 1;
        A -= getValue(v);
      case ADD(v):
        workLoad += 1;
        A += getValue(v);
      case JMP(v):
        workLoad += 1;
        pc = getValue(v);
      case OUT(v):
        workLoad += 1;
        trace(name+":\t"+ (Std.is(v, Value) ? getValue(v) : v));
      case BNE(a, b, pos):
        workLoad += 3;
        if (getValue(a) != getValue(b)) pc = getValue(pos);
      case BEQ(a, b, pos):
        workLoad += 3;
        if (getValue(a) == getValue(b)) pc = getValue(pos);
      case BLT(a, b, pos):
        workLoad += 3;
        if (getValue(a) < getValue(b)) pc = getValue(pos);
      case BGT(a, b, pos):
        workLoad += 3;
        if (getValue(a) > getValue(b)) pc = getValue(pos);
      case AND(a):
        workLoad += 1;
        A = A & getValue(a);
      case IOR(a):
        workLoad += 1;
        A = A | getValue(a);
      case XOR(a):
        workLoad += 1;
        A = A ^ getValue(a);
      case LSH(a):
        workLoad += 1;
        A = A << getValue(a);
      case RSH(a):
        workLoad += 1;
        A = A >> getValue(a);
      case JSR(v):
        workLoad += 1;
        pushStack(pc);
        pc = getValue(v);
      case PHA:
        pushStack(A);
      case PLA:
        A = popStack();
      case RTS:
        pc = popStack();
      case RTI:
        workLoad = prevWorkLoad;
        pc = popStack();
      case BRK:
        pc = -1;
      case MEM(a, b):
        workLoad += 2;
        printMem(getValue(a), getValue(b));
      case NOP:
        workLoad += 1;
      case DMA(v):
        runDMA(getValue(v));
    }
    return pc;
  }

  function runDMA(configStart:Int) {
    workLoad += 5; //Utter nonsense but no time for actual parallelism. Simulate DMA parallelism by simply not costing that much.
    var config = readMem(configStart++);
    var fromOffset = readMem(configStart++);
    var fromLength = readMem(configStart++);
    var dstOffset = readMem(configStart);

    var from = config >> 4 & 0xFF;
    var to = config & 0x0F;

    if (from > MEMCTRL.length - 1)
        throw "Unknown or invalid dma source " + from;
    if (to > MEMCTRL.length - 1)
        throw "Unknown or invalid dma source " + to;

    Vector.blit(MEMCTRL[from], fromOffset, MEMCTRL[to], dstOffset, fromLength);
  }

  public function next() {
    cycleCount++;
    if (workLoad == -1) return;
    if (workLoad > 0) {
      workLoad--;
      return;
    }
    var instruction = program.instructions[pc];
    if (instruction == null) throw "Program counter overflow: " + pc + "/" + program.instructions.length;
    pc = step(instruction);
  }

  public function interrupt(irq:Int) {
    if (!isRunning()) return;
    if (program.interrupts.exists(irq)) {
      prevWorkLoad = workLoad;
      workLoad = 0;
      pushStack(pc);
      pc = program.interrupts[irq];
    }
  }

  public function run(program:Program = null) {
    this.program = program;
    reset();
    try {
      while (isRunning()) next();
      trace("Program completed");
    } catch (e:Dynamic) {
      trace("Program crashed at " + pc + ": "+e);
    }
  }
}