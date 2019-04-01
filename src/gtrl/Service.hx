package gtrl;

#if nodejs

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
	//static var readline : js.node.readline.Interface;

	static function start( configFile : String, setupFile : String ) {

		println( 'Starting [$configFile,$setupFile]' );

		stop();

		return Promise.all([ Json.readFile( configFile ), Json.readFile( setupFile ) ]).then( function(r){
			
			config = r[0];
			setup = r[1];

			switch config.net.host {
			case null,'auto': config.net.host = om.Network.getLocalIP()[0];
			default:
			}
			exitIf( config.net.host == null, 'failed to resolve ip address', 1 );

			return Db.open( config.db ).then( function(db){

				Service.db = db;

				for( r in setup ) {
					println( "["+r.name+"]" );
					var sensors = new Array<Sensor<Any>>();
					var interval = (r.interval != null) ? r.interval : 60;
					for( s in r.sensors ) {
						if( s.enabled != null && !s.enabled ) {
							println( s.name+' disabled' );
							continue;
						}
						var driver : gtrl.sensor.Driver = null;
						var d : Dynamic = s.driver;
						switch d.type {
						case 'adafruit_dht':
							driver = new gtrl.sensor.driver.AdafruitDHTDriver( d.options.cmd, d.options.pin, d.options.type );
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
							var sensor = new gtrl.sensor.DHTSensor( s.name, driver, (s.interval != null) ? s.interval : interval );
							sensors.push( cast sensor );
						default:
							trace('Unknown sensor type: '+s.type );
						}
						println( '╰─ ['+s.name+'] ready' );
					}
					rooms.push( new Room( r.name, r.size, sensors ) );
				}
				function initRoom( i : Int ) {
					var room = rooms[i];
					room.init().then( function(e) {
						println( "Room["+room.name+"] ready");
						room.onData = (s,d) -> handleSensorData( room, s, d );
						room.onError = (s,e) -> handleSensorError( room, s, e );
						if( ++i < rooms.length ) {
							initRoom( i );
						} else {
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
			}).then( function(_){
				//println('>>>');
				//readline = Readline.createInterface({ input : process.stdin, output : process.stdout });
				//readline.question( '>' );
			});
		});
	}

	static function stop() {
		//for( r in rooms ) r.stop();
		//if( readline != null ) readline.close();
		for( room in rooms ) room.stop();
		if( net != null ) net.stop();
		if( db != null ) db.close( function(?e){
			if( e != null ) trace(e);
		});
	}

	static function exit( ?msg : Dynamic, code = 0 ) {
		if( msg != null ) println( msg );
		Sys.exit( code );
	}

	static inline function exitIf( condition : Bool, msg : Dynamic, code = 1 )
		if( condition ) exit( msg, code );

	static inline function exitIfError( ?e : Error, code = 1 )
		if( e != null ) exit( e, code );

	static function handleSensorData<T>( room : Room, sensor : Sensor<T>, data : T ) {
		var now = Date.now();
		log( '${room.name}:${sensor.name} '+Reflect.fields( data ).map( f -> return '$f:'+Reflect.field( data, f ) ).join(' '), now );
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

	static function handleSensorError<T>( room : Room, sensor : Sensor<T>, error : Error ) {
		//TODO
		trace(error);
		/*
		var now = Date.now();
		log( 'ERROR: ${room.name}:${sensor.name}:$type', now );
		if( db != null ) {
			db.insertError( room.name, sensor.name, type, Date.now(), function(?e){
				if( e != null ) trace(e);
			});
		}
		*/
	}

	public static function log( msg : String, ?time : Date ) {
		if( time == null ) time = Date.now();
		if( !isSystemService ) print( DateTools.format( time, "%H:%M:%S" )+' ' );
		println( msg );
	}

	static function main() {

		exitIf( !System.is( 'linux' ), 'linux only' );
		#if gtrl_release
		exitIf( !System.isRaspberryPi(), 'not a rasperry pi device' );
		#end

		var args = Sys.args();
		//TODO: var cmd = args.shift();

		var configFile = 'config.json';
		var setupFile = 'setup.json';

		var argsHandler : {getDoc:Void->String,parse:Array<Dynamic>->Void};
		argsHandler = hxargs.Args.generate([
			@doc("Backup log.db")["backup","bak"] => function( ?dir : String ) {
				if( dir == null ) dir = 'dat';
				exitIf( !FileSystem.exists( dir ), 'Directory [$dir] not found' );
				exitIf( !FileSystem.isDirectory( dir ), 'Path is not a directory [$dir]' );
				var file = 'log.'+DateTools.format( Date.now(), "%Y-%m-%d_%H:%M:%S" )+'.db';
				var path = '$dir/$file';
				exitIf( FileSystem.exists( path ), 'File [$path] already exists' );
				sys.io.File.copy( 'log.db', path );
				exit( 'Copied log.db to $path' );
			},
			@doc("Path to config file")["--config","-c"] => function( ?path : String ) {
				exitIf( !FileSystem.exists( path ), 'Config file [$path] not found' );
				configFile = path;
			},
			@doc("Path to setup file")["--setup","-s"] => function( path : String ) {
				exitIf( !FileSystem.exists( path ), 'Setup file [$path] not found' );
				setupFile = path;
			},
			["--service"] => function() isSystemService = true,
			@doc("Print usage")["--help","-help","-h"] => function() {
				exit( 'Usage : gtrl <cmd> [params]\n'+argsHandler.getDoc(), 1 );
			},
			_ => arg -> exit( 'Unknown parameter: $arg', 1 )
		]);
		argsHandler.parse( args );

		start( configFile, setupFile ).then( function(_){
			//println( 'ready' );
		}).catchError( function(e){
			exit( e, 1 );
		});
	}
}

#end
