package rtmpClient.io
{
	public class FlvWriter
	{
		private var _channelTimes:Object = {};
		private var primaryChannel:int = -1;
		private var lastLoggedSeconds:int;
		private var seekTime:int;
		private var startTime:int;
		
		public function FlvWriter()
		{
		}
		
		/*public FlvWriter(final String fileName) {
			this(0, fileName);
		}
		
		public FlvWriter() {
			this.seekTime = seekTime < 0 ? 0 : seekTime;
			this.startTime = System.currentTimeMillis();
			if(fileName == null) {
				logger.info("save file notspecified, will only consume stream");
				out = null;
				return;
			}
			try {
				File file = new File(fileName);
				FileOutputStream fos = new FileOutputStream(file);
				out = fos.getChannel();
				out.write(FlvAtom.flvHeader().toByteBuffer());
				logger.info("opened file for writing: {}", file.getAbsolutePath());
			} catch (Exception e) {
				throw new RuntimeException(e);
			}        
		}
		
		@Override
		public void close() {
			if(out != null) {
				try {
					out.close();
				} catch (Exception e) {
					throw new RuntimeException(e);
				}
			}
			if(primaryChannel == -1) {
				logger.warn("no media was written, closed file");
				return;
			}
			logger.info("finished in {} seconds, media duration: {} seconds (seek time: {})",
				new Object[]{(System.currentTimeMillis() - startTime) / 1000,
					(channelTimes[primaryChannel] - seekTime) / 1000, 
					seekTime / 1000});
		}
		
		private void logWriteProgress() {
			final int seconds = (channelTimes[primaryChannel] - seekTime) / 1000;
			if (seconds >= lastLoggedSeconds + 10) {
				logger.info("write progress: " + seconds + " seconds");
				lastLoggedSeconds = seconds - (seconds % 10);
			}
		}
		
		@Override
		public void write(final RtmpMessage message) {
			final RtmpHeader header = message.getHeader();
			if(header.isAggregate()) {
				final ChannelBuffer in = message.encode();
				while (in.readable()) {
					final FlvAtom flvAtom = new FlvAtom(in);
					final int absoluteTime = flvAtom.getHeader().getTime();
					channelTimes[primaryChannel] = absoluteTime;
					write(flvAtom);
					// logger.debug("aggregate atom: {}", flvAtom);
					logWriteProgress();
				}
			} else { // METADATA / AUDIO / VIDEO
				final int channelId = header.getChannelId();
				channelTimes[channelId] = seekTime + header.getTime();
				if(primaryChannel == -1 && (header.isAudio() || header.isVideo())) {
					logger.info("first media packet for channel: {}", header);
					primaryChannel = channelId;
				}
				if(header.getSize() <= 2) {
					return;
				}
				write(new FlvAtom(header.getMessageType(), channelTimes[channelId], message.encode()));
				if (channelId == primaryChannel) {
					logWriteProgress();
				}
			}
		}
		
		private void write(final FlvAtom flvAtom) {
			if(logger.isDebugEnabled()) {
				logger.debug("writing: {}", flvAtom);
			}
			if(out == null) {
				return;
			}
			try {
				out.write(flvAtom.write().toByteBuffer());
			} catch (Exception e) {
				throw new RuntimeException(e);
			}
		}*/
	}
}