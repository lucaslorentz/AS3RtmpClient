package rtmpClient.messages
{
	import flash.net.Socket;
	import flash.utils.ByteArray;
	
	import rtmpClient.IRtmpMessage;
	import rtmpClient.RtmpHeader;

	public class AbstractMessage implements IRtmpMessage
	{
		private var _header:RtmpHeader;
		
		public function AbstractMessage(header:RtmpHeader = null, bytes:ByteArray = null)
		{
			_header = header;
			
			if(_header == null)
				_header = new RtmpHeader(messageType);
				
			if(bytes)
				decode(bytes);
		}
		
		public function get header():RtmpHeader {
			return _header;
		}
		
		public function get messageType():int {
			throw new Error("Not implemented.");
		}
		
		public function encode():ByteArray {
			throw new Error("Not implemented.");
		}
		
		public function decode(bytes:ByteArray):void {
		}
		
		public function toString():String {
			return header.toString();
		}
	}
}