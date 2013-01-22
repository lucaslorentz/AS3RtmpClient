package rtmpClient
{
	import flash.media.StageVideo;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.utils.ByteArray;
	
	import rtmpClient.io.FlvAtom;
	import rtmpClient.messages.Command;
	import rtmpClient.messages.Control;
	import rtmpClient.messages.MessageType;
	import rtmpClient.messages.Metadata;
	import rtmpClient.messages.MetadataAmf0;

	public class RtmpStreamPlayer implements IRtmpHandler
	{
		private var _rtmpConnection:RtmpConnection;
		private var _netConnection:NetConnection;
		private var _netStream:NetStream;
		private var _playPath:String;
		
		private var _channelTimes:Object = {};
		private var _primaryChannel:int = -1;
		private var _seekTime:int;
		
		public var logger:IRtmpLogger = new TraceRtmpLogger();
		
		public function RtmpStreamPlayer()
		{
			_netConnection = new NetConnection();
			_netConnection.connect(null);
		}
		
		public function play(urlConfig:String, video:Object):void
		{
			stop();				
			
			var propertiesList:Array = urlConfig.split(/\s+/g);
			var connectParameters:Object = {};
			
			var url:String = propertiesList[0];
			for(var i:int = 1; i < propertiesList.length; i++){
				var firstEqualIndex:int = String(propertiesList[i]).indexOf("=");
				var name:String = String(propertiesList[i]).substring(0, firstEqualIndex);
				var value:String = String(propertiesList[i]).substring(firstEqualIndex + 1);
				connectParameters[name] = String(value).replace(/\\20/g, " ").replace(/\\5c/g, "\\");
			}
			
			_playPath = connectParameters.playpath;
			
			_rtmpConnection = new RtmpConnection();
			_rtmpConnection.logger = logger;
			_rtmpConnection.handler = this;
			_rtmpConnection.connect(url, connectParameters);
			
			_netStream = new NetStream(_netConnection);
			_netStream.play(null);
			
			if(video is Video)
				(video as Video).attachNetStream(_netStream);
			else if(video is StageVideo)
				(video as StageVideo).attachNetStream(_netStream);
		}
		
		public function stop():void {
			if(_rtmpConnection){
				_rtmpConnection.disconnect();
				if(_netStream){
					_netStream.close();
					_netStream.dispose();
				}
				
				_rtmpConnection = null;
				_netStream = null;
			}
		}
				
		public function onStreamCreated(streamId:int):void
		{
			_rtmpConnection.sendMessage(Command.subscribe(_rtmpConnection.streamId, _playPath));
			_rtmpConnection.sendMessage(Command.play(_rtmpConnection.streamId, _playPath));
			_rtmpConnection.sendMessage(Control.setBuffer(_rtmpConnection.streamId, 0));
			
			_netStream.appendBytes(FlvAtom.flvHeader());
		}
		
		public function onStreamData(message:IRtmpMessage):void
		{
			var header:RtmpHeader = message.header;
			
			if(header.isAggregate) {
				var input:ByteArray = message.encode();
				input.position = 0;
				while (input.bytesAvailable > 0) {
					var flvAtom:FlvAtom = FlvAtom.parseFromByteArray(input);
					flvAtom.header.time = header.time; //Added by Lucas
					var absoluteTime:int = flvAtom.header.time;
					_channelTimes[_primaryChannel] = absoluteTime;
					write(flvAtom);
					// logger.debug("aggregate atom: {}", flvAtom);
					//logWriteProgress();
				}
			} else { // METADATA / AUDIO / VIDEO					
				var channelId:int = header.channelId;
				_channelTimes[channelId] = _seekTime + header.time;
				if(_primaryChannel == -1 && (header.isAudio || header.isVideo)) {
					//logger.info("first media packet for channel: {}", header);
					_primaryChannel = channelId;
				}
				if(header.size <= 2) {
					return;
				}
				
				write(FlvAtom.createWithValues(header.messageType, _channelTimes[channelId], message.encode()));
				
				/*if (channelId == primaryChannel) {
				logWriteProgress();
				}*/
			}
		}
		
		public function onMetadata(metadata:Metadata):void
		{
			if(metadata.name == "|RtmpSampleAccess"){
				var metadataForFlv:Metadata = Metadata.createWithValues(MetadataAmf0, metadata.name, [true, true]); //Modify RtmpSampleAccess to enable draw video to bitmap
				
				var flvAtom:FlvAtom = FlvAtom.createWithValues(MessageType.METADATA_AMF0, 0, metadataForFlv.encode());
				write(flvAtom);
			}
		}
		
		private function write(atom:FlvAtom):void {			
			_netStream.appendBytes(atom.write());
		}
	}
}