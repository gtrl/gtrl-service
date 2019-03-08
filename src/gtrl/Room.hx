package gtrl;

import gtrl.Sensor;

typedef Size = {
	var w : Int;
	var h : Int;
	var d : Int;
}

class Room {

	public dynamic function onData<T>( s : Sensor<T>, d : T ) {}
	//public dynamic function onError<T>( s : Sensor<T>, e : Sensor.ErrorType ) {}
	public dynamic function onError<T>( s : Sensor<T>, e : Error ) {}

	public var name(default,null) : String;
	public var size(default,null) : Size;
	public var sensors(default,null) : Array<Sensor<Any>>;

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
					s.onError = function(e){
						//handleSensorError( s, type );
						handleSensorError( s, e );
					}
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
		for( s in sensors ) s.startInterval();
	}

	public function stop() {
		for( s in sensors ) s.stopInterval();
	}

	public function toString() : String {
		return '$name '+sensors.map( s -> return '[${s.toString()}]' ).join(' ');
	}

	function handleSensorData<T>( sensor : Sensor<T>, data : T ) {
		onData( sensor, data );
	}

	function handleSensorError<T>( sensor : Sensor<T>, error : Error ) {
		onError( sensor, error );
	}

	/*
	function handleSensorError<T>( sensor : Sensor<T>, type : Sensor.ErrorType ) {
		onError( sensor, type );
		//onError( new SensorError( sensor, type ) );
	}
	*/

	/*
	function handleSensorError( e : SensorError ) {
		//onError( sensor, type );
		onError( sensor, type );
	}
	*/
}
