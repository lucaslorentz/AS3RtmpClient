package rtmpClient.messages
{
	import flash.net.ObjectEncoding;
	import flash.utils.ByteArray;
	
	import rtmpClient.RtmpHeader;

	public class MetadataAmf0 extends Metadata
	{
		public function MetadataAmf0(header:RtmpHeader = null, bytes:ByteArray = null)
		{
			super(header, bytes);
		}
		
		override public function get messageType():int {
			return MessageType.METADATA_AMF0;
		}
		
		override public function encode():ByteArray {
			var bytes:ByteArray = new ByteArray();
			bytes.objectEncoding = ObjectEncoding.AMF0;
			bytes.writeObject(_name);
			
			if(_data != null)
			{
				for each(var o:Object in _data)
					bytes.writeObject(o);
			}
			
			return bytes;
		}
		
		override public function decode(bytes:ByteArray):void {
			super.decode(bytes);
			bytes.objectEncoding = ObjectEncoding.AMF0;
			_name = bytes.readObject();
			
			_data = new Array();
			while(bytes.bytesAvailable > 0){
				_data.push(bytes.readObject());
			}
		}
	}
}