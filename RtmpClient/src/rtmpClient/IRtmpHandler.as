package rtmpClient
{
	import rtmpClient.messages.DataMessage;
	import rtmpClient.messages.Metadata;

	public interface IRtmpHandler
	{
		function onMetadata(metadata:Metadata):void;
		
		function onStreamData(message:IRtmpMessage):void;
		
		function onStreamCreated(streamId:int):void;
	}
}