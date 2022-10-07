return function(gameInstance, func)
	for _, subWorld in pairs(gameInstance.subWorldsById) do
		func(subWorld.map.chunkLoadingThread)
	end
end
