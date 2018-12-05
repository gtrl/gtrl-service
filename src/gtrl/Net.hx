package gtrl;

import js.npm.ws.Server as WebSocketServer;
import js.npm.ws.WebSocket;

class Net extends js.node.http.Server {

	var ws : WebSocketServer;

	public function new( ) {

		super();

		ws = new WebSocketServer( { server: this, clientTracking: true } );
		ws.on( 'connection', function(e) {
			trace('NEW CLIENT []');
		});
		ws.on( 'close', function(e) {
			//trace(e);
			//trace('CLIENT CLOSE ['+untyped ws.clients.size+']');
			//clients.remove( e );
			//trace('CLOSE ['+clients.length+']');
		});
		ws.on( 'message', function(e) {
			trace(e);
		});
		ws.on( 'error', function(e) {
			trace(e);
		});
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
}
