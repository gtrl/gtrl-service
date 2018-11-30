package gtrl.sensor.driver;

class DummyDriver extends Driver {

	public function new() {
		super( 'dummy' );
	}

	public override function read( callback : Buffer->Void ) {
		var buf = Buffer.alloc( 8 );
		buf.writeFloatLE( 20 + Math.random()*10, 0 );
		buf.writeFloatLE( 40 + Math.random()*20, 4 );
		Timer.delay( function(){
			callback( buf );
		}, 1 );
	}
}
