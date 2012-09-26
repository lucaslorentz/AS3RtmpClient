package
{
	import flash.events.Event;
	import flash.media.Video;
	
	import mx.core.UIComponent;
	
	public class VideoContainer extends UIComponent
	{
		private var _video:Video;
				
		public function get video():Video {
			return _video;
		}
		
		public function set video(video:Video):void
		{
			if(_video != video){
				if (_video != null)
				{
					_video.removeEventListener(Event.ENTER_FRAME, _videoEnterFrameHandler, false);
					removeChild(_video);
				}
				
				_video = video;
				
				if (_video != null)
				{
					_video.width = width;
					_video.height = height;
					_video.addEventListener(Event.ENTER_FRAME, _videoEnterFrameHandler, false, 0, true);
					addChild(_video);
				}
			}
		}
		
		private function _videoEnterFrameHandler(e:Event):void {
			if(_video.videoWidth != 0 && _video.videoHeight != 0){
				_video.removeEventListener(Event.ENTER_FRAME, _videoEnterFrameHandler, false);
				updateVideoSize();
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			if (_video != null && _video.videoWidth != 0 && _video.videoHeight != 0)
				updateVideoSize();
		}
		
		private function updateVideoSize():void {
			var scaleX:Number = unscaledWidth/_video.videoWidth;
			var scaleY:Number = unscaledHeight/_video.videoHeight;
			
			scaleX = scaleY = Math.min(scaleX, scaleY);
			
			_video.width = scaleX * _video.videoWidth;
			_video.height = scaleY * _video.videoHeight;
			_video.x = (unscaledWidth - _video.width)/2;
			_video.y = (unscaledHeight - _video.height)/2;
		}
	}
}