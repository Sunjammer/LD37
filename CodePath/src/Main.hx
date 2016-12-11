package;
import haxe.Log;
import haxe.PosInfos;
import haxe.ds.Vector;
import js.Browser;
import js.Lib;
import js.html.Window;
import vm.Assembler;
import vm.Machine;

class Main {
  var machines:Array<Machine>;
  var log:Array<String>;

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

  static function main() { new Main(); }

  public function new() {
    var outputField = Browser.document.getElementById("output");
    var runButton = Browser.document.getElementById("runButton");
    Browser.document.onclick = function(event){
      for (m in machines){
        m.RAM[50] = event.x;
        m.RAM[51] = event.y;
        m.interrupt(1);
      }
    }

    runButton.onclick = function(event) {
        log = [];
        buildAndRun();
    }

    var sourceField = Browser.document.getElementById("input");

    sourceField.innerHTML =
    /*"init:
LDA 1 ;dma map 1 (rom)
LSH 4
TAX
LDA 0 ;dma map 0 (ram)
IOR X
STA 10 ;Store config
LDA 0
STA 11 ;Source offset
LDA 10
STA 12 ;Source length
LDA 10
STA 13 ;Destination offset
DMA 10 ;Run DMA with data starting at #10
end:
BRK";*/
    sourceField.innerText =
"tick: SLP 1000
ADD 1
TRC A
JMP tick
end: BRK
IRQ1: TRC #50 ;mouseX
  TRC #51 ;mouseY
  RTI ;Back to sleep
";
    log = [];
    outputField.innerHTML = "";
    Log.trace = function(d:Dynamic, ?pos:PosInfos){
      log.push(d);
      if (log.length > 20) log.shift();
      outputField.innerHTML = log.join("<br/>");
    }
  }

  function buildAndRun(){
    var a = new Machine("Alpha");
    a.ROM = new Vector<Int>(128);
    for (i in 0...a.ROM.length){
      a.ROM[i] = i;
    }
    var sourceField = Browser.document.getElementById("input");

    try{
      a.load(Assembler.assemble(sourceField.innerText));
    }catch (e:Dynamic){
      Browser.alert(e+"");
    }

    machines = [a];

    Browser.window.requestAnimationFrame(update);
  }

  function update(time:Float) {
    try{
      var clock = Math.floor(Machine.CLOCK_RATE / 60); //approx cycles per frame
      while (clock-- > 0) {
        for (m in machines) {
          if (m.isRunning()) {
            m.next();
            if (!m.isRunning()) {
              trace(m.name+" is complete");
            }
          }
        }
      }

      for (m in machines) {
        if (m.isRunning()) {
          Browser.window.requestAnimationFrame(update);
          return;
        }
      }
      trace("All machines done");
    }catch (e:Dynamic){
      Browser.alert(e+"");
    }
  }
}