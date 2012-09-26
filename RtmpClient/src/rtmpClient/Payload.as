package rtmpClient
{
	import flash.utils.ByteArray;

	public class Payload extends ByteArray
	{
		private var _size:int;
		
		public function Payload(size:int)
		{
			_size = size;
		}
		
		public function get writableBytes():int {
			return _size - length;
		}
		
		public function get writable():Boolean {
			return length < _size;
		}
	}
}