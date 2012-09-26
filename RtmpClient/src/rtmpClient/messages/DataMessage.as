package rtmpClient.messages
{
	import flash.utils.ByteArray;
	
	import rtmpClient.RtmpHeader;

	public class DataMessage extends AbstractMessage
	{
		protected var _data:ByteArray;
		
		public function DataMessage(header:RtmpHeader, bytes:ByteArray)
		{
			super(header, bytes);
		}
		
		public function get data():ByteArray {
			return _data;
		}
		
		public function setData(data:ByteArray):void {
			_data = data;
			header.size = data.length;
		}
		
		/*public DataMessage(final byte[] ... bytes) {
			data = ChannelBuffers.wrappedBuffer(bytes);
			header.setSize(data.readableBytes());
		}
		
		public DataMessage(final int time, final ChannelBuffer in) {        
			header.setTime(time);
			header.setSize(in.readableBytes());
			data = in;
		}*/
		
		override public function encode():ByteArray {
			_data.position = 0;            
			return _data;
		}
		
		override public function decode(bytes:ByteArray):void {
			super.decode(bytes);
			_data = bytes;
		}
		
		public function get isConfig():Boolean {
			return false;
		}
	}
}