AS3RtmpClient
==============

This is a proof of concept RtmpClient based on Flazr (http://flazr.com/) created to run on Flash Player (AS3 + Sockets + ByteArray).

First of all. I did that code some time ago. I'm not working on it anymore, and it is just a proof of concept.

MOTIVATION
==============

Why creating a AS3 RtmpClient if Flash supports it natively?

I did that experiment when I was trying to figure out some way to save video streaming to hd using only Flash Player. 

Things that I got working on my tests:
- Save streaming video to a local file, while it is playing.
- Modify RtmpSampleAccess to true on any video, allowing to take snapshots (bitmapData.draw) of the video.
- Send customized swfUrl, pageUrl, and other connection parameters.
- Publish custom bitmaps to a live stream. Instead of sharing a Webcam, I shared a display object.
- I also created an app using Adobe AIR to play RTMP Streams on my Android devices. For personal use ;-)

USAGE
==============

```AS3
var connectionConfig:String = "rtmp://rtmp01.hddn.com/play playpath=mp4:vod/demo.flowplayervod/buffalo_soldiers.mp4";

var video:Video = new Video();

var rtmpNetStream:RtmpStreamPlayer = new RtmpStreamPlayer();				
rtmpNetStream.play(connectionConfig, video);
```
The play method receives a connection configuration like librtmp.
http://rtmpdump.mplayerhq.hu/librtmp.3.html

Some videos will work, some others will not. Whatever, this library is just a proof of concept. :-)

LICENSE
==============

As Flazr. This project is licensed under the LGPL License.  
http://www.gnu.org/licenses/lgpl.html