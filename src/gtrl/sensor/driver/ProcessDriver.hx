package gtrl.sensor.driver;

import js.node.ChildProcess;
import js.node.child_process.ChildProcess as ChildProcessObject;

class ProcessDriver extends Driver {

	//TODO global/shared process
	//static var proc : ChildProcessObject;

	public var cmd(default,null) : String;
	public var args(default,null) : Array<String>;

	var proc : ChildProcessObject;
	var pendingCallback : Buffer->Void;

	public function new( ?type = 'process', cmd : String, ?args : Array<String> ) {
		super( type );
		this.cmd = cmd;
		this.args = (args == null) ? [] : args;
	}

	public override function connect() : Promise<Nil> {
		return new Promise( function(resolve,reject){
			proc = ChildProcess.spawn( cmd, args );
			proc.stdout.on( 'data', function(chunk:Buffer) {
				handleData( chunk );
			});
			proc.stderr.on( 'data', function(err) {
				trace('stderr: ' + err);
			});
			proc.on( 'close', function(code:Int,signal:String) {
				trace('close ', code, signal );
			});
			return resolve( nil );
		});
	}

	public override function read( callback : Buffer->Void ) {
	}

	public override function toString() : String {
		return '[process:cmd,$args]';
	}

	function handleData( buf : Buffer ) {
	}

}
