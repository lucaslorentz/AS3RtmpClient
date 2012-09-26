package rtmpClient
{
	import flash.net.Socket;
	import flash.utils.ByteArray;
	
	import rtmpClient.messages.ChunkSize;
	import rtmpClient.messages.MessageType;
	
	public class RtmpDecoder
	{
		private static const STATE_GET_HEADER:int = 0;
		private static const STATE_GET_PAYLOAD:int = 1;
		
		private var _header:RtmpHeader;
		private var _channelId:int;
		private var _payload:Payload;
		private var _chunkSize:int = 128;
		
		private var _incompleteHeaders:Object = {};
		private var _incompletePayloads:Object = {};
		private var _completedHeaders:Object = {};
		
		private var _state:int = STATE_GET_HEADER;
		
		public function process(socket:Socket):IRtmpMessage {
			switch(_state) {
				
				case STATE_GET_HEADER:
					if(socket.bytesAvailable < RtmpHeader.MAX_ENCODED_SIZE)
						return null; //Read it later
					
					_header = new RtmpHeader();
					_header.parse(socket, _incompleteHeaders);
					_channelId = _header.channelId;
					
					if(_incompletePayloads[_channelId] == null) { // new chunk stream
						_incompleteHeaders[_channelId] = _header;
						_incompletePayloads[_channelId] = new Payload(_header.size);
					}
					
					_payload = _incompletePayloads[_channelId];
					
					checkpoint(STATE_GET_PAYLOAD);
				
				case STATE_GET_PAYLOAD:
					var bytesToRead:int = Math.min(_payload.writableBytes, _chunkSize);
					
					if(socket.bytesAvailable < bytesToRead)
						return null; //Read it later
					
					var bytes:ByteArray = new ByteArray();
					if(bytesToRead > 0)
						socket.readBytes(bytes, 0, bytesToRead);
					_payload.writeBytes(bytes);
					checkpoint(STATE_GET_HEADER);
					if(_payload.writable) { // more chunks remain
						return null;
					}
					_incompletePayloads[_channelId] = null;
					var prevHeader:RtmpHeader = _completedHeaders[_channelId];                
					if (!_header.isLarge) {
						_header.time = prevHeader.time + _header.deltaTime;
					}
					
					_payload.position = 0;
					var message:IRtmpMessage = MessageType.decode(_header, _payload);
					/*if(logger.isDebugEnabled()) {
						logger.debug("<< {}", message);
					}*/
					_payload = null;
					if(_header.isChunkSize) {
						var csMessage:ChunkSize = message as ChunkSize;
						trace("decoder new chunk size: {}", csMessage);
						_chunkSize = csMessage.chunkSize;
					}
					_completedHeaders[_channelId] = _header;
					
					return message;
					
				default:               
					throw new Error("unexpected decoder state: " + _state);
					
			}
		}
		
		public function checkpoint(state:int):void {
			_state = state;
		}
	}
}