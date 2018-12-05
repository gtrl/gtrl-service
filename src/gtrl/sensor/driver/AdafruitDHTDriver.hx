package gtrl.sensor.driver;

/**
	Relies on gtrl/bin/read_dht.py script to read DHT sensors.

	@see https://github.com/adafruit/Adafruit_Python_DHT
**/
class AdafruitDHTDriver extends ProcessDriver {

	public static inline var TYPE = 'adafruit_dht';
	public static inline var MSG_SIZE = 8;

	public var pin(default,null) : Int;
	public var sensorType(default,null) : Int;

	public function new( cmd = "bin/read_dht.py", pin : Int, sensorType = 22 ) {
		super( TYPE, cmd );
		this.pin = pin;
		this.sensorType = sensorType;
	}

	public override function read( callback : Buffer->Void ) {
		if( pendingCallback != null ) {
			trace("ALREADY PENDING REQUEST" );
		} else {
			pendingCallback = callback;
			var buf = Buffer.alloc( 2 );
			buf.writeUInt8( pin, 0 );
			buf.writeUInt8( sensorType, 1 );
			proc.stdin.write( buf );
		}
	}

	public override function toString() : String {
		return '[$TYPE,pin,$sensorType]';
	}

	override function handleData( buf : Buffer ) {
		if( buf.length == MSG_SIZE ) {
			pendingCallback( buf );
		} else {
			var code = buf.readInt8(0);
			trace("INCOMPLETE MSG [pin="+pin+"code="+code+",len="+buf.length+"]");
		}
		pendingCallback = null;
	}
}
