local list = require("lib.list")

local registry = require("registry")
local consts = require("consts")

local circleAabbCollision = require("util.collision.circleAabb")

local core = {}

function core:init()
	self.loadedChunksGrid = {}
	self.loadedChunksList = list()
	self.randomTickTime = 0
	
	self.activeChunkRequests = 0
	self.chunkRequests = {}
	self.chunkLoadingThread = love.thread.newThread("systems/map/threads/loadingGenerating.lua")
	
	local subWorldId = self:getWorld().id
	local infoChannelName = consts.chunkInfoChannelName .. subWorldId
	self.infoChannel = love.thread.getChannel(infoChannelName)
	local requestChannelName = consts.chunkLoadingRequestChannelName .. subWorldId
	self.requestChannel = love.thread.getChannel(requestChannelName)
	local resultChannelName = consts.chunkLoadingResultChannelName .. subWorldId
	self.resultChannel = love.thread.getChannel(resultChannelName)
	
	self.chunkLoadingThread:start(subWorldId)
end

local function getChunkIterationStartEnd(player, radius)
	local x1 = math.floor((player.position.value.x - radius) / (consts.chunkWidth * consts.tileWidth))
	local x2 = math.ceil((player.position.value.x + radius) / (consts.chunkWidth * consts.tileWidth))
	local y1 = math.floor((player.position.value.y - radius) / (consts.chunkHeight * consts.tileHeight))
	local y2 = math.ceil((player.position.value.y + radius) / (consts.chunkHeight * consts.tileHeight))
	return x1, x2, y1, y2
end

local function chunkPositionIsInRadius(x, y, player, radius)
	return circleAabbCollision(
		player.position.value.x, player.position.value.y, radius,
		x * consts.chunkWidth * consts.tileWidth, y * consts.chunkHeight * consts.tileHeight, consts.chunkWidth * consts.tileWidth, consts.chunkHeight * consts.tileHeight
	)
end

function core:newWorld()
	-- Set theme
	self.soilMaterials = {
		{materialName = "loam", abundanceMultiply = 14, noiseWidth = 50, noiseHeight = 50},
		{materialName = "clay", abundanceMultiply = 13, noiseWidth = 50, noiseHeight = 50},
		{materialName = "sand", abundanceMultiply = 5, noiseWidth = 50, noiseHeight = 50},
		{materialName = "silt", abundanceMultiply = 7, noiseWidth = 50, noiseHeight = 50},
		{materialName = "water", abundanceMultiply = 0, abundanceAdd = 10}
	}
	
	local infoTable = {
		registry = registry,
		soilMaterials = self.soilMaterials,
		superWorldSeed = self:getWorld().superWorld.seed
	}
	local registryLoad
	registryLoad, registry.load = registry.load, nil -- Remove function temporarily
	self.infoChannel:push(infoTable)
	registry.load = registryLoad
end

function core:fixedUpdate(dt)
	local player = self.players[1]
	if not player then
		self.loadedChunksList:clear()
		for x in pairs(self.loadedChunksGrid) do
			self.loadedChunksGrid[x] = nil
		end
		return
	end
	
	self.randomTickTime = self.randomTickTime + dt
	
	-- TODO: Move below code to chunks.lua?
	
	assert(consts.chunkProcessingRadius <= consts.chunkLoadingRadius, "Chunk loading radius is less than chunk processing radius")
	assert(consts.chunkLoadingRadius <= consts.chunkUnloadingRadius, "Chunk unloading radius is less than loading radius")
	
	-- Unload chunks outside of chunk unloading radius
	for chunk in self.loadedChunksList:elements() do
		if not chunkPositionIsInRadius(chunk.x, chunk.y, player, consts.chunkUnloadingRadius) then
			self:unloadChunk(chunk)
		end
	end
	
	-- Request loading of all unloaded chunks within loading radius
	local x1, x2, y1, y2 = getChunkIterationStartEnd(player, consts.chunkLoadingRadius)
	for x = x1, x2 do
		for y = y1, y2 do
			if chunkPositionIsInRadius(x, y, player, consts.chunkLoadingRadius) then
				if not self:getLoadedChunk(x, y) and not self:getChunkRequest(x, y) then
					self:requestChunk(x, y)
				end
			end
		end
	end
	
	-- Receive chunks already loaded (don't wait for not-yet-loaded chunks)
	while true do
		local chunk = self.resultChannel:pop()
		if not chunk then
			break
		end
		self:receiveChunk(chunk)
	end
	
	-- Force wait for all chunks to load if any chunk in processing range is unloaded
	-- TODO: Reorganise into non-spaghetti code
	-- TODO: Only force waiting for chunks in processing range
	local forceLoadAll = false
	local x1, x2, y1, y2 = getChunkIterationStartEnd(player, consts.chunkProcessingRadius)
	for x = x1, x2 do
		local breakFromX = false
		for y = y1, y2 do
			if chunkPositionIsInRadius(x, y, player, consts.chunkProcessingRadius) then
				if self:getChunkRequest(x, y) then
					breakFromX = true
					forceLoadAll = true
					break
				end
			end
		end
		if breakFromX then
			break
		end
	end
	if forceLoadAll then
		-- TODO: Maybe log forcing loading all chunks?
		while self.activeChunkRequests > 0 do
			self:receiveChunk(self.resultChannel:demand())
			print(self.activeChunkRequests)
		end
	end
	
	local x1, x2, y1, y2 = getChunkIterationStartEnd(player, consts.chunkLoadingRadius)
	for x = x1, x2 do
		for y = y1, y2 do
			if chunkPositionIsInRadius(x, y, player, consts.chunkLoadingRadius) then
				assert(self:getChunkRequest(x, y) or self:getLoadedChunk(x, y))
			end
		end
	end
	
	-- Tick chunks within processing range
	local superWorld = self:getWorld().superWorld
	local rng = superWorld.rng
	local x1, x2, y1, y2 = getChunkIterationStartEnd(player, consts.chunkProcessingRadius)
	for x = x1, x2 do
		for y = y1, y2 do
			if chunkPositionIsInRadius(x, y, player, consts.chunkProcessingRadius) then
				local chunk = self:getLoadedChunk(x, y)
				assert(chunk, "Missing chunk in processing chunks radius at " .. x .. ", " .. y)
				chunk.time = chunk.time + dt
				chunk.randomTickTime = chunk.randomTickTime + dt
				while chunk.randomTickTime >= consts.randomTickInterval do
					local x = rng:random(0, consts.chunkWidth - 1)
					local y = rng:random(0, consts.chunkHeight - 1)
					self:tickTile(chunk.tiles[x][y], dt)
					chunk.randomTickTime = chunk.randomTickTime - consts.randomTickInterval
				end
			end
		end
	end
end

function core:validate()
	-- TODO: Return whether the structure of the map is correct, and state where if not
end

return core
