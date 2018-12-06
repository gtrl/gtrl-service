package gtrl;

import js.node.http.IncomingMessage;
import js.node.http.ServerResponse;
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

	public function start() {

		on( 'request', handleRequest );

		ws = new WebSocketServer( { server: this, clientTracking: true } );
		ws.on( 'connection', function(e) {
			println( 'Client connected' );
		});
		ws.on( 'close', function(e) {
			println( 'Client disconnected' );
		});
		ws.on( 'message', function(e) {
			trace(e);
		});
		ws.on( 'error', function(e) {
			trace(e);
		});

		listen( port, host );
	}

	public function stop() {
		close();
	}

	public function broadcast( msg : Dynamic ) {
		var str = Json.stringify( msg );
		var clients : js.Set<Dynamic> = untyped ws.clients;
		clients.forEach( function(v,k,s){
			v.send( str, e -> {
				if( e != null ) trace( e );
			} );
		} );
	}

	function handleRequest( req : IncomingMessage, res : ServerResponse ) {
		var url = Url.parse( req.url, true );
		//trace( url );
		if( req.method == 'POST' ) {
			var str = '';
			req.on( 'data', function(c) str += c );
			req.on( 'end', function() {
				var data = Json.parse( str );
				var time = Date.fromTime( data.time );
				//trace(time);
				Service.db.all( 'dht', function(e,rows:Array<Dynamic>){
					if( e != null ) trace( e );
					res.writeHead( 200, {
						'Access-Control-Allow-Origin': '*',
						'Content-Type': 'application/json'
					} );
					res.end( Json.stringify( rows ) );
				});
			});
		}
	}
}
