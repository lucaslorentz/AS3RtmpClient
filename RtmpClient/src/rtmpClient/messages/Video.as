
package rtmpClient.messages
{
	import flash.utils.ByteArray;
	
	import rtmpClient.RtmpHeader;

	public class Video extends DataMessage
	{
		public function Video(header:RtmpHeader = null, bytes:ByteArray = null)
		{
			super(header, bytes);
		}
		
		override public function get isConfig():Boolean {
			_data.position = 0;
			return _data.length > 3 && _data.readInt() == 0x17000000;
		}
		
		/*public Video(final byte[] ... bytes) {
			super(bytes);
		}
		
		public Video(final int time, final byte[] prefix, final int compositionOffset, final byte[] videoData) {
			header.setTime(time);
			data = ChannelBuffers.wrappedBuffer(prefix, Utils.toInt24(compositionOffset), videoData);
			header.setSize(data.readableBytes());
		}
		
		public Video(final int time, final ChannelBuffer in) {
			super(time, in);
		}*/
		
		public static function get empty():Video {
			var empty:Video = new Video();
			empty._data = new ByteArray();
			empty._data.writeByte(0);
			empty._data.writeByte(0);
			return empty;
		}
		
		override public function get messageType():int {
			return MessageType.VIDEO;
		}
	}
}