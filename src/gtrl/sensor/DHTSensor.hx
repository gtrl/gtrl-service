package gtrl.sensor;

import gtrl.Sensor;
import gtrl.sensor.Driver;

/*
enum abstract DHTSensorType(Int) from Int to Int {
	var DHT11 = 11;
	var DHT22 = 22;
}
*/

typedef Data = {
	var temperature : Float;
	var humidity : Float;
}

class DHTSensor extends Sensor<Data> {

	public static inline var TYPE = 'dht';

	/** Float value precision **/
	public var precision : Int;

	public var minTemperature = 10;
	public var maxTemperature = 70;
	public var minHumidity = 30;
	public var maxHumidity = 100;

	public function new( name : String, driver : Driver, interval : Int, precision = 2 ) {
		super( TYPE, name, driver, interval );
		this.precision = precision;
	}

	override function handleData( err : Error, buf : Buffer ) {
		//super.handleData( err, buf );
		if( err != null ) {
			onError( err );
		} else {
			var t = buf.readFloatLE(0);
			var h = buf.readFloatLE(4);
			if( minTemperature != null && t < minTemperature ) {
				trace('invalid temperature value: '+t );
				//onError( new Error( value_invalid ) );
				//onError( new Error( ''+value_invalid ) );
				return;
			}
			if( maxTemperature != null && t > maxTemperature ) {
				trace('invalid temperature value: '+h );
				//onError( new Error( value_invalid ) );
				//onError( new Error( ''+value_invalid ) );
				return;
			}
			if( minHumidity != null && h < minHumidity ) {
				trace('invalid humidity value: '+h );
				//onError( new Error( value_invalid ) );
				//onError( new Error( ''+value_invalid ) );
				return;
			}
			if( maxHumidity != null && h > maxHumidity ) {
				trace('invalid humidity value: '+h );
				//onError( new Error( value_invalid ) );
				//onError( new Error( ''+value_invalid ) );
				return;
			}
			if( precision != null && precision > 0 ) {
				function precise( v : Float, p : Int) {
					var s = Std.string(v);
					var i = s.indexOf('.');
					if( i == -1 )
						return v;
					var commas = s.substr( i );
					if( commas.length > precision ) commas = commas.substr( 0, precision + 1 );
					return Std.parseFloat( s.substr( 0, i ) + commas );
				}
				t = precise( t, precision );
				h = precise( h, precision );
				//t = FloatTools.precision( t, this.precision );
				//h = FloatTools.precision( h, this.precision );
				//trace(precision,t, untyped t.toFixed(precision));
				//t = untyped t.toFixed( precision );
				//h = untyped h.toFixed( precision );
			}
			onData( { temperature: t, humidity: h } );
		}
	}
}
