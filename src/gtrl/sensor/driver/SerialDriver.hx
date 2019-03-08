package gtrl.sensor.driver;

import js.npm.serialport.SerialPort;

class SerialDriver extends Driver {

	//static inline var CMD_INFO = 0x0;
	static inline var CMD_READ = 0x0;
	static inline var MSG_SIZE = 8;

	static var ports : Map<String,SerialPort>;
	static var drivers : Map<Int,SerialDriver>;
	static var pendingQueue : Array<Int>;
	static var cache : Buffer;
	static var cachePosition : Int;

	static function getSerialPort( path : String, baud : BaudRate ) : SerialPort {
		if( ports == null ) {
			ports = new Map<String,SerialPort>();
			drivers = new Map<Int,SerialDriver>();
			pendingQueue = new Array<Int>();
			cache = Buffer.alloc( MSG_SIZE );
			cachePosition = 0;
		} else if( ports.exists( path ) )
			return ports.get( path );
		var port = new SerialPort( path, { baudRate: baud, autoOpen : false } );
		ports.set( path, port );
		port.on( SerialPortEvent.close, function(){
			trace("TODO serialport closed");
		});
		port.on( SerialPortEvent.error, function(e){
			trace("TODO serialport error "+e);
		});
		port.on( SerialPortEvent.data, function handleSerialData( chunk : Buffer ) {
			//trace("<<< "+chunk.length);
			var cursor = 0;
			while( cursor < chunk.length ) {
				cache[cachePosition++] = chunk[cursor++];
				if( cachePosition == MSG_SIZE ) {
					var driver = drivers.get( pendingQueue.shift() );
					driver.handleResult( null, Buffer.from( cache ) );
					cache = Buffer.alloc( MSG_SIZE );
					cachePosition = 0;
					if( pendingQueue.length > 0 ) {
						var driver = drivers.get( pendingQueue[0] );
						driver.send();
					}
				}
			}
		});
		return port;
	}

	public var pin(default,null) : Int;

	var port : SerialPort;
	var pendingCallback : Error->Buffer->Void;
	//var pendingDataCallback : Buffer->Void;
	//var pendingErrorCallback : Error->Void;

	public function new( path : String, pin : Int, baud : BaudRate = _115200 ) {
		super( 'serial' );
		this.pin = pin;
		port = getSerialPort( path, baud );
		drivers.set( pin, this );
	}

	public override function connect() : Promise<Nil> {
		if( port.isOpen )
			return Promise.resolve();
		return new Promise( function(resolve,reject){
			port.open( function(e) {
				if( e != null ) reject( e ) else {
					resolve( nil );
				}
			});
		});
	}

	/*
	//public override function read( onData : Buffer->Void, onError : Error->Void ) {
	public override function read( onResult : Error->Buffer->Void ) {
		if( pendingCallback != null ) {
			trace("ALREADY PENDING "+pin );
			return;
		}
		pendingQueue.push( pin );
		pendingCallback = onResult;
		//pendingErrorCallback = onError;
		switch pendingQueue.length {
		case 1: send( CMD_READ );
		case i if( i >= 16 ): trace('MAX PENDING ');
		default:
			trace("PENDING "+pendingQueue.length );
		}
	}
	*/

	function send( cmd : Int = CMD_READ ) {
		var buf = Buffer.alloc( 2 );
		buf.writeUInt8( cmd, 0 );
		buf.writeUInt8( pin, 1 );
		port.write( buf, function(e) {
			if( e != null ) trace(e);
		});
	}

	function handleResult( err : Error, buf : Buffer ) {
		pendingCallback( err, buf );
		pendingCallback = null;
	}
}
