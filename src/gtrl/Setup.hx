package gtrl;

typedef Setup = Array<{
	name : String,
	size : Dynamic,
	sensors : Array<{
		name : String,
		type : String,
		interval : Int, // sec
		driver : {
			type : String,
			options : Dynamic
		}
	}>
}>
