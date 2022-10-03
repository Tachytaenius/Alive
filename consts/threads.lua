local threads = {}

threads.quitChannelName = "quit"
threads.chunkInfoChannelName = "chunkInfo" -- Pass the materials registry and other things
threads.chunkLoadingRequestChannelName = "chunkRequest"
threads.chunkLoadingResultChannelName = "chunkResult"

return threads
