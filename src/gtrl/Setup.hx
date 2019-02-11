package gtrl;

typedef SensorSetup = {
	name : String,
	type : String,
	interval : Int, // sec
	driver : {
		type : String,
		options : Dynamic
	}
}

typedef RoomSetup = {
	name : String,
	size : Dynamic,
	sensors : Array<SensorSetup>
}

typedef Setup = Array<RoomSetup>;
