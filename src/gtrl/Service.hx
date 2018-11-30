package gtrl;

import js.npm.Sqlite3;
import js.npm.sqlite3.*;
import om.System;
import om.Term;
import gtrl.Sensor;

class Service {

	public static var isSystemService(default,null) = false;

	static var config = {
		host: 'auto',
		port: 9000,
		db: 'log.db',
		rooms: [
			{
				name: "tent",
				size: { w: 120, h: 200, d: 120 },
				sensors: [
					{
						name: "top",
						type: DHT22,
						pin: 17,
						pause: 10000,
						position: "tl",

					}
				]
			}
		]
	};

	static var rooms = new Array<Room>();
	static var db : Database;
	static var web : Web;

	static function start() : Promise<Nil> {

		return initDatabase( config.db ).then( function(_) {

			for( i in 0...config.rooms.length ) {
				var r = config.rooms[i];
				var sensors = new Array<Sensor>();
				for( s in r.sensors ) {
					var sensor = new Sensor( s.name, s.type, s.pin, s.pause );
					sensors.push( sensor );
				}
				var room = new Room( r.name, r.size, sensors );
				room.onData = function(sensor,data){
					//handleSensorData( sensor, r );
					handleRoomData( room, sensor, data );
				};
				room.onError = function(e:Sensor.Error){
					println( e );
				};
				rooms.push( room );
			}

			web = new Web( );
			web.on( 'request', (req,res) -> {
				var url = Url.parse( req.url, true );
				trace( url );
				db.all( "SELECT * FROM dht", (e,rows:Array<Dynamic>) -> {
					if( e != null ) trace( e );
					res.writeHead( 200, {
						'Access-Control-Allow-Origin': '*',
						'Content-Type': 'application/json'
					} );
					res.end( Json.stringify( rows ) );
				});
			} );
			web.listen( config.port, config.host );

			for( room in rooms ) room.start();

			return nil;
		});
	}

	static function initDatabase( file : String ) : Promise<Nil> {
		return if( db != null ) Promise.resolve() else {
			new Promise( (resolve,reject) -> {
				db = new Database( file );
				//db.run( "CREATE TABLE IF NOT EXISTS dht (time REAL,sensor TEXT,temperature REAL,humidity REAL)", function(e){
				db.run( "CREATE TABLE IF NOT EXISTS dht (time REAL,room TEXT,sensor TEXT,temperature REAL,humidity REAL)", function(e){
					if( e != null ) reject( e ) else resolve( nil );
				});
			} );
		}
	}

	static function stop() {
		for( r in rooms )
			r.stop();
		if( db != null ) {
			db.close();
		}
		if( web != null ) {
			web.close();
		}
	}

	static function handleRoomData( room : Room, sensor : Sensor, data : Sensor.Data ) {

		var now = Date.now();
		var time = now.getTime();

		if( !isSystemService ) print( DateTools.format( now, "%H:%M:%S" )+' ' );
		println( '${room.name}:${sensor.name} temperature=${data.temperature} humidity=${data.humidity}' );

		if( db != null ) {
			var sql = "INSERT INTO dht VALUES ($time,$room,$sensor,$temperature,$humidity)";
			db.run( sql, {
				'$time': time,
				'$room': room.name,
				'$sensor': sensor.name,
				'$temperature': data.temperature,
				'$humidity': data.humidity
			}, function(e){
				if( e != null ) {
					trace( e );
				}
			} );
		}

		if( web != null ) {
			web.broadcast({
				time: time,
				room: room.name,
				sensor: sensor.name,
				temperature: data.temperature,
				humidity: data.humidity
			});
		}
	}

	/*
	static function handleSensorData( sensor : Sensor, data : Sensor.Data ) {

		var now = Date.now();
		var time = now.getTime();

		println( '${sensor.name} temperature=${data.temperature} humidity=${data.humidity}' );

		if( db != null ) {
			var sql = "INSERT INTO dht VALUES ($time,$sensor,$temperature,$humidity)";
			db.run( sql, {
				'$time': time,
				'$sensor': sensor.name,
				'$temperature': data.temperature,
				'$humidity': data.humidity
			}, function(e){
				if( e != null ) {
					trace( e );
				}
			} );
		}
	}
	*/

	static function exit( ?msg : Dynamic, code = 0 ) {
		if( msg != null ) Sys.println( msg );
		Sys.exit( code );
	}

	static inline function exitIfError( ?e : Error, code = 1 )
		if( e != null ) exit( e, code );

	static function main() {

		if( !System.is( 'linux' ) ) exit( 'not linux', 1 );
		#if gtrl_release
		if( !System.isRaspberryPi() ) exit( 'not a rasperry pi device', 1 );
		#end


		var argsHandler : {getDoc:Void->String,parse:Array<Dynamic>->Void};
		argsHandler = hxargs.Args.generate([
			//@doc("Path to config") ["-config"] => (file:String) -> config.db = file,
			@doc("Path to db") ["-db"] => (file:String) -> config.db = file,
			@doc("Host name/address")["-host"] => (name:String) -> config.host = name,
			@doc("Port number")["-port"] => (number:Int) -> config.port = number,
			["--service"] => () -> isSystemService = true,
			@doc("Print usage") ["--help","-h"] => () -> {
				println( 'Usage : gtrl <cmd> [params]' );
				exit( argsHandler.getDoc() );
			},
			_ => arg -> exit( 'Unknown parameter: $arg', 1 )
		]);

		var args = Sys.args();
		switch args[0] {
		case 'config': exit( config );
		default: argsHandler.parse( args );
		}

		switch config.host {
		case null,'auto': config.host = om.Network.getLocalIP()[0];
		default:
		}
		if( config.host == null )
			exit( 'failed to resolve ip address', 1 );

		start().then( e -> {
			println( 'service started' );
		});

		/*
		var readline = js.node.Readline.createInterface( { input: process.stdin } );
		readline.on( 'line', function(line) {
			var args = ~/(\s+)/.split( line );
			var cmd = args[0];
			switch cmd {
			case 'clear':
				Term.clear();
				print('❯ ');
			case 'config':
				println( config );
			case 'h','help':
				println('NOHELP!');
				print('❯ ');
			case 'sensors':
			case _:
			}
		});
		print('❯ ');
		*/
	}


}
