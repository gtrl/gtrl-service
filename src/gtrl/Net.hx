package gtrl;

#if nodejs

import js.node.http.IncomingMessage;
import js.node.http.ServerResponse;
import js.npm.ws.Server;
import js.npm.ws.Server as WebSocketServer;
import js.npm.ws.WebSocket;

class Net extends js.node.http.Server {

	public var host(default,null) : String;
	public var port(default,null) : Int;

	var ws : WebSocketServer;

	public function new( host : String, port : Int ) {
		super();
		this.host = host;
		this.port = port;
	}

	public function start( websocket = true ) {

		on( 'request', handleRequest );

		if( websocket ) {
			ws = new WebSocketServer( { server: this, clientTracking: true } );
			ws.on( Connection, function(s,r) {
				var ip = r.connection.remoteAddress;
				println( '$ip connected' );
				s.once( Close, function(status,message) {
					var info = '$ip disconnected '+status;
					if( message != null ) info += ' $message';
					println( info );
				} );
			});
			ws.on( 'message', function(e) {
				trace(e);
			});
			ws.on( 'error', function(e) {
				trace(e);
			});
		}

		listen( port, host );
	}

	public function stop() {
		close();
	}

	public function broadcast( msg : Dynamic ) {
		var str = Json.stringify( msg );
		var clients : js.lib.Set<Dynamic> = untyped ws.clients;
		clients.forEach( function(v,k,s){
			v.send( str, e -> {
				if( e != null ) trace( e );
			} );
		} );
	}

	function handleRequest( req : IncomingMessage, res : ServerResponse ) {
		var url = Url.parse( req.url, true );
		//trace( url );
		var path = url.path.substr(1);
		res.writeHead( 200, {
			'Access-Control-Allow-Origin': '*',
			'Content-Type': 'application/json'
		} );
		switch path {
		case '': //
		case 'setup':
			//TODO create json from actual service setup in use
			//for( room in Service.rooms )
			res.end( Json.stringify( Service.setup ) );
		case 'data':
			switch req.method {
			case 'POST':
				var str = '';
				req.on( 'data', function(c) str += c );
				req.on( 'end', function() {
					var filter = Json.parse( str );
					var time = Date.fromTime( filter.time );
					Service.db.get( 'dht', {
						room: filter.room,
						sensor : filter.sensor,
						from: time.getTime()
					}, function(e,rows:Array<gtrl.db.Entry>){
						if( e != null ) {
							trace( e );
							//TODO
						} else {
							res.end( Json.stringify( rows ) );
						}
					});
				});
			default:
				Service.db.get( 'dht', function(e,rows:Array<Dynamic>){
					if( e != null ) {
						trace( e );
						//TODO
					} else {
						res.end( Json.stringify( rows ) );
					}
				});
			}
		case 'read':
			trace("REQUESTED SENSOR READ");
			//TODO: filter
			for( r in Service.rooms ) {
				r.readSensors();
			}
			res.end( Json.stringify( {} ) );
		}
	}
}

#end

