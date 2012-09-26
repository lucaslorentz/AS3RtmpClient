package rtmpClient.messages
{
	import flash.utils.ByteArray;
	
	import rtmpClient.RtmpHeader;

	public class Aggregate extends DataMessage
	{
		public function Aggregate(header:RtmpHeader = null, bytes:ByteArray = null)
		{
			super(header, bytes);
		}
		
		/*public Aggregate(int time, ChannelBuffer in) {
			super();
			header.setTime(time);
			data = in;
			header.setSize(data.readableBytes());
		}*/
		
		override public function get messageType():int {
			return MessageType.AGGREGATE;
		}
		
		override public function get isConfig():Boolean {
			return false;
		}
	}
}