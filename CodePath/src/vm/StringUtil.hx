package vm;

/**
 * ...
 * @author Andreas Kennedy
 */

class StringUtil{
  public static inline function readUntil(str:String, character:String):String{
    var out = "";
    for (i in 0...str.length) {
      var char = str.charAt(i);
      if (char == character) break;
      out += char;
    }
    return out;
  }
  public static inline function readFrom(str:String, character:String):String{
    var idx = str.lastIndexOf(character) + 1;
    return str.substr(idx);
  }
}