package vm;

import haxe.ds.Vector;
using StringTools;
using Std;
using vm.StringUtil;
/**
 * ...
 * @author Andreas Kennedy
 */
class Assembler {
  public static function assemble(source:String):Program {
    var rawlines = source.trim().split("\n");

    //label, comment and trim prepass
    var lines:Array<String> = [];
    var aliases = new Map<String, String>();
    var labels = new Map<String,String>();
    var interrupts = new Map<Int,Int>();
    var count = 0;
    for (i in 0...rawlines.length) {
      var line = rawlines[i].readUntil(";").trim();
      if (line.length == 0) continue;
      if (line.indexOf(":") > -1) {
        if (line.indexOf("IRQ") > -1) {
          interrupts[Std.parseInt(line.substring(3))] = count;
        } else {
          labels[line.substr(0, line.length - 1)] = count+"";
        }
        line = line.readFrom(":").trim();
      }
      if (line.indexOf("alias") >-1) {
        var components = line.split(" ");
        components.shift();
        aliases[components[0]] = components[1];
        continue;
      }
      count++;
      lines.push(line);
    }

    for (i in 0...lines.length) {
      var line = lines[i];
      for (label in labels.keys()) {
        var idx = line.indexOf(label);
        if (idx >-1) {
          lines[i] = line.replace(label, labels[label]);
        }
      }
      for (alias in aliases.keys()) {
        var idx = line.indexOf(alias);
        if (idx >-1) {
          lines[i] = line.replace(alias, aliases[alias]);
        }
      }
    }

    //Generate instructions
    var out = { instructions:new Vector<Instruction>(lines.length), interrupts:interrupts};
    for (i in 0...lines.length) {
      out.instructions[i] = parseLine(lines[i], i);
    }
    return out;
  }

  public static function parseLine(line:String, lineNo:Int):Instruction {
    var tokens = line.split(" ");
    var operator = tokens.shift();
    try {
      var i = Instruction.createByName(operator, [for (t in tokens) toValue(t)]);
      if (i.getParameters().length != tokens.length) throw 'Missing operand';
      return i;
    } catch (e:Dynamic) {
      throw "Syntax error " + operator+" at line "+lineNo+": "+e;
    }
  }

  static function toValue(str:String):Dynamic {
    var v = str.toLowerCase();
    return switch (v) {
      case _.charAt(0) => "@":
        Value.Relative(str.substr(1).trim().parseInt());
      case _.charAt(0) => "#":
        str.indexOf("##") > -1
          ? Value.Location(str.substr(2).trim().parseInt(), false)
          : Value.Location(str.substr(1).trim().parseInt(), true);
      case _.charAt(0) => "a":
        Value.AReg;
      case _.charAt(0) => "x":
        Value.XReg;
      case _.charAt(0) => "y":
        Value.YReg;
      case Std.parseInt(_) => null:
        str;
      case _:
        Value.Const(str.parseInt());

    }
  }
}
