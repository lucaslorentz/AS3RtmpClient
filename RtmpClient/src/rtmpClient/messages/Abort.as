package rtmpClient.messages
{
	import flash.utils.ByteArray;
	
	import rtmpClient.RtmpHeader;

	public class Abort extends AbstractMessage
	{
		private var _streamId:int;
		
		public function Abort(header:RtmpHeader = null, bytes:ByteArray = null)
		{
			super(header, bytes);
		}
		
		/*public Abort(final int streamId) {
			this.streamId = streamId;
		}*/
		
		public function get streamId():int {
			return _streamId;
		}
		
		override public function get messageType():int {
			return MessageType.ABORT;
		}
		
		override public function encode():ByteArray {
			var out:ByteArray = new ByteArray();
			out.writeInt(_streamId);
			return out;
		}
		
		override public function decode(bytes:ByteArray):void {
			super.decode(bytes);
			_streamId = bytes.readInt();
		}
		
		override public function toString():String {
			return super.toString() + "streamId: " + streamId;
		}
	}
}