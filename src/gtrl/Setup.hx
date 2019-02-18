package gtrl;

typedef RoomSize = {
	w : Int,
	h : Int,
	d : Int,
}

typedef SensorSetup = {
	name : String,
	type : String,
	interval : Int, // sec
	enabled: Null<Bool>,
	driver : {
		type : String,
		options : Dynamic
	}
}

typedef RoomSetup = {
	name : String,
	size : RoomSize,
	sensors : Array<SensorSetup>
}

typedef Setup = Array<RoomSetup>;
