package gtrl;

import js.node.http.IncomingMessage;
import js.node.http.ServerResponse;
import om.System;
import om.Term;

private typedef Config = {
	var db : String;
	var net : {
		var host : String;
		var port : Int;
	};
}

private typedef Setup = Array<{
	name: String,
	size: Dynamic,
	sensors: Array<Dynamic>
}>;

class Service {

	static var config : Config = {
		db: 'log.db',
		net: {
			host: 'auto',
			port: 9000
		}
	};

	static var setup : Setup = [
		{
			name: "lab",
			size: { w: 500, h: 400, d: 300 },
			sensors: [
				{
					name: "top",
					type: "dht",
					interval: 2000,
					driver: {
						type: "adafruit_dht",
						options: {
							pin: 17
						}
					}
				},
				{
					name: "bot",
					type: "dht",
					interval: 2000,
					driver: {
						type: "adafruit_dht",
						options: {
							pin: 24
						}
					}
				},
				/*
				{
					name: "bot",
					type: "dht",
					interval: 10000,
					driver: {
						type: "serial",
						options: {
							path: "/dev/ttyACM0",
							baud: 115200,
							pin: 2
						}
					}
				}
				*/
			]
		}
	];

	public static var isSystemService(default,null) = false;
	public static var rooms(default,null) = new Array<Room>();

	static var db : Db;
	static var net : Net;

	static function stop() {
		//for( r in rooms ) r.stop();
		if( db != null ) db.close( function(?e){
			if( e != null ) trace(e);
		});
		if( net != null ) net.close();
	}

	static function handleSensorData<T>( room : Room, sensor : Sensor<T>, data : T ) {

		var now = Date.now();

		if( !isSystemService ) print( DateTools.format( now, "%H:%M:%S" )+' ' );
		print( '${room.name}:${sensor.name} ' );
		println( Reflect.fields( data ).map( f -> return f+':'+Reflect.field( data, f ) ) );

		if( db != null ) {
			db.insert( room.name, sensor.type, sensor.name, data, now, function(?e){
				if( e != null ) trace(e);
			} );
		}

		if( net != null ) {
			net.broadcast({
				time: now,
				room: room.name,
				sensor: { name: sensor.name, type: sensor.type },
				data: data
			});
		}
	}

	static function exit( ?msg : Dynamic, code = 0 ) {
		if( msg != null ) println( msg );
		Sys.exit( code );
	}

	static inline function exitIf( condition : Bool, msg : Dynamic, code = 1 )
		if( condition ) exit( msg, code );

	static inline function exitIfError( ?e : Error, code = 1 )
		if( e != null ) exit( e, code );

	static function main() {

		exitIf( !System.is( 'linux' ), 'linux only' );
		#if gtrl_release
		exitIf( !System.isRaspberryPi(), 'not a rasperry pi device' );
		#end

		var configFile : String;

		var argsHandler : {getDoc:Void->String,parse:Array<Dynamic>->Void};
		argsHandler = hxargs.Args.generate([
			//@doc("Path to config") ["-config"] => (file:String) -> config.db = file,
			//@doc("Path to db") ["-db"] => (file:String) -> config.db = file,
			//@doc("Host name/address")["-host"] => (name:String) -> config.host = name,
			//@doc("Port number")["-port"] => (number:Int) -> config.port = number,
			@doc("Path to config file")["--config","-c"] => function( ?path : String ) {
				if( path == null )
					exit( Std.string( config ), 0 );
				exitIf( !FileSystem.exists( path ), 'Config file [$path] not found' );
				configFile = path;
			},
			["--service"] => function() isSystemService = true,
			@doc("Print usage")["--help","-h"] => function() {
				exit( 'Usage : gtrl <cmd> [params]\n'+argsHandler.getDoc(), 1 );
			},
			_ => arg -> exit( 'Unknown parameter: $arg', 1 )
		]);

		var args = Sys.args();
		switch args[0] {
		case 'config': exit( config );
		default: argsHandler.parse( args );
		}

		if( configFile != null ) {
			config = Json.parseFile( configFile );
		}

		switch config.net.host {
		case null,'auto': config.net.host = om.Network.getLocalIP()[0];
		default:
		}
		if( config.net.host == null )
			exit( 'failed to resolve ip address', 1 );

		Db.open( config.db ).then( function(db){

			Service.db = db;

			for( r in setup ) {
				var sensors = new Array<Sensor<Any>>();
				for( s in r.sensors ) {
					var driver : gtrl.sensor.Driver = null;
					var d : Dynamic = s.driver;
					switch d.type {
					case 'adafruit_dht':
						driver = new gtrl.sensor.driver.AdafruitDHTDriver( d.options.cmd, d.options.pin );
					case 'dummy':
						driver = new gtrl.sensor.driver.DummyDriver();
					case 'process':
						driver = new gtrl.sensor.driver.ProcessDriver( null, d.options.cmd, d.options.args );
					case 'serial':
						driver = new gtrl.sensor.driver.SerialDriver( d.options.path, d.options.pin );
					default:
						trace('driver not found');
					}
					switch s.type {
					case 'dht':
						var sensor = new gtrl.sensor.DHTSensor( s.name, driver, s.interval );
						sensors.push( cast sensor );
					}
				}
				rooms.push( new Room( r.name, r.size, sensors ) );
			}
			function initRoom( i : Int ) {
				var room = rooms[i];
				room.init().then( e -> {
					println( "ROOM["+room.name+"] READY");
					room.onData = (s,d) -> handleSensorData( room, s, d );
					if( ++i < rooms.length ) {
						initRoom( i );
					} else {
						trace("ALL ROOMS READY");
						for( room in rooms ) room.start();
					}
				});
			}
			initRoom(0);

			if( config.net != null ) {
				println( 'Starting web interface [${config.net.host}:${config.net.port}]' );
				net = new Net( );
				net.on( 'request', (req:IncomingMessage,res:ServerResponse) -> {
					var url = Url.parse( req.url, true );
					//trace( url );
					if( req.method == 'POST' ) {
						var str = '';
						req.on( 'data', function(c) str += c );
						req.on( 'end', function() {
							var data = Json.parse( str );
							var time = Date.fromTime( data.time );
							trace(time);

							db.all( 'dht', function(e,rows:Array<Dynamic>){
								if( e != null ) trace( e );
								res.writeHead( 200, {
									'Access-Control-Allow-Origin': '*',
									'Content-Type': 'application/json'
								} );
								res.end( Json.stringify( rows ) );
							});
						});
					}
				} );
				net.listen( config.net.port, config.net.host );
			}

		}).catchError( e -> {
			exit( e, 1 );
		});
	}
}
