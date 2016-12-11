package vm;

enum Value
{
	Const(v:Int);
	Location(v:Int, ram:Bool);
	Relative(v:Int);
	AReg;
	XReg;
	YReg;
}

