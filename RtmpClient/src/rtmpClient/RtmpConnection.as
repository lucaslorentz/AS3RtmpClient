package rtmpClient
{	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.Socket;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import rtmpClient.messages.BytesRead;
	import rtmpClient.messages.Command;
	import rtmpClient.messages.Control;
	import rtmpClient.messages.MessageType;
	import rtmpClient.messages.Metadata;
	import rtmpClient.messages.SetPeerBw;
	import rtmpClient.messages.WindowAckSize;
	import rtmpClient.handShakes.BasicRtmpHandshake;
	import rtmpClient.handShakes.DigestRtmpHandshake;
	
	public class RtmpConnection extends EventDispatcher
	{
		public var logger:IRtmpLogger = new TraceRtmpLogger();
		
		public var handler:IRtmpHandler;
		public var publisher:IRtmpPublisher;
		
		private var _status : String;
		private var _socket : Socket;
		
		private var _decoder:RtmpDecoder = new RtmpDecoder();
		private var _encoder:RtmpEncoder = new RtmpEncoder();
		
		private var _customConnectOptions:Object;
		private var _url:String;
		private var _protocol:String;
		private var _server:String
		private var _port:int = 1935;
		private var _application:String;
		private var _instanceName:String;
		
		private var _transactionId:int = 1;
		private var _transactionToFunctionMap:Object = {};
		private var _swfvBytes:ByteArray;
		
		private var _bytesReadWindow:int = 2500000;
		private var _bytesRead:uint = 0;
		private var _bytesReadLastSent:uint = 0;    
		private var _bytesWrittenWindow:int = 2500000;
		
		private var _streamId:int;
		
		private var _handShake:IRtmpHandshake;
		
		private var _swfLoader:URLLoader;
				
		public function get streamId():int {
			return _streamId;
		}
		
		public function RtmpConnection( )
		{
			// reset status			
			_status = "inactive";		
		}
		
		private function onClose ( event:Event ):void
		{
			_status = "inactive";
			
			if(logger)
				logger.write( "socketClose: " + event );			
		}
		
		private function onIOError ( event:IOErrorEvent ):void
		{
			if(logger)
				logger.write( "socketIOError: " + event );			
		}
		
		private function onSecurityError ( event:SecurityErrorEvent ):void
		{
			if(logger)
				logger.write( "socketSecurityError " + event );			
		}
		
		private function onConnect ( event:Event ):void
		{
			sendHandShake1();
		}
		
		private function onData ( event:ProgressEvent ):void
		{			
			switch ( _status )
			{		
				case "handshake1" :
					handleServerAllAndSendHandShake2();
					break;
				case "handshake" :
					openConnection();
					break;
				case "active" :
					handleSocketBytes();
					break;
				case "inactive" : break;
			}            
		}
		
		public function connect(url:String, customConnectOptions:Object = null):void {
			connectInternal(url, customConnectOptions);
		}
		
		private function connectInternal(url:String, customConnectOptions:Object = null, isRedirect:Boolean = false):void {
			_customConnectOptions = customConnectOptions;
			
			var regex:RegExp = /(?P<protocol>\w*?):\/\/   (?P<server>[\w._@]*?)   (?::(?P<port>\d*))?   (?:   \/+(?P<application>[\w._@]+?)  (?:\/+(?P<instanceName>[\w._@]+?))?    )?  \/*$/gx;
			var parts:Object = regex.exec(url);
			
			_protocol = parts.protocol;
			_server = parts.server;
			_port = parts.port || 1935;
			_application = parts.application;
			_instanceName = parts.instanceName;
			
			_url = url;
			
			if(isRedirect)
			{
				if(_application)
					customConnectOptions.app = _application;
			}
			
			if(_customConnectOptions.swfVfy == "1"){
				_swfLoader = new URLLoader();
				_swfLoader.dataFormat = URLLoaderDataFormat.BINARY;
				_swfLoader.addEventListener(Event.COMPLETE, _swfLoaderComplete, false, 0, true);
				_swfLoader.addEventListener(IOErrorEvent.IO_ERROR, _swfLoaderIOError, false, 0, true);
				_swfLoader.load(new URLRequest(_customConnectOptions.swfUrl));
			} else {
				startConnect();
			}
		}
		
		private function _swfLoaderIOError(e:Event):void {
			_swfLoader = null;
		}
		
		private function _swfLoaderComplete(e:Event):void {
			var swfBytes:ByteArray = _swfLoader.data as ByteArray;

			var swfSize:int = swfBytes.length;
			var swfHash:ByteArray = Utils.sha256(swfBytes, DigestRtmpHandshake.CLIENT_CONST);
			
			_swfLoader = null;
			
			startConnect(swfHash, swfSize);
		}
		
		private function startConnect(swfHash:ByteArray = null, swfSize:int = 0):void {
			disconnect();
			
			// create new socket
			_socket = new Socket();
			
			// initializing events			
			_socket.addEventListener( Event.CLOSE , onClose, false, 0, true );
			_socket.addEventListener( Event.CONNECT , onConnect, false, 0, true );
			_socket.addEventListener( IOErrorEvent.IO_ERROR , onIOError, false, 0, true );
			_socket.addEventListener( ProgressEvent.SOCKET_DATA , onData, false, 0, true );
			_socket.addEventListener( SecurityErrorEvent.SECURITY_ERROR , onSecurityError, false, 0, true );	
			
			_socket.connect( _server , _port );
			
			//_handShake = new DigestRtmpHandshake(false, swfHash, swfSize);
			_handShake = new BasicRtmpHandshake();
		}
		
		private function sendHandShake1():void {
			_status = "handshake1";
			
			var bytes1:ByteArray = _handShake.encodeClient0();
			var bytes2:ByteArray = _handShake.encodeClient1();
			
			_socket.writeBytes(bytes1);
			_socket.writeBytes(bytes2);
			_socket.flush();
			
			if(logger)
				logger.write("Sent C0, C1");
		}
		
		private function handleServerAllAndSendHandShake2():void {
			if(logger)
				logger.write("Received S0, S1");
			
			if(_socket.bytesAvailable < DigestRtmpHandshake.HANDSHAKE_SIZE * 2 + 1)
			{
				trace("Invalid S0, S1");
				return;
			}
			
			var serverBytes:ByteArray = new ByteArray();

			_socket.readBytes( serverBytes, 0, DigestRtmpHandshake.HANDSHAKE_SIZE * 2 + 1);		
			_handShake.decodeServerAll(serverBytes);
			
			_swfvBytes = _handShake.getSwfvBytes();
			
			_socket.writeBytes( _handShake.encodeClient2() );
						
			_status = "handshake";
			
			sendCommandExpectingResult(Command.createConnectCommand(_application, _url, _customConnectOptions), connectResultHandler);
			
			if(logger)
				logger.write("Sent C2, Connect");
		}
		
		private function sendCommandExpectingResult(command:Command, resultHandler:Function):void {
			var id:int = _transactionId++;
			command.transactionId = id;
			_transactionToFunctionMap[id] = resultHandler;
			sendMessage(command);
			
			if(logger)
				logger.write("Sent command (expecting result): ", command);
		}
		
		public function sendMessage(message:IRtmpMessage):void {
			_encoder.writeRequested(_socket, message);
			_socket.flush();
		}
		
		public function openConnection ( ):void
		{
			_status = "active";
			handleSocketBytes();
			
			if(logger)
				logger.write("Received S2");
		}
		
		private function handleSocketBytes():void {
			while(_socket.connected && _socket.bytesAvailable > 0){
				var message:IRtmpMessage = _decoder.process(_socket);
				if(!message)
					break;
				handleMessage(message);
			}
		}
		
		private function handleMessage(message:IRtmpMessage):void {
			/*if(publisher != null && publisher.handle(me)) {
			return;
			}*/
			
			switch(message.header.messageType) {
				case MessageType.CHUNK_SIZE: // handled by decoder
					break;
				case MessageType.CONTROL:
					var control:Control = message as Control;
					switch(control.type) {
						case Control.PING_REQUEST:
							var time:int = control.time;
							
							var pong:Control = Control.pingResponse(time);
							sendMessage(pong);
							
							if(logger){
								logger.write("Received server ping: ", time);
								logger.write("Sent ping response: ", pong);
							}
							break;
						case Control.SWFV_REQUEST:
							if(logger)
								logger.write("SWFV Request");
							if(_swfvBytes == null) {
								if(logger)
									logger.write("swf verification not initialized! not sending response, server likely to stop responding / disconnect");
							} else {
								var swfv:Control = Control.swfvResponse(_swfvBytes);
								if(logger)
									logger.write("sending swf verification response: ", swfv);
								sendMessage(swfv);
							}
							break;
						case Control.STREAM_BEGIN:
							if(logger)
								logger.write("Stream Begin");
							
							/*if(publisher != null && !publisher.isStarted()) {
							publisher.start(socket, options.getStart(), options.getLength(), new ChunkSize(4096));
							return;
							}*/
							
							if(_streamId != 0) {
								sendMessage(Control.setBuffer(_streamId, 0/*options.getBuffer()*/));
							}
							break;
						default:
							//trace("ignoring control message: ", control);
					}
					break;
				case MessageType.METADATA_AMF0:
				case MessageType.METADATA_AMF3:
					if(handler)
						handler.onMetadata(message as Metadata);
					
					break;
				case MessageType.AUDIO:
				case MessageType.VIDEO:
				case MessageType.AGGREGATE:
					
					_bytesRead += message.header.size;
					if((_bytesRead - _bytesReadLastSent) > _bytesReadWindow) {
						if(logger)
							logger.write("sending bytes read ack ", _bytesRead);
						_bytesReadLastSent = _bytesRead;
						sendMessage(BytesRead.createWithValues(_bytesRead));
					}
					
					if(handler)
						handler.onStreamData(message);
					
					break;
				case MessageType.COMMAND_AMF0:
				case MessageType.COMMAND_AMF3:
					var command:Command = message as Command;                
					var name:String = command.name;
					
					if(logger)
						logger.write("server command: ", name);
					
					var resultHandler:Function = _transactionToFunctionMap[command.transactionId];
					delete _transactionToFunctionMap[command.transactionId];
					
					if(resultHandler != null)
						resultHandler(command);
					
					if(name == "onStatus") {
						var temp:Object = command.args[0];						
						var code:String = temp["code"];
						
						if(logger)
							logger.write("onStatus code: ", code);
						
						if (code == "NetStream.Failed"
							|| code == "NetStream.Play.Failed"
							|| code == "NetStream.Play.Stop"
							|| code == "NetStream.Play.StreamNotFound") {
							
							if(logger)
								logger.write("disconnecting, code: "+code+", bytes read: "+_bytesRead);
							
							disconnect();
							return;
						}
						
						if(code == "NetStream.Publish.Start")
							onStreamPublishStart();
						
						/*if(code == "NetStream.Publish.Start"
							&& _publisher != null && !_publisher.isStarted) {
							publisher.start(socket, options.getStart(), options.getLength(), new ChunkSize(4096));
							return;
						}*/
						/*if (_publisher != null && code == "NetStream.Unpublish.Success") {
							trace("unpublish success, closing channel");
							ChannelFuture future = channel.write(Command.closeStream(streamId));
							future.addListener(ChannelFutureListener.CLOSE);
							return;
						}*/
					} else if(name == "close") {
						if(logger)
							logger.write("server called close, closing socket");
						
						disconnect();
						return;
					}
					break;
				case MessageType.BYTES_READ:
					if(logger)
						logger.write("ack from server: ", message);
					break;
				case MessageType.WINDOW_ACK_SIZE:
					var was:WindowAckSize = message as WindowAckSize;                
					if(was.value != _bytesReadWindow) {
						sendMessage(SetPeerBw.dynamic(_bytesReadWindow));
					}                
					break;
				case MessageType.SET_PEER_BW:
					var spb:SetPeerBw = message as SetPeerBw;                
					if(spb.value != _bytesWrittenWindow) {
						sendMessage(WindowAckSize.createWithValue(_bytesWrittenWindow));
					}
					break;
				default:
					if(logger)
						logger.write("ignoring rtmp message: ", message);
			}
		}
		
		protected function connectResultHandler(command:Command):void {
			if(command.name == "_result") {
				sendCommandExpectingResult(Command.createStream(), createStreamResultHandler);
			} else if(command.name == "_error") {
				var errorObject:Object = command.args[0];						
				var errorCode:String = errorObject["code"];
				
				disconnect();
				
				if(errorCode == "NetConnection.Connect.Rejected")
				{
					var ex:Object = errorObject["ex"];
					if(ex && ex["redirect"]) //Redirect connection
					{
						connectInternal(ex["redirect"], _customConnectOptions, true);
						if(logger)
							logger.write("Redirecting to: ", ex["redirect"]);
					}
				}
			}
		}
		
		protected function createStreamResultHandler(command:Command):void {
			if(command.name == "_result") {
				_streamId = command.args[0];
				
				if(logger)
					logger.write("streamId to use: ", _streamId);
				
				if(handler)
					handler.onStreamCreated(_streamId);
			}
			
			/*if(options.getPublishType() != null) { // TODO append, record                            
			var reader:IRtmpReader;
			if(options.getFileToPublish() != null) {
			reader = RtmpPublisher.getReader(options.getFileToPublish());
			} else {
			reader = options.getReaderToPublish();
			}
			if(options.getLoop() > 1) {
			reader = new LoopedReader(reader, options.getLoop());
			}
			publisher = new RtmpPublisher(reader, streamId, options.getBuffer(), false, false) {
			@Override protected RtmpMessage[] getStopMessages(long timePosition) {
			return new RtmpMessage[]{Command.unpublish(streamId)};
			}
			};
			
			sendMessage(Command.publish(_streamId, options));
			return;
			} else {
			writer = options.getWriterToSave();
			if(writer == null) {
			writer = new FlvWriter(options.getStart(), options.getSaveAs());
			}
			sendMessage(Command.play(streamId, options));
			sendMessage(Control.setBuffer(streamId, 0));
			}*/
		}
		
		public function disconnect():void {
			if(_socket && _socket.connected)
				_socket.close();
		}
				
		public var onStreamPublishStart:Function;
	}	
}