package gtrl;

typedef Size = {
	var w : Int;
	var h : Int;
	var d : Int;
}

class Room {

	public dynamic function onError( e : Sensor.Error ) {}
	public dynamic function onData( s : Sensor, d : Sensor.Data ) {}

	public var name(default,null) : String;
	public var size(default,null) : Size;
	public var sensors(default,null) : Array<Sensor>;

	//var fan : Array<Dynamic>;

	public function new( name : String, size : Size, sensors : Array<Sensor> ) {
		this.name = name;
		this.size = size;
		this.sensors = sensors;
	}

	public function start() {
		for( s in sensors ) {
			s.onData = function(data){
				//trace(data);
				onData( s, data );
			}
			s.onError = function(e){
				trace(e);
			}
			s.start();
		}
	}

	public function stop() {
		for( s in sensors ) {
			s.stop();
		}
	}


}
