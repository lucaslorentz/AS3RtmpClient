package rtmpClient.messages
{
	import flash.net.Socket;
	import flash.utils.ByteArray;
	
	import rtmpClient.RtmpHeader;

	public class WindowAckSize extends AbstractMessage
	{
		private var _value:int;
		
		public function WindowAckSize(header:RtmpHeader = null, bytes:ByteArray = null)
		{
			super(header, bytes);
		}
		
		public static function createWithValue(value:int):WindowAckSize {
			var message:WindowAckSize = new WindowAckSize();
			message._value = value;
			return message;
		}
		
		public function get value():int {
			return _value;
		}
		
		override public function get messageType():int {
			return MessageType.WINDOW_ACK_SIZE;
		}
		
		override public function encode():ByteArray {
			var bytes:ByteArray = new ByteArray();
			bytes.writeInt(_value);
			return bytes;
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