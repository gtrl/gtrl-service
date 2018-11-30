package gtrl.sensor;

import gtrl.sensor.Driver;

typedef Data = {
	var temperature : Float;
	var humidity : Float;
}

class DHTSensor extends Sensor<Data> {

	public static inline var TYPE = 'dht';

	public var precision : Int;

	public function new( name : String, driver : Driver, interval : Int, precision = 2 ) {
		super( TYPE, name, driver, interval );
		this.precision = precision;
	}

	override function handleData( buf : Buffer ) {
		super.handleData( buf );
		var t = buf.readFloatLE(0);
		var h = buf.readFloatLE(4);
		if( precision > 0 ) {
			t = t.precision( precision );
			h = h.precision( precision );
		}
		onData( { temperature: t, humidity: h } );
	}
}
