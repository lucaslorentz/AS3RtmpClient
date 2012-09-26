package rtmpClient
{
	import flash.utils.ByteArray;

	public interface IRtmpHandshake
	{
		function encodeClient0():ByteArray;
		function encodeClient1():ByteArray;
		function encodeClient2():ByteArray;
		
		function decodeServerAll(bytes:ByteArray):Boolean;
		
		function getSwfvBytes():ByteArray;
	}
}