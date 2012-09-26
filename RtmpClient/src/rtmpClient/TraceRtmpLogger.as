package rtmpClient
{
	public class TraceRtmpLogger implements IRtmpLogger
	{
		public function write(...texts):void
		{
			trace.apply(null, texts);
		}
		
	}
}