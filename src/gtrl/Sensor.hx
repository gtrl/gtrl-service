package gtrl;

import gtrl.sensor.Driver;

enum abstract ErrorType(Int) to Int {
	var read_error = 0;
	var value_invalid = 1;
}

class SensorError extends js.lib.Error {

	public final sensor : Sensor<Any>;
	public final type : ErrorType;

	public function new( sensor : Sensor<Any>, type : ErrorType, ?message : String ) {
		super( message );
		this.sensor = sensor;
		this.type = type;
	}
}

@:keep
@:keepSub
class Sensor<T> {

	public dynamic function onData( data : T ) {}
	public dynamic function onError( err : Error ) {}
	//public dynamic function onError( type : ErrorType ) {}
	//public dynamic function onError( e : SensorError ) {}

	public final type : String;
	public final name : String;

	//public var enabled : bool;
	public var interval(default,null) : Int;
	public var reading(default,null) = false;

	var driver : Driver;
	var timer : Timer;

	//TODO: sensor specific options as object, not arguments
	//function new( type : String, name : String, driver : Driver, settings : S ) {
	function new( type : String, name : String, driver : Driver, interval : Int ) {
		this.type = type;
		this.name = name;
		this.driver = driver;
		this.interval = interval;
	}

	public function connect() : Promise<Nil> {
		return driver.connect();
	}

	public function disconnect() : Promise<Nil> {
		stopTimer();
		return driver.disconnect();
	}

	public function startInterval( immediate = true ) { //TODO remove?
		stopTimer();
		if( immediate ) driver.read( handleData );
		timer = new Timer( interval * 1000 );
		timer.run = handleTimer;
	}

	public function stopInterval() {
		stopTimer();
	}

	/*
	public function update() {
		stopTimer();
		//driver.read( handleData );
		startTimer();
	}
	*/

	public function read() {
		//driver.read( handleData );
		if( reading ) {
			trace("ALREADY READING");
		} else {
			stopInterval();
			startInterval( true );
		}
	}

	public function toString() : String {
		return '(name=$name,driver=${driver.toString()})';
	}

	function stopTimer() {
		if( timer != null ) {
			timer.stop();
			timer = null;
		}
	}

	function handleTimer() {
		//reading = true;
		driver.read( handleData );
	}

	function handleData( err : Error, buf : Buffer ) {
		reading = false;
	}
}
