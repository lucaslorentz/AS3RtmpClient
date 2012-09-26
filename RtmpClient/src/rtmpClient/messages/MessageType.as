package rtmpClient.messages
{
	import flash.utils.ByteArray;
	
	import rtmpClient.IRtmpMessage;
	import rtmpClient.RtmpHeader;

	public class MessageType
	{
		public static const CHUNK_SIZE:int = 0x01;
		public static const ABORT:int = 0x02;
		public static const BYTES_READ:int = 0x03;
		public static const CONTROL:int = 0x04;
		public static const WINDOW_ACK_SIZE:int = 0x05;
		public static const SET_PEER_BW:int = 0x06;
		// unknown 0x07
		public static const AUDIO:int = 0x08;
		public static const VIDEO:int = 0x09;
		// unknown 0x0A - 0x0E
		public static const METADATA_AMF3:int = 0x0F;
		public static const SHARED_OBJECT_AMF3:int = 0x10;
		public static const COMMAND_AMF3:int = 0x11;
		public static const METADATA_AMF0:int = 0x12;
		public static const SHARED_OBJECT_AMF0:int = 0x13;
		public static const COMMAND_AMF0:int = 0x14;
		public static const AGGREGATE:int = 0x16;
		
		public static function decode(header:RtmpHeader, bytes:ByteArray):IRtmpMessage {
			switch(header.messageType) {
				case ABORT: return new Abort(header, bytes);
				case BYTES_READ: return new BytesRead(header, bytes);
				case CHUNK_SIZE: return new ChunkSize(header, bytes);
				case COMMAND_AMF0: return new CommandAmf0(header, bytes);
				case METADATA_AMF0: return new MetadataAmf0(header, bytes);
				case CONTROL: return new Control(header, bytes);
				case WINDOW_ACK_SIZE: return new WindowAckSize(header, bytes);
				case SET_PEER_BW: return new SetPeerBw(header, bytes);
				case AUDIO: return new Audio(header, bytes);
				case VIDEO: return new Video(header, bytes);
				case AGGREGATE: return new Aggregate(header, bytes);
				default: throw new Error("unable to create message for: " + header);
			}
			
			return null;
		}
		
		public static function getDefaultChannelId(type:int):int {
			switch(type) {
				case CHUNK_SIZE:
				case CONTROL:
				case ABORT:
				case BYTES_READ:
				case WINDOW_ACK_SIZE:
				case SET_PEER_BW:            
					return 2;
				case COMMAND_AMF0:
				case COMMAND_AMF3: // TODO verify
					return 3;
				case METADATA_AMF0:
				case METADATA_AMF3: // TODO verify
				case AUDIO:
				case VIDEO:
				case AGGREGATE:
				default: // TODO verify
					return 5;
			}
		}
	}
}