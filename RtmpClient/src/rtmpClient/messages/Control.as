package rtmpClient.messages
{
	import flash.utils.ByteArray;
	
	import rtmpClient.RtmpHeader;
	
	public class Control extends AbstractMessage
	{
		public static const STREAM_BEGIN:int = 0;
		public static const STREAM_EOF:int = 1;
		public static const STREAM_DRY:int = 2;
		public static const SET_BUFFER:int = 3;
		public static const STREAM_IS_RECORDED:int = 4;
		public static const PING_REQUEST:int = 6;
		public static const PING_RESPONSE:int = 7;
		public static const SWFV_REQUEST:int = 26;
		public static const SWFV_RESPONSE:int = 27;
		public static const BUFFER_EMPTY:int = 31;
		public static const BUFFER_FULL:int = 32;
		
		private var _type:int;
		private var _streamId:int;
		private var _bufferLength:int;
		private var _time:int;
		private var _bytes:ByteArray;
		
		public function Control(header:RtmpHeader = null, bytes:ByteArray = null)
		{
			super(header, bytes);
		}
		
		/*private Control(Type type, int time) {
		this.type = type;
		this.time = time;
		}
		
		private Control(int streamId, Type type) {
		this.streamId = streamId;
		this.type = type;
		}*/
		
		override public function get messageType():int {
			return MessageType.CONTROL;
		}
		
		public function get type():int {
			return _type;
		}
		
		public function get time():int {
			return _time;
		}
		
		public function get bufferLenght():int {
			return _bufferLength;
		}
		
		override public function encode():ByteArray {
			var size:int;
			
			switch(_type) {
				case SWFV_RESPONSE: size = 44; break;
				case SET_BUFFER: size = 10; break;
				default: size = 6;
			}
			
			var out:ByteArray = new ByteArray();
			out.writeShort(_type);
			
			switch(type) {
				case STREAM_BEGIN:
				case STREAM_EOF:
				case STREAM_DRY:
				case STREAM_IS_RECORDED:
					out.writeInt(_streamId);
					break;
				case SET_BUFFER:
					out.writeInt(_streamId);
					out.writeInt(_bufferLength);
					break;
				case PING_REQUEST:
				case PING_RESPONSE:
					out.writeInt(_time);
					break;
				case SWFV_REQUEST:                
					break;
				case SWFV_RESPONSE:
					out.writeBytes(_bytes);
					break;
				case BUFFER_EMPTY:
				case BUFFER_FULL:
					out.writeInt(_streamId);
					break;
			}
			
			return out;
		}
		
		override public function decode(bytes:ByteArray):void {
			super.decode(bytes);
			_type = bytes.readShort();
			switch(type) {
				case STREAM_BEGIN:
				case STREAM_EOF:
				case STREAM_DRY:
				case STREAM_IS_RECORDED:
					_streamId = bytes.readInt();
					break;
				case SET_BUFFER:
					_streamId = bytes.readInt();
					_bufferLength = bytes.readInt();
					break;
				case PING_REQUEST:
				case PING_RESPONSE:
					_time = bytes.readInt();
					break;
				case SWFV_REQUEST:
					// only type (2 bytes)
					break;
				case SWFV_RESPONSE:
					_bytes = new ByteArray();
					_bytes.writeBytes(bytes);
					//in.readBytes(bytes);
					break;
				case BUFFER_EMPTY:
				case BUFFER_FULL:
					_streamId = bytes.readInt();
					break;
			}	
		}
		
		override public function toString():String {
			var str:String = "";
			str += super.toString();
			str += _type;
			str += " streamId: " + _streamId;
			
			switch(type) {
				case SET_BUFFER:
					str += " bufferLength: " + _bufferLength;
					break;
				case PING_REQUEST:
				case PING_RESPONSE:
					str += " time: " + _time;
					break;
			}
			
			return str;
		}
		
		public static function setBuffer(streamId:int, bufferLength:int):Control {
			var control:Control = new Control();
			control._bufferLength = bufferLength;
			control._type = SET_BUFFER;
			control._time = 0;
			control._streamId = streamId;
			return control;
		}
		
		public static function pingRequest(time:int):Control {
			var control:Control = new Control();
			control._type = PING_REQUEST;
			control._time = time;
			return control;
		}
		
		public static function pingResponse(time:int):Control {
			var control:Control = new Control();
			control._type = PING_RESPONSE;
			control._time = time;
			return control;
		}
		
		public static function swfvResponse(bytes:ByteArray):Control {
			var control:Control = new Control();
			control._type = SWFV_RESPONSE;
			control._time = 0;
			control._bytes = bytes;
			return control;
		}
		
		/*public static Control streamBegin(int streamId) {
		Control control = new Control(Type.STREAM_BEGIN, 0);
		control.streamId = streamId;
		return control;
		}
		
		public static Control streamIsRecorded(int streamId) {
		return new Control(streamId, Type.STREAM_IS_RECORDED);
		}
		
		public static Control streamEof(int streamId) {
		return new Control(streamId, Type.STREAM_EOF);
		}
		
		public static Control bufferEmpty(int streamId) {
		return new Control(streamId, Type.BUFFER_EMPTY);
		}
		
		public static Control bufferFull(int streamId) {
		return new Control(streamId, Type.BUFFER_FULL);
		}*/
	}
}