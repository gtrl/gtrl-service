package gtrl;

import om.System;

private typedef Config = {
	db : String,
	net : {
		host : String,
		port : Int
	}
}

class Service {

	public static var isSystemService(default,null) = false;

	public static var config(default,null) : Config;
	public static var setup(default,null) : Setup;

	public static var rooms(default,null) = new Array<Room>();
	public static var db(default,null) : Db;

	static var net : Net;

	static function stop() {
		//for( r in rooms ) r.stop();
		if( db != null ) db.close( function(?e){
			if( e != null ) trace(e);
		});
		if( net != null ) net.stop();
	}

	static function handleSensorData<T>( room : Room, sensor : Sensor<T>, data : T ) {

		var now = Date.now();

		if( !isSystemService ) print( DateTools.format( now, "%H:%M:%S" )+' ' );
		print( '${room.name}:${sensor.name} ' );
		println( Reflect.fields( data ).map( f -> return f+':'+Reflect.field( data, f ) ) );

		if( db != null ) {
			db.insert( "dht", room.name, sensor.name, data, now, function(?e){
				if( e != null ) trace(e);
			} );
		}

		if( net != null ) {
			net.broadcast({
				time: now.getTime(),
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

		var configFile = 'config.json';
		var setupFile = 'setup.json';

		var argsHandler : {getDoc:Void->String,parse:Array<Dynamic>->Void};
		argsHandler = hxargs.Args.generate([
			//@doc("Path to db") ["-db"] => (file:String) -> config.db = file,
			//@doc("Host name/address")["-host"] => (name:String) -> config.host = name,
			//@doc("Port number")["-port"] => (number:Int) -> config.port = number,
			@doc("Path to config file")["--config","-c"] => function( ?path : String ) {
				exitIf( !FileSystem.exists( path ), 'Config file [$path] not found' );
				configFile = path;
			},
			@doc("Path to setup file")["--setup","-s"] => function( path : String ) {
				exitIf( !FileSystem.exists( path ), 'Setup file [$path] not found' );
				setupFile = path;
			},
			["--service"] => function() isSystemService = true,
			@doc("Print usage")["--help","-h"] => function() {
				exit( 'Usage : gtrl <cmd> [params]\n'+argsHandler.getDoc(), 1 );
			},
			_ => arg -> exit( 'Unknown parameter: $arg', 1 )
		]);

		argsHandler.parse( Sys.args() );
		
		println( 'config=$configFile, setup=$setupFile' );

		Promise.all([ Json.readFile( configFile ), Json.readFile( setupFile ) ]).then( function(r){
			
			config = r[0];
			setup = r[1];

			switch config.net.host {
			case null,'auto': config.net.host = om.Network.getLocalIP()[0];
			default:
			}
			exitIf( config.net.host == null, 'failed to resolve ip address', 1 );

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
					net = new Net( config.net.host, config.net.port );
					net.start();
				}
			}).catchError( e -> {
				exit( e, 1 );
			});
		}).catchError( function(e){
			exit( e, 1 );
		});
	}
}
