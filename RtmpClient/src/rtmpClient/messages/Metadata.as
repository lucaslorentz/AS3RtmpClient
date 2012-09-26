package rtmpClient.messages
{
	import flash.utils.ByteArray;
	
	import rtmpClient.RtmpHeader;

	public class Metadata extends AbstractMessage
	{
		protected var _name:String;
		protected var _data:Array;
		
		public function Metadata(header:RtmpHeader = null, bytes:ByteArray = null)
		{
			super(header, bytes);
		}
		
		public static function createWithValues(type:Class, name:String, data:Array = null):Metadata {
			var metadata:Metadata = new type();
			metadata._name = name;
			metadata._data = data;
			metadata.header.size = metadata.encode().length;
			return metadata;	
		}
		
		public function get name():String {
			return _name;
		}
				
		public function getData(index:int):Object {
			if(_data == null || _data.length < index + 1)
				return null;
			
			return _data[index];
		}
		
		private function getValue(key:String):Object {
			var map:Object = getMap(0);
			if(map == null)
				return null;
			
			return map[key];
		}
		
		public function setValue(key:String, value:Object):void {
			if(_data == null || _data.length == 0)
				_data = [];
			
			if(_data[0] == null)
				_data[0] = {};
			
			var map:Object = _data[0];
			map[key] = value;
		}
		
		public function getMap(index:int):Object {
			return getData(index);
		}
		
		public function getString(key:String):String {
			return String(getValue(key));
		}
		
		public function getBoolean(key:String):Boolean {
			return getValue(key);
		}
		
		public function getDouble(key:String):Number {
			return Number(getValue(key));
		}
		
		public function getDuration():Number {
			if(_data == null || _data.length == 0)
				return -1;
			
			var map:Object = getMap(0);
			if(map == null)
				return -1;
			
			var o:Object = map["duration"];
			if(o == null)
				return -1;
			
			return Number(o);
		}
		
		public function setDuration(duration:Number):void {
			if(_data == null || _data.length == 0)
				_data = [];
			
			var map:Object = _data[0];
			if(map == null){
				_data[0] = { "duration": duration};
				return;
			}
			
			map["duration"] = duration;
		}
		
		override public function toString():String {
			return super.toString() + "name: "+ _name + " data: " + _data;
		}
		
		//==========================================================================		
		/*public static Metadata onPlayStatus(double duration, double bytes) {
			Map<String, Object> map = Command.onStatus(Command.OnStatus.STATUS,
				"NetStream.Play.Complete",
				pair("duration", duration),
				pair("bytes", bytes));
			return new MetadataAmf0("onPlayStatus", map);
		}
		
		public static Metadata rtmpSampleAccess() {
			return new MetadataAmf0("|RtmpSampleAccess", false, false);
		}
		
		public static Metadata dataStart() {
			return new MetadataAmf0("onStatus", object(pair("code", "NetStream.Data.Start")));
		}*/
		
		//==========================================================================
		
		/**
		 [ (map){
		 duration=112.384, moovPosition=28.0, width=640.0, height=352.0, videocodecid=avc1,
		 audiocodecid=mp4a, avcprofile=100.0, avclevel=30.0, aacaot=2.0, videoframerate=29.97002997002997,
		 audiosamplerate=24000.0, audiochannels=2.0, trackinfo= [
		 (object){length=3369366.0, timescale=30000.0, language=eng, sampledescription=[(object){sampletype=avc1}]},
		 (object){length=2697216.0, timescale=24000.0, language=eng, sampledescription=[(object){sampletype=mp4a}]}
		 ]}]
		 */
		
		/*public static Metadata onMetaDataTest(MovieInfo movie) {
			Amf0Object track1 = object(
				pair("length", 3369366.0),
				pair("timescale", 30000.0),
				pair("language", "eng"),
				pair("sampledescription", new Amf0Object[]{object(pair("sampletype", "avc1"))})
			);
			Amf0Object track2 = object(
				pair("length", 2697216.0),
				pair("timescale", 24000.0),
				pair("language", "eng"),
				pair("sampledescription", new Amf0Object[]{object(pair("sampletype", "mp4a"))})
			);
			Map<String, Object> map = map(
				pair("duration", movie.getDuration()),
				pair("moovPosition", movie.getMoovPosition()),
				pair("width", 640.0),
				pair("height", 352.0),
				pair("videocodecid", "avc1"),
				pair("audiocodecid", "mp4a"),
				pair("avcprofile", 100.0),
				pair("avclevel", 30.0),
				pair("aacaot", 2.0),
				pair("videoframerate", 29.97002997002997),
				pair("audiosamplerate", 24000.0),
				pair("audiochannels", 2.0),
				pair("trackinfo", new Amf0Object[]{track1, track2})
			);
			return new MetadataAmf0("onMetaData", map);
		}
		
		public static Metadata onMetaData(MovieInfo movie) {
			Map<String, Object> map = map(
				pair("duration", movie.getDuration()),
				pair("moovPosition", movie.getMoovPosition())
			);
			TrackInfo track1 = movie.getVideoTrack();
			Amf0Object t1 = null;
			if(track1 != null) {
				String sampleType = track1.getStsd().getSampleTypeString(1);
				t1 = object(
					pair("length", track1.getMdhd().getDuration()),
					pair("timescale", track1.getMdhd().getTimeScale()),
					pair("sampledescription", new Amf0Object[]{object(pair("sampletype", sampleType))})
				);
				VideoSD video = movie.getVideoSampleDescription();
				map(map,
					pair("width", (double) video.getWidth()),
					pair("height", (double) video.getHeight()),
					pair("videocodecid", sampleType)
				);
			}
			TrackInfo track2 = movie.getAudioTrack();
			Amf0Object t2 = null;
			if(track2 != null) {
				String sampleType = track2.getStsd().getSampleTypeString(1);
				t2 = object(
					pair("length", track2.getMdhd().getDuration()),
					pair("timescale", track2.getMdhd().getTimeScale()),
					pair("sampledescription", new Amf0Object[]{object(pair("sampletype", sampleType))})
				);
				map(map,
					pair("audiocodecid", sampleType)
				);
			}
			List<Amf0Object> trackList = new ArrayList<Amf0Object>();
			if(t1 != null) {
				trackList.add(t1);
			}
			if(t2 != null) {
				trackList.add(t2);
			}
			map(map, pair("trackinfo", trackList.toArray()));
			return new MetadataAmf0("onMetaData", map);
		}*/
		
		//==========================================================================
	}
}