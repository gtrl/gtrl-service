package gtrl;

import haxe.PosInfos;
import js.node.ChildProcess;
import js.node.child_process.ChildProcess as ChildProcessObject;

enum abstract Type(Int) {
	var DHT11 = 11;
	var DHT22 = 22;
	var AM2302 = 22;
}

typedef Data = {
	var temperature : Float;
	var humidity : Float;
}

class Error extends om.error.ErrorType {

	public var sensor(default,null) : Sensor;

	public function new( sensor : Sensor, message : String, ?pos : haxe.PosInfos ) {
		super( message, pos );
		this.sensor = sensor;
	}
}

class Sensor {

	public dynamic function onError( e : Sensor.Error ) {}
	public dynamic function onData( d : Data ) {}

	public var name(default,null) : String;
	public var type(default,null) : Type;
	public var pin(default,null) : Int;
	public var pause(default,null) : Int; //TODO get/set

	var proc : ChildProcessObject;
	var timer : Timer;

	public function new( name : String, type : Type, pin : Int, pause : Int ) {
		this.name = name;
		this.type = type;
		this.pin = pin;
		this.pause = pause;
	}

	public function start() {
		function _read() {
			read( function(e,r){
				if( e != null ) {
					onError( new Error( this, e.message ) );
				} else {
					var data = Json.parse( r );
					//var temperature = (data[0] == null) ? null : data[0].precision(2);
					//var humidity = (data[1] == null) ? null : data[1].precision(2);
					onData( { temperature: data[0], humidity: data[1] } );
					timer = new Timer( pause );
					timer.run = function(){
						timer.stop();
						timer = null;
						_read();
					};
				}
			});
		}
		_read();
	}

	public function stop() {
		if( timer != null ) {
			timer.stop();
			timer = null;
			//proc.exit(0);
		}
	}

	public function read( callback : Error->Dynamic->Void ) {
		if( proc != null ) {
			callback( new Error( this, 'process active' ), null );
		} else {
			var error = '';
			var result = '';
			var args = [ 'bin/read_dht.py', Std.string(pin) ];
			proc = ChildProcess.spawn( 'python', args );
			proc.stdout.on( 'data', function(data) {
				//trace( data.length );
				result += data;
			});
			proc.stderr.on( 'data', function(err) {
				//trace('stderr: ' + err);
				error += err;
				//callback( new Error( err ), null );
			});
			proc.on( 'close', function(code:Int) {
				//trace('close: ' + code);
				proc = null;
				switch code {
				case 0:
					//trace( result );
					callback( null, result.trim() );
				default:
					callback( new Error( this, error.trim() ), null );
				}
			});
		}
	}

}
