package rtmpClient.handShakes
{
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	import rtmpClient.IRtmpHandshake;

	public class BasicRtmpHandshake implements IRtmpHandshake
	{
		private var _serverData:ByteArray;
		
		public function BasicRtmpHandshake()
		{
		}
				
		public function encodeClient0():ByteArray
		{
			var bytes:ByteArray = new ByteArray();
			bytes.writeByte(0x03);
			return bytes;
		}
		
		public function encodeClient1():ByteArray
		{
			//Generate random data
			var randomBytes:ByteArray = new ByteArray();
			
			randomBytes.writeInt(getTimer()); //Client timestamp
			randomBytes.writeInt(0); //Server timestamp
			
			var count : int = -1;
			while ( ++count < (1536 - 8))
				randomBytes.writeByte( Math.random()*0xFF );
			
			return randomBytes;
		}
		
		public function encodeClient2():ByteArray
		{
			return _serverData;
		}
		
		public function decodeServerAll(bytes:ByteArray):Boolean
		{
			bytes.readByte( ); //Read S0
			
			_serverData = new ByteArray();
			bytes.readBytes( _serverData, 0, 1536 );
			
			var echoBytes : ByteArray = new ByteArray( );
			bytes.readBytes( echoBytes, 0, 1536 );
						
			return true;
		}
		
		public function getSwfvBytes():ByteArray
		{
			return null;
		}
		
	}
}