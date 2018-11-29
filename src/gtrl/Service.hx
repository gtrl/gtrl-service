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
		sensors: [
			{
				name: "top",
				type: DHT22,
				pin: 17,
				pause: 1000
			},
			/*
			{
				name: "mid",
				type: DHT22,
				pin: 23,
				pause: 10000
			},
			{
				name: "bottom",
				type: DHT22,
				pin: 24,
				pause: 10000
			}
			*/
		]
	};

	static var sensors = new Array<Sensor>();
	static var db : Database;

	static function initDatabase( file : String ) : Promise<Nil> {
		return if( db != null ) Promise.resolve() else {
			new Promise( (resolve,reject) -> {
				db = new Database( file );
				db.run( "CREATE TABLE IF NOT EXISTS dht (time REAL,sensor TEXT,temperature REAL,humidity REAL)", function(e){
					if( e != null ) reject( e ) else resolve( nil );
				});
			} );
		}
	}

	static function stop() {
		if( db != null ) {
			db.close();
		}
		//...
	}

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

	static function exit( ?msg : Dynamic, code = 0 ) {
		if( msg != null ) Sys.println( msg );
		Sys.exit( code );
	}

	static inline function exitIfError( ?e : Error, code = 1 )
		if( e != null ) exit( e, code );

	static function main() {

		if( !System.is( 'linux' ) ) exit( 'not linux', 1 );
		#if release
		if( !System.isRaspberryPi()) exit( 'not a rasperry pi device', 1 );
		#end

		var args = Sys.args();
		//var path = Sys.getEnv( 'GTRL_PATH' );

		var argsHandler : {getDoc:Void->String,parse:Array<Dynamic>->Void};
		argsHandler = hxargs.Args.generate([
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

		initDatabase( config.db ).then( function(_) {

			for( i in 0...config.sensors.length ) {
				var s = config.sensors[i];
				var sensor = new Sensor( s.name, s.type, s.pin, s.pause );
				sensor.onData = function(r){
					handleSensorData( sensor, r );
				};
				sensor.onError = function(e:Sensor.Error){
					println( e );
				};
				sensor.start();
			}

			var server = js.node.Http.createServer( (req,res) -> {
				//trace(req);
				var url = Url.parse( req.url, true );
				db.all( "SELECT * FROM dht", (e,rows:Array<Dynamic>) -> {
					if( e != null ) trace( e );
					res.writeHead( 200, {
						'Access-Control-Allow-Origin': '*',
						'Content-Type': 'application/json'
					} );
					res.end( Json.stringify( rows ) );
				});
			});
			server.listen( config.port, config.host );
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
