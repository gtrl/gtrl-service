package gtrl;

import gtrl.sensor.Driver;

@:keep
@:keepSub
class Sensor<T> {

	public dynamic function onData( data : T ) {}

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
		return driver.disconnect();
	}

	public function start() {
		timer = new Timer( interval * 1000 );
		timer.run = function() {
			driver.read( handleData );
		}
	}

	public function toString() : String {
		return '(name=$name,driver=${driver.toString()})';
	}

	function handleData( buf : Buffer ) {
	}
}
