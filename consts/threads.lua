local threads = {}

threads.threadShutdownTime = 3 -- In seconds
threads.quitChannelName = "quit"
threads.chunkInfoChannelName = "chunkInfo" -- Pass the materials registry and other things
threads.chunkLoadingRequestChannelName = "chunkRequest"
threads.chunkLoadingResultChannelName = "chunkResult"

return threads
