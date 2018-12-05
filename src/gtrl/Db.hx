package gtrl;

class Db {

	var db : js.npm.sqlite3.Database;

	function new( db : js.npm.sqlite3.Database ) {
		this.db = db;
	}

	public function get() {
		//TODO
	}

	public function all( table : String, callback : Error->Array<Dynamic>->Void ) {
		db.all( "SELECT * FROM "+table, callback );
	}

	public function insert<T>( room : String, sensorType : String, sensorName : String, data : T, ?time : Date, ?callback : ?Error->Void ) {
		if( time == null ) time = Date.now();
		var names : Array<String> = ["time","room","sensor"];
		var values : Array<Dynamic> = [time.getTime(),room,sensorName];
		for( f in Reflect.fields( data ) ) {
			names.push( f );
			values.push( Reflect.field( data, f ) );
		}
		var sql = "INSERT INTO "+sensorType+" VALUES ("+names.map(s->return "$"+s).join(',')+")";
		db.run( sql, values, function(e){
			if( callback != null ) callback( e );
		} );
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
