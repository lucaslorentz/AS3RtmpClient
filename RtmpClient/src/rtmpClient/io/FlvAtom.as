package rtmpClient.io
{
	import flash.utils.ByteArray;
	
	import rtmpClient.IRtmpMessage;
	import rtmpClient.RtmpHeader;
	
	public class FlvAtom implements IRtmpMessage
	{
		private var _header:RtmpHeader;
		private var _data:ByteArray;
		
		public function get originalBytes():ByteArray {
			return null;
		}
				
		public static function flvHeader():ByteArray {
			var bytes:ByteArray = new ByteArray();
			bytes.writeByte(0x46); // F
			bytes.writeByte(0x4C); // L
			bytes.writeByte(0x56); // V
			bytes.writeByte(0x01); // version
			bytes.writeByte(0x05); // flags: audio + video
			bytes.writeInt(0x09); // header size = 9
			bytes.writeInt(0); // previous tag size, here = 0
			return bytes;
		}
		
		public static function parseFromByteArray(bytes:ByteArray):FlvAtom {
			var atom:FlvAtom = new FlvAtom();
			atom._header = readHeader(bytes);
			atom._data = new ByteArray();
			if(atom._header.size > 0)
				bytes.readBytes(atom._data, 0, atom._header.size);
			bytes.position += 4; //prev offset
			return atom;
		}
		
		public static function createWithValues(messageType:int, time:int, data:ByteArray):FlvAtom {
			var atom:FlvAtom = new FlvAtom();
			atom._header = new RtmpHeader(messageType, time, data.length);
			atom._data = data;
			return atom;
		}
		
		public function write():ByteArray {
			var out:ByteArray = new ByteArray();
			out.writeByte(header.messageType);
			writeMedium(out, header.size);
			writeMedium(out, header.time);
			out.writeInt(0); // 4 bytes of zeros (reserved)
			out.writeBytes(_data);
			out.writeInt(header.size + 11); // previous tag size
			return out;
		}
		
		public static function readHeader(input:ByteArray):RtmpHeader {
			var messageType:int = input.readByte();
			var size:int = readMedium(input);
			var time:int = readMedium(input);
			input.readInt(); //0 - reserved
			return new RtmpHeader(messageType, time, size);
		}
		
		//============================ RtmpMessage =================================
		
		public function get messageType():int {
			return header.messageType;
		}
		
		public function get header():RtmpHeader {
			return _header;
		}
		
		public function get data():ByteArray {
			return _data;
		}
		
		public function encode():ByteArray {
			return _data;
		}
		
		public function decode(input:ByteArray):void {
			_data = input;
		}
		
		public function toString():String {
			return header + " data: " + data;
		}
		
		private static function readMedium(bytes:ByteArray):int {
			var val:int = 0;
			val += bytes.readUnsignedByte() << 16;
			val += bytes.readUnsignedByte() << 8;
			val += bytes.readUnsignedByte();
			return val;
		}
		
		private static function writeMedium(bytes:ByteArray, value:int):void {
			bytes.writeByte(value >> 16 & 0xFF);
			bytes.writeByte(value >> 8 & 0xFF);
			bytes.writeByte(value & 0xFF);
		}
	}
}