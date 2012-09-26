package rtmpClient.messages
{
	import flash.net.ObjectEncoding;
	import flash.utils.ByteArray;
	
	import rtmpClient.RtmpHeader;

	public class CommandAmf0 extends Command
	{
		public function CommandAmf0(header:RtmpHeader = null, bytes:ByteArray = null)
		{
			super(header, bytes);
		}
		
		override public function get messageType():int {
			return MessageType.COMMAND_AMF0;
		}
		
		override public function encode():ByteArray {
			var bytes:ByteArray = new ByteArray();
			bytes.objectEncoding = ObjectEncoding.AMF0;
			bytes.writeObject(_name);
			bytes.writeObject(_transactionId);
			bytes.writeObject(_object);
			
			if(_args != null)
			{
				for each(var o:Object in _args)
					bytes.writeObject(o);
			}
			
			return bytes;
		}
		
		override public function decode(bytes:ByteArray):void {
			super.decode(bytes);
			bytes.objectEncoding = ObjectEncoding.AMF0;
			_name = bytes.readObject();
			_transactionId = bytes.readObject();
			_object = bytes.readObject();
			
			_args = [];
			while(bytes.bytesAvailable > 0){
				_args.push(bytes.readObject());
			}
		}
	}
}