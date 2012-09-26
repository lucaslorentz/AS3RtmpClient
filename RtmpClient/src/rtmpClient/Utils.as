package rtmpClient
{
	import com.hurlant.crypto.Crypto;
	import com.hurlant.crypto.hash.HMAC;
	
	import flash.utils.ByteArray;

	public class Utils
	{
		public static function sha256(message:ByteArray, key:ByteArray):ByteArray {
			var mac:HMAC = Crypto.getHMAC("sha256");
			return mac.compute(key, message);
		}
		
		public static function arrayToByteArray(array:Array):ByteArray {
			var byteArray:ByteArray = new ByteArray();
			for each(var byte:int in array)
				byteArray.writeByte(byte);
			return byteArray;
		}
		
		public static function byteArrayToArray(byteArray:ByteArray):Array {
			var array:Array = [];
			var oldPosition:int = byteArray.position;
			byteArray.position = 0;
			while(byteArray.bytesAvailable)
				array.push(byteArray.readByte());
			byteArray.position = oldPosition;
			return array;
		}
		
		public static function cloneByteArray(byteArray:ByteArray):ByteArray {
			var clone:ByteArray = new ByteArray();
			clone.writeBytes(byteArray);
			return clone;
		}
		
		public static function byteArrayAreEquals(array1:ByteArray, array2:ByteArray):Boolean {
			if(array1.length != array2.length)
				return false;
			
			var oldPosition1:int = array1.position;
			var oldPosition2:int = array2.position;
			
			array1.position = 0;
			array2.position = 0;
			
			while(array1.bytesAvailable > 0){
				if(array1.readByte() != array2.readByte())
					return false;
			}
			
			array1.position = oldPosition1;
			array2.position = oldPosition2;
			
			return true;
		}
		
		public static function arrayAreEquals(array1:Array, array2:Array):Boolean {
			if(array1.length != array2.length)
				return false;
			
			for(var i:int = 0; i < array1.length; i++){
				if(array1[i] != array2[i])
					return false;
			}
			
			return true;
		}
	}
}