package gtrl;

import js.npm.Sqlite3;
import js.npm.sqlite3.*;
//import js.npm.serialport.SerialPort;
import js.node.http.IncomingMessage;
import js.node.http.ServerResponse;
import om.System;
import om.Term;

class Service {

	public static var isSystemService(default,null) = false;

	static var config = {
		host: 'auto',
		port: 9000,
		db: 'log.db',
		rooms: [
			/*
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
			*/
			{
				name: "lab",
				size: { w: 500, h: 400, d: 300 },
				sensors: [
					{
						name: "top",
						type: "dht",
						//position: "t",
						interval: 3000,
						driver: {
							type: "dummy"
						}
					},
				/*
					{
						name: "top",
						type: "dht",
						//position: "t",
						interval: 3000,
						driver: {
							type: "process",
							options: {
								cmd: "bin/read_dht.py",
								args: ['17']
							}
						}
					},
					*/
					/*
					{
						name: "top",
						type: "dht",
						//position: "t",
						interval: 10000,
						driver: {
							type: "serial",
							options: {
								path: "/dev/ttyACM0",
								baud: 115200,
								pin: 1
							}
						}
					},
					{
						name: "bot",
						type: "dht",
						//position: "b",
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
		]
	};

	static var rooms : Array<Room>;
	static var db : Database;
	static var web : Web;

	static function stop() {
		//for( r in rooms ) r.stop();
		if( db != null ) {
			db.close();
		}
		if( web != null ) {
			web.close();
		}
	}

	static function handleSensorData<T>( room : Room, sensor : Sensor<T>, data : T ) {

		var now = Date.now();
		var time = now.getTime();

		if( !isSystemService ) print( DateTools.format( now, "%H:%M:%S" )+' ' );
		print( '${room.name}:${sensor.name} ' );
		println( Reflect.fields( data ).map( f -> return f+':'+Reflect.field( data, f ) ) );

		if( db != null ) {
			switch sensor.type {
			case 'dht':
				//var d : gtrl.sensor.DHTSensor.Data = cast data;
				var names : Array<String> = ["time","room","sensor"];
				var values : Array<Dynamic> = [time,room.name,sensor.name];
				for( f in Reflect.fields( data ) ) {
					var v = Reflect.field( data, f );
					names.push( f );
					values.push( v );
				}
				var sql = "INSERT INTO "+sensor.type+" VALUES ("+names.map(s->return "$"+s).join(',')+")";
				db.run( sql, values, function(e){
					if( e != null ) trace( e );
				} );
			}
		}

		if( web != null ) {
			web.broadcast({
				time: time,
				room: room.name,
				sensor: { name: sensor.name, type: sensor.type },
				data: data
			});
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

		db = new Database( config.db );
		db.run( "CREATE TABLE IF NOT EXISTS dht (time REAL,room TEXT,sensor TEXT,temperature REAL,humidity REAL)", function(e){

			exitIfError( e );

			web = new Web( );
			web.on( 'request', (req:IncomingMessage,res:ServerResponse) -> {
				var url = Url.parse( req.url, true );
				//trace( url );
				if( req.method == 'POST' ) {
					var str = '';
					req.on( 'data', function(c) str += c );
					req.on( 'end', function() {
						var data = Json.parse( str );
						var time = Date.fromTime( data.time );
						trace(time);
						db.all( "SELECT * FROM dht", (e,rows:Array<Dynamic>) -> {
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
			web.listen( config.port, config.host );

			rooms = [];
			for( r in config.rooms ) {
				var sensors = new Array<Sensor<Any>>();
				for( s in r.sensors ) {
					var driver : gtrl.sensor.Driver = null;
					var d : Dynamic = s.driver;
					switch d.type {
					case 'dummy':
						driver = new gtrl.sensor.driver.DummyDriver();
					case 'process':
						driver = new gtrl.sensor.driver.ProcessDriver( d.options.cmd, d.options.args );
					case 'serial':
						driver = new gtrl.sensor.driver.SerialDriver( d.options.path, d.options.pin );
					default:
						trace('driver not found');
					}
					if( driver == null ) {
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

		});
	}
}
