package rtmpClient
{
	import flash.net.Socket;
	import flash.utils.ByteArray;

	public interface IRtmpMessage
	{
		function get header():RtmpHeader;
		
		function get messageType():int;
		
		function encode():ByteArray;
		
		function decode(bytes:ByteArray):void;
	}
}