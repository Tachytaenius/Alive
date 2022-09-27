local list = require("lib.list")

local registry = require("registry")
local consts = require("consts")

local circleAabbCollision = require("util.collision.circleAabb")

local core = {}

function core:init()
	self.chunks = {}
	self.loadedChunks = list()
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
	
	-- Make initial chunks
	for x = 0, 1 do
		for y = 0, 1 do
			local chunk = self:generateChunk(x, y)
			self:addTo2DArray(chunk)
			self.loadedChunks:add(chunk) -- TEMP
			self:makeChunkMeshes(chunk)
		end
	end
end

local function chunkPositionIsInLoadingRadius(x, y, player)
	return circleAabbCollision(
		player.position.value.x, player.position.value.y, consts.chunkLoadingRadius,
		x * consts.chunkWidth * consts.tileWidth, y * consts.chunkHeight * consts.tileHeight, consts.chunkWidth * consts.tileWidth, consts.chunkHeight * consts.tileHeight
	)
end

function core:fixedUpdate(dt)
	local player = self.players[1]
	if not player then
		return
	end
	
	for chunk in self.loadedChunks:elements() do
		if not chunkPositionIsInLoadingRadius(chunk.x, chunk.y, player) then
			-- self:unloadChunk(chunk) TEMP
		end
	end
	
	local x1 = math.floor((player.position.value.x - consts.chunkLoadingRadius) / (consts.chunkWidth * consts.tileWidth))
	local x2 = math.ceil((player.position.value.x + consts.chunkLoadingRadius) / (consts.chunkWidth * consts.tileWidth))
	local y1 = math.floor((player.position.value.y - consts.chunkLoadingRadius) / (consts.chunkHeight * consts.tileHeight))
	local y2 = math.ceil((player.position.value.y + consts.chunkLoadingRadius) / (consts.chunkHeight * consts.tileHeight))
	for x = x1, x2 do
		for y = y1, y2 do
			if chunkPositionIsInLoadingRadius(x, y, player) then
				local column = self.chunks[x]
				if column then
					local chunk = self.chunks[x][y]
					if chunk and not self.loadedChunks:has(chunk) then
						-- self:loadChunk(x, y) TEMP
					end
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
