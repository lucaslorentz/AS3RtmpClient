package rtmpClient
{
	import flash.net.Socket;
	import flash.utils.ByteArray;
	
	import rtmpClient.messages.MessageType;
	
	public class RtmpHeader
	{
		public static const TYPE_LARGE:int = 0;
		public static const TYPE_MEDIUM:int = 1;
		public static const TYPE_SMALL:int = 2;
		public static const TYPE_TINY:int = 3;
		
		public static const MAX_CHANNEL_ID:int = 65600;
		public static const MAX_NORMAL_HEADER_TIME:int = 0xFFFFFF;
		public static const MAX_ENCODED_SIZE:int = 18;
		
		private var _headerType:int;
		private var _channelId:int;
		private var _deltaTime:int;
		private var _time:int;    
		private var _size:int;
		private var _messageType:int;
		private var _streamId:int;
		
		public function RtmpHeader(messageType:int = 0, time:int = 0, size:int = 0):void {
			_messageType = messageType;
			_channelId = MessageType.getDefaultChannelId(messageType);
			_time = time;
			_size = size;
		}
		
		public function parse(socket:Socket, incompleteHeaders:Object):void
		{
			var firstByteInt:int = socket.readByte();
			var typeAndChannel:int;
			
			if((firstByteInt & 0x3f) == 0){
				typeAndChannel = (firstByteInt & 0xff) << 8 | (socket.readByte() & 0xff);
				_channelId = 64 + (typeAndChannel & 0xff);
				_headerType = typeAndChannel >> 14;
			} else if((firstByteInt & 0x3f) == 1){
				typeAndChannel = (firstByteInt & 0xff) << 16 | (socket.readByte() & 0xff) << 8 | (socket.readByte() & 0xff);
				_channelId = 64 + ((typeAndChannel >> 8) & 0xff) + ((typeAndChannel & 0xff) << 8);
				_headerType = typeAndChannel >> 22;
			} else {
				typeAndChannel = firstByteInt & 0xff;
				_channelId = (typeAndChannel & 0x3f);
				_headerType = typeAndChannel >> 6;
			}
			
			var prevHeader:RtmpHeader = incompleteHeaders[_channelId];
			switch(_headerType) {
				case TYPE_LARGE:
					_time = readMedium(socket);
					_size = readMedium(socket);
					_messageType = socket.readByte();
					_streamId = readInt32Reverse(socket);
					if(_time == MAX_NORMAL_HEADER_TIME) {
						_time = socket.readInt();
					}
					break;
				case TYPE_MEDIUM:
					_deltaTime = readMedium(socket);
					_size = readMedium(socket);
					_messageType = socket.readByte();
					_streamId = prevHeader._streamId;
					if(_deltaTime == MAX_NORMAL_HEADER_TIME) {
						_deltaTime = socket.readInt();
					}
					break;
				case TYPE_SMALL:
					_deltaTime = readMedium(socket);
					_size = prevHeader._size;
					_messageType = prevHeader._messageType;
					_streamId = prevHeader._streamId;
					if(_deltaTime == MAX_NORMAL_HEADER_TIME) {
						_deltaTime = socket.readInt();
					}
					break;
				case TYPE_TINY:
					_headerType = prevHeader._headerType; // preserve original
					_time = prevHeader._time;
					_deltaTime = prevHeader._deltaTime;
					_size = prevHeader._size;
					_messageType = prevHeader._messageType;
					_streamId = prevHeader._streamId;
					break;
			}
		}
		
		private function readMedium(socket:Socket):int {
			var val:int = 0;
			val += socket.readUnsignedByte() << 16;
			val += socket.readUnsignedByte() << 8;
			val += socket.readUnsignedByte();
			return val;
		}
		
		private function writeMedium(bytes:ByteArray, value:int):void {
			bytes.writeByte(value >> 16 & 0xFF);
			bytes.writeByte(value >> 8 & 0xFF);
			bytes.writeByte(value & 0xFF);
		}
		
		public function readInt32Reverse(socket:Socket):int {
			var a:int = socket.readByte();
			var b:int = socket.readByte();
			var c:int = socket.readByte();
			var d:int = socket.readByte();
			var val:int = 0;
			val += d << 24;
			val += c << 16;
			val += b << 8;
			val += a;
			return val;
		}
		
		public function writeInt32Reverse(bytes:ByteArray, value:int):void {
			bytes.writeByte(value & 0xFF);
			bytes.writeByte(value >> 8 & 0xFF);
			bytes.writeByte(value >> 16 & 0xFF);
			bytes.writeByte(value >> 24 & 0xFF);
		}
		
		public function get isMedia():Boolean {
			switch(_messageType) {
				case MessageType.AUDIO:
				case MessageType.VIDEO:
				case MessageType.AGGREGATE:
					return true;
				default:
					return false;
			}
		}
		
		public function get isMetadata():Boolean {
			return _messageType == MessageType.METADATA_AMF0
				|| _messageType == MessageType.METADATA_AMF3;
		}
		
		public function get isAggregate():Boolean {
			return _messageType == MessageType.AGGREGATE;
		}
		
		public function get isAudio():Boolean {
			return _messageType == MessageType.AUDIO;
		}
		
		public function get isVideo():Boolean {
			return _messageType == MessageType.VIDEO;
		}
		
		public function get isLarge():Boolean {
			return _headerType == TYPE_LARGE;
		}
		
		public function get isControl():Boolean {
			return _messageType == MessageType.CONTROL;
		}
		
		public function get isChunkSize():Boolean {
			return _messageType == MessageType.CHUNK_SIZE;
		}
		
		public function get headerType():int {
			return _headerType;
		}
		
		public function set headerType(value:int):void {
			_headerType = value;
		}
		
		public function get channelId():int {
			return _channelId;
		}
		
		public function set channelId(value:int):void {
			_channelId = value;
		}
		
		public function get time():int {
			return _time;
		}
		
		public function set time(value:int):void {
			_time = value;
		}
		
		public function get deltaTime():int {
			return _deltaTime;
		}
		
		public function set deltaTime(value:int):void {
			_deltaTime = value;
		}
		
		public function get size():int {
			return _size;
		}
		
		public function set size(value:int):void {
			_size = value;
		}
		
		public function get messageType():int {
			return _messageType;
		}
		
		public function set messageType(value:int):void {
			this._messageType = value;
		}
		
		public function get streamId():int {
			return _streamId;
		}
		
		public function set streamId(value:int):void {
			_streamId = value;
		}
		
		public function encode(out:ByteArray):void {
			out.writeBytes(encodeHeaderTypeAndChannel(_headerType, _channelId));
				
			if(_headerType == TYPE_TINY) {
				return;
			}
			
			var extendedTime:Boolean;
			if(_headerType == TYPE_LARGE) {
				extendedTime = time >= MAX_NORMAL_HEADER_TIME;             
			} else {
				extendedTime = deltaTime >= MAX_NORMAL_HEADER_TIME;
			}
			if(extendedTime) {
				writeMedium(out, MAX_NORMAL_HEADER_TIME); 
			} else {                                        // LARGE / MEDIUM / SMALL
				writeMedium(out, _headerType == TYPE_LARGE ? time : deltaTime);
			}
			if(_headerType != TYPE_SMALL) {
				writeMedium(out, size);                      // LARGE / MEDIUM
				out.writeByte(messageType);     // LARGE / MEDIUM
				if(_headerType == TYPE_LARGE) {
					writeInt32Reverse(out, streamId); // LARGE
				}
			}
			if(extendedTime) {
				out.writeInt(_headerType == TYPE_LARGE ? time : deltaTime);
			}
		}
		
		public function getTinyHeader():ByteArray {
			return encodeHeaderTypeAndChannel(TYPE_TINY, _channelId);
		}
		
		private static function encodeHeaderTypeAndChannel(_headerType:int, _channelId:int):ByteArray {
			var array:Array;
			
			if (_channelId <= 63) {
				array = [ (_headerType << 6) + _channelId ];
			} else if (_channelId <= 320) {
				array = [ _headerType << 6, _channelId - 64 ];
			} else {            
				array = [ (_headerType << 6) | 1, (_channelId - 64) & 0xff, (_channelId - 64) >> 8 ];
			}
			
			var bytes:ByteArray = new ByteArray();
			for each(var b:int in array)
				bytes.writeByte(b);
			return bytes;
		}
		
		public function toString():String {
			return "[" + _headerType + " " + messageType + " c" + _channelId + " #" +streamId + " t" + time + " (" + deltaTime + ") s" +size + "]";
		}
	}
}