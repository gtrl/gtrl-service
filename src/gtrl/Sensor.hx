package gtrl;

import gtrl.sensor.Driver;

enum abstract ErrorType(Int) to Int {
	var read_fail = 0;
	var value_invalid = 1;
}

@:keep
@:keepSub
class Sensor<T> {

	public dynamic function onData( data : T ) {}
	public dynamic function onError( type : ErrorType ) {}

	public var type(default,null) : String;
	public var name(default,null) : String;
	public var interval(default,null) : Int;

	var driver : Driver;
	var timer : Timer;

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
		stop();
		return driver.disconnect();
	}

	public function start() {
		stop();
		timer = new Timer( interval * 1000 );
		timer.run = function() {
			driver.read( handleData );
		}
	}

	public function stop() {
		if( timer != null ) {
			timer.stop();
			timer = null;
		}
	}

	public function toString() : String {
		return '(name=$name,driver=${driver.toString()})';
	}

	function handleData( buf : Buffer ) {
	}
}
