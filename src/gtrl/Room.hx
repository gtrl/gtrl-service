package gtrl;

typedef Size = {
	var w : Int;
	var h : Int;
	var d : Int;
}

class Room {

	public dynamic function onData<T>( s : Sensor<T>, d : T ) {}
	//public dynamic function onError( e : Sensor.Error ) {}

	public var name(default,null) : String;
	public var size(default,null) : Size;
	public var sensors(default,null) : Array<Sensor<Any>>;

	//var fan : Array<Dynamic>;

	public function new( name : String, size : Size, sensors : Array<Sensor<Any>> ) {
		this.name = name;
		this.size = size;
		this.sensors = sensors;
	}

	public function init() : Promise<Nil> {
		return new Promise( function(resolve,reject){
			function connectNext( i : Int ) {
				var s = sensors[i];
				s.connect().then( (_) -> {
					s.onData = function(data){
						handleSensorData( s, data );
					}
					//s.onError = handleSensorData;
					if( ++i < sensors.length ) {
						connectNext( i );
					} else {
						resolve( nil );
					}
				}).catchError( e -> reject(e) );
			}
			connectNext( 0 );
		});
	}

	public function start() {
		for( s in sensors ) s.start();
	}

	/*
	public function stop() {
		for( s in sensors ) {
			s.stop();
		}
	}
	*/

	public function toString() : String {
		var str = '$name';
		for( s in sensors ) str += ' ['+s.toString()+']';
		return str;
	}

	function handleSensorData<T>( sensor : Sensor<T>, data : T ) {
		//trace(sensor.name+': '+data);
		onData( sensor, data );
	}
}
