package rtmpClient
{
	import flash.net.Socket;
	import flash.utils.ByteArray;
	
	import rtmpClient.messages.ChunkSize;
	import rtmpClient.messages.Control;

	public class RtmpEncoder
	{
		private var _chunkSize:int = 128;    
		private var _channelPrevHeaders:Array = new Array(RtmpHeader.MAX_CHANNEL_ID);    
		
		private function clearPrevHeaders():void {
			trace("clearing prev stream headers");
			_channelPrevHeaders = new Array(RtmpHeader.MAX_CHANNEL_ID);
		}
		
		public function writeRequested(socket:Socket, message:IRtmpMessage):void {
			socket.writeBytes(encode(message));
		}
		
		public function encode(message:IRtmpMessage):ByteArray {			
			var bodyBytes:ByteArray = message.encode();

			var header:RtmpHeader = message.header;
			
			if(header.isChunkSize) {
				var csMessage:ChunkSize = message as ChunkSize;
				trace("encoder new chunk size: ", csMessage);
				_chunkSize = csMessage.chunkSize;
			} else if(header.isControl) {
				var control:Control = message as Control;
				if(control.type == Control.STREAM_BEGIN) {
					clearPrevHeaders();
				}
			}
			
			var channelId:int = header.channelId;
			header.size = bodyBytes.length;
			
			var prevHeader:RtmpHeader = null;//_channelPrevHeaders[channelId];
			if(prevHeader != null // first stream message is always large
				&& header.streamId > 0 // all control messages always large
				&& header.time > 0) { // if time is zero, always large
				if(header.size == prevHeader.size) {
					header.headerType = RtmpHeader.TYPE_SMALL;
				} else {
					header.headerType = RtmpHeader.TYPE_MEDIUM;
				}
				
				var deltaTime:int = header.time - prevHeader.time;
				if(deltaTime < 0) {
					trace("negative time: {}", header);
					header.deltaTime = 0;
				} else {
					header.deltaTime = deltaTime;
				}
			} else {
				// otherwise force to LARGE
				header.headerType = RtmpHeader.TYPE_LARGE;
			}
			_channelPrevHeaders[channelId] = header;        
			
			/*if(logger.isDebugEnabled()) {
				logger.debug(">> {}", message);
			} */
			
			var packetBytes:ByteArray = new ByteArray();
			var packetLength:int = RtmpHeader.MAX_ENCODED_SIZE + header.size + header.size / _chunkSize
							
			var firstChunk:Boolean = true;
			bodyBytes.position = 0;
			while(bodyBytes.bytesAvailable > 0) {
				var size:int = Math.min(_chunkSize, bodyBytes.bytesAvailable);
				if(firstChunk) {                
					header.encode(packetBytes);
					firstChunk = false;
				} else {
					packetBytes.writeBytes(header.getTinyHeader());
				}
				if(size > 0)
					bodyBytes.readBytes(packetBytes, packetBytes.position, size);
				packetBytes.position += size;
			}
			
			return packetBytes;
		}
	}
}