package rtmpClient.messages
{
	import flash.utils.ByteArray;
	
	import rtmpClient.RtmpHeader;

	public class Audio extends DataMessage
	{
		public function Audio(header:RtmpHeader = null, bytes:ByteArray = null)
		{
			super(header, bytes);
		}
		
		override public function get isConfig():Boolean {
			_data.position = 0;
			return _data.length > 3 && _data.readInt() == 0xaf001310;
		}
		
		/*public Audio(final byte[] ... bytes) {
			super(bytes);
		}
		
		public Audio(final int time, final byte[] prefix, final byte[] audioData) {
			header.setTime(time);
			data = ChannelBuffers.wrappedBuffer(prefix, audioData);
			header.setSize(data.readableBytes());
		}
		
		public Audio(final int time, final ChannelBuffer in) {
			super(time, in);
		}*/
		
		public static function get empty():Audio {
			var empty:Audio = new Audio();
			empty._data = new ByteArray();
			return empty;
		}
		
		override public function get messageType():int {
			return MessageType.AUDIO;
		}
	}
}