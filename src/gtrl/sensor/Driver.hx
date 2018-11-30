package gtrl.sensor;

class Driver {

	public var type(default,null) : String;

	function new( type : String ) {
		this.type = type;
	}

	public function connect() : Promise<Nil> {
		return Promise.resolve();
	}

	public function disconnect() : Promise<Nil> {
		return Promise.resolve();
	}

	public function read( callback : Buffer->Void ) {
	}

	public function toString() : String {
		return throw new AbstractMethod();
	}


}
