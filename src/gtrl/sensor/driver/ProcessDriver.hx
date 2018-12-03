package gtrl.sensor.driver;

import js.node.ChildProcess;
import js.node.child_process.ChildProcess as ChildProcessObject;

class ProcessDriver extends Driver {

	public var cmd(default,null) : String;
	public var args(default,null) : Array<String>;

	var proc : ChildProcessObject;

	public function new( cmd : String, args : Array<String> ) {
		super( 'process' );
		this.cmd = cmd;
		this.args = args;
	}

	public override function read( callback : Buffer->Void ) {

		//TODO
		//trace( "READ" );

		if( proc != null ) {
			trace("process already active");
			return;
		}

		var MSG_SIZE = 8;
		var cursor = 0;
		var cache = Buffer.alloc( MSG_SIZE );
		var cachePosition = 0;

		proc = ChildProcess.spawn( cmd, args );
		proc.stdout.on( 'data', function(chunk:Buffer) {
			trace( 'stdout: ' +chunk.length );
			while( cursor < chunk.length ) {
				cache[cachePosition++] = chunk[cursor++];
			}
		});
		proc.stderr.on( 'data', function(err) {
			trace('stderr: ' + err);
			//error += err;
			//callback( new Error( err ), null );
		});
		proc.on( 'close', function(code:Int,signal:String) {
			trace('close ', code, signal );
			//proc.disconnect();
			proc = null;
			switch code {
			case 0:
				if( cachePosition != MSG_SIZE ) {
					trace("INVALID MESSAGE");
				} else {
					var data = Buffer.from( cache ) ;
					cache = Buffer.alloc( MSG_SIZE );
					cachePosition = 0;
					callback( data );
				}
			default:
				trace("ERRROR ");
				cache = Buffer.alloc( MSG_SIZE );
				cachePosition = 0;
			}
		});
	}

	/*
	public override function toString() : String {
		return '[process:$exe,$args]';
	}
	*/

}
