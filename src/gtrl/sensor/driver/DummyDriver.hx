package gtrl.sensor.driver;

/**
	Simulation of a driver for development/testing.
**/
class DummyDriver extends Driver {

	public var readDelay : Int;

	public function new( readDelay = 1 ) {
		super( 'dummy' );
		this.readDelay = readDelay;
	}

	public override function read( onResult : Error->Buffer->Void ) {
		var buf = Buffer.alloc( 8 );
		buf.writeFloatLE( 20 + Math.random()*10, 0 );
		buf.writeFloatLE( 40 + Math.random()*20, 4 );
		Timer.delay( function(){
			onResult( null, buf );
		}, readDelay );
	}
}
