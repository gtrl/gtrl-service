package gtrl;

import gtrl.db.Entry;

private typedef Filter = {
	?from : Float,
	?until : Float,
	?room : String,
	?sensor : String,
}

class Db {

	var db : js.npm.sqlite3.Database;

	function new( db : js.npm.sqlite3.Database ) {
		this.db = db;
	}

	public function get( table = "dht", ?filter : Filter, callback : Error->Array<Entry>->Void ) {
		var sql = 'SELECT * FROM $table';
		if( filter != null ) {
			var conds = new Array<String>();
			if( filter.from != null ) conds.push( 'time>="${filter.from}"' );
			if( filter.until != null ) conds.push( 'time<="${filter.until}"' );
			if( filter.room != null ) conds.push( 'room="${filter.room}"' );
			if( filter.sensor != null ) conds.push( 'sensor="${filter.sensor}"' );
			if( conds.length > 0 ) sql += ' WHERE '+conds.join( ' AND ' );
		}
		db.all( sql, callback );
	}

	public function insert<T>( table = "dht", room : String, sensor : String, data : T, ?time : Date, ?callback : ?Error->Void ) {
		if( time == null ) time = Date.now();
		var names : Array<String> = ["time","room","sensor"];
		var values : Array<Dynamic> = [time.getTime(),room,sensor];
		for( f in Reflect.fields( data ) ) {
			names.push( f );
			values.push( Reflect.field( data, f ) );
		}
		var sql = 'INSERT INTO $table VALUES ('+names.map(s->return "$"+s).join(',')+')';
		db.run( sql, values, callback );
	}

	public function close( ?callback : ?Error->Void ) {
		db.close( function(e){
			db = null;
			if( callback != null ) callback( e );
		} );
	}

	public static function open( path : String ) : Promise<Db> {
		return new Promise( function(resolve,reject){
			var sqlite = new js.npm.sqlite3.Database( path );
			///TODO
			sqlite.run( "CREATE TABLE IF NOT EXISTS dht (time REAL,room TEXT,sensor TEXT,temperature REAL,humidity REAL)", function(e){
				if( e != null ) reject( e ) else {
					resolve( new Db( sqlite ) );
				}
			});
		});
	}
}
