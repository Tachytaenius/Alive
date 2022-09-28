local consts = require("consts")
local serialisation = require("serialisation")

local chunks = {}

function chunks:removeChunkFromGrid(chunk)
	assert(self.chunks[chunk.x][chunk.y], "No chunk to remove from grid at " .. chunk.x .. ", " .. chunk.y)
	self.chunks[chunk.x][chunk.y] = nil
	local hasValue = false
	for k in pairs(self.chunks[chunk.x]) do
		hasValue = true
		break
	end
	if not hasValue then
		self.chunks[chunk.x] = nil
	end
end

function chunks:addChunkToGrid(chunk)
	self.chunks[chunk.x] = self.chunks[chunk.x] or {}
	assert(not self.chunks[chunk.x][chunk.y], "Can't add to grid, chunk already exists at " .. chunk.x .. ", " .. chunk.y)
	self.chunks[chunk.x][chunk.y] = chunk
end

function chunks:getChunk(x, y)
	if self.chunks[x] then
		return self.chunks[x][y]
	end
end

function chunks:generateChunk(chunkX, chunkY)
	assert(not (self.chunks[chunkX] and self.chunks[chunkX][chunkY]), "Can't generatee chunk, chunk already exists at " .. chunkX .. ", " .. chunkY)
	
	local superWorld = self:getWorld().superWorld
	
	local chunk = {
		x = chunkX, y = chunkY,
		time = 0,
		randomTickTime = 0,
		-- tickCursorX = 0, tickCursorY = 0 -- NOTE: For unused non-random ticks
	}
	
	-- Make the tiles
	local tiles = {}
	chunk.tiles = tiles
	for localTileX = 0, consts.chunkWidth - 1 do
		tiles[localTileX] = {}
		for localTileY = 0, consts.chunkHeight - 1 do
			self:generateTile(chunk, localTileX, localTileY)
		end
	end
	
	self:addChunkToGrid(chunk)
	self:makeChunkMeshes(chunk)
	self.loadedChunks:add(chunk)
	
	return chunk
end

function chunks:loadOrGenerateChunk(x, y)
	local path = "chunks/" .. x .. "," .. y .. ".bin"
	local info = love.filesystem.getInfo(path)
	if not info then
		return self:generateChunk(x, y)
	elseif info.type == "directory" then
		error(path .. " is a directory")
	end
	
	local serialisedData, errorMessage = love.filesystem.read(path)
	assert(serialisedData, "Could not read file for chunk at " .. x .. ", " .. y .. ": " .. errorMessage)
	local chunk = serialisation.deserialiseChunk(serialisedData, x, y)
	for x = 0, consts.chunkWidth - 1 do
		for y = 0, consts.chunkHeight - 1 do
			local tile = chunk.tiles[x][y]
			self:updateLumpDependentTickValues(tile)
			self:updateTileRendering(tile)
		end
	end
	self:addChunkToGrid(chunk)
	self:makeChunkMeshes(chunk)
	self.loadedChunks:add(chunk)
	
	return chunk
end

function chunks:unloadChunk(chunk)
	self:removeChunkFromGrid(chunk)
	self.loadedChunks:remove(chunk)
	local info = love.filesystem.getInfo("chunks/")
	if not info then
		love.filesystem.createDirectory("chunks/")
	elseif info.type ~= "directory" then
		error("There is a non-folder item at chunks/")
	end
	local path = "chunks/" .. chunk.x .. "," .. chunk.y .. ".bin"
	local data = serialisation.serialiseChunk(chunk)
	local success, errorMessage = love.filesystem.write(path, data)
	if not success then
		error("Could not create file for chunk at " .. chunk.x .. ", " .. chunk.y .. ": " .. errorMessage)
	end
end

return chunks
