package gtrl;

typedef RoomSize = {
	w : Int,
	h : Int,
	d : Int,
}

typedef SensorSetup = {
	name : String,
	type : String,
	interval : Null<Int>, // sec
	enabled: Null<Bool>,
	driver : {
		type : String,
		options : Dynamic
	}
}

typedef RoomSetup = {
	name : String,
	size : RoomSize,
	interval : Null<Int>, // sec
	sensors : Array<SensorSetup>
}

typedef Setup = Array<RoomSetup>;
