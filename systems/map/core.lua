local list = require("lib.list")

local registry = require("registry")
local consts = require("consts")

local circleAabbCollision = require("util.collision.circleAabb")

local core = {}

function core:init()
	self.chunks = {}
	self.loadedChunks = list()
end

local function getChunkLoadingStartEnd(player, radius)
	local x1 = math.floor((player.position.value.x - radius) / (consts.chunkWidth * consts.tileWidth))
	local x2 = math.ceil((player.position.value.x + radius) / (consts.chunkWidth * consts.tileWidth))
	local y1 = math.floor((player.position.value.y - radius) / (consts.chunkHeight * consts.tileHeight))
	local y2 = math.ceil((player.position.value.y + radius) / (consts.chunkHeight * consts.tileHeight))
	return x1, x2, y1, y2
end

local function chunkPositionIsInLoadingRadius(x, y, player, radius)
	return circleAabbCollision(
		player.position.value.x, player.position.value.y, radius,
		x * consts.chunkWidth * consts.tileWidth, y * consts.chunkHeight * consts.tileHeight, consts.chunkWidth * consts.tileWidth, consts.chunkHeight * consts.tileHeight
	)
end

function core:newWorld()
	-- Set theme
	self.soilMaterials = {
		{material = registry.materials.byName.loam, abundanceMultiply = 14, noiseWidth = 50, noiseHeight = 50},
		{material = registry.materials.byName.clay, abundanceMultiply = 13, noiseWidth = 50, noiseHeight = 50},
		{material = registry.materials.byName.sand, abundanceMultiply = 5, noiseWidth = 50, noiseHeight = 50},
		{material = registry.materials.byName.silt, abundanceMultiply = 7, noiseWidth = 50, noiseHeight = 50},
		{material = registry.materials.byName.water, abundanceMultiply = 0, abundanceAdd = 10}
	}
	
	local player = self.players[1]
	if player then
		-- Make initial chunks
		local x1, x2, y1, y2 = getChunkLoadingStartEnd(player, consts.chunkLoadingRadius)
		for x = x1, x2 do
			for y = y1, y2 do
				if chunkPositionIsInLoadingRadius(x, y, player, consts.chunkLoadingRadius) then
					self:loadOrGenerateChunk(x, y)
				end
			end
		end
	end
end

function core:fixedUpdate(dt)
	local player = self.players[1]
	if not player then
		return
	end
	
	for chunk in self.loadedChunks:elements() do
		if not chunkPositionIsInLoadingRadius(chunk.x, chunk.y, player, consts.chunkUnloadingRadius) then
			self:unloadChunk(chunk)
		end
	end
	
	local x1, x2, y1, y2 = getChunkLoadingStartEnd(player, consts.chunkLoadingRadius)
	for x = x1, x2 do
		for y = y1, y2 do
			if chunkPositionIsInLoadingRadius(x, y, player, consts.chunkLoadingRadius) then
				if not self:getChunk(x, y) then
					self:loadOrGenerateChunk(x, y)
				end
			end
		end
	end
	
	local rng = self:getWorld().superWorld.rng
	for chunk in self.loadedChunks:elements() do
		for i = 1, consts.randomTicksPerChunkPerTick do
			local x = rng:random(0, consts.chunkWidth - 1)
			local y = rng:random(0, consts.chunkHeight - 1)
			self:tickTile(chunk.tiles[x][y], dt)
		end
	end
	
	-- NOTE: For unused non-random ticks
	-- for chunk in self.loadedChunks:elements() do
	-- 	local x, y = chunk.tickCursorX, chunk.tickCursorY
	-- 	for i = 1, consts.tileTicksPerChunkPerTick do
	-- 		self:tickTile(chunk.tiles[x][y], dt)
	-- 		x = x + 1
	-- 		if x == consts.chunkWidth then
	-- 			x = 0
	-- 			y = y + 1
	-- 		end
	-- 		if y == consts.chunkHeight then
	-- 			y = 0
	-- 		end
	-- 	end
	-- 	chunk.tickCursorX, chunk.tickCursorY = x, y
	-- end
end

function core:validate()
	-- TODO: Return whether the structure of the map is correct, and state where if not
end

return core
