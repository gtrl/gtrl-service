package gtrl;

import js.node.ChildProcess;
import js.node.child_process.ChildProcess as ChildProcessObject;

enum abstract Type(Int) to Int {
	var DHT11 = 11;
	var DHT22 = 22;
	//var AM2302 = 22;
}

typedef Data = {
	var temperature : Float;
	var humidity : Float;
}

class Sensor {

	public dynamic function onError( e : Error ) {}
	public dynamic function onData( d : Data ) {}

	public var name(default,null) : String;
	public var type(default,null) : Type;
	public var pin(default,null) : Int;
	public var exe(default,null) : String;
	public var pause(default,null) : Int;

	var proc : ChildProcessObject;
	var timer : Timer;

	public function new( name : String, type : Type, pin : Int, exe : String, pause : Int ) {
		this.name = name;
		this.type = type;
		this.pin = pin;
		this.exe = exe;
		this.pause = pause;
	}

	public function start() {
		//if( timer != null )
		function _read() {
			read( function(e,r){
				if( e != null ) {
					onError( e );
				} else {
					var data = Json.parse( r );
					//var temperature = (data[0] == null) ? null : data[0].precision(2);
					//var humidity = (data[1] == null) ? null : data[1].precision(2);
					//onData( { temperature: temperature, humidity: humidity } );
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
			trace("PRROCESS ACTIVE");
			return;
		}
		var result = '';
		var args = [ Std.string(pin) ];
		proc = ChildProcess.spawn( exe, args );
		proc.stdout.on( 'data', function(data) {
			//trace( data.length );
			result += data;
		});
		proc.stderr.on( 'data', function(data) {
			trace('stderr: ' + data);
		});
		proc.on( 'close', function(code:Int) {
			//trace('close: ' + code);
			proc = null;
			switch code {
			case 0:
				//trace( result );
				callback( null, result.trim() );
			default:
				//trace("ERROR" +code);
				callback( new Error('ERROR $code'), null );
			}
		});
	}

}
