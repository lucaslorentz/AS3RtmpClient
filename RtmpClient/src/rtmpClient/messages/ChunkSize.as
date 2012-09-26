package rtmpClient.messages
{
	import flash.net.Socket;
	import flash.utils.ByteArray;
	
	import rtmpClient.RtmpHeader;

	public class ChunkSize extends AbstractMessage
	{
		private var _chunkSize:int;
		
		public function ChunkSize(header:RtmpHeader, bytes:ByteArray)
		{
			super(header, bytes);
		}
		
		override public function get messageType():int {
			return MessageType.CHUNK_SIZE;
		}
		
		public function get chunkSize():int {
			return _chunkSize;
		}
		
		override public function encode():ByteArray {
			var out:ByteArray = new ByteArray();
			out.writeInt(_chunkSize);
			return out;
		}
		
		override public function decode(bytes:ByteArray):void {
			super.decode(bytes);
			_chunkSize = bytes.readInt();
		}
		
		override public function toString():String {
			return super.toString() + chunkSize;
		}
	}
}