package gtrl.sensor;

import gtrl.sensor.Driver;

typedef Data = {
	var temperature : Float;
	var humidity : Float;
}

class DHTSensor extends Sensor<Data> {

	public static inline var TYPE = 'dht';

	/** Float value precision **/
	public var precision : Int;

	public var minTemperature = 0;
	public var maxTemperature = 70;
	public var minHumidity = 0;
	public var maxHumidity = 100;

	public function new( name : String, driver : Driver, interval : Int, precision = 2 ) {
		super( TYPE, name, driver, interval );
		this.precision = precision;
	}

	override function handleData( buf : Buffer ) {

		super.handleData( buf );

		var t = buf.readFloatLE(0);
		var h = buf.readFloatLE(4);

		if( minTemperature != null && t < minTemperature ) {
			trace('invalid temperature value: '+t );
			onError( invalid_value );
			return;
		}
		if( maxTemperature != null && t > maxTemperature ) {
			trace('invalid temperature value: '+h );
			onError( invalid_value );
			return;
		}
		if( minHumidity != null && h < minHumidity ) {
			trace('invalid humidity value: '+h );
			onError( invalid_value );
			return;
		}
		if( maxHumidity != null && h > maxHumidity ) {
			trace('invalid humidity value: '+h );
			onError( invalid_value );
			return;
		}

		if( precision != null && precision > 0 ) {
			t = t.precision( precision );
			h = h.precision( precision );
		}
		
		onData( { temperature: t, humidity: h } );
	}
}
