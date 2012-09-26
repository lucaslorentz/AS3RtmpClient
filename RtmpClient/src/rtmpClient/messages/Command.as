package rtmpClient.messages
{
	import flash.utils.ByteArray;
	
	import rtmpClient.RtmpHeader;

	public class Command extends AbstractMessage
	{
		protected var _name:String;
		protected var _transactionId:int;
		protected var _object:Object;
		protected var _args:Array;
		
		public function Command(header:RtmpHeader = null, bytes:ByteArray = null)
		{
			super(header, bytes);
		}
				
		public function get object():Object {
			return _object;
		}
		
		public function get args():Array {
			return _args;
		}
		
		public function get name():String {
			return _name;
		}
		
		public function get transactionId():int {
			return _transactionId;
		}
		
		public function set transactionId(value:int):void {
			_transactionId = value;
		}
		
		override public function toString():String {
			return super.toString() + "name: " + _name + ", transactionId: " + _transactionId + ", object: "+_object + " args: " + _args;
		}
		
		//==========================================================================
		
		public static function createWithValues(type:Class, transactionId:int, name:String, object:Object, args:Array):Command {
			var command:Command = new type();
			
			command._transactionId = transactionId;
			command._name = name;
			command._object = object;
			command._args = args;
			
			return command;
		}
		
		public static function createStream():Command {
			return Command.createWithValues(CommandAmf0, 0, "createStream", null, null);
		}
		
		public static function publish(streamId:int, streamName:String, publishType:String):Command { // TODO
			var command:Command = Command.createWithValues(CommandAmf0, 0, "publish", null, [streamName, publishType]);
			command.header.channelId = 8;
			command.header.streamId = streamId;
			return command;
		}
		
		private static function publishStatus(code:String, streamName:String, clientId:String, pairs:Object = null):Command {
			var status:Object = createStatusObject(LEVEL_STATUS, code, null, streamName, {
				details: streamName,
				clientid: clientId			
			});
			
			if(pairs){
				for each(var s:String in pairs)
				status[s] = pairs[s];
			}
			
			var command:Command = Command.createWithValues(CommandAmf0, 0, "onStatus", null, [ status ]);
			command.header.channelId = 8;
			return command;
		}
		
		public static function publishStart(streamName:String, clientId:String, streamId:int):Command {
			return publishStatus("NetStream.Publish.Start", streamName, clientId);
		}
		
		public static const LEVEL_ERROR:String = "_error";
		public static const LEVEL_STATUS:String = "_status";
		public static const LEVEL_WARNING:String = "_warning";
		
		public static function createStatusObject(
			level:String, code:String, description:String, details:String = null, pairs:Object = null):Object {
			var object:Object = {
				"level": level,
				"code": code
			};
			
			if(pairs != null){
				if(description != null)
					object["description"] = description;
				
				if(details != null)
					object["details"] = details;
			}
			
			return object;
		}
		
		public static function createConnectCommand(appName:String, tcUrl:String, overrideValues:Object = null, args:Array = null):Command {
			var object:Object = {
				app : appName,
				flashVer: "WIN 9,0,124,2",
				tcUrl: tcUrl,
				fpad: false,
				audioCodecs: 1639,
				videoCodecs: 252,
				objectEncoding: 0,
				capabilities: 15,
				videoFunction: 1
			};
			
			if(overrideValues){
				for(var i:String in overrideValues){
					object[i] = overrideValues[i];
				}
			}
			
			return Command.createWithValues(CommandAmf0, 0, "connect", object, args);
		}
		
		/*
		public static Command connectSuccess(int transactionId) {
		Map<String, Object> object = onStatus(OnStatus.STATUS,
		"NetConnection.Connect.Success", "Connection succeeded.",            
		pair("fmsVer", "FMS/3,5,1,516"),
		pair("capabilities", 31.0),
		pair("mode", 1.0),
		pair("objectEncoding", 0.0));
		return new CommandAmf0(transactionId, "_result", null, object);
		}*/
		
		/*public static Command onBWDone() {
		return new CommandAmf0("onBWDone", null);
		}
		
		public static Command createStreamSuccess(int transactionId, int streamId) {
		return new CommandAmf0(transactionId, "_result", null, streamId);
		}*/
		
		public static function play(streamId:int, streamName:String):Command {
			var playArgs:Array = [ streamName ];
			
			/*
			if(options.getStart() != -2 || options.getArgs() != null) {
				playArgs.add(options.getStart());
			}
			if(options.getLength() != -1 || options.getArgs() != null) {
				playArgs.add(options.getLength());
			}
			if(options.getArgs() != null) {
				playArgs.addAll(Arrays.asList(options.getArgs()));
			}
			*/
			
			var command:Command = Command.createWithValues(CommandAmf0, 0, "play", null, playArgs);
			command.header.channelId = 8;
			command.header.streamId = streamId;        
			return command;
		}
		
		public static function subscribe(streamId:int, streamName:String):Command {
			var subscribeArgs:Array = [ streamName ];
			
			/*
			if(options.getStart() != -2 || options.getArgs() != null) {
			playArgs.add(options.getStart());
			}
			if(options.getLength() != -1 || options.getArgs() != null) {
			playArgs.add(options.getLength());
			}
			if(options.getArgs() != null) {
			playArgs.addAll(Arrays.asList(options.getArgs()));
			}
			*/
			
			var command:Command = Command.createWithValues(CommandAmf0, 0, "FCSubscribe", null, subscribeArgs);
			command.header.channelId = 8;
			command.header.streamId = streamId;        
			return command;
		}
		
		/*private static Command playStatus(String code, String description, String playName, String clientId, Pair ... pairs) {
		Amf0Object status = onStatus(OnStatus.STATUS,
		"NetStream.Play." + code, description + " " + playName + ".",
		pair("details", playName),
		pair("clientid", clientId));
		object(status, pairs);
		Command command = new CommandAmf0("onStatus", null, status);
		command.header.setChannelId(5);
		return command;
		}
		
		public static Command playReset(String playName, String clientId) {
		Command command = playStatus("Reset", "Playing and resetting", playName, clientId);
		command.header.setChannelId(4); // ?
		return command;
		}
		
		public static Command playStart(String playName, String clientId) {
		Command play = playStatus("Start", "Started playing", playName, clientId);
		return play;
		}
		
		public static Command playStop(String playName, String clientId) {
		return playStatus("Stop", "Stopped playing", playName, clientId);
		}
		
		public static Command playFailed(String playName, String clientId) {
		Amf0Object status = onStatus(OnStatus.ERROR,
		"NetStream.Play.Failed", "Stream not found");
		Command command = new CommandAmf0("onStatus", null, status);
		command.header.setChannelId(8);
		return command;
		}
		
		public static Command seekNotify(int streamId, int seekTime, String playName, String clientId) {
		Amf0Object status = onStatus(OnStatus.STATUS,
		"NetStream.Seek.Notify", "Seeking " + seekTime + " (stream ID: " + streamId + ").",
		pair("details", playName),
		pair("clientid", clientId));        
		Command command = new CommandAmf0("onStatus", null, status);
		command.header.setChannelId(5);
		command.header.setStreamId(streamId);
		command.header.setTime(seekTime);
		return command;
		}
		
		public static Command pauseNotify(String playName, String clientId) {
		Amf0Object status = onStatus(OnStatus.STATUS,
		"NetStream.Pause.Notify", "Pausing " + playName,
		pair("details", playName),
		pair("clientid", clientId));
		Command command = new CommandAmf0("onStatus", null, status);
		command.header.setChannelId(5);
		return command;
		}
		
		public static Command unpauseNotify(String playName, String clientId) {
		Amf0Object status = onStatus(OnStatus.STATUS,
		"NetStream.Unpause.Notify", "Unpausing " + playName,
		pair("details", playName),
		pair("clientid", clientId));
		Command command = new CommandAmf0("onStatus", null, status);
		command.header.setChannelId(5);
		return command;
		}*/
		
		/*public static Command unpublishSuccess(String streamName, String clientId, int streamId) {
		return publishStatus("NetStream.Unpublish.Success", streamName, clientId);
		}
		
		public static Command unpublish(int streamId) {
		Command command = new CommandAmf0("publish", null, false);
		command.header.setChannelId(8);
		command.header.setStreamId(streamId);
		return command;
		}
		
		public static Command publishBadName(int streamId) {
		Command command = new CommandAmf0("onStatus", null, 
		onStatus(OnStatus.ERROR, "NetStream.Publish.BadName", "Stream already exists."));
		command.header.setChannelId(8);
		command.header.setStreamId(streamId);
		return command;
		}
		
		public static Command publishNotify(int streamId) {
		Command command = new CommandAmf0("onStatus", null,
		onStatus(OnStatus.STATUS, "NetStream.Play.PublishNotify"));
		command.header.setChannelId(8);
		command.header.setStreamId(streamId);
		return command;
		}
		
		public static Command unpublishNotify(int streamId) {
		Command command = new CommandAmf0("onStatus", null,
		onStatus(OnStatus.STATUS, "NetStream.Play.UnpublishNotify"));
		command.header.setChannelId(8);
		command.header.setStreamId(streamId);
		return command;
		}
		
		public static Command closeStream(int streamId) {
		Command command = new CommandAmf0("closeStream", null);
		command.header.setChannelId(8);
		command.header.setStreamId(streamId);
		return command;
		}*/
	}
}