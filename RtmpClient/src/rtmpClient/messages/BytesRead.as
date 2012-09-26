package rtmpClient.messages
{
	import flash.utils.ByteArray;
	
	import rtmpClient.RtmpHeader;

	public class BytesRead extends AbstractMessage
	{
		private var _value:int;
		
		public function BytesRead(header:RtmpHeader = null, bytes:ByteArray = null)
		{
			super(header, bytes);
		}
		
		public static function createWithValues(bytesRead:int):BytesRead {
			var message:BytesRead = new BytesRead();
			message._value = bytesRead;
			return message;
		}
		
		override public function get messageType():int {
			return MessageType.BYTES_READ;
		}
		
		public function get value():int {
			return _value;
		}
		
		override public function encode():ByteArray {
			var out:ByteArray = new ByteArray();
			out.writeInt(_value);
			return out;
		}
		
		override public function decode(bytes:ByteArray):void {
			super.decode(bytes);
			_value = bytes.readInt();
		}
		
		override public function toString():String {
			return super.toString() + value;
		}
	}
}