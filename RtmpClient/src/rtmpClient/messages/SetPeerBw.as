package rtmpClient.messages
{
	import flash.utils.ByteArray;
	
	import rtmpClient.RtmpHeader;

	public class SetPeerBw extends AbstractMessage
	{
		public static const LIMIT_TYPE_HARD:int = 0;
		public static const LIMIT_TYPE_SOFT:int = 1;
		public static const LIMIT_TYPE_DYNAMIC:int = 2;
		
		private var _value:int;
		private var _limitType:int;
		
		public function SetPeerBw(header:RtmpHeader = null, bytes:ByteArray = null)
		{
			super(header, bytes);
		}
		
		/*public SetPeerBw(int value, LimitType limitType) {
			this.value = value;
			this.limitType = limitType;
		}*/
		
		public static function dynamic(value:int):SetPeerBw {
			var spb:SetPeerBw = new SetPeerBw();
			spb._value = value;
			spb._limitType = LIMIT_TYPE_DYNAMIC;
			return spb;
		}
		
		public static function hard(value:int):SetPeerBw {
			var spb:SetPeerBw = new SetPeerBw();
			spb._value = value;
			spb._limitType = LIMIT_TYPE_HARD;
			return spb;
		}
		
		public function get value():int {
			return _value;
		}
		
		override public function get messageType():int {
			return MessageType.SET_PEER_BW;
		}
		
		override public function encode():ByteArray {
			var bytes:ByteArray = new ByteArray();
			bytes.writeInt(_value);
			bytes.writeByte(_limitType);
			return bytes;
		}
		
		override public function decode(bytes:ByteArray):void {
			super.decode(bytes);
			_value = bytes.readInt();
			_limitType = bytes.readByte();
		}
		
		override public function toString():String {
			return super.toString() + "windowSize: " + value + " limitType: " + _limitType;
		}
	}
}