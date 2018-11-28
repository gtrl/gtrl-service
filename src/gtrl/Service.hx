package gtrl;

import js.npm.Sqlite3;
import js.npm.sqlite3.*;
import om.Term;
import gtrl.Sensor;

class Service {

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

	static function handleSensorData( sensor : Sensor, data : Sensor.Data ) {

		var now = Date.now();
		var time = now.getTime();
		println( '['+DateTools.format( now, "%H:%M:%S" )+'] '+sensor.name+' [temperature='+data.temperature+',humidity='+data.humidity+']' );

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

	static function main() {

		var config = {
			db: 'log.db',
			sensors: [
				{
					name: "top",
					type: DHT22,
					pin: 17,
					pause: 1000
				},
				{
					name: "mid",
					type: DHT22,
					pin: 23,
					pause: 1000
				},
				{
					name: "bottom",
					type: DHT22,
					pin: 24,
					pause: 1000
				}
			]
		};

		initDatabase( config.db ).then( function(_) {
			for( i in 0...config.sensors.length ) {
				var s = config.sensors[i];
				var sensor = new Sensor( s.name, s.type, s.pin, './bin/read_dht.py', s.pause );
				sensor.onData = function(r){
					handleSensorData( sensor, r );
				};
				sensors.push( sensor );
				sensor.start();
			}
			//db.close();
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
			case 'list':
				SerialPort.list().then( e -> {
					println(e);
				});
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
